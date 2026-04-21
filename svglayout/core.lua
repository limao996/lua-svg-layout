---@class svglayout.core
local M = {}

---@param s string
---@return string
function M.escape_xml(s)
    return (s:gsub("[&<>\"']", {
        ["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;",
        ['"'] = "&quot;", ["'"] = "&apos;",
    }))
end

---@param t table
---@return table
function M.shallow_copy(t)
    local r = {}
    for k, v in pairs(t) do r[k] = v end
    return r
end

---@param a table
---@param b table
---@return table
function M.merge(a, b)
    local r = M.shallow_copy(a or {})
    if b then for k, v in pairs(b) do r[k] = v end end
    return r
end

---序列化 SVG 属性
---@param attrs table<string,any>
---@return string
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

---唯一 ID 生成
local _id = 0
function M.gen_id(prefix)
    _id = _id + 1
    return (prefix or "id") .. _id
end

return M