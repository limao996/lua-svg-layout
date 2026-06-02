---@class svglayout.builder
local M = {}

---@class svglayout.BuilderContext Builder 回调执行上下文
---@field width number 内容区宽度
---@field height number 内容区高度
---@field x number 内容区 X 坐标
---@field y number 内容区 Y 坐标
---@field add fun(self:svglayout.BuilderContext, node:table) 动态添加子节点

---创建 Builder 动态内容生成组件
---回调在渲染阶段执行，可根据运行时上下文动态构建子节点
---渲染时对子节点重新布局，支持动态内容的尺寸自适应
---@param props? {build:fun(ctx:svglayout.BuilderContext):table|table[], style:table?}
---@return table Builder 节点
function M.Builder(props)
    local components = require("svglayout.components")
    local layout = require("svglayout.layout")
    local style_util = require("svglayout.style")

    props = props or {}
    local node = components.Box({ style = props.style, children = {} })
    node.type = "builder"

    -- 调用 build 回调生成子节点列表
    local function build_children(self, ctx)
        local collected = {}
        local bctx = {
            width = ctx.content_w,
            height = ctx.content_h,
            x = ctx.x or 0,
            y = ctx.y or 0,
            add = function(_, n) collected[#collected + 1] = n end,
        }
        local result = props.build and props.build(bctx)
        if type(result) == "table" then
            if result.type then
                collected[#collected + 1] = result
            else
                for _, n in ipairs(result) do collected[#collected + 1] = n end
            end
        end
        return collected
    end

    -- 测量阶段：调用 build 获取子节点，计算内容尺寸
    node._measure = function(self, hint_w, hint_h)
        local style = self.style or {}
        local dir = style.direction or "column"
        local gap = style.gap or 0
        local pad = style_util.normalize_spacing(style.padding)

        local collected = build_children(self, { content_w = hint_w or 0, content_h = hint_h or 0 })
        self._built_children = collected

        local total_main = 0
        local cross_max = 0
        for i, child in ipairs(collected) do
            if i > 1 then total_main = total_main + gap end
            if dir == "row" then
                local child_h = hint_h and (hint_h - pad[1] - pad[3]) or nil
                local cw, ch = layout.measure(child, nil, child_h)
                total_main = total_main + cw
                if ch > cross_max then cross_max = ch end
            else
                local cw, ch = layout.measure(child, hint_w)
                total_main = total_main + ch
                if cw > cross_max then cross_max = cw end
            end
        end

        local content_w = (dir == "row") and total_main or cross_max
        local content_h = (dir == "column") and total_main or cross_max
        return content_w, content_h
    end

    -- 渲染阶段：重新构建并布局子节点
    local original_render = node._render
    function node:_render(ctx)
        local b = self._box
        local collected = self._built_children or {}
        self._built_children = nil

        if #collected == 0 then
            collected = build_children(self, {
                content_w = b.content_w, content_h = b.content_h,
                x = b.content_x, y = b.content_y,
            })
        end

        self.children = collected
        local style = self.style or {}
        local dir = style.direction or "column"
        local gap = style.gap or 0
        local pad = style_util.normalize_spacing(style.padding)

        local total_main = 0
        for i, child in ipairs(self.children) do
            if i > 1 then total_main = total_main + gap end
            if dir == "row" then
                local iw = layout.measure(child)
                total_main = total_main + iw
            else
                local _, ih = layout.measure(child, b.content_w)
                total_main = total_main + ih
            end
        end

        -- 动态内容超出盒子时自动扩展
        if dir == "column" then
            local total_h = pad[1] + total_main + pad[3]
            if total_h > b.h then
                b.h = total_h
                b.content_h = total_main
            end
        elseif dir == "row" then
            local total_w = pad[2] + total_main + pad[4]
            if total_w > b.w then
                b.w = total_w
                b.content_w = total_main
            end
        end

        -- 逐子布局
        local cursor = 0
        for i, child in ipairs(self.children) do
            if i > 1 then cursor = cursor + gap end
            if dir == "row" then
                layout.layout(child, b.content_x + cursor, b.content_y,
                    b.content_w - cursor, b.content_h)
                cursor = cursor + child._box.w
            else
                layout.layout(child, b.content_x, b.content_y + cursor,
                    b.content_w, b.content_h - cursor)
                cursor = cursor + child._box.h
            end
        end
        return original_render(self, ctx)
    end
    return node
end

return M
