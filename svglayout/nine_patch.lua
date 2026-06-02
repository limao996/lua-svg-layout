---@class svglayout.nine_patch
local M = {}

local core = require("svglayout.core")

---@class svglayout.NinePatchConfig 九宫格配置
---@field href string 源图片 URL
---@field src_width number 源图内容区宽度（不含 1px 边框）
---@field src_height number 源图内容区高度（不含 1px 边框）
---@field left number|string 左侧固定区宽度（支持百分比）
---@field right number|string 右侧固定区宽度（支持百分比）
---@field top number|string 顶部固定区高度（支持百分比）
---@field bottom number|string 底部固定区高度（支持百分比）
---@field repeat_mode string? 默认重复模式，默认 "no-repeat"
---@field block_repeat (table<string,string>)? 逐块重复模式覆盖
---@field scale number? 源素材缩放倍率，默认 1

---@class svglayout.NinePatchBlock 九宫格块
---@field name string "tl"|"t"|"tr"|"l"|"c"|"r"|"bl"|"b"|"br"
---@field sx number 源图中 X
---@field sy number 源图中 Y
---@field sw number 源图中宽度
---@field sh number 源图中高度
---@field stretch_x boolean 水平可拉伸
---@field stretch_y boolean 垂直可拉伸

---@class svglayout.NinePatch 解析后的九宫格定义
---@field href string 源图片 URL
---@field src_w number 源图总宽度（缩放后）
---@field src_h number 源图总高度（缩放后）
---@field blocks svglayout.NinePatchBlock[] 9 个块（行优先）
---@field default_repeat string 默认重复模式
---@field block_repeat table<string,string> 逐块覆盖
---@field scale number 缩放倍率

---解析百分比值
---@param val string|number 值
---@param total number 参照总量
---@return number 数值
local function resolve_pct(val, total)
    if type(val) == "string" then
        local pct = val:match("^(%-?[%d%.]+)%%$")
        if pct then
            return total * tonumber(pct) / 100
        end
    end
    return val or 0 ---@type number
end

---解析 9.png 配置，生成九宫格块定义
---@param config svglayout.NinePatchConfig
---@return svglayout.NinePatch
function M.parse_config(config)
    local src_w = config.src_width
    local src_h = config.src_height
    local scale = config.scale or 1

    local left = resolve_pct(config.left, src_w)
    local right = resolve_pct(config.right, src_w)
    local top = resolve_pct(config.top, src_h)
    local bottom = resolve_pct(config.bottom, src_h)

    if scale ~= 1 then
        src_w = math.floor(src_w * scale + 0.5)
        src_h = math.floor(src_h * scale + 0.5)
        left = math.floor(left * scale + 0.5)
        right = math.floor(right * scale + 0.5)
        top = math.floor(top * scale + 0.5)
        bottom = math.floor(bottom * scale + 0.5)
    end

    local stretch_w = math.max(0, src_w - left - right)
    local stretch_h = math.max(0, src_h - top - bottom)

    -- 行优先排列 9 个块：左上→上→右上→左→中→右→左下→下→右下
    local blocks = {
        { name = "tl", sx = 0,                sy = 0,               sw = left,      sh = top,       stretch_x = false, stretch_y = false },
        { name = "t",  sx = left,             sy = 0,               sw = stretch_w, sh = top,       stretch_x = true,  stretch_y = false },
        { name = "tr", sx = left + stretch_w, sy = 0,               sw = right,     sh = top,       stretch_x = false, stretch_y = false },
        { name = "l",  sx = 0,                sy = top,             sw = left,      sh = stretch_h, stretch_x = false, stretch_y = true },
        { name = "c",  sx = left,             sy = top,             sw = stretch_w, sh = stretch_h, stretch_x = true,  stretch_y = true },
        { name = "r",  sx = left + stretch_w, sy = top,             sw = right,     sh = stretch_h, stretch_x = false, stretch_y = true },
        { name = "bl", sx = 0,                sy = top + stretch_h, sw = left,      sh = bottom,    stretch_x = false, stretch_y = false },
        { name = "b",  sx = left,             sy = top + stretch_h, sw = stretch_w, sh = bottom,    stretch_x = true,  stretch_y = false },
        { name = "br", sx = left + stretch_w, sy = top + stretch_h, sw = right,     sh = bottom,    stretch_x = false, stretch_y = false },
    }

    local default_repeat = config.repeat_mode or "no-repeat"
    local block_repeat = {}
    if config.block_repeat then
        for k, v in pairs(config.block_repeat) do
            block_repeat[k:lower()] = v
        end
    end

    return {
        href = config.href,
        src_w = src_w,
        src_h = src_h,
        blocks = blocks,
        default_repeat = default_repeat,
        block_repeat = block_repeat,
        scale = scale,
    }
end

