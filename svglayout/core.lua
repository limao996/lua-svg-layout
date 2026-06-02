---@class svglayout.core
local M = {}

---将字符串中的 XML 特殊字符转义为实体引用
---支持 VarHandle 变量：自动通过 tostring 触发 __tostring 元方法，
---输出 {{name}} 占位符，同时确保 XML 特殊字符被正确转义
---@param s string|table 原始字符串或 VarHandle
---@return string 转义后的安全 XML 字符串
---@nodiscard
function M.escape_xml(s)
    s = tostring(s)
    return (s:gsub("[&<>\"']", {
        ["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;",
        ['"'] = "&quot;", ["'"] = "&apos;",
    }))
end

---创建表的浅拷贝（仅复制第一层键值对）
---@generic T: table
---@param t T 源表
---@return T 新表，嵌套对象仍共享引用
---@nodiscard
function M.shallow_copy(t)
    local r = {}
    for k, v in pairs(t) do r[k] = v end
    return r
end

---将属性键值对序列化为 SVG 标签属性字符串
---键按字母排序以保证输出可预测；nil 和 false 值自动跳过
---@param attrs table<string, any> 属性表
---@return string 格式如 `key1="val1" key2="val2"`
---@nodiscard
function M.attrs_to_str(attrs)
    if not attrs then return "" end
    local parts = {}
    local keys = {}
    for k in pairs(attrs) do keys[#keys + 1] = k end
    table.sort(keys)
    for _, k in ipairs(keys) do
        local v = attrs[k]
        if v ~= nil and v ~= false then
            parts[#parts + 1] = string.format('%s="%s"', k, M.escape_xml(tostring(v)))
        end
    end
    return table.concat(parts, " ")
end

---生成全局唯一 ID（内部维护递增计数器）
---@param prefix string? ID 前缀，默认 "id"
---@return string 唯一 ID，如 "box42"
---@nodiscard
local _id = 0
function M.gen_id(prefix)
    _id = _id + 1
    return (prefix or "id") .. _id
end

---根据文本对齐方式计算 SVG text-anchor 和 X 坐标
---@param align string "left"|"center"|"right"
---@param content_x number 内容区左边界
---@param content_w number 内容区宽度
---@return string anchor SVG text-anchor（"start"|"middle"|"end"）
---@return number tx 文本 X 坐标
---@nodiscard
function M.compute_text_alignment(align, content_x, content_w)
    align = align or "left"
    if align == "center" then
        return "middle", content_x + content_w / 2
    elseif align == "right" then
        return "end", content_x + content_w
    else
        return "start", content_x
    end
end

return M
