---@class svglayout.style
local M = {}

---规范化间距值为四元数组 [top, right, bottom, left]
---输入格式：nil → {0,0,0,0}；数字 → 四方向相同；
---{t,r,b,l} → 顺序映射；{t,r} → 上下=t，左右=r；
---{top=t,right=r,bottom=b,left=l} → 命名键映射
---@param p? number|number[]|table 间距值
---@return number[4] [top, right, bottom, left]
---@nodiscard
function M.normalize_spacing(p)
    if p == nil then return { 0, 0, 0, 0 } end
    if type(p) == "number" then return { p, p, p, p } end
    if #p == 2 then return { p[1], p[2], p[1], p[2] } end
    if #p == 4 then return { p[1], p[2], p[3], p[4] } end
    return { p.top or 0, p.right or 0, p.bottom or 0, p.left or 0 }
end

---合并两个样式表，返回新表（不修改原始表）
---@generic T: table
---@param base T 基础样式
---@param override table 覆盖样式
---@return T 合并结果
---@nodiscard
function M.extend(base, override)
    local r = {}
    for k, v in pairs(base or {}) do r[k] = v end
    for k, v in pairs(override or {}) do r[k] = v end
    return r
end

---解析尺寸声明值，返回数值和模式
---支持：nil→auto；数字→fixed；"auto"→auto；"fill"→fill；"50%"→百分比 fixed；"100"→字符串转数字 fixed
---@param v any 尺寸值
---@param parent? number 父容器尺寸（百分比计算用）
---@return number? 解析后的数值
---@return '"fixed"'|'"auto"'|'"fill"' 解析模式
---@nodiscard
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
