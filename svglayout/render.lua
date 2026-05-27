---@class svglayout.render
local M = {}

local core = require("svglayout.core")

---@class svglayout.RenderContext 渲染上下文，在渲染过程中传递
---@field defs string[] SVG defs 定义列表，收集所有渐变、图案、滤镜定义

---@class svglayout.ShadowStyle 阴影样式
---@field dx? number 阴影水平偏移，默认 2
---@field dy? number 阴影垂直偏移，默认 2
---@field blur? number 阴影模糊半径，默认 3
---@field color? string 阴影颜色，默认 "#000000"
---@field opacity? number 阴影透明度，默认 0.35

---解析 paint 值：字符串直接返回；paint 对象（渐变/图案）则注册 def 并返回 ref
---@param v any 颜色值、渐变对象或图案对象
---@param ctx table 渲染上下文
---@return string? 解析后的 SVG paint 字符串（颜色值或 url(#xxx) 引用）
function M.resolve_paint(v, ctx)
    if v == nil then return nil end
    if type(v) == "string" then return v end
    if type(v) == "table" and v._register then
        v._register(ctx)
        return v.ref
    end
    return tostring(v)
end

---构建 SVG 滤镜定义字符串
---支持 blur（高斯模糊）与 shadow（投影）的组合效果
---阴影基于 SourceAlpha，保证描边元素也能正确投影
---@param style table 节点样式表
---@param id string 节点 ID，用于生成唯一滤镜 ID
---@return string? filter_def 滤镜定义字符串，无滤镜时返回 nil
---@return string? filter_ref 滤镜引用字符串（形如 `url(#f_xxx)`），无滤镜时返回 nil
local function build_filter(style, id)
    local has_blur = style.blur ~= nil
    local has_shadow = style.shadow ~= nil
    if not has_blur and not has_shadow then return nil, nil end

    local fid = "f_" .. id
    local parts = {
        string.format(
            '<filter id="%s" x="-50%%" y="-50%%" width="200%%" height="200%%" filterUnits="objectBoundingBox">',
            fid),
    }

    if has_shadow then
        local s = style.shadow
        local dx = s.dx or 2
        local dy = s.dy or 2
        local sblur = s.blur or 3
        local color = s.color or "#000000"
        local opacity = s.opacity or 0.35

        parts[#parts + 1] = string.format(
            '<feGaussianBlur in="SourceAlpha" stdDeviation="%s" result="shadowBlur"/>', sblur)
        parts[#parts + 1] = string.format(
            '<feOffset in="shadowBlur" dx="%s" dy="%s" result="shadowOffset"/>', dx, dy)
        parts[#parts + 1] = string.format(
            '<feFlood flood-color="%s" flood-opacity="%s" result="shadowColor"/>',
            color, opacity)
        parts[#parts + 1] =
            '<feComposite in="shadowColor" in2="shadowOffset" operator="in" result="shadow"/>'
    end

    if has_blur then
        parts[#parts + 1] = string.format(
            '<feGaussianBlur in="SourceGraphic" stdDeviation="%s" result="blurred"/>',
            tostring(style.blur))
    end

    if has_shadow and has_blur then
        parts[#parts + 1] = [[<feMerge>
  <feMergeNode in="shadow"/>
  <feMergeNode in="blurred"/>
</feMerge>]]
    elseif has_shadow then
        parts[#parts + 1] = [[<feMerge>
  <feMergeNode in="shadow"/>
  <feMergeNode in="SourceGraphic"/>
</feMerge>]]
    else
        parts[#parts + 1] = '<feMerge><feMergeNode in="blurred"/></feMerge>'
    end

    parts[#parts + 1] = "</filter>"
    return table.concat(parts, "\n"), string.format("url(#%s)", fid)
end

---渲染节点为 SVG 字符串
---调用节点的 _render 协议方法，若无则返回空字符串
---@param node table 节点对象
---@param ctx table 渲染上下文
---@return string 节点渲染后的 SVG 字符串
function M.render(node, ctx)
    ctx = ctx or { defs = {} }
    if node._render then
        return node:_render(ctx)
    end
    return ""
end

---渲染节点盒子层（背景 + 边框 + 包裹 <g>）
---滤镜、裁剪、变换、透明度统一由 <g> 承担，保证对子内容也生效
---@param node table 节点对象
---@param inner_svg string 已渲染的子内容 SVG 字符串
---@param ctx table 渲染上下文
---@param opts? {skip_bg?:boolean} 选项，skip_bg=true 时不绘制背景/边框矩形（供形状组件使用）
---@return string 包装后的完整 SVG 字符串
function M.render_box(node, inner_svg, ctx, opts)
    opts = opts or {}
    local style = node.style or {}
    local b = node._box
    if not b then return inner_svg end

    local node_id = node._id or core.gen_id("n")

    local filter_def, filter_ref = build_filter(style, node_id)
    if filter_def then table.insert(ctx.defs, filter_def) end

    local clip_ref
    if style.clip then
        local cid = "c_" .. node_id
        local rx = style.border_radius or 0
        table.insert(ctx.defs, string.format(
            '<clipPath id="%s"><rect x="%s" y="%s" width="%s" height="%s" rx="%s" ry="%s"/></clipPath>',
            cid, b.x, b.y, b.w, b.h, rx, rx))
        clip_ref = string.format("url(#%s)", cid)
    end

    local bg_rect = ""
    local has_bg = style.background ~= nil
    local has_border = style.border ~= nil
    if (not opts.skip_bg) and (has_bg or has_border) then
        local rect_attrs = {
            x = b.x, y = b.y, width = b.w, height = b.h,
            rx = style.border_radius, ry = style.border_radius,
            fill = M.resolve_paint(style.background, ctx) or "none",
            stroke = M.resolve_paint(style.border, ctx),
            ["stroke-width"] = style.border_width,
        }
        bg_rect = "<rect " .. core.attrs_to_str(rect_attrs) .. "/>"
    end

    local need_wrapper = filter_ref or clip_ref or style.transform or style.opacity

    if need_wrapper then
        local g_attrs = {
            filter = filter_ref,
            ["clip-path"] = clip_ref,
            transform = style.transform,
            opacity = style.opacity,
        }
        return string.format("<g %s>\n%s\n%s\n</g>",
            core.attrs_to_str(g_attrs),
            bg_rect,
            inner_svg)
    else
        if bg_rect == "" then
            return inner_svg
        end
        return bg_rect .. "\n" .. inner_svg
    end
end

return M