---渲染九宫格为 SVG 片段
---每块使用 <image> + clip-path 裁剪源图对应区域
---根据重复模式决定使用 <pattern> 或直接裁剪渲染
---@param ctx table 渲染上下文（含 defs）
---@param np svglayout.NinePatch 九宫格定义
---@param box {x:number, y:number, w:number, h:number} 目标盒子
---@param block_repeat_override? table<string,string> 逐块重复模式临时覆盖
---@return string SVG 片段
function M.render(ctx, np, box, block_repeat_override)
    local parts = {}
    local defs = ctx.defs

    local bw = box.w
    local bh = box.h
    local bx = box.x
    local by = box.y

    -- 源图总尺寸（含 1px 边框）
    local src_w = np.src_w + 2
    local src_h = np.src_h + 2

    local b = np.blocks

    local fixed_w = b[1].sw + b[3].sw
    local fixed_h = b[1].sh + b[7].sh

    local stretch_w_avail = math.max(0, bw - fixed_w)
    local stretch_h_avail = math.max(0, bh - fixed_h)

    local stretchable_col_w = b[5].sw
    local stretchable_row_h = b[5].sh

    -- 计算目标网格各行列尺寸
    local target_w0 = b[1].sw
    local target_w1 = stretchable_col_w > 0 and stretch_w_avail or 0
    local target_w2 = b[3].sw
    local target_h0 = b[1].sh
    local target_h1 = stretchable_row_h > 0 and stretch_h_avail or 0
    local target_h2 = b[7].sh

    local col_x = { bx, bx + target_w0, bx + target_w0 + target_w1 }
    local col_w = { target_w0, target_w1, target_w2 }
    local row_y = { by, by + target_h0, by + target_h0 + target_h1 }
    local row_h = { target_h0, target_h1, target_h2 }

    local repeat_override = block_repeat_override or {}
    local escaped_href = core.escape_xml(np.href)

    for idx = 1, 9 do
        local block = b[idx]
        local row = math.ceil(idx / 3)
        local col = ((idx - 1) % 3) + 1

        local tx = col_x[col]
        local ty = row_y[row]
        local tw = col_w[col]
        local th = row_h[row]

        if tw > 0 and th > 0 and block.sw > 0 and block.sh > 0 then
            local repeat_mode = repeat_override[block.name]
                or np.block_repeat[block.name]
                or np.default_repeat

            if (block.stretch_x or block.stretch_y) and repeat_mode ~= "no-repeat" then
                -- 重复模式：使用 <pattern> 平铺
                local pattern_id = core.gen_id("np")
                local tile_w, tile_h

                if repeat_mode == "repeat" then
                    tile_w = block.sw
                    tile_h = block.sh
                elseif repeat_mode == "repeat-x" then
                    tile_w = block.sw
                    tile_h = th
                elseif repeat_mode == "repeat-y" then
                    tile_w = tw
                    tile_h = block.sh
                else
                    tile_w = block.sw
                    tile_h = block.sh
                end

                local pat_clip_id = "pc_" .. pattern_id
                table.insert(defs, string.format(
                    '<clipPath id="%s"><rect x="0" y="0" width="%s" height="%s"/></clipPath>',
                    pat_clip_id, tostring(tile_w), tostring(tile_h)))

                local pat_def = string.format(
                    '<pattern id="%s" width="%s" height="%s" patternUnits="userSpaceOnUse">',
                    pattern_id, tostring(tile_w), tostring(tile_h))
                pat_def = pat_def .. string.format(
                    '<g clip-path="url(#%s)">', pat_clip_id)

                if repeat_mode == "repeat" then
                    pat_def = pat_def .. string.format(
                        '<image href="%s" x="%s" y="%s" width="%s" height="%s" preserveAspectRatio="none"/>',
                        escaped_href,
                        tostring(-(block.sx + 1)), tostring(-(block.sy + 1)),
                        tostring(src_w), tostring(src_h))
                elseif repeat_mode == "repeat-x" then
                    local scale_y = th / block.sh
                    pat_def = pat_def .. string.format(
                        '<image href="%s" x="%s" y="%s" width="%s" height="%s" preserveAspectRatio="none"/>',
                        escaped_href,
                        tostring(-(block.sx + 1)),
                        tostring(-(block.sy + 1) * scale_y),
                        tostring(src_w),
                        tostring(src_h * scale_y))
                elseif repeat_mode == "repeat-y" then
                    local scale_x = tw / block.sw
                    pat_def = pat_def .. string.format(
                        '<image href="%s" x="%s" y="%s" width="%s" height="%s" preserveAspectRatio="none"/>',
                        escaped_href,
                        tostring(-(block.sx + 1) * scale_x),
                        tostring(-(block.sy + 1)),
                        tostring(src_w * scale_x),
                        tostring(src_h))
                else
                    pat_def = pat_def .. string.format(
                        '<image href="%s" x="%s" y="%s" width="%s" height="%s" preserveAspectRatio="none"/>',
                        escaped_href,
                        tostring(-(block.sx + 1)), tostring(-(block.sy + 1)),
                        tostring(src_w), tostring(src_h))
                end

                pat_def = pat_def .. '</g></pattern>'
                table.insert(defs, pat_def)

                parts[#parts + 1] = string.format(
                    '<rect x="%s" y="%s" width="%s" height="%s" fill="url(#%s)"/>',
                    tostring(tx), tostring(ty),
                    tostring(tw), tostring(th),
                    pattern_id)
            else
                -- 拉伸模式：clip-path 裁剪源图对应区域
                local clip_id = core.gen_id("np_clip")
                local cid = "c_" .. clip_id
                table.insert(defs, string.format(
                    '<clipPath id="%s"><rect x="%s" y="%s" width="%s" height="%s"/></clipPath>',
                    cid, tostring(tx), tostring(ty), tostring(tw), tostring(th)))

                local scale_x = tw / block.sw
                local scale_y = th / block.sh
                local img_x = tx - (block.sx + 1) * scale_x
                local img_y = ty - (block.sy + 1) * scale_y
                local img_w = src_w * scale_x
                local img_h = src_h * scale_y

                parts[#parts + 1] = string.format(
                    '<g clip-path="url(#%s)"><image href="%s" x="%s" y="%s" width="%s" height="%s" preserveAspectRatio="none"/></g>',
                    cid, escaped_href,
                    tostring(img_x), tostring(img_y),
                    tostring(img_w), tostring(img_h))
            end
        end
    end

    return table.concat(parts, "\n")
end

return M
