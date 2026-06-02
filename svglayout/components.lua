---@class svglayout.components
local M = {}

local core = require("svglayout.core")
local render = require("svglayout.render")
local layout = require("svglayout.layout")
local measure = require("svglayout.text_measure")
local style_util = require("svglayout.style")

---@alias ComponentNode table 组件节点（含 style、children、_measure、_render 等字段）

---@class svglayout.ComponentProps 通用属性
---@field style? table 样式表
---@field children? table[] 子节点

---创建节点对象
---若 style 是 Style 实例，自动物化为纯样式表
---@param type string 节点类型
---@param props table 属性表
---@return ComponentNode
local function make_node(type, props)
    local style = props.style or {}
    local mt = getmetatable(style)
    if mt and mt._STYLE_MT then
        local plain = {}
        for k, v in pairs(style) do
            plain[k] = v
        end
        style = plain
    end
    return {
        type = type,
        style = style,
        children = props.children or {},
        props = props,
        _id = core.gen_id(type),
    }
end

-- ============ Box ============

---创建通用弹性容器组件
---direction="column" 且未显式声明高度时自动获得分页拆分能力
---@param props svglayout.ComponentProps
---@return ComponentNode
function M.Box(props)
    props = props or {}
    local node = make_node("box", props)

    -- 纵向 Box 的分页拆分逻辑
    local function box_split(self, avail_h)
        local b = self._box
        if not b or not b.content_w then return nil, self end
        local s = self.style
        local pad = style_util.normalize_spacing(s.padding)
        local gap = s.gap or 0
        local dir = s.direction or "column"
        if dir ~= "column" then return nil, self end

        local content_h = avail_h - pad[1] - pad[3]
        if content_h <= 0 then return nil, self end

        local first_children = {}
        local rest_children = {}
        local used = 0

        for i, c in ipairs(self.children) do
            local _, ch = layout.measure(c, b.content_w, nil)
            local need_gap = (#first_children > 0) and gap or 0

            if used + need_gap + ch <= content_h then
                table.insert(first_children, c)
                used = used + need_gap + ch
            elseif c._splittable and c._split then
                local avail = content_h - used - need_gap
                if avail > 0 then
                    layout.layout_fixed(c, 0, 0, b.content_w, avail)
                    local first, rest = c:_split(avail)
                    if first then table.insert(first_children, first) end
                    if rest then table.insert(rest_children, rest) end
                else
                    table.insert(rest_children, c)
                end
                for j = i + 1, #self.children do
                    table.insert(rest_children, self.children[j])
                end
                break
            else
                table.insert(rest_children, c)
                for j = i + 1, #self.children do
                    table.insert(rest_children, self.children[j])
                end
                break
            end
        end

        if #first_children == 0 then return nil, self end

        local first = M.Box { style = core.shallow_copy(s), children = first_children }
        local rest = nil
        if #rest_children > 0 then
            rest = M.Box { style = core.shallow_copy(s), children = rest_children }
        end
        return first, rest
    end

    -- 纵向无固定高度时启用分页
    local s = props.style or {}
    if (s.direction or "column") == "column" and type(s.height) ~= "number" and (props.children and #props.children > 0) then
        node._splittable = true
        node._split = box_split
    end

    function node:_render(ctx)
        local parts = {}
        for _, c in ipairs(self.children) do
            parts[#parts + 1] = render.render(c, ctx)
        end
        return render.render_box(self, table.concat(parts, "\n"), ctx)
    end
    return node
end

-- ============ Text（单行） ============

---@class svglayout.TextProps
---@field text? string 文本
---@field style? table 样式

---创建单行文本组件
---支持颜色、字体大小、水平对齐等样式控制
---@param props svglayout.TextProps
---@return ComponentNode
function M.Text(props)
    props = props or {}
    local node = make_node("text", props)
    node.text = props.text or ""

    function node:_measure(hint_w, hint_h)
        local s = self.style
        local fs = s.font_size or 14
        local tw = measure.text_width(self.text, fs)
        local th = fs * (s.line_height or 1.2)
        return tw, th
    end

    function node:_render(ctx)
        local b = self._box
        local s = self.style
        local fs = s.font_size or 14
        local anchor, tx = core.compute_text_alignment(s.text_align, b.content_x, b.content_w)
        local ty = b.content_y + fs
        local attrs = {
            x = tx, y = ty,
            ["font-family"] = s.font_family or "sans-serif",
            ["font-size"] = fs,
            ["font-weight"] = s.font_weight,
            fill = render.resolve_paint(s.color or s.fill, ctx) or "#000",
            ["text-anchor"] = anchor,
        }
        local inner = string.format("<text %s>%s</text>",
            core.attrs_to_str(attrs), core.escape_xml(self.text))
        local skip = (s.background == nil) and (s.border == nil)
        return render.render_box(self, inner, ctx, { skip_bg = skip })
    end
    return node
end

-- ============ TextBlock（多行） ============

---@class svglayout.TextBlockProps
---@field text? string 文本
---@field line_height? number 行高倍率（默认 1.4）
---@field style? table 样式

---创建多行文本组件
---支持自动换行和分页拆分；CJK 逐字换行，英文按空格换行
---@param props svglayout.TextBlockProps
---@return ComponentNode
function M.TextBlock(props)
    props = props or {}
    local node = make_node("text_block", props)
    node.text = props.text or ""
    node.line_height = props.line_height or 1.4
    node._splittable = true

    -- 计算换行，结果缓存在 self._lines
    local function compute_lines(self, content_w)
        local fs = self.style.font_size or 14
        if content_w and content_w > 0 then
            self._lines = measure.wrap(self.text, content_w, fs)
        else
            self._lines = { self.text }
        end
        self._line_h = fs * self.line_height
        self._last_cw = content_w
    end

    function node:_measure(hint_w, hint_h)
        local fs = self.style.font_size or 14
        if hint_w and hint_w > 0 then
            compute_lines(self, hint_w)
            local maxw = 0
            for _, ln in ipairs(self._lines) do
                local lw = measure.text_width(ln, fs)
                if lw > maxw then maxw = lw end
            end
            return math.min(maxw, hint_w), #self._lines * self._line_h
        else
            local w = measure.text_width(self.text, fs)
            return w, fs * self.line_height
        end
    end

    -- 按行拆分文本用于分页
    function node:_split(avail_h)
        local b = self._box
        if not self._lines or self._last_cw ~= b.content_w then
            compute_lines(self, b.content_w)
        end
        local fit = math.floor(avail_h / self._line_h)
        if fit <= 0 then return nil, self end
        if fit >= #self._lines then return self, nil end

        local first_lines, rest_lines = {}, {}
        for i, ln in ipairs(self._lines) do
            if i <= fit then first_lines[#first_lines + 1] = ln
            else rest_lines[#rest_lines + 1] = ln end
        end
        return M.TextBlock {
            text = table.concat(first_lines, "\n"),
            line_height = self.line_height,
            style = core.shallow_copy(self.style),
        }, M.TextBlock {
            text = table.concat(rest_lines, "\n"),
            line_height = self.line_height,
            style = core.shallow_copy(self.style),
        }
    end

    function node:_render(ctx)
        local b = self._box
        local s = self.style
        local fs = s.font_size or 14
        if not self._lines or self._last_cw ~= b.content_w then
            compute_lines(self, b.content_w)
        end
        local anchor, tx = core.compute_text_alignment(s.text_align, b.content_x, b.content_w)

        local parts = { string.format(
            '<text font-family="%s" font-size="%s" fill="%s" text-anchor="%s"%s>',
            s.font_family or "sans-serif", fs,
            render.resolve_paint(s.color or s.fill, ctx) or "#000", anchor,
            s.font_weight and (' font-weight="' .. s.font_weight .. '"') or "") }
        for i, line in ipairs(self._lines) do
            local ty = b.content_y + fs + (i - 1) * self._line_h
            parts[#parts + 1] = string.format(
                '<tspan x="%s" y="%s">%s</tspan>',
                tx, ty, core.escape_xml(line))
        end
        parts[#parts + 1] = "</text>"
        local skip = (s.background == nil) and (s.border == nil)
        return render.render_box(self, table.concat(parts), ctx, { skip_bg = skip })
    end
    return node
end

-- ============ Rect / Circle / Line / Path ============

-- 形状组件的默认测量：返回固定尺寸或 0
local function shape_measure(self)
    local s = self.style
    local w = type(s.width) == "number" and s.width or 0
    local h = type(s.height) == "number" and s.height or 0
    return w, h
end

---@class svglayout.RectProps
---@field style? table 支持 fill、stroke、stroke_width、border_radius

---创建矩形组件，支持圆角和填充/描边
---@param props svglayout.RectProps
---@return ComponentNode
function M.Rect(props)
    props = props or {}
    local node = make_node("rect", props)
    node._measure = shape_measure
    function node:_render(ctx)
        local b = self._box; local s = self.style
        local attrs = {
            x = b.x, y = b.y, width = b.w, height = b.h,
            rx = s.border_radius, ry = s.border_radius,
            fill = render.resolve_paint(s.fill, ctx) or "#000",
            stroke = render.resolve_paint(s.stroke, ctx),
            ["stroke-width"] = s.stroke_width,
        }
        local inner = "<rect " .. core.attrs_to_str(attrs) .. "/>"
        return render.render_box(self, inner, ctx, { skip_bg = true })
    end
    return node
end

---@class svglayout.CircleProps
---@field r? number 半径（仅未通过 style.width/height 设置时生效）
---@field style? table

---创建圆形组件
---@param props svglayout.CircleProps
---@return ComponentNode
function M.Circle(props)
    props = props or {}
    local node = make_node("circle", props)
    node._measure = function(self)
        local s = self.style
        local d = 0
        if type(s.width) == "number" then d = s.width end
        if type(s.height) == "number" and s.height > d then d = s.height end
        if props.r then d = props.r * 2 end
        return d, d
    end
    function node:_render(ctx)
        local b = self._box; local s = self.style
        local r = props.r or math.min(b.w, b.h) / 2
        local attrs = {
            cx = b.x + b.w / 2, cy = b.y + b.h / 2, r = r,
            fill = render.resolve_paint(s.fill, ctx) or "#000",
            stroke = render.resolve_paint(s.stroke, ctx),
            ["stroke-width"] = s.stroke_width,
        }
        local inner = "<circle " .. core.attrs_to_str(attrs) .. "/>"
        return render.render_box(self, inner, ctx, { skip_bg = true })
    end
    return node
end

---@class svglayout.LineProps
---@field x1? number 起点 X（默认左边界）
---@field y1? number 起点 Y（默认上边界）
---@field x2? number 终点 X（默认右边界）
---@field y2? number 终点 Y（默认下边界）
---@field style? table

---创建线条组件
---@param props svglayout.LineProps
---@return ComponentNode
function M.Line(props)
    props = props or {}
    local node = make_node("line", props)
    node._measure = shape_measure
    function node:_render(ctx)
        local b = self._box; local s = self.style
        local attrs = {
            x1 = props.x1 or b.x, y1 = props.y1 or b.y,
            x2 = props.x2 or (b.x + b.w), y2 = props.y2 or (b.y + b.h),
            stroke = render.resolve_paint(s.stroke, ctx) or "#000",
            ["stroke-width"] = s.stroke_width or 1,
        }
        local inner = "<line " .. core.attrs_to_str(attrs) .. "/>"
        return render.render_box(self, inner, ctx, { skip_bg = true })
    end
    return node
end

---@class svglayout.PathProps
---@field d string SVG path 数据
---@field style? table

---创建 SVG 路径组件
---@param props svglayout.PathProps
---@return ComponentNode
function M.Path(props)
    props = props or {}
    local node = make_node("path", props)
    node._measure = shape_measure
    function node:_render(ctx)
        local s = self.style
        local attrs = {
            d = props.d,
            fill = render.resolve_paint(s.fill, ctx) or "none",
            stroke = render.resolve_paint(s.stroke, ctx),
            ["stroke-width"] = s.stroke_width,
        }
        local inner = "<path " .. core.attrs_to_str(attrs) .. "/>"
        return render.render_box(self, inner, ctx, { skip_bg = true })
    end
    return node
end

-- ============ Group ============

---创建 SVG 组组件
---用于将多个元素组合，统一应用变换、透明度等效果
---@param props svglayout.ComponentProps
---@return ComponentNode
function M.Group(props)
    props = props or {}
    local node = make_node("group", props)
    function node:_render(ctx)
        local parts = {}
        for _, c in ipairs(self.children) do
            parts[#parts + 1] = render.render(c, ctx)
        end
        return render.render_box(self, table.concat(parts, "\n"), ctx, { skip_bg = true })
    end
    return node
end

-- ============ Raw ============

---创建原始 SVG 组件（直接嵌入任意 SVG 代码）
---@param props {svg?:string, style?:table}
---@return ComponentNode
function M.Raw(props)
    props = props or {}
    local node = make_node("raw", props)
    node.svg = props.svg or ""
    node._measure = shape_measure
    function node:_render(ctx)
        local skip = (self.style.background == nil) and (self.style.border == nil)
        return render.render_box(self, self.svg, ctx, { skip_bg = skip })
    end
    return node
end

-- ============ Image ============

---@class svglayout.ImageProps
---@field href? string 图片 URL
---@field preserve_aspect_ratio? string SVG preserveAspectRatio（默认 "xMidYMid meet"）
---@field nine_patch? svglayout.NinePatchConfig|boolean 九宫格配置
---@field nine_patch_repeat? table<string,string> 逐块重复模式覆盖
---@field style? table

---创建图像组件，支持普通嵌入和九宫格渲染
---@param props svglayout.ImageProps
---@return ComponentNode
function M.Image(props)
    props = props or {}
    local node = make_node("image", props)
    node._measure = shape_measure

    local np_config = props.nine_patch
    local parsed_np = nil

    if type(np_config) == "table" then
        local nine_patch = require("svglayout.nine_patch")
        if np_config.blocks then
            parsed_np = np_config
            parsed_np.href = parsed_np.href or props.href
        else
            np_config.href = np_config.href or props.href
            parsed_np = nine_patch.parse_config(np_config)
        end
    end

    function node:_render(ctx)
        local b = self._box

        if parsed_np then
            local nine_patch = require("svglayout.nine_patch")
            local inner = nine_patch.render(ctx, parsed_np, b, props.nine_patch_repeat)
            local skip = (self.style.background == nil) and (self.style.border == nil)
            return render.render_box(self, inner, ctx, { skip_bg = skip })
        end

        local attrs = {
            x = b.x, y = b.y, width = b.w, height = b.h,
            href = props.href,
            preserveAspectRatio = props.preserve_aspect_ratio or "xMidYMid meet",
        }
        local inner = "<image " .. core.attrs_to_str(attrs) .. "/>"
        local skip = (self.style.background == nil) and (self.style.border == nil)
        return render.render_box(self, inner, ctx, { skip_bg = skip })
    end
    return node
end

-- ============ 进阶容器组件 ============

---创建水平弹性容器（Box + direction="row"）
---@param props svglayout.ComponentProps
---@return ComponentNode
function M.Row(props)
    props = props or {}
    local base_style = { direction = "row" }
    props.style = style_util.extend(base_style, props.style or {})
    return M.Box(props)
end

---创建垂直弹性容器（Box + direction="column"）
---@param props svglayout.ComponentProps
---@return ComponentNode
function M.Column(props)
    props = props or {}
    local base_style = { direction = "column" }
    props.style = style_util.extend(base_style, props.style or {})
    return M.Box(props)
end

---创建层叠容器（Box + direction="stack"）
---子节点在 Z 轴上层叠排列
---@param props svglayout.ComponentProps
---@return ComponentNode
function M.ZStack(props)
    props = props or {}
    local base_style = { direction = "stack" }
    props.style = style_util.extend(base_style, props.style or {})
    return M.Box(props)
end

---创建弹性空白填充（Box + flex=1）
---@param props? svglayout.ComponentProps
---@return ComponentNode
function M.Spacer(props)
    props = props or {}
    local base_style = { flex = 1 }
    props.style = style_util.extend(base_style, props.style or {})
    return M.Box(props)
end

---@class svglayout.DividerProps
---@field color? string 颜色（默认 "#e0e0e0"）
---@field thickness? number 粗细（默认 1）
---@field direction? string "horizontal"|"vertical"（默认 "horizontal"）
---@field margin? number|table 外边距（默认 {8,0,8,0}）
---@field style? table 附加样式

---创建分割线组件
---@param props svglayout.DividerProps
---@return ComponentNode
function M.Divider(props)
    props = props or {}
    local color = props.color or "#e0e0e0"
    local thickness = props.thickness or 1
    local dir = props.direction or "horizontal"
    local margin = props.margin or { 8, 0, 8, 0 }

    local base_style
    if dir == "vertical" then
        base_style = { width = thickness, height = "fill", background = color, margin = margin }
    else
        base_style = { height = thickness, width = "fill", background = color, margin = margin }
    end
    props.style = style_util.extend(base_style, props.style or {})
    return M.Box(props)
end

return M
