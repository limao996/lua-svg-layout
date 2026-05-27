---@class svglayout.core
local M = {}

---将字符串中的 XML 特殊字符转义为对应的实体引用
---转义规则: `&` → `&amp;`, `<` → `&lt;`, `>` → `&gt;`, `"` → `&quot;`, `'` → `&apos;`
---@param s string 要转义的原始字符串
---@return string 转义后的安全 XML 字符串，可直接嵌入 SVG 属性或文本节点
---@nodiscard
function M.escape_xml(s)
    return (s:gsub("[&<>\"']", {
        ["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;",
        ['"'] = "&quot;", ["'"] = "&apos;",
    }))
end

---创建表的浅拷贝，仅复制第一层的键值对
---@generic T: table
---@param t T 要拷贝的源表
---@return T 拷贝后的新表，与原表共享嵌套对象的引用
---@nodiscard
function M.shallow_copy(t)
    local r = {}
    for k, v in pairs(t) do r[k] = v end
    return r
end

---合并两个表并返回新表，b 中的键值会覆盖 a 中的同名键
---@generic T1: table, T2: table
---@param a T1 基础表，作为合并的起点
---@param b T2 覆盖表，其键值将覆盖 a 中的同名项
---@return T1|T2 合并后的新表，不会修改原始表
---@nodiscard
function M.merge(a, b)
    local r = M.shallow_copy(a or {})
    if b then for k, v in pairs(b) do r[k] = v end end
    return r
end

---序列化属性表为 SVG 标签属性字符串
---键按字母顺序排序以确保输出可预测；值为 nil 或 false 的键会被自动跳过
---@param attrs table<string, any> 属性键值对表
---@return string 格式化后的属性字符串，形如 `key1="val1" key2="val2"`
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

---生成全局唯一 ID 字符串
---内部维护递增计数器以保证每次调用返回不同 ID
---@param prefix? string ID 前缀，默认为 `"id"`
---@return string 唯一 ID 字符串，形如 `"box42"` 或 `"id13"`
---@nodiscard
local _id = 0
function M.gen_id(prefix)
    _id = _id + 1
    return (prefix or "id") .. _id
end

return M
