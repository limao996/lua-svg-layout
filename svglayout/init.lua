---@class svglayout 主模块，提供声明式 SVG 布局和渲染能力
local M = {}

local core      = require("svglayout.core")
local layout    = require("svglayout.layout")
local render    = require("svglayout.render")
local components = require("svglayout.components")
local builder   = require("svglayout.builder")
local paginate  = require("svglayout.paginate")
local defs_mod  = require("svglayout.defs")
local style_mod = require("svglayout.style_modifier")
local page_callback = require("svglayout.page_callback")

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
M.Row            = components.Row
M.Column         = components.Column
M.ZStack         = components.ZStack
M.Spacer         = components.Spacer
M.Divider        = components.Divider
M.Builder        = builder.Builder
M.PageCallback   = page_callback.PageCallback
M.LinearGradient = defs_mod.LinearGradient
M.RadialGradient = defs_mod.RadialGradient
M.Pattern        = defs_mod.Pattern
M.Style          = style_mod

---@class svglayout.RenderOptions 渲染选项
---@field width number SVG 画布宽度，默认 800
---@field height? number|'"auto"' SVG 画布高度；nil 或 "auto" 时根据内容自适应
---@field viewBox? string SVG viewBox 属性，未指定时自动计算

---拼装完整的 SVG 文档字符串
---将主体内容与 defs 定义合并为合法的 SVG 文档
---@param body string SVG 主体内容（<g> 等标签）
---@param defs_list string[] 定义列表（渐变、图案、滤镜等）
---@param w number SVG 宽度
---@param h number SVG 高度
---@param viewBox? string SVG viewBox 属性，未指定时自动从宽高计算
---@return string 完整的 SVG 文档字符串
local function wrap_svg(body, defs_list, w, h, viewBox)
    local defs = #defs_list > 0 and ("<defs>" .. table.concat(defs_list, "\n") .. "</defs>") or ""
    return string.format(
        '<?xml version="1.0" encoding="UTF-8"?>\n' ..
        '<svg xmlns="http://www.w3.org/2000/svg" width="%s" height="%s" viewBox="%s">\n%s\n%s\n</svg>',
        w, h, viewBox or string.format("0 0 %s %s", w, h), defs, body)
end

---单页渲染：将组件树渲染为单个 SVG 文档字符串
---高度为 "auto" 或未指定时，自动按内容高度裁剪
---@param root table 根节点组件
---@param opts svglayout.RenderOptions 渲染选项
---@return string 完整的 SVG 文档字符串
function M.render_svg(root, opts)
    opts = opts or {}
    local w = opts.width or 800
    local h = opts.height
    if h == nil or h == "auto" then
        layout.layout(root, 0, 0, w, math.huge)
        h = root._box.h
    else
        layout.layout(root, 0, 0, w, h)
    end
    local ctx = { defs = {}, page = 1, total_pages = 1 }
    local body = render.render(root, ctx)
    return wrap_svg(body, ctx.defs, w, h, opts.viewBox)
end

---分页渲染：将组件树按页高拆分为多个 SVG 文档
---每页独立渲染，返回字符串数组
---@param root table 根节点组件
---@param opts {width:number, height:number} 渲染选项，width 和 height 均为必填数值
---@return string[] 每页一个完整的 SVG 文档字符串
function M.render_pages(root, opts)
    opts = opts or {}
    local w = opts.width or 800
    local h = opts.height or 600
    assert(type(h) == "number" and h > 0, "render_pages requires a numeric height")

    local pages = paginate.paginate(root, w, h)
    local out = {}
    for i, pg in ipairs(pages) do
        local saved_h = pg.style and pg.style.height
        if pg.style then pg.style.height = h end
        layout.layout(pg, 0, 0, w, h)
        if pg.style then pg.style.height = saved_h end

        local ctx = { defs = {}, page = i, total_pages = #pages }
        local body = render.render(pg, ctx)
        out[i] = wrap_svg(body, ctx.defs, w, h)
    end
    return out
end

---获取分页后的节点数组（不渲染）
---便于调用方自定义处理每页内容，如单独修改样式或输出为其他格式
---@param root table 根节点组件
---@param opts {width:number, height:number} 分页选项
---@return table[] 分页后的节点数组，每页一个根节点
function M.paginate_nodes(root, opts)
    opts = opts or {}
    return paginate.paginate(root, opts.width or 800, opts.height or 600)
end

---注册自定义组件工厂函数
---注册后的组件可通过 M[name] 直接调用
---@param name string 组件名称
---@param factory fun(props:table):table 组件工厂函数，接收属性表返回节点对象
function M.register(name, factory)
    M[name] = factory
end

---创建自定义声明式组件
---接收渲染函数并返回一个工厂函数，方便定义无状态组件
---@generic T
---@param render_fn fun(props:T):table 渲染函数，接收属性表返回节点对象
---@return fun(props:T):table 组件工厂函数
function M.define(render_fn)
    return function(props)
        return render_fn(props or {})
    end
end

M._core     = core
M._layout   = layout
M._render   = render
M._paginate = paginate

return M
