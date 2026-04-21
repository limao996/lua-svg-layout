local style_util = require("svglayout.style")

local M = {}

-- =======================================================================
-- 阶段 1：MEASURE —— 计算 intrinsic（自然尺寸）
-- 返回的尺寸包含节点自身的 padding，但不含 margin
-- hint_w / hint_h 是父容器给的"建议可用宽高"（用于换行等），nil 表示不限
-- =======================================================================

---@param node table
---@param hint_w number|nil
---@param hint_h number|nil
---@return number intrinsic_w
---@return number intrinsic_h
function M.measure(node, hint_w, hint_h)
    local s = node.style or {}
    local pad = style_util.normalize_spacing(s.padding)

    -- 尝试把 style 里的显式尺寸也参与决策
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

    -- 节点可自定义度量（Text / TextBlock / Image 等叶子组件）
    if node._measure then
        -- 把父给的 hint 扣掉 padding 传给节点内容
        local content_hint_w = (fixed_w or hint_w)
        if content_hint_w then content_hint_w = content_hint_w - pad[2] - pad[4] end
        local cw, ch = node:_measure(content_hint_w, hint_h)
        local iw = (fixed_w) or (cw + pad[2] + pad[4])
        local ih = (fixed_h) or (ch + pad[1] + pad[3])
        node._intrinsic = { w = iw, h = ih, content_w = iw - pad[2] - pad[4], content_h = ih - pad[1] - pad[3] }
        return iw, ih
    end

    -- 无子节点：仅 padding
    local children = node.children or {}
    if #children == 0 then
        local iw = fixed_w or (pad[2] + pad[4])
        local ih = fixed_h or (pad[1] + pad[3])
        node._intrinsic = { w = iw, h = ih }
        return iw, ih
    end

    -- 有子节点：按方向聚合
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
        else -- stack方向
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
    else -- stack方向
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
---@param children table[]
---@param dir "row"|"column"|"stack"
---@param content_main number
---@param content_cross number
---@param gap number
---@return number[] 每个子节点分配到的主轴尺寸
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
        
        -- 在stack方向中，flex和fill应该被忽略，因为所有子组件都重叠
        if dir == "stack" then
            flex = nil
            if mode == "fill" then mode = "auto" end
        elseif flex and flex > 0 then
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
            sizes[i] = 0  -- 后面分配
        else
            -- auto：使用 intrinsic 主轴
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
    
    -- 在stack方向中，所有子组件都获得content_main的尺寸
    if dir == "stack" then
        for i = 1, n do
            sizes[i] = content_main
        end
    end
    
    return sizes, modes
end

---计算交叉轴尺寸
local function resolve_cross(child, dir, content_cross, align, main_size)
    local cs = child.style or {}
    local raw
    if dir == "row" then
        raw = cs.height
    elseif dir == "column" then
        raw = cs.width
    else -- stack方向
        raw = cs.height  -- 对于stack，我们使用height作为交叉轴
    end
    
    local val, mode = style_util.resolve_size(raw, content_cross)
    if mode == "fixed" then return val end
    if mode == "fill" then return content_cross end
    -- auto
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
    else -- stack方向
        cross = content_cross  -- 对于stack，交叉轴尺寸就是content_cross
    end
    if cross > content_cross then cross = content_cross end
    return cross
end

---以固定的外部尺寸布局节点（内部决定自身 content 区 + 递归子节点）
---@param node table
---@param x number
---@param y number
---@param w number
---@param h number
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
    else -- stack方向
        content_main = node._box.content_w
        content_cross = node._box.content_h
    end

    local main_sizes = distribute_main(children, dir, content_main, content_cross, gap)

    if dir == "stack" then
        -- stack方向：所有子组件重叠放置
        for i, child in ipairs(children) do
            local main_sz = main_sizes[i]
            local cross_sz = resolve_cross(child, dir, content_cross, align, main_sz)
            local cross_offset = 0
            if align == "center" then
                cross_offset = (content_cross - cross_sz) / 2
            elseif align == "end" then
                cross_offset = content_cross - cross_sz
            end

            -- 对于stack方向，所有子组件都放在相同位置
            local cx = node._box.content_x
            local cy = node._box.content_y
            local cw = main_sz
            local ch = cross_sz
            
            M.layout_fixed(child, cx, cy, cw, ch)
        end
    else
        -- row/column方向：原有逻辑
        -- justify 偏移
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

---入口：对节点进行布局
---在给定可用区域内决定节点自身尺寸，然后调用 layout_fixed
---@param node table
---@param avail_x number
---@param avail_y number
---@param avail_w number
---@param avail_h number
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
        -- auto：measure
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

---兼容旧 API（给 paginate 用）
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
