---@class svglayout.page_number
local M = {}

local components = require("svglayout.components")
local layout = require("svglayout.layout")

---创建 PageNumber 模板页码组件
---基于模板字符串（支持 {page}、{total} 变量）渲染页码
---比 PageCallback 更简洁，适合纯文本页码显示
---@param props? {template:string?, style:table?, text_style:table?}
---@return table PageNumber 节点
function M.PageNumber(props)
    props = props or {}
    local template = props.template or "{page} / {total}"
    local text_style = props.text_style or {}

    local node = components.Box({ style = props.style, children = {} })
    node.type = "page_number"

    -- 测量阶段：用占位符估算尺寸
    function node:_measure(hint_w, hint_h)
        local content = template:gsub("{page}", "1"):gsub("{total}", "1")
        local text_node = components.Text({ text = content, style = text_style })
        return text_node:_measure(hint_w, hint_h)
    end

    -- 渲染阶段：替换模板变量并布局文本
    local original_render = node._render
    function node:_render(ctx)
        local page = ctx.page or 1
        local total = ctx.total_pages or 1
        local content = template:gsub("{page}", tostring(page)):gsub("{total}", tostring(total))

        local text_node = components.Text({ text = content, style = text_style })
        self.children = { text_node }

        local b = self._box
        if b then
            layout.layout(text_node, b.content_x, b.content_y, b.content_w, b.content_h)
        end

        return original_render(self, ctx)
    end

    return node
end

return M
