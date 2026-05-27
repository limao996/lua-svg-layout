---@class svglayout.builder
local M = {}

---@class svglayout.BuilderContext Builder 回调执行上下文
---@field width number 内容区宽度
---@field height number 内容区高度
---@field x number 内容区左上角 X 坐标
---@field y number 内容区左上角 Y 坐标
---@field add fun(self:svglayout.BuilderContext, node:table) 向 Builder 添加子节点

---创建 Builder 动态内容生成组件
---传入回调函数，回调在渲染阶段执行，可根据运行时上下文动态构建子节点
---Builder 会在渲染时对其子节点重新布局，支持动态内容的尺寸自适应
---@param props {build:fun(ctx:svglayout.BuilderContext):table|table[], style?:table} 组件属性
---@return table Builder 节点对象
function M.Builder(props)
    local components = require("svglayout.components")
    local layout = require("svglayout.layout")

    props = props or {}
    local node = components.Box({ style = props.style, children = {} })
    node.type = "builder"

    local original_render = node._render
    function node:_render(ctx)
        local b = self._box
        local collected = {}
        local bctx = {
            width = b.content_w,
            height = b.content_h,
            x = b.content_x,
            y = b.content_y,
            add = function(self2, n) collected[#collected + 1] = n end,
        }
        local result = props.build and props.build(bctx)
        if type(result) == "table" then
            if result.type then
                collected[#collected + 1] = result
            else
                for _, n in ipairs(result) do collected[#collected + 1] = n end
            end
        end
        self.children = collected
        local style = self.style or {}
        local pad = require("svglayout.style").normalize_spacing(style.padding)
        local cursor = 0
        local dir = style.direction or "column"
        local gap = style.gap or 0
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
