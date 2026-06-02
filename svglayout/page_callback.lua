---@class svglayout.page_callback
local M = {}

local components = require("svglayout.components")
local layout = require("svglayout.layout")
local style_util = require("svglayout.style")

---创建 PageCallback 动态页码组件
---接收 build(page, total) 回调，在分页渲染时根据当前页码动态生成子节点
---常用于页码显示、页眉页脚等需要感知页码的场景
---@param props? {build:fun(page:number, total:number):table|table[], style:table?}
---@return table PageCallback 节点
function M.PageCallback(props)
    props = props or {}
    local build_fn = props.build
    assert(type(build_fn) == "function", "PageCallback requires a build function")

    local node = components.Box({ style = props.style, children = {} })
    node.type = "page_callback"

    -- 渲染阶段：根据页码回调生成子节点并布局
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

        -- 根据方向对子节点进行布局
        local b = self._box
        if b then
            local style = self.style or {}
            local dir = style.direction or "column"
            local gap = style.gap or 0
            local pad = style_util.normalize_spacing(style.padding)

            if dir == "stack" then
                for _, child in ipairs(self.children) do
                    layout.layout(child, b.content_x, b.content_y, b.content_w, b.content_h)
                end
            else
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
            end
        end

        return original_render(self, ctx)
    end

    return node
end

return M
