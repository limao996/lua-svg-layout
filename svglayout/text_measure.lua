---@class svglayout.TextMeasure
local M = {}

-- 字宽系数（相对 font_size）：英文 0.55、CJK 1.0、标点 0.35
local DEFAULT_ASCII = 0.55
local DEFAULT_CJK   = 1.0
local DEFAULT_PUNCT = 0.35

---判断 Unicode 码点是否属于 CJK 字符范围
---覆盖 CJK 统一表意文字、韩文音节、兼容表意文字、全角标点
---@param cp integer Unicode 码点
---@return boolean
local function is_cjk(cp)
    return (cp >= 0x3000 and cp <= 0x9FFF)
        or (cp >= 0xAC00 and cp <= 0xD7AF)
        or (cp >= 0xF900 and cp <= 0xFAFF)
        or (cp >= 0xFF00 and cp <= 0xFFEF)
end

-- 常见 ASCII 标点字符码点查找表
local ASCII_PUNCT = {
    [string.byte(",")] = true, [string.byte(".")] = true,
    [string.byte(";")] = true, [string.byte(":")] = true,
    [string.byte("!")] = true, [string.byte("?")] = true,
    [string.byte("'")] = true, [string.byte('"')] = true,
}

---UTF-8 码点迭代器（仅返回码点，无字符串分配）
---@param s string UTF-8 字符串
---@return fun(): integer? 迭代函数，每次返回一个 Unicode 码点
function M.utf8_iter_cp(s)
    local i = 1
    local len = #s
    return function()
        ::restart::
        if i > len then return nil end
        local b = string.byte(s, i)
        local bytes
        if b < 0x80 then bytes = 1
        elseif b < 0xC0 then i = i + 1; goto restart
        elseif b < 0xE0 then bytes = 2
        elseif b < 0xF0 then bytes = 3
        else bytes = 4 end
        local cp = utf8.codepoint(s, i)
        i = i + bytes
        return cp
    end
end

---UTF-8 字符迭代器（返回码点和字符子串）
---比 utf8_iter_cp 多一次 sub 分配，适合需要子串的场景（如换行）
---@param s string UTF-8 字符串
---@return fun(): integer?, string? 迭代函数，返回 (码点, 字符)
function M.utf8_iter(s)
    local i = 1
    local len = #s
    return function()
        ::restart::
        if i > len then return nil end
        local b = string.byte(s, i)
        local bytes
        if b < 0x80 then bytes = 1
        elseif b < 0xC0 then i = i + 1; goto restart
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

---估算单个字符的渲染宽度 = font_size * 字宽系数
---@param cp integer Unicode 码点
---@param font_size number 字体大小（px）
---@return number 预估宽度（px）
---@nodiscard
function M.char_width(cp, font_size)
    if is_cjk(cp) then return font_size * DEFAULT_CJK end
    if cp < 128 and ASCII_PUNCT[cp] then return font_size * DEFAULT_PUNCT end
    return font_size * DEFAULT_ASCII
end

---估算整行文本总宽度（遍历字符累加，不处理换行符）
---@param text string 文本
---@param font_size number 字体大小（px）
---@return number 总宽度（px）
---@nodiscard
function M.text_width(text, font_size)
    local w = 0
    for cp in M.utf8_iter_cp(text) do
        w = w + M.char_width(cp, font_size)
    end
    return w
end

---按最大宽度对文本换行，返回行数组
---策略：CJK 逐字拆分超宽换行；英文按空格分词，超长单词强制截断；`\n` 显式分段
---@param text string 文本
---@param max_width number 最大行宽（px）
---@param font_size number 字体大小（px）
---@return string[] 行数组
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

            -- 将缓存的单词刷入当前行；放不下时另起一行
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
                    -- CJK 字符按单字处理，超宽则换行
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
                    -- 空格作为单词分隔符，仅当不在行首时消耗宽度
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
                    -- 非 CJK 非空格字符，组装为单词
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
