---@class svglayout.layout
local M = {}

local style_util = require("svglayout.style")

---@alias LayoutDirection '"row"'|'"column"'|'"stack"' 布局主轴方向
---@alias JustifyMode '"start"'|'"center"'|'"end"'|'"space-between"'|'"space-around"' 主轴对齐模式
---@alias AlignMode '"start"'|'"center"'|'"end"'|'"stretch"' 交叉轴对齐模式
---@alias SizeMode '"fixed"'|'"auto"'|'"fill"' 尺寸解析模式

---@class LayoutBox 布局完成后节点拥有的盒子几何信息
---@field x number 盒子左上角 X 坐标（已包含父容器偏移）
---@field y number 盒子左上角 Y 坐标（已包含父容器偏移）
---@field w number 盒子总宽度（含 padding）
---@field h number 盒子总高度（含 padding）
---@field content_x number 内容区左上角 X 坐标
---@field content_y number 内容区左上角 Y 坐标
---@field content_w number 内容区宽度（不含 padding）
---@field content_h number 内容区高度（不含 padding）

---@class IntrinsicSize Measure 阶段计算的自然尺寸
---@field w number 自然宽度（含 padding）
---@field h number 自然高度（含 padding）
---@field content_w? number 自然内容区宽度（不含 padding）
---@field content_h? number 自然内容区高度（不含 padding）

-- =======================================================================
-- 阶段 1：MEASURE —— 计算 intrinsic（自然尺寸）
-- 返回的尺寸包含节点自身的 padding，但不含 margin
-- hint_w / hint_h 是父容器给的"建议可用宽高"（用于换行等），nil 表示不限
-- =======================================================================

---测量节点的自然尺寸（intrinsic size）
---递归计算子节点尺寸，支持固定尺寸、百分比、auto 以及 flex 加权分配前的基础尺寸
---@param node table 要测量的节点对象
---@param hint_w? number 父容器建议的可用宽度，nil 表示不限
---@param hint_h? number 父容器建议的可用高度，nil 表示不限
---@return number intrinsic_w 节点自然宽度（含 padding）
---@return number intrinsic_h 节点自然高度（含 padding）
function M.measure(node, hint_w, hint_h)
    local s = node.style or {}
    local pad = style_util.normalize_spacing(s.padding)

    local fixed_w = nil
    local fixed_h = nil
    if type(s.width) == "number" then fixed_w = s.width
    elseif type(s.width) == "string" then
        local pct = s.width:match("^(%-?[%d%.]+)%%$")
        if pct and hint_w then fixed_w = hint_w * tonumber(pct) / 100 end
        if not pct and tonumber(s.width) then fixed_w = tonumber(s.width) end
    end
    if type(s.height) == "number" then fixed_h = s.height
    elseif type(s.height) == "string" then
        local pct = s.height:match("^(%-?[%d%.]+)%%$")
        if pct and hint_h then fixed_h = hint_h * tonumber(pct) / 100 end
        if not pct and tonumber(s.height) then fixed_h = tonumber(s.height) end
    end

    if node._measure then
        local content_hint_w = (fixed_w or hint_w)
        if content_hint_w then content_hint_w = content_hint_w - pad[2] - pad[4] end
        local cw, ch = node:_measure(content_hint_w, hint_h)
        local iw = (fixed_w) or (cw + pad[2] + pad[4])
        local ih = (fixed_h) or (ch + pad[1] + pad[3])
        node._intrinsic = { w = iw, h = ih, content_w = iw - pad[2] - pad[4], content_h = ih - pad[1] - pad[3] }
        return iw, ih
    end

    local children = node.children or {}
    if #children == 0 then
        local iw = fixed_w or (pad[2] + pad[4])
        local ih = fixed_h or (pad[1] + pad[3])
        node._intrinsic = { w = iw, h = ih }
        return iw, ih
    end

    local dir = s.direction or "column"
    local gap = s.gap or 0

    local child_hint_w = (fixed_w or hint_w)
    if child_hint_w then child_hint_w = child_hint_w - pad[2] - pad[4] end
    local child_hint_h = (fixed_h or hint_h)
    if child_hint_h then child_hint_h = child_hint_h - pad[1] - pad[3] end

    local main_total = 0
    local cross_max = 0
    local max_w = 0
    local max_h = 0

    for i, child in ipairs(children) do
        local cw, ch
        if dir == "row" then
            cw, ch = M.measure(child, nil, child_hint_h)
            if i > 1 then main_total = main_total + gap end
            main_total = main_total + cw
            if ch > cross_max then cross_max = ch end
            if cw > max_w then max_w = cw end
            if ch > max_h then max_h = ch end
        elseif dir == "column" then
            cw, ch = M.measure(child, child_hint_w, nil)
            if i > 1 then main_total = main_total + gap end
            main_total = main_total + ch
            if cw > cross_max then cross_max = cw end
            if cw > max_w then max_w = cw end
            if ch > max_h then max_h = ch end
        else
            cw, ch = M.measure(child, child_hint_w, child_hint_h)
            if cw > max_w then max_w = cw end
            if ch > max_h then max_h = ch end
        end
    end

    local content_w, content_h
    if dir == "row" then
        content_w = main_total
        content_h = cross_max
    elseif dir == "column" then
        content_w = cross_max
        content_h = main_total
    else
        content_w = max_w
        content_h = max_h
    end

    local iw = fixed_w or (content_w + pad[2] + pad[4])
    local ih = fixed_h or (content_h + pad[1] + pad[3])
    node._intrinsic = { w = iw, h = ih }
    return iw, ih
