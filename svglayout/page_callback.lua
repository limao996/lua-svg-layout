---@class svglayout.page_callback
local M = {}

---创建 PageCallback 动态页码组件
---接收 build(page, total) 回调函数，在分页渲染时根据当前页码动态生成子节点
---常用于页码显示、页眉页脚等需要感知页码的场景
---@param props {build:fun(page:number, total:number):table|table[], style?:table} 组件属性
---@return table PageCallback 节点对象
function M.PageCallback(props)
    local components = require("svglayout.components")
    local layout = require("svglayout.layout")

    props = props or {}
    local build_fn = props.build
    assert(type(build_fn) == "function", "PageCallback requires a build function")

    local node = components.Box({ style = props.style, children = {} })
    node.type = "page_callback"

    local original_render = node._render
    function node:_render(ctx)
        local page = ctx.page or 1
        local total = ctx.total_pages or 1
        local result = build_fn(page, total) or {}
        if type(result) == "table" then
            if result.type then
                self.children = { result }
            else
                self.children = result
            end
        else
            self.children = {}
        end

        local b = self._box
        if b then
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
        end

        return original_render(self, ctx)
    end

    return node
end

return M
