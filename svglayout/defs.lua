---@class svglayout.Defs
local M = {}

local core = require("svglayout.core")

---@class svglayout.GradientStop 渐变色标
---@field offset number|string 位置（0~1 数字或 "50%" 字符串）
---@field color string 颜色
---@field opacity? number 透明度 0~1

---@class svglayout.DefObject 定义对象，可通过 .ref 在 fill/stroke 中引用
---@field ref string 引用，如 "url(#xxx)"
---@field _def string SVG defs 定义
---@field _register fun(ctx:table) 注册到渲染上下文

---创建线性渐变定义对象
---在 fill/stroke 中使用 .ref 属性引用
---@param props {id?:string, x1?:string|number, y1?:string|number, x2?:string|number, y2?:string|number, stops:svglayout.GradientStop[]}
---@return svglayout.DefObject
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
---在 fill/stroke 中使用 .ref 属性引用
---@param props {id?:string, cx?:string|number, cy?:string|number, r?:string|number, stops:svglayout.GradientStop[]}
---@return svglayout.DefObject
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
---@param props {id?:string, width:number, height:number, content:string}
---@return svglayout.DefObject
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
