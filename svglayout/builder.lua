local M = {}

---@class svglayout.BuilderContext
---@field width number
---@field height number
---@field x number
---@field y number
---@field add fun(self, node:table)

---Builder: 传入回调，回调内可使用声明式语法构建子节点
---@param props {build:fun(ctx:svglayout.BuilderContext):table|table[], style?:table}
---@return table
function M.Builder(props)
    local components = require("svglayout.components")
    local layout = require("svglayout.layout")

    props = props or {}
    local node = components.Box({ style = props.style, children = {} })
    node.type = "builder"

    local original_render = node._render
    function node:_render(ctx)
        -- 先构造子节点
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
        -- 对新子节点做布局（以当前 content 区域为可用空间）
        local style = self.style or {}
        local pad = require("svglayout.style").normalize_spacing(style.padding)
        -- 简化：重新对子节点布局
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