---@class svglayout.style
local M = {}

---规范化间距值为四元数组 [top, right, bottom, left]
---支持多种输入格式：
--- - `nil` → `{0, 0, 0, 0}`
--- - `number` → 四个方向相同
--- - `{top, right, bottom, left}` → 按顺序映射
--- - `{top, right}` → 上下 = top, 左右 = right
--- - `{top=t, right=r, bottom=b, left=l}` → 按命名键映射
---@param p? number|number[]|table 间距值
---@return number[4] 四元数组 [top, right, bottom, left]，索引从 1 开始
---@nodiscard
function M.normalize_spacing(p)
    if p == nil then return { 0, 0, 0, 0 } end
    if type(p) == "number" then return { p, p, p, p } end
    if #p == 2 then return { p[1], p[2], p[1], p[2] } end
    if #p == 4 then return { p[1], p[2], p[3], p[4] } end
    return { p.top or 0, p.right or 0, p.bottom or 0, p.left or 0 }
end

---扩展样式表：合并基础样式和覆盖样式，返回新表而不修改原始表
---@generic T: table
---@param base T 基础样式表
---@param override table 覆盖样式表，同名字段将覆盖 base 中的值
---@return T 合并后的新样式表
---@nodiscard
function M.extend(base, override)
    local r = {}
    for k, v in pairs(base or {}) do r[k] = v end
    for k, v in pairs(override or {}) do r[k] = v end
    return r
end

---解析尺寸声明为结构化模式
---支持的输入格式：
--- - `nil` → auto 模式
--- - `number` → fixed 模式，直接使用该数值
--- - `"auto"` → auto 模式，由子节点内容决定
--- - `"fill"` → fill 模式，填满父容器可用空间
--- - `"50%"` → fixed 模式，按父容器尺寸百分比计算
--- - `"100"` → fixed 模式，自动转换为数字
---@param v any 尺寸声明值
---@param parent? number 父容器对应方向的可用尺寸，nil 表示未知
---@return number? 数值结果；nil 表示需要后续布局阶段决策
---@return '"fixed"'|'"auto"'|'"fill"' 解析模式：fixed（固定值）、auto（自适应）、fill（填充）
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
