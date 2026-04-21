local core = require("svglayout.core")
local render = require("svglayout.render")
local measure = require("svglayout.text_measure")
local style_util = require("svglayout.style")

local M = {}

local function make_node(type, props)
    return {
        type = type,
        style = props.style or {},
        children = props.children or {},
        props = props,
        _id = core.gen_id(type),
    }
end

-- ============ Box ============
function M.Box(props)
    props = props or {}
    local node = make_node("box", props)
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
function M.Text(props)
    props = props or {}
    local node = make_node("text", props)
    node.text = props.text or ""

    -- 关键：实现 _measure，返回 content 尺寸
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
        local align = s.text_align or "left"
        local anchor, tx
        if align == "center" then anchor = "middle"; tx = b.content_x + b.content_w / 2
        elseif align == "right" then anchor = "end"; tx = b.content_x + b.content_w
        else anchor = "start"; tx = b.content_x end
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
function M.TextBlock(props)
    props = props or {}
    local node = make_node("text_block", props)
    node.text = props.text or ""
    node.line_height = props.line_height or 1.4
    node._splittable = true

    local function compute_lines(self, content_w)
        local fs = self.style.font_size or 14
        if content_w and content_w > 0 then
            self._lines = measure.wrap(self.text, content_w, fs)
        else
            -- 没有宽度提示时不换行
            self._lines = { self.text }
        end
        self._line_h = fs * self.line_height
        self._last_cw = content_w
    end

    -- 返回 content 尺寸（不含 padding）
    function node:_measure(hint_w, hint_h)
        local fs = self.style.font_size or 14
        if hint_w and hint_w > 0 then
            compute_lines(self, hint_w)
            -- 宽度：实际最长行宽
            local maxw = 0
            for _, ln in ipairs(self._lines) do
                local lw = measure.text_width(ln, fs)
                if lw > maxw then maxw = lw end
            end
            return math.min(maxw, hint_w), #self._lines * self._line_h
        else
            -- 没有宽度提示，单行宽
            local w = measure.text_width(self.text, fs)
            return w, fs * self.line_height
        end
    end

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
        local align = s.text_align or "left"
        local anchor, tx
        if align == "center" then anchor = "middle"; tx = b.content_x + b.content_w / 2
        elseif align == "right" then anchor = "end"; tx = b.content_x + b.content_w
        else anchor = "start"; tx = b.content_x end

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
-- 形状：若未声明尺寸，intrinsic 给 0（由父容器的 align=stretch 或 fill 决定）
local function shape_measure(self)
    -- 形状的 intrinsic 就是 style.width/height（若有），否则 0
    local s = self.style
    local w = type(s.width) == "number" and s.width or 0
    local h = type(s.height) == "number" and s.height or 0
    return w, h
end

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

return M
