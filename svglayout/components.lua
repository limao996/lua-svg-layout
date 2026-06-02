---@class svglayout.components
local M = {}

local core = require("svglayout.core")
local render = require("svglayout.render")
local layout = require("svglayout.layout")
local measure = require("svglayout.text_measure")
local style_util = require("svglayout.style")

---@alias ComponentNode table 组件节点对象，包含 style、children、_measure、_render 等字段

---@class svglayout.ComponentProps 通用组件属性
---@field style? table 样式表
---@field children? table[] 子节点数组

---创建节点对象
---若 style 是 Style 实例（链式 API），会自动物化为纯样式表
---@param type string 节点类型标识
---@param props table 属性表
---@return ComponentNode 节点对象
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

---创建弹性容器组件，支持 Flexbox 布局
---根据 direction 属性支持 row（水平）、column（纵向）和 stack（重叠）三种布局模式
---纵向布局的 Box 且未显式声明高度时，自动获得可拆分能力（支持分页）
---@param props svglayout.ComponentProps 组件属性
---@return ComponentNode Box 节点对象
function M.Box(props)
    props = props or {}
    local node = make_node("box", props)

    ---拆分 Box 的子节点用于分页
    ---将子节点按可用高度拆分为"放入当前页"和"剩余"两部分
    ---@param self table Box 节点自身
    ---@param avail_h number 可用于放置子节点的垂直空间
    ---@return ComponentNode? first 放入当前页的部分，nil 表示无法拆分
    ---@return ComponentNode? rest 剩余部分，nil 表示已全部放入
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
                    if first then
                        table.insert(first_children, first)
                    end
                    if rest then
                        table.insert(rest_children, rest)
                    end
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

        local first = M.Box {
            style = core.shallow_copy(s),
            children = first_children,
        }
        local rest = nil
        if #rest_children > 0 then
            rest = M.Box {
                style = core.shallow_copy(s),
                children = rest_children,
            }
        end
        return first, rest
    end

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

---@class svglayout.TextProps 单行文本组件属性
---@field text? string 文本内容
---@field style? table 样式表

---创建单行文本组件
---支持字体大小、颜色、水平对齐等样式控制
---文本宽度通过估算方式计算（非精确字体度量）
---@param props svglayout.TextProps 组件属性
---@return ComponentNode Text 节点对象
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

---@class svglayout.TextBlockProps 多行文本组件属性
---@field text? string 文本内容
---@field line_height? number 行高倍率，默认 1.4
---@field style? table 样式表

---创建多行文本组件
---支持自动换行和分页拆分；换行策略区分 CJK 字符（逐字换行）和英文单词（按空格换行）
---文本宽度通过估算方式计算，适合 CJK 和混合文本场景
---@param props svglayout.TextBlockProps 组件属性
---@return ComponentNode TextBlock 节点对象
function M.TextBlock(props)
    props = props or {}
    local node = make_node("text_block", props)
    node.text = props.text or ""
    node.line_height = props.line_height or 1.4
    node._splittable = true

    ---计算文本行，根据内容宽度进行换行
    ---结果缓存在 self._lines 中，同时记录 last_cw 以检测宽度变化
    ---@param self table 节点自身
    ---@param content_w number 内容区宽度
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

    ---拆分 TextBlock 用于分页
    ---按行拆分：计算可用高度能容纳的行数，将文本分为"当前页"和"剩余"两部分
    ---@param self table 节点自身
    ---@param avail_h number 可用于放置文本的垂直空间
    ---@return ComponentNode? first 放入当前页的部分
    ---@return ComponentNode? rest 剩余部分
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

---形状组件的默认测量函数
---若未声明尺寸，intrinsic 返回 0（由父容器的 align=stretch 或 fill 决定最终尺寸）
---@param self table 形状节点自身
---@return number width 形状自然宽度
---@return number height 形状自然高度
local function shape_measure(self)
    local s = self.style
    local w = type(s.width) == "number" and s.width or 0
    local h = type(s.height) == "number" and s.height or 0
    return w, h
end

---@class svglayout.RectProps 矩形组件属性
---@field style? table 样式表，支持 fill、stroke、stroke_width、border_radius 等

---创建矩形组件
---支持圆角（border_radius）、填充（fill）和描边（stroke）样式
---@param props svglayout.RectProps 组件属性
---@return ComponentNode Rect 节点对象
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

---@class svglayout.CircleProps 圆形组件属性
---@field r? number 圆的半径（仅在未通过 style.width/height 设置尺寸时生效）
---@field style? table 样式表，支持 fill、stroke、stroke_width 等

---创建圆形组件
---支持通过 style.width/height 或 props.r 控制圆形直径
---@param props svglayout.CircleProps 组件属性
---@return ComponentNode Circle 节点对象
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

---@class svglayout.LineProps 线条组件属性
---@field x1? number 起点 X 坐标，默认使用盒子左边界
---@field y1? number 起点 Y 坐标，默认使用盒子上边界
---@field x2? number 终点 X 坐标，默认使用盒子右边界
---@field y2? number 终点 Y 坐标，默认使用盒子下边界
---@field style? table 样式表，支持 stroke、stroke_width 等

