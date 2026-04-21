---@class svglayout.Style
---@field width? number|string
---@field height? number|string
---@field flex? number
-- ... 其他字段同前

local M = {}

---规范化间距值为四元数组 [top, right, bottom, left]
---@param p number|table|nil 间距值，可以是数字、数组或表
---@return number[] 四元数组 [top, right, bottom, left]
function M.normalize_spacing(p)
    if p == nil then return { 0, 0, 0, 0 } end
    if type(p) == "number" then return { p, p, p, p } end
    if #p == 2 then return { p[1], p[2], p[1], p[2] } end
    if #p == 4 then return { p[1], p[2], p[3], p[4] } end
    return { p.top or 0, p.right or 0, p.bottom or 0, p.left or 0 }
end

---扩展样式表，合并基础样式和覆盖样式
---@param base table 基础样式表
---@param override table 覆盖样式表
---@return table 合并后的样式表
function M.extend(base, override)
    local r = {}
    for k, v in pairs(base or {}) do r[k] = v end
    for k, v in pairs(override or {}) do r[k] = v end
    return r
end

---解析尺寸声明
---@param v any
---@param parent number|nil   父容器对应方向的可用尺寸；nil 表示未知
---@return number?  数值；nil 表示需要后续决策
---@return string   模式："fixed"|"auto"|"fill"
function M.resolve_size(v, parent)
    if v == nil then return nil, "auto" end
    if type(v) == "number" then return v, "fixed" end
    if type(v) == "string" then
        if v == "auto" then return nil, "auto" end
        if v == "fill" then return nil, "fill" end
        local pct = v:match("^(%-?[%d%.]+)%%$")
        if pct and parent then
            return parent * tonumber(pct) / 100, "fixed"
        end
        local n = tonumber(v)
        if n then return n, "fixed" end
    end
    return nil, "auto"
end

return M
