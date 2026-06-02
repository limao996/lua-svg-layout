---@class svglayout.render
local M = {}

local core = require("svglayout.core")

---@class svglayout.RenderContext 渲染上下文
---@field defs string[] SVG defs 定义列表（滤镜、裁剪路径、渐变等）
---@field page? number 当前页码（分页渲染时）
---@field total_pages? number 总页数（分页渲染时）

---@class svglayout.ShadowStyle 阴影配置
---@field dx? number 水平偏移（默认 2）
---@field dy? number 垂直偏移（默认 2）
---@field blur? number 模糊半径（默认 3）
---@field color? string 颜色（默认 "#000000"）
---@field opacity? number 透明度（默认 0.35）

---解析 paint 值：字符串直接返回；定义对象（渐变/图案）注册 def 并返回 url(#id) 引用
---@param v any 颜色值或定义对象
---@param ctx table 渲染上下文
---@return string? SVG paint 值
function M.resolve_paint(v, ctx)
    if v == nil then return nil end
    if type(v) == "string" then return v end
    if type(v) == "table" and v._register then
        v._register(ctx)
        return v.ref
    end
    return tostring(v)
end

---构建 SVG 滤镜定义
---支持 blur（高斯模糊）与 shadow（投影）的组合效果
---阴影基于 SourceAlpha 以保证描边元素也能正确投影
---@param style table 节点样式
---@param id string 节点 ID
---@return string? filter_def 滤镜定义（无滤镜时返回 nil）
---@return string? filter_ref 滤镜引用如 `url(#f_xxx)`（无滤镜时返回 nil）
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

        -- 基于 SourceAlpha 生成阴影
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

    -- 合并阴影和模糊结果
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

---渲染节点为 SVG 字符串（调用节点的 _render 协议方法）
---@param node table 节点
---@param ctx table 渲染上下文
---@return string SVG 片段
function M.render(node, ctx)
    ctx = ctx or { defs = {} }
    if node._render then
        return node:_render(ctx)
    end
    return ""
end

---渲染节点的盒子层（背景 + 边框 + <g> 包裹）
---滤镜、裁剪、变换、透明度通过 <g> 统一施加，确保对子内容也生效
---@param node table 节点
---@param inner_svg string 子内容 SVG
---@param ctx table 渲染上下文
---@param opts? {skip_bg?:boolean} 选项，skip_bg=true 跳过背景/边框矩形（供形状组件用）
---@return string 包装后的 SVG
function M.render_box(node, inner_svg, ctx, opts)
    opts = opts or {}
    local style = node.style or {}
    local b = node._box
    if not b then return inner_svg end

    local node_id = node._id or core.gen_id("n")

    -- 构建滤镜
    local filter_def, filter_ref = build_filter(style, node_id)
    if filter_def then table.insert(ctx.defs, filter_def) end

    -- 构建裁剪路径
    local clip_ref
    if style.clip then
        local cid = "c_" .. node_id
        local rx = style.border_radius or 0
        table.insert(ctx.defs, string.format(
            '<clipPath id="%s"><rect x="%s" y="%s" width="%s" height="%s" rx="%s" ry="%s"/></clipPath>',
            cid, b.x, b.y, b.w, b.h, rx, rx))
        clip_ref = string.format("url(#%s)", cid)
    end

    -- 背景和边框矩形
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

    -- 变换（transform + rotate）
    local transform = style.transform or ""
    if style.rotate then
        local rot = style.rotate
        local angle, cx, cy
        if type(rot) == "number" then
            angle = rot
            cx = b.x + b.w / 2
            cy = b.y + b.h / 2
        elseif type(rot) == "table" then
            angle = rot.angle or 0
            local rc = rot.cx
            if type(rc) == "string" then
                local pct = rc:match("^(%-?[%d%.]+)%%$")
                cx = b.x + (pct and b.w * tonumber(pct) / 100 or 0)
            else
                cx = b.x + (rc or b.w / 2)
            end
            local ry = rot.cy
            if type(ry) == "string" then
                local pct = ry:match("^(%-?[%d%.]+)%%$")
                cy = b.y + (pct and b.h * tonumber(pct) / 100 or 0)
            else
                cy = b.y + (ry or b.h / 2)
            end
        end
        transform = transform .. string.format(" rotate(%s, %s, %s)", tostring(angle), tostring(cx), tostring(cy))
        transform = transform:match("^%s*(.-)%s*$")
    end
    local transform_attr = (transform ~= "") and transform or nil

    local need_wrapper = filter_ref or clip_ref or transform_attr or style.opacity

    if need_wrapper then
        -- 需要 <g> 包裹：统一施加特效
        local g_attrs = {
            filter = filter_ref,
            ["clip-path"] = clip_ref,
            transform = transform_attr,
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