end

-- =======================================================================
-- 阶段 2+3：layout —— 根据父给定的盒子尺寸放置子节点
-- 入口在外部调用，顶层节点的 avail_w/h 会被视作可用空间
-- =======================================================================

---分配主轴尺寸给一组子节点
---根据 flex 权重、固定尺寸和 auto 模式分配主轴上的空间
---@param children table[] 子节点数组
---@param dir LayoutDirection 布局方向
---@param content_main number 内容区主轴总尺寸
---@param content_cross number 内容区交叉轴总尺寸
---@param gap number 子节点间距
---@return number[] 每个子节点分配到的主轴尺寸数值
---@return string[] 每个子节点的分配模式
local function distribute_main(children, dir, content_main, content_cross, gap)
    local n = #children
    local total_gap = gap * math.max(n - 1, 0)
    local sizes = {}
    local modes = {}
    local flexes = {}
    local fixed_sum = 0
    local flex_sum = 0

    for i, child in ipairs(children) do
        local cs = child.style or {}
        local raw = (dir == "row") and cs.width or cs.height
        local val, mode = style_util.resolve_size(raw, content_main)
        local flex = cs.flex

        if dir == "stack" then
            flex = nil
            if mode == "fill" then mode = "auto" end
        elseif type(flex) == "number" and flex > 0 then
            mode = "flex"
        elseif mode == "fill" then
            mode = "flex"; flex = 1
        end

        modes[i] = mode
        flexes[i] = flex or 0

        if mode == "fixed" then
            sizes[i] = val
            fixed_sum = fixed_sum + val
        elseif mode == "flex" then
            flex_sum = flex_sum + (flex or 1)
            sizes[i] = 0
        else
            local iw, ih = M.measure(child,
                (dir == "row") and nil or content_cross,
                (dir == "row") and content_cross or nil)
            local main = (dir == "row") and iw or ih
            sizes[i] = main
            fixed_sum = fixed_sum + main
        end
    end

    local remaining = content_main - total_gap - fixed_sum
    if remaining < 0 then remaining = 0 end
    if flex_sum > 0 then
        for i = 1, n do
            if modes[i] == "flex" then
                sizes[i] = remaining * (flexes[i] == 0 and 1 or flexes[i]) / flex_sum
            end
        end
    end

    if dir == "stack" then
        for i = 1, n do
            sizes[i] = content_main
        end
    end

    return sizes, modes
end

---计算子节点在交叉轴上的尺寸
---根据子节点样式声明和交叉轴对齐模式决定最终交叉轴尺寸
---@param child table 子节点
---@param dir LayoutDirection 布局方向
---@param content_cross number 内容区交叉轴总尺寸
---@param align AlignMode 交叉轴对齐模式
---@param main_size number 子节点已分配的主轴尺寸
---@return number 子节点在交叉轴上的最终尺寸
local function resolve_cross(child, dir, content_cross, align, main_size)
    local cs = child.style or {}
    local raw
    if dir == "row" then
        raw = cs.height
    elseif dir == "column" then
        raw = cs.width
    else
        raw = cs.height
    end

    local val, mode = style_util.resolve_size(raw, content_cross)
    if mode == "fixed" then return val end
    if mode == "fill" then return content_cross end
    if align == "stretch" then
        return content_cross
    end
    local iw, ih = M.measure(child,
        (dir == "row") and main_size or nil,
        (dir == "row") and nil or main_size)
    local cross
    if dir == "row" then
        cross = ih
    elseif dir == "column" then
        cross = iw
    else
        cross = content_cross
    end
    if cross > content_cross then cross = content_cross end
    return cross
end

