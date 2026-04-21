local core = require("svglayout.core")

---@class svglayout.render
local M = {}

---解析 paint 值：字符串直接返回；paint 对象则注册 def 并返回 ref
---@param v any
---@param ctx table
---@return string?
function M.resolve_paint(v, ctx)
    if v == nil then return nil end
    if type(v) == "string" then return v end
    if type(v) == "table" and v._register then
        v._register(ctx)
        return v.ref
    end
    return tostring(v)
end

---构建滤镜定义。支持 blur 与 shadow 组合；阴影基于 SourceAlpha，保证描边元素也能投影
---@param style table
---@param id string
---@return string? filter_def
---@return string? filter_ref
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

---渲染节点为 SVG
---@param node table
---@param ctx table
---@return string
function M.render(node, ctx)
    ctx = ctx or { defs = {} }
    if node._render then
        return node:_render(ctx)
    end
    return ""
end

---渲染盒子层：背景 + 边框 + 包裹 <g>
---滤镜/裁剪/变换/透明度统一由 <g> 承担，保证对子内容也生效
---@param node table
---@param inner_svg string
---@param ctx table
---@param opts? {skip_bg?:boolean}  skip_bg=true 时不绘制背景/边框矩形（供形状组件使用）
---@return string
function M.render_box(node, inner_svg, ctx, opts)
    opts = opts or {}
    local style = node.style or {}
    local b = node._box
    if not b then return inner_svg end

    local node_id = node._id or core.gen_id("n")

    -- 滤镜
    local filter_def, filter_ref = build_filter(style, node_id)
    if filter_def then table.insert(ctx.defs, filter_def) end

    -- 裁剪
    local clip_ref
    if style.clip then
        local cid = "c_" .. node_id
        local rx = style.border_radius or 0
        table.insert(ctx.defs, string.format(
            '<clipPath id="%s"><rect x="%s" y="%s" width="%s" height="%s" rx="%s" ry="%s"/></clipPath>',
            cid, b.x, b.y, b.w, b.h, rx, rx))
        clip_ref = string.format("url(#%s)", cid)
    end

    -- 背景 / 边框矩形
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
