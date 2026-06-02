---@class svglayout.variable 变量系统
---
---SVG 模板变量系统
---
---设计原理：允许在 SVG 模板代码中使用 var("name") 声明动态变量占位符，
---最终输出的 SVG 文件中该变量以 {{name}} 格式呈现，可供外部模板引擎
---（如 Jinja2、Mustache、Handlebars 等）后续替换为实际值。
---
---实现机制：
---  1. VarHandle —— var() 返回的轻量级对象，携带变量名
---  2. __tostring —— 元方法使得 VarHandle 在字符串上下文中
---     自动输出 {{name}}，对非变量代码路径完全透明
---  3. resolve_numeric —— 布局测量阶段将数值型变量降级为默认值，
---     保证布局计算正常进行，渲染阶段仍输出 {{name}}
---
---转换规则：
---  输入                    SVG 输出
---  text = var("title")     {{title}}
---  font_size = var("fs")   font-size="{{fs}}"
---  background = var("bg")  fill="{{bg}}"
---  fill = var("color")     fill="{{color}}"
---
---使用限制：
---  - VarHandle 适用于标量值（字符串、数字、颜色），
---    不适用于复合配置对象（如 shadow、rotate 等结构体配置）
---  - 数值型变量在布局阶段使用默认值（font_size 默认 14，
---    width/height 默认 auto），不影响布局计算
local M = {}

---VarHandle 元表
---__tostring 返回 {{变量名}} 格式的占位符
local var_handle_mt = {
    __tostring = function(self)
        return "{{" .. self._name .. "}}"
    end,
    _VAR_HANDLE_MT = true,
}

---@class svglayout.VarHandle 变量句柄
---@field _name string 变量名称
M.VarHandle = {}

---创建模板变量占位符
---在 SVG 生成代码中调用此函数声明一个动态变量，
---最终输出的 SVG 文件中该变量会以 {{variable_name}} 格式呈现
---@param name string 变量名称（不能为空字符串）
---@return svglayout.VarHandle 变量句柄
---@usage var("title")  --> 在 SVG 中输出 {{title}}
function M.var(name)
    assert(type(name) == "string", "var(): name must be a string, got " .. type(name))
    assert(#name > 0, "var(): name must not be empty")
    return setmetatable({ _name = name }, var_handle_mt)
end

---判断值是否为 VarHandle 变量
---@param v any 待检查的值
---@return boolean 是否为变量句柄
function M.is_var(v)
    return type(v) == "table" and getmetatable(v) == var_handle_mt
end

---解析数值属性
---若为变量或 nil 则返回默认值，否则返回原值
---用于布局测量阶段，当 font_size、width 等数值属性为变量时提供合理的默认值
---@param v any 属性值
---@param default number 默认值（变量或 nil 时的回退值，默认为 0）
---@return number 解析后的数值
function M.resolve_numeric(v, default)
    if M.is_var(v) then return default or 0 end
    if v == nil then return default or 0 end
    return v
end

---将变量格式化为 SVG 输出值
---变量返回 {{name}}，其他值返回原值
---@param v any 属性值
---@return any SVG 输出值
function M.to_svg_value(v)
    if M.is_var(v) then return tostring(v) end
    return v
end

return M