---创建线条组件
---通过 x1/y1/x2/y2 指定起点和终点坐标，未指定时使用盒子边界
---@param props svglayout.LineProps 组件属性
---@return ComponentNode Line 节点对象
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

---@class svglayout.PathProps 路径组件属性
---@field d string SVG path 数据（如 "M10 10 L20 20"）
---@field style? table 样式表，支持 fill、stroke、stroke_width 等

---创建路径组件
---支持 SVG path 数据字符串和完整的填充/描边样式控制
---@param props svglayout.PathProps 组件属性
---@return ComponentNode Path 节点对象
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

---@class svglayout.GroupProps 组组件属性
---@field style? table 样式表
---@field children? table[] 子节点数组

---创建 SVG 组件组
---用于将多个元素组合为一个逻辑单元，统一应用变换、透明度等效果
---@param props svglayout.GroupProps 组件属性
---@return ComponentNode Group 节点对象
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

---@class svglayout.RawProps 原始 SVG 组件属性
---@field svg? string 原始 SVG 代码字符串
---@field style? table 样式表

---创建原始 SVG 组件
---直接嵌入任意 SVG 代码，不进行任何处理或转义
---@param props svglayout.RawProps 组件属性
---@return ComponentNode Raw 节点对象
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

---@class svglayout.ImageProps 图像组件属性
---@field href? string 图像 URL 或路径
---@field preserve_aspect_ratio? string SVG preserveAspectRatio 属性，默认 "xMidYMid meet"
---@field style? table 样式表

---创建图像组件
---使用 SVG `<image>` 标签嵌入外部图片，支持宽高比控制
---@param props svglayout.ImageProps 组件属性
---@return ComponentNode Image 节点对象
function M.Image(props)
    props = props or {}
    local node = make_node("image", props)
    node._measure = shape_measure
    function node:_render(ctx)
        local b = self._box
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
-- Row / Column / ZStack 是 Box 的声明式别名，预设 direction 方向
-- Spacer / Divider 是常用的辅助容器元素

---创建水平弹性容器（Box + direction="row"）
---子节点沿水平方向排列，支持 flex、gap、justify、align 等布局属性
---@param props svglayout.ComponentProps 组件属性
---@return ComponentNode Row 节点对象
function M.Row(props)
    props = props or {}
    local base_style = { direction = "row" }
    props.style = style_util.extend(base_style, props.style or {})
    return M.Box(props)
end

---创建垂直弹性容器（Box + direction="column"）
---子节点沿垂直方向排列，支持 flex、gap、justify、align 等布局属性
---未显式声明高度时自动获得分页拆分能力
---@param props svglayout.ComponentProps 组件属性
---@return ComponentNode Column 节点对象
function M.Column(props)
    props = props or {}
    local base_style = { direction = "column" }
    props.style = style_util.extend(base_style, props.style or {})
    return M.Box(props)
end

---创建层叠容器（Box + direction="stack"）
---子节点在 Z 轴上层叠排列，后加入的子节点在上层
---常用于叠加文本标签、遮罩层等场景
---@param props svglayout.ComponentProps 组件属性
---@return ComponentNode ZStack 节点对象
function M.ZStack(props)
    props = props or {}
    local base_style = { direction = "stack" }
    props.style = style_util.extend(base_style, props.style or {})
    return M.Box(props)
end

---创建弹性空白填充元素
---自动占据父容器主轴上的剩余空间，用于在 Row/Column 中推开其他元素
---等价于 Box { style = { flex = 1 } }
---@param props? svglayout.ComponentProps 组件属性
---@return ComponentNode Spacer 节点对象
function M.Spacer(props)
    props = props or {}
    local base_style = { flex = 1 }
    props.style = style_util.extend(base_style, props.style or {})
    return M.Box(props)
end

---@class svglayout.DividerProps 分割线组件属性
---@field color? string 分割线颜色，默认 "#e0e0e0"
---@field thickness? number 分割线粗细，默认 1
---@field direction? string 分割线方向，"horizontal" 或 "vertical"，默认 "horizontal"
---@field margin? number|table 分割线外边距，默认 { 8, 0, 8, 0 }
---@field style? table 附加样式表（可覆盖上述属性）

---创建分割线组件
---作为视觉分隔元素，支持水平和垂直方向
---@param props svglayout.DividerProps 组件属性
---@return ComponentNode Divider 节点对象
function M.Divider(props)
    props = props or {}
    local color = props.color or "#e0e0e0"
    local thickness = props.thickness or 1
    local dir = props.direction or "horizontal"
    local margin = props.margin or { 8, 0, 8, 0 }

    local base_style
    if dir == "vertical" then
        base_style = {
            width = thickness,
            height = "fill",
            background = color,
            margin = margin,
        }
    else
        base_style = {
            height = thickness,
            width = "fill",
            background = color,
            margin = margin,
        }
    end
    props.style = style_util.extend(base_style, props.style or {})
    return M.Box(props)
end

return M
