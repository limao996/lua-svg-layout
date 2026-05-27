---@class svglayout.paginate
local M = {}

local layout = require("svglayout.layout")
local core = require("svglayout.core")
local style_util = require("svglayout.style")

---@class svglayout.PageNode 分页生成的页面节点
---@field type string 节点类型
---@field style table 页面样式（继承自根节点）
---@field children table[] 该页包含的子节点
---@field _id string 页面唯一 ID
---@field _render? fun(self:table, ctx:table):string 渲染方法（继承自根节点）

---计算子节点在给定宽度下的"分页高度"
---如果子节点声明 flex/fill（纵向会吃掉全部剩余），则按其 intrinsic 计算，避免吞掉整页
---@param child table 子节点
---@param content_w number 内容区宽度
---@return number 子节点在分页中应占用的高度
local function measure_child_height(child, content_w)
    local s = child.style or {}
    if type(s.height) == "number" then
        return s.height
    end
    if type(s.height) == "string" then
        local pct = s.height:match("^(%-?[%d%.]+)%%$")
        if tonumber(s.height) then return tonumber(s.height) end
        if pct then end
    end
    local _, ih = layout.measure(child, content_w, nil)
    return ih
end

---将根节点沿 column 方向按指定页高进行分页
---仅纵向（column）布局支持分页；非纵向布局直接返回单页
---自动识别三类节点：
---  pre_fixed — 首位溢出节点之前、能容纳下的节点，在每页顶部重复（如标题）
---  overflow  — 需要跨页拆分的内容节点
---  post_fixed — 末位溢出节点之后、能容纳下的节点，在每页底部重复（如页码）
---@param root table 根节点
---@param page_w number 页宽
---@param page_h number 页高
---@return table[] 每页一个与 root 同结构的节点，每页高度不超过 page_h
function M.paginate(root, page_w, page_h)
    local style = root.style or {}
    if (style.direction or "column") ~= "column" then
        layout.layout(root, 0, 0, page_w, page_h)
        return { root }
    end

    local saved_h = style.height
    style.height = page_h
    layout.layout(root, 0, 0, page_w, page_h)
    style.height = saved_h

    local content_w = root._box.content_w
    local max_h = root._box.content_h
    local gap = style.gap or 0

    ---创建单页节点
    ---@param children table[] 该页的子节点列表
    ---@return svglayout.PageNode 页面节点
    local function make_page(children)
        return {
            type = root.type,
            style = root.style,
            children = children,
            _id = core.gen_id("page"),
            _render = root._render,
        }
    end

    -- ========== 第一遍扫描：测量所有子节点高度 ==========
    local child_heights = {}
    for i, c in ipairs(root.children) do
        child_heights[i] = measure_child_height(c, content_w)
    end

    -- ========== 识别首/末位"大节点"（单个高度超过页高的节点） ==========
    local first_big, last_big
    for i, ch in ipairs(child_heights) do
        if ch > max_h then
            if not first_big then first_big = i end
            last_big = i
        end
    end

    -- 如果没有大节点，所有子节点都在一页内
    if not first_big then
        return { make_page(root.children) }
    end

    -- ========== 构建 pre_fixed（首个大节点之前，逐级检查是否装得下） ==========
    local pre_fixed = {}
    local pre_total = 0
    for i = 1, first_big - 1 do
        local ch = child_heights[i]
        local need_gap = (#pre_fixed > 0) and gap or 0
        if pre_total + need_gap + ch <= max_h then
            table.insert(pre_fixed, root.children[i])
            pre_total = pre_total + need_gap + ch
        else
            first_big = i
            break
        end
    end

    -- ========== 构建 overflow（从 first_big 到 last_big） ==========
    local overflow = {}
    for i = first_big, last_big do
        table.insert(overflow, root.children[i])
    end

    -- ========== 构建 post_fixed（末位大节点之后，逐级检查） ==========
    local post_fixed = {}
    local post_total = 0
    for i = last_big + 1, #root.children do
        local ch = child_heights[i]
        local need_gap = (#post_fixed > 0) and gap or 0
        table.insert(post_fixed, root.children[i])
        post_total = post_total + need_gap + ch
    end

    -- ========== 计算溢出区域可用高度 ==========
    local pre_gap = (#pre_fixed > 0) and gap or 0
    local post_gap = (#post_fixed > 0) and gap or 0
    local overflow_avail = max_h - pre_total - post_total - pre_gap - post_gap

    -- 如果溢出区域太小，将 post_fixed 退回 overflow
    if overflow_avail <= 0 and #post_fixed > 0 then
        for _, c in ipairs(post_fixed) do
            table.insert(overflow, c)
        end
        post_fixed = {}
        post_total = 0
        post_gap = 0
        overflow_avail = max_h - pre_total - pre_gap
    end

    if overflow_avail <= 0 then
        overflow_avail = math.max(max_h * 0.5, 1)
    end

    -- ========== 分页处理 overflow 队列 ==========
    local pages = {}
    local current = {}
    local used = 0

    local function flush()
        if #current > 0 then
            -- 每页结构：pre_fixed + overflow_portion + post_fixed
            local page_children = {}
            for _, fc in ipairs(pre_fixed) do
                table.insert(page_children, fc)
            end
            for _, cc in ipairs(current) do
                table.insert(page_children, cc)
            end
            for _, pc in ipairs(post_fixed) do
                table.insert(page_children, pc)
            end
            pages[#pages + 1] = make_page(page_children)
            current = {}
            used = 0
        end
    end

    local queue = {}
    for _, c in ipairs(overflow) do queue[#queue + 1] = c end

    local i = 1
    while i <= #queue do
        local child = queue[i]
        local need_gap = (#current > 0) and gap or 0
        local ch = measure_child_height(child, content_w)

        if used + need_gap + ch <= overflow_avail then
            current[#current + 1] = child
            used = used + need_gap + ch
            i = i + 1
        elseif child._splittable and child._split then
            local avail = overflow_avail - used - need_gap
            if avail <= 0 then
                flush()
            else
                layout.layout_fixed(child, 0, 0, content_w, avail)
                local first, rest = child:_split(avail)
                if first then
                    current[#current + 1] = first
                end
                flush()
                if rest then
                    queue[i] = rest
                else
                    i = i + 1
                end
            end
        else
            if #current == 0 then
                current[#current + 1] = child
                flush()
                i = i + 1
            else
                flush()
            end
        end
    end
    flush()

    return pages
end

return M