---以固定的外部尺寸对节点进行精确布局
---计算节点自身的 content 区坐标，然后递归放置所有子节点
---@param node table 节点对象
---@param x number 盒子左上角绝对 X 坐标
---@param y number 盒子左上角绝对 Y 坐标
---@param w number 盒子宽度
---@param h number 盒子高度
---@return LayoutBox 布局完成的盒子几何信息
function M.layout_fixed(node, x, y, w, h)
    local style = node.style or {}
    local pad = style_util.normalize_spacing(style.padding)

    node._box = {
        x = x, y = y, w = w, h = h,
        content_x = x + pad[4], content_y = y + pad[1],
        content_w = w - pad[2] - pad[4],
        content_h = h - pad[1] - pad[3],
    }

    local children = node.children or {}
    if #children == 0 then return node._box end

    local dir = style.direction or "column"
    local gap = style.gap or 0
    local justify = style.justify or "start"
    local align = style.align or "stretch"

    local content_main, content_cross
    if dir == "row" then
        content_main = node._box.content_w
        content_cross = node._box.content_h
    elseif dir == "column" then
        content_main = node._box.content_h
        content_cross = node._box.content_w
    else
        content_main = node._box.content_w
        content_cross = node._box.content_h
    end

    local main_sizes = distribute_main(children, dir, content_main, content_cross, gap)

    if dir == "stack" then
        for i, child in ipairs(children) do
            local main_sz = main_sizes[i]
            local cross_sz = resolve_cross(child, dir, content_cross, align, main_sz)
            local cross_offset = 0
            if align == "center" then
                cross_offset = (content_cross - cross_sz) / 2
            elseif align == "end" then
                cross_offset = content_cross - cross_sz
            end

            local cx = node._box.content_x
            local cy = node._box.content_y
            local cw = main_sz
            local ch = cross_sz

            M.layout_fixed(child, cx, cy, cw, ch)
        end
    else
        local used = 0
        for i, sz in ipairs(main_sizes) do
            used = used + sz
            if i > 1 then used = used + gap end
        end
        local free = content_main - used
        if free < 0 then free = 0 end
        local start_offset, extra_gap = 0, 0
        if justify == "center" then start_offset = free / 2
        elseif justify == "end" then start_offset = free
        elseif justify == "space-between" and #children > 1 then
            extra_gap = free / (#children - 1)
        elseif justify == "space-around" and #children > 0 then
            local unit = free / #children
            start_offset = unit / 2
            extra_gap = unit
        end

        local cursor = start_offset
        for i, child in ipairs(children) do
            local main_sz = main_sizes[i]
            local cross_sz = resolve_cross(child, dir, content_cross, align, main_sz)
            local cross_offset = 0
            if align == "center" then
                cross_offset = (content_cross - cross_sz) / 2
            elseif align == "end" then
                cross_offset = content_cross - cross_sz
            end

            local cx, cy, cw, ch
            if dir == "row" then
                cx = node._box.content_x + cursor
                cy = node._box.content_y + cross_offset
                cw = main_sz
                ch = cross_sz
            else
                cx = node._box.content_x + cross_offset
                cy = node._box.content_y + cursor
                cw = cross_sz
                ch = main_sz
            end

            M.layout_fixed(child, cx, cy, cw, ch)
            cursor = cursor + main_sz + gap + extra_gap
        end
    end

    return node._box
end

---布局入口：在给定可用区域内决定节点自身尺寸，然后调用 layout_fixed
---自动处理 margin、百分比尺寸和 auto 回退逻辑
---@param node table 节点对象
---@param avail_x number 可用区域左上角 X 坐标
---@param avail_y number 可用区域左上角 Y 坐标
---@param avail_w number 可用区域宽度
---@param avail_h number 可用区域高度
---@return LayoutBox 布局完成的盒子几何信息
function M.layout(node, avail_x, avail_y, avail_w, avail_h)
    local style = node.style or {}
    local margin = style_util.normalize_spacing(style.margin)

    local outer_w = avail_w - margin[2] - margin[4]
    local outer_h = avail_h - margin[1] - margin[3]

    local w, wmode = style_util.resolve_size(style.width, avail_w)
    local h, hmode = style_util.resolve_size(style.height, avail_h)

    local box_w, box_h

    if wmode == "fixed" then
        box_w = w
    elseif wmode == "fill" then
        box_w = outer_w
    else
        local iw = M.measure(node, outer_w, outer_h)
        box_w = math.min(iw, outer_w)
    end

    if hmode == "fixed" then
        box_h = h
    elseif hmode == "fill" then
        box_h = outer_h
    else
        local _, ih = M.measure(node, box_w, outer_h)
        box_h = math.min(ih, outer_h)
    end

    M.layout_fixed(node, avail_x + margin[4], avail_y + margin[1], box_w, box_h)
    return node._box
end

---平移整个子树的所有盒子坐标
---递归遍历节点及其所有子节点，将所有 _box 坐标偏移指定量
---@param node table 节点对象
---@param dx number X 方向偏移量
---@param dy number Y 方向偏移量
function M.translate(node, dx, dy)
    if dx == 0 and dy == 0 then return end
    if node._box then
        local b = node._box
        b.x = b.x + dx; b.y = b.y + dy
        b.content_x = b.content_x + dx; b.content_y = b.content_y + dy
    end
    if node.children then
        for _, c in ipairs(node.children) do M.translate(c, dx, dy) end
    end
end

return M
