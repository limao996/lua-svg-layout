local layout = require("svglayout.layout")
local core = require("svglayout.core")
local style_util = require("svglayout.style")

---@class svglayout.paginate
local M = {}

---计算子节点在给定宽度下的"分页高度"：
---如果子节点声明 flex/fill（纵向会吃掉全部剩余），则按其 intrinsic 计算，避免吞掉整页
---@param child table
---@param content_w number
---@return number
local function measure_child_height(child, content_w)
    local s = child.style or {}
    -- 如果纵向声明了固定高度，直接用
    if type(s.height) == "number" then
        return s.height
    end
    if type(s.height) == "string" then
        local pct = s.height:match("^(%-?[%d%.]+)%%$")
        if tonumber(s.height) then return tonumber(s.height) end
        -- 百分比在分页上下文无意义，退化为 intrinsic
        if pct then
            -- 忽略，按 intrinsic 计算
        end
    end
    -- auto / fill / flex → 都按 intrinsic 计算（忽略 flex 在纵向分页里的含义）
    local _, ih = layout.measure(child, content_w, nil)
    return ih
end

---将根节点沿 column 方向按 page_h 分页
---@param root table
---@param page_w number
---@param page_h number
---@return table[]  每页是一个与 root 同结构的节点
function M.paginate(root, page_w, page_h)
    local style = root.style or {}
    if (style.direction or "column") ~= "column" then
        -- 非纵向布局不分页
        layout.layout(root, 0, 0, page_w, page_h)
        return { root }
    end

    -- 强制一次"页高固定"的布局以计算出 content 区
    local saved_h = style.height
    style.height = page_h
    layout.layout(root, 0, 0, page_w, page_h)
    style.height = saved_h

    local content_w = root._box.content_w
    local max_h = root._box.content_h
    local gap = style.gap or 0

    -- 构造页节点
    local function make_page(children)
        return {
            type = root.type,
            style = root.style,
            children = children,
            _id = core.gen_id("page"),
            _render = root._render,
        }
    end

    ---@type table[]
    local pages = {}
    ---@type table[]
    local current = {}
    local used = 0

    local function flush()
        if #current > 0 then
            pages[#pages + 1] = make_page(current)
            current = {}
            used = 0
        end
    end

    -- 用队列是因为 _split 可能把 rest 推回队首
    ---@type table[]
    local queue = {}
    for _, c in ipairs(root.children) do queue[#queue + 1] = c end

    local i = 1
    while i <= #queue do
        local child = queue[i]
        local need_gap = (#current > 0) and gap or 0
        local ch = measure_child_height(child, content_w)

        if used + need_gap + ch <= max_h then
            -- 完整放下
            current[#current + 1] = child
            used = used + need_gap + ch
            i = i + 1
        elseif child._splittable and child._split then
            -- 尝试拆分
            local avail = max_h - used - need_gap
            if avail <= 0 then
                -- 当前页已满，换页再试
                flush()
            else
                -- 让 _split 先看看 child 在这个宽度下的实际度量
                -- 先把 child 的 _box 临时布局一下（layout_fixed 到可用区域）
                -- 让 _split 拿到正确的 content_w
                layout.layout_fixed(child, 0, 0, content_w, avail)
                local first, rest = child:_split(avail)
                if first then
                    current[#current + 1] = first
                end
                flush()
                if rest then
                    queue[i] = rest  -- 剩余推回原位
                else
                    i = i + 1
                end
            end
        else
            -- 不可拆分
            if #current == 0 then
                -- 独占一页（即使超高也只能放一页）
                current[#current + 1] = child
                flush()
                i = i + 1
            else
                flush()  -- 换页重试当前节点
            end
        end
    end
    flush()

    return pages
end

return M
