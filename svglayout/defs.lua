---@class svglayout.Defs
local M = {}

local core = require("svglayout.core")

---@class svglayout.GradientStop 渐变色标定义
---@field offset number|string 色标位置，0~1 的数字或 "50%" 格式字符串
---@field color string 色标颜色值
---@field opacity? number 色标透明度（0~1）

---@class svglayout.DefObject 定义对象，可在 fill/stroke 中通过 .ref 引用
---@field ref string 定义引用字符串，形如 "url(#xxx)"
---@field _def string 原始 SVG defs 定义字符串
---@field _register fun(ctx:table) 注册回调，将定义写入渲染上下文

---创建线性渐变定义对象
---在 `fill`/`stroke` 中使用返回值的 `.ref` 属性（如 `grad.ref`）即可引用
---@param props {id?:string, x1?:string|number, y1?:string|number, x2?:string|number, y2?:string|number, stops:svglayout.GradientStop[]} 渐变属性
---@return svglayout.DefObject 包含 ref 引用和注册方法的定义对象
function M.LinearGradient(props)
    local id = props.id or core.gen_id("lg")
    local stops = {}
    for _, s in ipairs(props.stops or {}) do
        local off = type(s.offset) == "number" and (s.offset * 100 .. "%") or s.offset
        stops[#stops + 1] = string.format(
            '<stop offset="%s" stop-color="%s"%s/>',
            off, s.color,
            s.opacity and (' stop-opacity="' .. s.opacity .. '"') or "")
    end
    local def = string.format(
        '<linearGradient id="%s" x1="%s" y1="%s" x2="%s" y2="%s">%s</linearGradient>',
        id, props.x1 or "0%", props.y1 or "0%",
        props.x2 or "100%", props.y2 or "0%", table.concat(stops))
    return {
        ref = string.format("url(#%s)", id),
        _def = def,
        _register = function(ctx) table.insert(ctx.defs, def) end,
    }
end

---创建径向渐变定义对象
---在 `fill`/`stroke` 中使用返回值的 `.ref` 属性引用
---@param props {id?:string, cx?:string|number, cy?:string|number, r?:string|number, stops:svglayout.GradientStop[]} 渐变属性
---@return svglayout.DefObject 包含 ref 引用和注册方法的定义对象
function M.RadialGradient(props)
    local id = props.id or core.gen_id("rg")
    local stops = {}
    for _, s in ipairs(props.stops or {}) do
        local off = type(s.offset) == "number" and (s.offset * 100 .. "%") or s.offset
        stops[#stops + 1] = string.format(
            '<stop offset="%s" stop-color="%s"%s/>',
            off, s.color,
            s.opacity and (' stop-opacity="' .. s.opacity .. '"') or "")
    end
    local def = string.format(
        '<radialGradient id="%s" cx="%s" cy="%s" r="%s">%s</radialGradient>',
        id, props.cx or "50%", props.cy or "50%", props.r or "50%", table.concat(stops))
    return {
        ref = string.format("url(#%s)", id),
        _def = def,
        _register = function(ctx) table.insert(ctx.defs, def) end,
    }
end

---创建 SVG Pattern（图案填充）定义对象
---@param props {id?:string, width:number, height:number, content:string} 图案属性，content 为原始 SVG 内容
---@return svglayout.DefObject 包含 ref 引用和注册方法的定义对象
function M.Pattern(props)
    local id = props.id or core.gen_id("pat")
    local def = string.format(
        '<pattern id="%s" width="%s" height="%s" patternUnits="userSpaceOnUse">%s</pattern>',
        id, props.width, props.height, props.content or "")
    return {
        ref = string.format("url(#%s)", id),
        _def = def,
        _register = function(ctx) table.insert(ctx.defs, def) end,
    }
end

return M
