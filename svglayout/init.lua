---@class svglayout
local M = {}

local core      = require("svglayout.core")
local layout    = require("svglayout.layout")
local render    = require("svglayout.render")
local components = require("svglayout.components")
local builder   = require("svglayout.builder")
local paginate  = require("svglayout.paginate")
local defs_mod  = require("svglayout.defs")

-- 组件导出
M.Box            = components.Box
M.Text           = components.Text
M.TextBlock      = components.TextBlock
M.Image          = components.Image
M.Rect           = components.Rect
M.Circle         = components.Circle
M.Line           = components.Line
M.Path           = components.Path
M.Group          = components.Group
M.Raw            = components.Raw
M.Builder        = builder.Builder
M.LinearGradient = defs_mod.LinearGradient
M.RadialGradient = defs_mod.RadialGradient
M.Pattern        = defs_mod.Pattern

---内部：拼装完整的 SVG 文档字符串
---@param body string SVG 主体内容
---@param defs_list string[] 定义列表（渐变、图案等）
---@param w number SVG 宽度
---@param h number SVG 高度
---@param viewBox? string SVG viewBox 属性
---@return string 完整的 SVG 文档字符串
local function wrap_svg(body, defs_list, w, h, viewBox)
    local defs = #defs_list > 0 and ("<defs>" .. table.concat(defs_list, "\n") .. "</defs>") or ""
    return string.format(
        '<?xml version="1.0" encoding="UTF-8"?>\n' ..
        '<svg xmlns="http://www.w3.org/2000/svg" width="%s" height="%s" viewBox="%s">\n%s\n%s\n</svg>',
        w, h, viewBox or string.format("0 0 %s %s", w, h), defs, body)
end

---单页渲染
---@param root table
---@param opts {width:number, height?:number|"auto", viewBox?:string}
---@return string
function M.render_svg(root, opts)
    opts = opts or {}
    local w = opts.width or 800
    local h = opts.height
    if h == nil or h == "auto" then
        -- 先按一个大可用高度布局，然后按根节点实际高度输出
        layout.layout(root, 0, 0, w, math.huge)
        h = root._box.h
    else
        layout.layout(root, 0, 0, w, h)
    end
    local ctx = { defs = {} }
    local body = render.render(root, ctx)
    return wrap_svg(body, ctx.defs, w, h, opts.viewBox)
end

---分页渲染
---@param root table
---@param opts {width:number, height:number}
---@return string[]  每页一个完整的 SVG 字符串
function M.render_pages(root, opts)
    opts = opts or {}
    local w = opts.width or 800
    local h = opts.height or 600
    assert(type(h) == "number" and h > 0, "render_pages requires a numeric height")

    local pages = paginate.paginate(root, w, h)
    local out = {}
    for i, pg in ipairs(pages) do
        -- 每页强制使用完整页高，避免 root 的 height="auto" 干扰
        local saved_h = pg.style and pg.style.height
        if pg.style then pg.style.height = h end
        layout.layout(pg, 0, 0, w, h)
        if pg.style then pg.style.height = saved_h end

        local ctx = { defs = {} }
        local body = render.render(pg, ctx)
        out[i] = wrap_svg(body, ctx.defs, w, h)
    end
    return out
end

---获取分页后的节点数组（不渲染），便于自定义处理
---@param root table
---@param opts {width:number, height:number}
---@return table[]
function M.paginate_nodes(root, opts)
    opts = opts or {}
    return paginate.paginate(root, opts.width or 800, opts.height or 600)
end

---自定义组件
---@param name string
---@param factory fun(props:table):table
function M.register(name, factory)
    M[name] = factory
end

---@generic T
---@param render_fn fun(props:T):table
---@return fun(props:T):table
function M.define(render_fn)
    return function(props)
        return render_fn(props or {})
    end
end

-- 底层模块暴露
M._core     = core
M._layout   = layout
M._render   = render
M._paginate = paginate

return M
