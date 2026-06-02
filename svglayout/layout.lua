---@class svglayout.layout
local M = {}

local style_util = require("svglayout.style")

---@alias LayoutDirection '"row"'|'"column"'|'"stack"' 主轴方向
---@alias JustifyMode '"start"'|'"center"'|'"end"'|'"space-between"'|'"space-around"' 主轴对齐
---@alias AlignMode '"start"'|'"center"'|'"end"'|'"stretch"' 交叉轴对齐
---@alias SizeMode '"fixed"'|'"auto"'|'"fill"' 尺寸模式

---@class LayoutBox 布局完成后的节点盒子信息
---@field x number 盒子左上角 X
---@field y number 盒子左上角 Y
---@field w number 盒子总宽度（含 padding）
---@field h number 盒子总高度（含 padding）
---@field content_x number 内容区左上角 X
---@field content_y number 内容区左上角 Y
---@field content_w number 内容区宽度（不含 padding）
---@field content_h number 内容区高度（不含 padding）

-- 阶段1：MEASURE — 计算自然尺寸（intrinsic size）
-- 返回尺寸包含 padding，不含 margin
-- hint_w/hint_h 为父容器建议可用空间，nil 表示不限

---测量节点的自然尺寸（递归）
---支持固定尺寸、百分比、"auto" 及 flex 分配前的基础尺寸计算
---@param node table 节点
---@param hint_w? number 父容器建议宽度
---@param hint_h? number 父容器建议高度
---@return number intrinsic_w 自然宽度
---@return number intrinsic_h 自然高度
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

    -- 委托给组件自定义 _measure
    if node._measure then
        local content_hint_w = (fixed_w or hint_w)
        if content_hint_w then content_hint_w = content_hint_w - pad[2] - pad[4] end
        local cw, ch = node:_measure(content_hint_w, hint_h)
        local iw = (fixed_w) or (cw + pad[2] + pad[4])
        local ih = (fixed_h) or (ch + pad[1] + pad[3])
        node._intrinsic = { w = iw, h = ih, content_w = iw - pad[2] - pad[4], content_h = ih - pad[1] - pad[3] }
        return iw, ih
    end

    -- 无子节点：返回固定尺寸或 padding 撑起的尺寸
    local children = node.children or {}
    if #children == 0 then
        local iw = fixed_w or (pad[2] + pad[4])
        local ih = fixed_h or (pad[1] + pad[3])
        node._intrinsic = { w = iw, h = ih }
        return iw, ih
    end

    -- 递归测量所有子节点，按方向汇总内容尺寸
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
            -- 水平：子节点高度受 hint_h 约束，宽度自由
            cw, ch = M.measure(child, nil, child_hint_h)
            if i > 1 then main_total = main_total + gap end
            main_total = main_total + cw
            if ch > cross_max then cross_max = ch end
            if cw > max_w then max_w = cw end
            if ch > max_h then max_h = ch end
        elseif dir == "column" then
            -- 纵向：子节点宽度受 hint_w 约束，高度自由
            cw, ch = M.measure(child, child_hint_w, nil)
            if i > 1 then main_total = main_total + gap end
            main_total = main_total + ch
            if cw > cross_max then cross_max = cw end
            if cw > max_w then max_w = cw end
            if ch > max_h then max_h = ch end
        else
            -- stack：所有子节点占地相同
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

-- 阶段2+3：LAYOUT — 根据父容器给定尺寸放置子节点

---按 flex 权重、固定值和 auto 模式分配子节点主轴尺寸
---@param children table[] 子节点列表
---@param dir LayoutDirection 方向
---@param content_main number 主轴总尺寸
---@param content_cross number 交叉轴总尺寸
---@param gap number 间距
---@return number[] 各子节点主轴尺寸
---@return string[] 各子节点分配模式
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

        -- stack 模式不支持 flex/fill
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
            -- auto：按自然尺寸
            local iw, ih = M.measure(child,
                (dir == "row") and nil or content_cross,
                (dir == "row") and content_cross or nil)
            local main = (dir == "row") and iw or ih
            sizes[i] = main
            fixed_sum = fixed_sum + main
        end
    end

    -- 将剩余空间按 flex 权重分配
    local remaining = content_main - total_gap - fixed_sum
    if remaining < 0 then remaining = 0 end
    if flex_sum > 0 then
        for i = 1, n do
            if modes[i] == "flex" then
                sizes[i] = remaining * (flexes[i] == 0 and 1 or flexes[i]) / flex_sum
            end
        end
    end

    -- stack：所有子节点占据全部主轴空间
    if dir == "stack" then
        for i = 1, n do
            sizes[i] = content_main
        end
    end

    return sizes, modes
end

---根据对齐模式确定子节点交叉轴尺寸
---@param child table 子节点
---@param dir LayoutDirection 方向
---@param content_cross number 交叉轴总尺寸
---@param align AlignMode 对齐模式
---@param main_size number 子节点已分配的主轴尺寸
---@return number 交叉轴尺寸
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
    -- 非 stretch 时取自然尺寸，但不超过交叉轴总尺寸
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

---以固定外部尺寸对节点进行精确布局
---计算节点自身 content 区域坐标，递归放置所有子节点
---@param node table 节点
---@param x number 绝对 X
---@param y number 绝对 Y
---@param w number 宽度
---@param h number 高度
---@return LayoutBox 盒子信息
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
        -- stack：所有子节点在相同位置重叠
        for i, child in ipairs(children) do
            local main_sz = main_sizes[i]
            local cross_sz = resolve_cross(child, dir, content_cross, align, main_sz)
            local cross_offset = 0
            if align == "center" then
                cross_offset = (content_cross - cross_sz) / 2
            elseif align == "end" then
                cross_offset = content_cross - cross_sz
            end

            M.layout_fixed(child, node._box.content_x, node._box.content_y, main_sz, cross_sz)
        end
    else
        -- 计算 justify 偏移
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

        -- 逐子布局，沿主轴方向推进 cursor
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

---布局入口：在给定可用区域内计算节点尺寸并放置
---自动处理 margin、百分比、auto 回退逻辑
---@param node table 节点
---@param avail_x number 可用区域 X
---@param avail_y number 可用区域 Y
---@param avail_w number 可用区域宽度
---@param avail_h number 可用区域高度
---@return LayoutBox 盒子信息
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
        -- auto：按自然尺寸但不超过可用空间
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

---平移子树所有盒子的坐标
---@param node table 节点
---@param dx number X 偏移
---@param dy number Y 偏移
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
