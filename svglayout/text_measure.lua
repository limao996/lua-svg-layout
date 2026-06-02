---@class svglayout.TextMeasure
local M = {}

---默认字宽系数（相对 font_size）
---英文/数字：约 0.55；CJK：约 1.0；标点：约 0.35
local DEFAULT_ASCII = 0.55
local DEFAULT_CJK   = 1.0
local DEFAULT_PUNCT = 0.35

---判断 Unicode 码点是否属于 CJK 字符范围
---覆盖汉字（CJK Unified Ideographs）、韩文（Hangul Syllables）、
---兼容表意文字（CJK Compatibility Ideographs）和全角标点（Fullwidth Forms）区域
---@param cp integer Unicode 码点
---@return boolean 如果码点属于 CJK 范围则返回 true
local function is_cjk(cp)
    return (cp >= 0x3000 and cp <= 0x9FFF)
        or (cp >= 0xAC00 and cp <= 0xD7AF)
        or (cp >= 0xF900 and cp <= 0xFAFF)
        or (cp >= 0xFF00 and cp <= 0xFFEF)
end

---常见 ASCII 标点符号查找表，用于宽度估算
local ASCII_PUNCT = {
    [string.byte(",")] = true, [string.byte(".")] = true,
    [string.byte(";")] = true, [string.byte(":")] = true,
    [string.byte("!")] = true, [string.byte("?")] = true,
    [string.byte("'")] = true, [string.byte('"')] = true,
}

---UTF-8 解码迭代器（仅码点）：依次返回字符串中每个字符的 Unicode 码点
---无字符串分配，适合只需码点进行宽度判断的场景（如 text_width）
---@param s string 要迭代的 UTF-8 字符串
---@return fun(): integer? 迭代器函数，每次调用返回 Unicode 码点
function M.utf8_iter_cp(s)
    local i = 1
    local len = #s
    return function()
        if i > len then return nil end
        local b = string.byte(s, i)
        local bytes
        if b < 0x80 then bytes = 1
        elseif b < 0xC0 then bytes = 1
        elseif b < 0xE0 then bytes = 2
        elseif b < 0xF0 then bytes = 3
        else bytes = 4 end
        local cp = utf8.codepoint(s, i)
        i = i + bytes
        return cp
    end
end

---UTF-8 解码迭代器（完整）：依次返回字符串中每个字符的码点和字符子串
---相比 utf8_iter_cp 多一次 string.sub 分配，适合需要子串的场景（如 wrap）
---@param s string 要迭代的 UTF-8 字符串
---@return fun(): integer?, string? 迭代器函数，每次调用返回 (码点, 字符子串)
function M.utf8_iter(s)
    local i = 1
    local len = #s
    return function()
        if i > len then return nil end
        local b = string.byte(s, i)
        local bytes
        if b < 0x80 then bytes = 1
        elseif b < 0xC0 then bytes = 1
        elseif b < 0xE0 then bytes = 2
        elseif b < 0xF0 then bytes = 3
        else bytes = 4 end
        local j = i + bytes - 1
        local ch = s:sub(i, j)
        local cp = utf8.codepoint(s, i)
        i = j + 1
        return cp, ch
    end
end

---估算单个字符的宽度（倍率 × font_size）
---CJK 字符按 1.0 倍率，ASCII 标点按 0.35 倍率，其他按 0.55 倍率
---@param cp integer Unicode 码点
---@param font_size number 字体大小（像素）
---@return number 预估字符宽度（像素）
---@nodiscard
function M.char_width(cp, font_size)
    if is_cjk(cp) then return font_size * DEFAULT_CJK end
    if cp < 128 and ASCII_PUNCT[cp] then return font_size * DEFAULT_PUNCT end
    return font_size * DEFAULT_ASCII
end

---估算整行文本的总宽度
---遍历所有字符累加宽度，不处理换行符
---@param text string 要测量的文本字符串
---@param font_size number 字体大小（像素）
---@return number 预估文本总宽度（像素）
---@nodiscard
function M.text_width(text, font_size)
    local w = 0
    for cp in M.utf8_iter_cp(text) do
        w = w + M.char_width(cp, font_size)
    end
    return w
end

---根据最大宽度对文本进行换行，返回行数组
---处理策略：
--- - CJK 字符：逐字拆分，超过宽度时换行
--- - 英文单词：按空格拆分，单词超长时强制截断
--- - 显式换行符（`\n`）：直接分段
---@param text string 要换行的文本
---@param max_width number 最大行宽（像素）
---@param font_size number 字体大小（像素）
---@return string[] 换行后的行数组，每行一个字符串
---@nodiscard
function M.wrap(text, max_width, font_size)
    if max_width <= 0 then return { text } end
    local lines = {}
    for paragraph in (text .. "\n"):gmatch("([^\n]*)\n") do
        if paragraph == "" then
            lines[#lines + 1] = ""
        else
            local line_parts = {}
            local line_w = 0
            local word = ""
            local word_w = 0

            local function flush_word()
                if word == "" then return end
                if line_w + word_w <= max_width or #line_parts == 0 then
                    line_parts[#line_parts + 1] = word
                    line_w = line_w + word_w
                else
                    lines[#lines + 1] = table.concat(line_parts)
                    line_parts = { word }
                    line_w = word_w
                end
                word = ""
                word_w = 0
            end

            for cp, ch in M.utf8_iter(paragraph) do
                local cw = M.char_width(cp, font_size)
                if is_cjk(cp) then
                    flush_word()
                    if line_w + cw <= max_width or #line_parts == 0 then
                        line_parts[#line_parts + 1] = ch
                        line_w = line_w + cw
                    else
                        lines[#lines + 1] = table.concat(line_parts)
                        line_parts = { ch }
                        line_w = cw
                    end
                elseif ch == " " then
                    flush_word()
                    if #line_parts > 0 then
                        if line_w + cw <= max_width then
                            line_parts[#line_parts + 1] = ch
                            line_w = line_w + cw
                        else
                            lines[#lines + 1] = table.concat(line_parts)
                            line_parts = {}
                            line_w = 0
                        end
                    end
                else
                    if word_w + cw > max_width then
                        if #line_parts > 0 then
                            lines[#lines + 1] = table.concat(line_parts)
                            line_parts = {}
                            line_w = 0
                        end
                        lines[#lines + 1] = word
                        word = ch
                        word_w = cw
                    else
                        word = word .. ch
                        word_w = word_w + cw
                    end
                end
            end
            flush_word()
            lines[#lines + 1] = table.concat(line_parts)
        end
    end
    return lines
end

return M
