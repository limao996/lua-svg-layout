---@class svglayout.TextMeasure
local M = {}

-- 默认字宽系数（相对 font_size）
-- 英文/数字：约 0.55；CJK：约 1.0；标点：约 0.3
local DEFAULT_ASCII = 0.55
local DEFAULT_CJK   = 1.0
local DEFAULT_PUNCT = 0.35

---判断 UTF-8 码点是否属于 CJK 范围
---@param cp integer
---@return boolean
local function is_cjk(cp)
    return (cp >= 0x3000 and cp <= 0x9FFF)
        or (cp >= 0xAC00 and cp <= 0xD7AF)
        or (cp >= 0xF900 and cp <= 0xFAFF)
        or (cp >= 0xFF00 and cp <= 0xFFEF)
end

local ASCII_PUNCT = {
    [string.byte(",")] = true, [string.byte(".")] = true,
    [string.byte(";")] = true, [string.byte(":")] = true,
    [string.byte("!")] = true, [string.byte("?")] = true,
    [string.byte("'")] = true, [string.byte('"')] = true,
}

---UTF-8 解码迭代器：返回 (码点, 字符, 字节起, 字节止)
---@param s string
function M.utf8_iter(s)
    local i = 1
    local len = #s
    return function()
        if i > len then return nil end
        local b = string.byte(s, i)
        local bytes
        if b < 0x80 then bytes = 1
        elseif b < 0xC0 then bytes = 1  -- 非法起始，按1字节跳过
        elseif b < 0xE0 then bytes = 2
        elseif b < 0xF0 then bytes = 3
        else bytes = 4 end
        local j = math.min(i + bytes - 1, len)
        local ch = s:sub(i, j)
        local cp = utf8.codepoint(s, i)
        local start = i
        i = j + 1
        return cp, ch, start, j
    end
end

---估算单个字符宽度（倍率 × font_size）
---@param cp integer
---@param font_size number
---@return number
function M.char_width(cp, font_size)
    if is_cjk(cp) then return font_size * DEFAULT_CJK end
    if cp < 128 and ASCII_PUNCT[cp] then return font_size * DEFAULT_PUNCT end
    return font_size * DEFAULT_ASCII
end

---估算整行文本宽度
---@param text string
---@param font_size number
---@return number
function M.text_width(text, font_size)
    local w = 0
    for cp in M.utf8_iter(text) do
        w = w + M.char_width(cp, font_size)
    end
    return w
end

---根据最大宽度换行，返回行数组
---CJK 按字拆分；英文按空格拆分（单词过长则强制截断）
---@param text string
---@param max_width number
---@param font_size number
---@return string[]
function M.wrap(text, max_width, font_size)
    if max_width <= 0 then return { text } end
    local lines = {}
    -- 按显式换行符先拆
    for paragraph in (text .. "\n"):gmatch("([^\n]*)\n") do
        if paragraph == "" then
            lines[#lines + 1] = ""
        else
            -- 逐字符组合
            local line = ""
            local line_w = 0
            local word = ""
            local word_w = 0

            local function flush_word()
                if word == "" then return end
                if line_w + word_w <= max_width or line == "" then
                    line = line .. word
                    line_w = line_w + word_w
                else
                    lines[#lines + 1] = line
                    line = word
                    line_w = word_w
                end
                word = ""
                word_w = 0
            end

            for cp, ch in M.utf8_iter(paragraph) do
                local cw = M.char_width(cp, font_size)
                if is_cjk(cp) then
                    flush_word()
                    if line_w + cw <= max_width or line == "" then
                        line = line .. ch
                        line_w = line_w + cw
                    else
                        lines[#lines + 1] = line
                        line = ch
                        line_w = cw
                    end
                elseif ch == " " then
                    flush_word()
                    if line ~= "" then
                        if line_w + cw <= max_width then
                            line = line .. ch
                            line_w = line_w + cw
                        else
                            lines[#lines + 1] = line
                            line = ""
                            line_w = 0
                        end
                    end
                else
                    -- 单词内字符
                    if word_w + cw > max_width then
                        -- 单词超宽，强制断开
                        if line ~= "" then
                            lines[#lines + 1] = line
                            line = ""; line_w = 0
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
            lines[#lines + 1] = line
        end
    end
    return lines
end

return M