package.path = package.path .. ";../?.lua;../?/init.lua;./?/init.lua"
local svg = require("svglayout")

-- ============================================================================
-- 综合示例：全面覆盖库的每个功能 + 性能测试
-- 本示例按功能分类，每个分类包含独立的演示和输出
-- ============================================================================

local output_dir = arg and arg[0] and arg[0]:match("^(.*[\\/])") or "./"
output_dir = output_dir .. "../output/"

local function save_output(filename, content)
    local path = output_dir .. filename
    local f = io.open(path, "w")
    if f then
        f:write(content)
        f:close()
        print("  [OK] 已保存 output/" .. filename)
    else
        print("  [ERR] 无法写入 " .. path)
    end
end

local function section(title)
    print("")
    print(string.rep("=", 60))
    print(title)
    print(string.rep("=", 60))
end

local function perf(name, fn)
    local start = os.clock()
    local result = fn()
    local elapsed = os.clock() - start
    print(string.format("  [性能] %s: %.4f 秒", name, elapsed))
    return result
end

-- ============================================================================
-- 1. 基础组件
-- ============================================================================
section("1. 基础组件 — Box / Text / TextBlock / Rect / Circle / Line / Path")

local doc1 = svg.Box {
    style = {
        width = 760, height = 500, background = "#f8f9fa",
        padding = 20, direction = "column", gap = 12,
    },
    children = {
        svg.Text {
            text = "基础组件演示",
            style = { height = 36, font_size = 24, font_weight = "bold", color = "#222", text_align = "center" },
        },
        svg.TextBlock {
            text = "TextBlock 支持自动换行。这是一段较长的文本，用于演示多行文本的自动换行效果。SVG Layout 库使用 UTF-8 感知的文本测量算法，能够正确处理中文、英文和混合文本。",
            style = { background = "#fff", padding = 12, border_radius = 6, font_size = 14, color = "#444", line_height = 1.5 },
        },
        svg.Box {
            style = { direction = "row", gap = 16, height = 80, align = "center" },
            children = {
                svg.Rect { style = { width = 80, height = 60, fill = "#e74c3c", border_radius = 8 } },
                svg.Rect { style = { width = 80, height = 60, fill = "#3498db", border_radius = 4 } },
                svg.Circle { style = { width = 60, height = 60, fill = "#2ecc71" } },
                svg.Circle { style = { width = 50, height = 50, fill = "#f39c12" } },
                svg.Line { style = { width = 100, height = 60, stroke = "#9b59b6", stroke_width = 3 } },
                svg.Path { d = "M10 40 Q30 0 50 40 Q70 0 90 40", style = { fill = "none", stroke = "#e67e22", stroke_width = 2 } },
            },
        },
    },
}
save_output("1_basic_components.svg", svg.render_svg(doc1))

-- ============================================================================
-- 2. 进阶容器组件
-- ============================================================================
section("2. 进阶容器 — Row / Column / ZStack / Spacer / Divider / Group / Raw")

local doc2 = svg.Box {
    style = {
        width = 760, height = 620, background = "#f8f9fa",
        padding = 20, direction = "column", gap = 16,
    },
    children = {
        svg.Text {
            text = "Row / Column / Spacer / Divider",
            style = { height = 30, font_size = 20, font_weight = "bold", color = "#222", text_align = "center" },
        },
        svg.Row {
            style = { gap = 8, height = 40, align = "center" },
            children = {
                svg.Text { text = "左", style = { font_size = 14, color = "#fff", background = "#e74c3c", padding = { 6, 12 } } },
                svg.Spacer(),
                svg.Text { text = "中", style = { font_size = 14, color = "#fff", background = "#3498db", padding = { 6, 12 } } },
                svg.Spacer(),
                svg.Text { text = "右", style = { font_size = 14, color = "#fff", background = "#2ecc71", padding = { 6, 12 } } },
            },
        },
        svg.Divider(),
        svg.Text {
            text = "Column 布局",
            style = { height = 24, font_size = 16, color = "#555" },
        },
        svg.Column {
            style = { gap = 6, background = "#fff", padding = 12, border_radius = 6 },
            children = {
                svg.Text { text = "项目 A", style = { font_size = 14, color = "#333" } },
                svg.Divider { color = "#ddd", thickness = 1 },
                svg.Text { text = "项目 B", style = { font_size = 14, color = "#333" } },
                svg.Divider { color = "#ddd", thickness = 1 },
                svg.Text { text = "项目 C", style = { font_size = 14, color = "#333" } },
            },
        },
        svg.Divider(),
        svg.Text {
            text = "ZStack（层叠布局）",
            style = { height = 24, font_size = 16, color = "#555" },
        },
        svg.ZStack {
            style = { width = 200, height = 80, align = "center" },
            children = {
                svg.Rect { style = { width = "100%", height = "100%", fill = "#e3f2fd", border_radius = 8 } },
                svg.Text { text = "层叠文本", style = { font_size = 18, color = "#1565c0", font_weight = "bold", text_align = "center" } },
            },
        },
        svg.Divider(),
        svg.Text {
            text = "Group / Image / Raw",
            style = { height = 24, font_size = 16, color = "#555" },
        },
        svg.Row {
            style = { gap = 12, height = 60, align = "center" },
            children = {
                svg.Box {
                    style = { width = 100, height = 60, background = "#e8e8e8", border_radius = 8, border = "#ccc", border_width = 1, align = "center" },
                    children = {
                        svg.Image {
                            href = "https://api.mmp.cc/api/pcwallpaper?category=cartoon&type=jpg",
                            style = { width = 100, height = 60, border_radius = 8, clip = true },
                        },
                    },
                },
                svg.Group {
                    style = { transform = "rotate(15, 152, 517)" },
                    children = {
                        svg.Rect { style = { width = 40, height = 40, fill = "#9b59b6", border_radius = 4 } },
                    },
                },
            },
        },
        svg.Text {
            text = "注：Raw 组件直接嵌入原始 SVG 代码，位置为全局坐标，不受布局影响（详见示例）",
            style = { font_size = 11, color = "#aaa", font_family = "sans-serif" },
        },
        -- Raw 独立演示：使用全局坐标，不受布局约束
        svg.Raw { svg = '<circle cx="620" cy="460" r="12" fill="#f1c40f" opacity="0.6"/><circle cx="640" cy="470" r="8" fill="#e67e22" opacity="0.6"/><circle cx="655" cy="460" r="6" fill="#e74c3c" opacity="0.6"/>' },
    },
}
save_output("2_containers.svg", svg.render_svg(doc2))

-- ============================================================================
-- 3. 视觉特效
-- ============================================================================
section("3. 视觉特效 — shadow / blur / opacity / transform(clip / rotate)")

local doc3 = svg.Box {
    style = {
        width = 760, height = 400, background = "#f0f4f8",
        padding = 30, direction = "column", gap = 20,
    },
    children = {
        svg.Text {
            text = "视觉特效演示",
            style = { height = 30, font_size = 22, font_weight = "bold", color = "#222", text_align = "center" },
        },
        svg.Box {
            style = { direction = "row", gap = 24, height = 140, align = "center", justify = "center" },
            children = {
                svg.Box {
                    style = { width = 120, height = 120, background = "#e74c3c", border_radius = 12,
                        shadow = { dx = 4, dy = 6, blur = 8, color = "#000", opacity = 0.35 } },
                    children = { svg.Text { text = "阴影", style = { height = 120, font_size = 16, color = "#fff", font_weight = "bold", text_align = "center" } } },
                },
                svg.Box {
                    style = { width = 120, height = 120, background = "#3498db", border_radius = 12, opacity = 0.7 },
                    children = { svg.Text { text = "透明度\n0.7", style = { height = 120, font_size = 16, color = "#fff", font_weight = "bold", text_align = "center" } } },
                },
                svg.Box {
                    style = { width = 120, height = 120, background = "#2ecc71", border_radius = 12, blur = 4 },
                    children = { svg.Text { text = "模糊\n4px", style = { height = 120, font_size = 16, color = "#fff", font_weight = "bold", text_align = "center" } } },
                },
            },
        },
        svg.Box {
            style = { direction = "row", gap = 24, height = 80, align = "center", justify = "center" },
            children = {
                svg.Box {
                    style = { width = 120, height = 60, background = "#9b59b6", border_radius = 8, transform = "rotate(-5, 236, 280)" },
                    children = { svg.Text { text = "旋转 -5°", style = { height = 60, font_size = 14, color = "#fff", text_align = "center" } } },
                },
                svg.Box {
                    style = { width = 120, height = 60, background = "#e67e22", border_radius = 8, clip = true },
                    children = {
                        svg.Circle { style = { width = 80, height = 80, fill = "#fff", opacity = 0.5 } },
                    },
                },
                svg.Box {
                    style = { width = 120, height = 60, background = "#1abc9c", border_radius = 8,
                        shadow = { dx = 0, dy = 0, blur = 6, color = "#1abc9c", opacity = 0.8 } },
                    children = { svg.Text { text = "发光阴影", style = { height = 60, font_size = 14, color = "#fff", text_align = "center" } } },
                },
            },
        },
    },
}
save_output("3_effects.svg", svg.render_svg(doc3))

-- ============================================================================
-- 4. 布局系统详解
-- ============================================================================
section("4. 布局系统 — justify / align / gap / flex / fill / 百分比 / margin")

local doc4 = svg.Box {
    style = {
        width = 760, height = 750, background = "#f8f9fa",
        padding = 20, direction = "column", gap = 16,
    },
    children = {
        svg.Text {
            text = "弹性布局详解放",
            style = { height = 30, font_size = 20, font_weight = "bold", color = "#222", text_align = "center" },
        },
        -- justify: start / center / end / space-between / space-around
        svg.Text { text = "justify 测试", style = { height = 20, font_size = 14, color = "#555" } },
        svg.Box {
            style = { direction = "row", justify = "start", gap = 4, background = "#fff", padding = 8, border_radius = 4, height = 40 },
            children = {
                svg.Rect { style = { width = 40, height = 24, fill = "#e74c3c", border_radius = 4 } },
                svg.Rect { style = { width = 40, height = 24, fill = "#3498db", border_radius = 4 } },
                svg.Rect { style = { width = 40, height = 24, fill = "#2ecc71", border_radius = 4 } },
            },
        },
        svg.Box {
            style = { direction = "row", justify = "center", gap = 4, background = "#fff", padding = 8, border_radius = 4, height = 40 },
            children = {
                svg.Rect { style = { width = 40, height = 24, fill = "#e74c3c", border_radius = 4 } },
                svg.Rect { style = { width = 40, height = 24, fill = "#3498db", border_radius = 4 } },
                svg.Rect { style = { width = 40, height = 24, fill = "#2ecc71", border_radius = 4 } },
            },
        },
        svg.Box {
            style = { direction = "row", justify = "space-between", background = "#fff", padding = 8, border_radius = 4, height = 40 },
            children = {
                svg.Rect { style = { width = 40, height = 24, fill = "#e74c3c", border_radius = 4 } },
                svg.Rect { style = { width = 40, height = 24, fill = "#3498db", border_radius = 4 } },
                svg.Rect { style = { width = 40, height = 24, fill = "#2ecc71", border_radius = 4 } },
            },
        },
        svg.Box {
            style = { direction = "row", justify = "space-around", background = "#fff", padding = 8, border_radius = 4, height = 40 },
            children = {
                svg.Rect { style = { width = 40, height = 24, fill = "#e74c3c", border_radius = 4 } },
                svg.Rect { style = { width = 40, height = 24, fill = "#3498db", border_radius = 4 } },
                svg.Rect { style = { width = 40, height = 24, fill = "#2ecc71", border_radius = 4 } },
            },
        },
        -- align: start / center / end / stretch
        svg.Text { text = "align 测试", style = { height = 20, font_size = 14, color = "#555" } },
        svg.Box {
            style = { direction = "row", align = "center", gap = 8, background = "#fff", padding = 8, border_radius = 4, height = 60 },
            children = {
                svg.Rect { style = { width = 40, height = 20, fill = "#e74c3c", border_radius = 4 } },
                svg.Rect { style = { width = 40, height = 40, fill = "#3498db", border_radius = 4 } },
                svg.Rect { style = { width = 40, height = 30, fill = "#2ecc71", border_radius = 4 } },
            },
        },
        svg.Box {
            style = { direction = "row", align = "end", gap = 8, background = "#fff", padding = 8, border_radius = 4, height = 60 },
            children = {
                svg.Rect { style = { width = 40, height = 20, fill = "#e74c3c", border_radius = 4 } },
                svg.Rect { style = { width = 40, height = 40, fill = "#3498db", border_radius = 4 } },
                svg.Rect { style = { width = 40, height = 30, fill = "#2ecc71", border_radius = 4 } },
            },
        },
        -- flex 权重
        svg.Text { text = "flex 权重", style = { height = 20, font_size = 14, color = "#555" } },
        svg.Box {
            style = { direction = "row", gap = 4, background = "#fff", padding = 8, border_radius = 4, height = 40 },
            children = {
                svg.Box { style = { flex = 1, height = 24, background = "#e74c3c", border_radius = 4 } },
                svg.Box { style = { flex = 2, height = 24, background = "#3498db", border_radius = 4 } },
                svg.Box { style = { flex = 1, height = 24, background = "#2ecc71", border_radius = 4 } },
            },
        },
        -- fill / 百分比
        svg.Text { text = "fill / 百分比", style = { height = 20, font_size = 14, color = "#555" } },
        svg.Box {
            style = { direction = "row", gap = 8, background = "#e8e8e8", padding = 8, border_radius = 4, height = 40 },
            children = {
                svg.Rect { style = { width = "30%", height = 24, fill = "#9b59b6", border_radius = 4 } },
                svg.Rect { style = { width = "fill", height = 24, fill = "#e67e22", border_radius = 4 } },
            },
        },
    },
}
save_output("4_layout.svg", svg.render_svg(doc4))

-- ============================================================================
-- 5. 样式链式 API（Style Modifier）
-- ============================================================================
section("5. 样式链式 API — svg.Style()")

local doc5 = svg.Box {
    style = svg.Style()
        :width(760)
        :height(260)
        :background("#f8f9fa")
        :padding(20)
        :direction("column")
        :gap(16),
    children = {
        svg.Text {
            text = "链式 Style API 演示",
            style = svg.Style():height(30):font_size(20):font_weight("bold"):color("#222"):text_align("center"),
        },
        svg.Box {
            style = svg.Style():direction("row"):gap(12):height(80):align("center"),
            children = {
                svg.Box {
                    style = svg.Style():width(120):height(60):background("#e74c3c"):border_radius(8)
                        :shadow({ dx = 2, dy = 3, blur = 4, color = "#000", opacity = 0.3 }),
                    children = {
                        svg.Text { text = "链式样式", style = svg.Style():height(60):font_size(14):color("#fff"):text_align("center") },
                    },
                },
                svg.Rect {
                    style = svg.Style():width(120):height(60):fill("#3498db"):border_radius(4):stroke("#2c3e50"):stroke_width(2),
                },
            },
        },
        svg.Text {
            text = "使用 merge() 合并样式",
            style = svg.Style():font_size(14):color("#666"):text_align("center")
                :merge({ background = "#fff", padding = 8, border_radius = 4 }),
        },
    },
}
save_output("5_style_api.svg", svg.render_svg(doc5))

-- ============================================================================
-- 6. 渐变与图案
-- ============================================================================
section("6. 渐变与图案 — LinearGradient / RadialGradient / Pattern")

local grad1 = svg.LinearGradient {
    x1 = "0%", y1 = "0%", x2 = "100%", y2 = "100%",
    stops = { { offset = 0, color = "#667eea" }, { offset = 1, color = "#764ba2" } },
}
local grad2 = svg.RadialGradient {
    cx = "50%", cy = "50%", r = "50%",
    stops = { { offset = 0, color = "#f7971e" }, { offset = 1, color = "#ffd200" } },
}
local pattern = svg.Pattern {
    width = 20, height = 20,
    content = '<circle cx="10" cy="10" r="3" fill="#3498db" opacity="0.3"/>',
}

local doc6 = svg.Box {
    style = {
        width = 760, height = 300, background = "#f8f9fa",
        padding = 20, direction = "column", gap = 16,
    },
    children = {
        svg.Text {
            text = "渐变与图案演示",
            style = svg.Style():height(30):font_size(20):font_weight("bold"):color("#222"):text_align("center"),
        },
        svg.Box {
            style = svg.Style():direction("row"):gap(16):height(200):align("center"),
            children = {
                svg.Box {
                    style = svg.Style():width(200):height(160):background(grad1):border_radius(12),
                    children = {
                        svg.Text { text = "线性渐变", style = svg.Style():height(160):font_size(18):color("#fff"):font_weight("bold"):text_align("center") },
                    },
                },
                svg.Box {
                    style = svg.Style():width(200):height(160):background(grad2):border_radius(12),
                    children = {
                        svg.Text { text = "径向渐变", style = svg.Style():height(160):font_size(18):color("#fff"):font_weight("bold"):text_align("center") },
                    },
                },
                svg.Box {
                    style = svg.Style():width(200):height(160):background(pattern):border("#3498db"):border_width(1):border_radius(12),
                    children = {
                        svg.Text { text = "图案填充", style = svg.Style():height(160):font_size(18):color("#333"):font_weight("bold"):text_align("center") },
                    },
                },
            },
        },
    },
}
save_output("6_gradients.svg", svg.render_svg(doc6))

-- ============================================================================
-- 7. Builder 动态组件 + 自定义组件
-- ============================================================================
section("7. Builder 动态内容 + 自定义组件")

local Badge = svg.define(function(props)
    return svg.Box {
        style = {
            background = props.color or "#3498db",
            border_radius = 12,
            padding = { 4, 10, 4, 10 },
        },
        children = {
            svg.Text {
                text = props.text or "徽章",
                style = { font_size = 12, color = "#fff", text_align = "center" },
            },
        },
    }
end)

svg.register("WarningBadge", function(props)
    return svg.Box {
        style = {
            background = props.outline and "#fff" or "#f39c12",
            border = props.outline and "#f39c12" or nil,
            border_width = props.outline and 2 or nil,
            border_radius = 4,
            padding = { 6, 14, 6, 14 },
        },
        children = {
            svg.Text {
                text = props.text or "⚠ 警告",
                style = { font_size = 14, color = props.outline and "#f39c12" or "#fff", font_weight = "bold", text_align = "center" },
            },
        },
    }
end)

local doc7 = svg.Box {
    style = svg.Style():width(760):height(320):background("#f8f9fa"):padding(20):direction("column"):gap(16),
    children = {
        svg.Text {
            text = "Builder + 自定义组件演示",
            style = svg.Style():height(30):font_size(20):font_weight("bold"):color("#222"):text_align("center"),
        },
        svg.Box {
            style = svg.Style():direction("row"):gap(12):height(40):align("center"),
            children = {
                Badge { text = "新功能", color = "#e74c3c" },
                Badge { text = "推荐", color = "#2ecc71" },
                Badge { text = "热门", color = "#3498db" },
                svg.WarningBadge { text = "!! 重要提示" },
                svg.WarningBadge { text = "外部链接", outline = true },
            },
        },
        svg.Builder {
            style = svg.Style():direction("column"):fillMaxSize():gap(6):background("#eee"):padding(12):border_radius(6),
            build = function(ctx)
                local items = {}
                for i = 1, 5 do
                    items[#items + 1] = svg.Box {
                        style = svg.Style():direction("row"):gap(8):height(28):align("center"),
                        children = {
                            svg.Circle { style = svg.Style():width(10):height(10):fill("#3498db") },
                            svg.Text { text = "动态项目 #" .. i .. "（宽度: " .. math.floor(ctx.width) .. "px）", style = { font_size = 13, color = "#444" } },
                        },
                    }
                end
                return items
            end,
        },
    },
}
save_output("7_builder.svg", svg.render_svg(doc7))

-- ============================================================================
-- 8. 文本系统全覆盖
-- ============================================================================
section("8. 文本系统 — 字体 / 对齐 / CJK / 行高 / TextBlock 分页")

local doc8 = svg.Box {
    style = svg.Style():width(760):height(580):background("#f8f9fa"):padding(20):direction("column"):gap(14),
    children = {
        svg.Text {
            text = "文本系统全覆盖演示",
            style = svg.Style():height(30):font_size(20):font_weight("bold"):color("#222"):text_align("center"),
        },
        svg.Text { text = "左对齐文本（默认）", style = svg.Style():font_size(15):color("#333") },
        svg.Text { text = "居中对齐文本", style = svg.Style():font_size(15):color("#333"):text_align("center") },
        svg.Text { text = "右对齐文本", style = svg.Style():font_size(15):color("#333"):text_align("right") },
        svg.Text { text = "粗体 + 大字", style = svg.Style():font_size(22):font_weight("bold"):color("#e74c3c") },
        svg.Text { text = "Custom Font", style = svg.Style():font_size(16):font_family("Georgia, serif"):color("#3498db") },
        svg.Divider(),
        svg.Text {
            text = "多行文本（TextBlock）：",
            style = svg.Style():font_size(14):font_weight("bold"):color("#555"),
        },
        svg.TextBlock {
            text = "这是一段包含中文、English、数字 12345 和混合标点符号的文本，用于测试 TextBlock 的自动换行能力。SVG Layout 库使用 UTF-8 感知算法，能够正确处理 CJK 字符的逐字换行和英文单词的按空格换行。line_height 参数控制行间距。",
            style = svg.Style():font_size(14):color("#444"):line_height(1.6):background("#fff"):padding(12):border_radius(6),
        },
        svg.TextBlock {
            text = "CJK 文本演示：日本語の文章も正しく表示されます。한국어도 문제없이 렌더링됩니다。中文英文混合 long long long long text 测试。",
            style = svg.Style():font_size(13):color("#555"):line_height(1.5):background("#e8f5e9"):padding(10):border_radius(6),
        },
    },
}
save_output("8_text.svg", svg.render_svg(doc8))

-- ============================================================================
-- 9. 分页系统
-- ============================================================================
section("9. 分页系统 — render_pages / paginate_nodes")

local items = {}
for i = 1, 30 do
    items[#items + 1] = svg.Row {
        style = svg.Style():gap(10):height(28):align("center"):background(i % 2 == 0 and "#f0f0f0" or "#fff"):padding({ 0, 8 }),
        children = {
            svg.Text { text = string.format("第 %02d 项", i), style = { font_size = 13, color = "#333", width = 60 } },
            svg.Text { text = "这是一段描述文本用于填充列表内容", style = { font_size = 13, color = "#888" } },
        },
    }
end

local doc9 = svg.Column {
    style = svg.Style():fillMaxSize():gap(4):padding(16):background("#f8f9fa"),
    children = {
        svg.Text { text = "分页系统演示", style = svg.Style():fillMaxWidth():font_size(20):font_weight("bold"):color("#222") },
        svg.Divider {},
        svg.Column {
            style = svg.Style():fillMaxSize():gap(4):padding(16):background("#fff"),
            children = items,
        },
    },
}

local pages_svg = perf("分页渲染 (30 项, A4 尺寸)", function()
    return svg.render_pages(doc9, { width = 500, height = 400 })
end)

for i, page_svg in ipairs(pages_svg) do
    save_output(string.format("9_page_%d.svg", i), page_svg)
end
print(string.format("  共 %d 页", #pages_svg))

local nodes = svg.paginate_nodes(doc9, { width = 500, height = 400 })
print(string.format("  paginate_nodes 返回 %d 个节点", #nodes))

-- 9.2 PageCallback 页码组件演示
print("")
print("--- 9.2 PageCallback 页码组件 ---")

local page_items = {}
for i = 1, 20 do
    page_items[#page_items + 1] = svg.Row {
        style = svg.Style():gap(10):height(26):align("center"):background(i % 2 == 0 and "#f5f5f5" or "#fff"):padding({ 0, 10 }),
        children = {
            svg.Text { text = string.format("数据行 %02d", i), style = { font_size = 12, color = "#333", width = 80 } },
            svg.Text { text = "这是一些示例数据", style = { font_size = 12, color = "#888" } },
        },
    }
end

local doc9_page_callback = svg.Column {
    style = svg.Style():fillMaxSize():gap(4):padding(16):background("#f0f4f8"),
    children = {
        svg.Text { text = "PageCallback 演示", style = svg.Style():fillMaxWidth():font_size(18):font_weight("bold"):color("#333"):text_align("center") },
        svg.Divider {},
        svg.Column {
            style = svg.Style():fillMaxSize():gap(2):padding(12):background("#fff"):border_radius(6),
            children = page_items,
        },
        svg.Divider {},
        svg.PageCallback {
            style = svg.Style():height(32):direction("row"):align("center"):justify("center"):gap(8),
            build = function(page, total)
                return {
                    svg.Text { text = "第", style = { font_size = 12, color = "#888" } },
                    svg.Text { text = tostring(page), style = { font_size = 14, color = "#3498db", font_weight = "bold" } },
                    svg.Text { text = "/", style = { font_size = 12, color = "#ccc" } },
                    svg.Text { text = tostring(total), style = { font_size = 14, color = "#333", font_weight = "bold" } },
                    svg.Text { text = "页", style = { font_size = 12, color = "#888" } },
                }
            end,
        },
    },
}

local page_cb_pages = perf("PageCallback 分页渲染 (20 项)", function()
    return svg.render_pages(doc9_page_callback, { width = 450, height = 350 })
end)
for i, page_svg in ipairs(page_cb_pages) do
    save_output(string.format("9_page_cb_%d.svg", i), page_svg)
end
print(string.format("  共 %d 页", #page_cb_pages))

-- ============================================================================
-- 10. 综合复杂场景
-- ============================================================================
section("10. 综合复杂场景 — 表单卡片 + 数据面板")

local form_grad = svg.LinearGradient {
    x1 = "0%", y1 = "0%", x2 = "100%", y2 = "100%",
    stops = { { offset = 0, color = "#667eea" }, { offset = 1, color = "#764ba2" } },
}

local doc10 = svg.Box {
    style = svg.Style():width(760):height(680):background("#eef1f5"):padding(24):direction("column"):gap(20),
    children = {
        -- 标题区域
        svg.Box {
            style = svg.Style():direction("row"):height(60):align("center"):gap(16):padding({ 0, 16 }),
            children = {
                svg.Rect { style = svg.Style():width(8):height(40):fill(form_grad):border_radius(4) },
                svg.Box {
                    style = svg.Style():direction("column"):gap(4),
                    children = {
                        svg.Text { text = "用户数据面板", style = svg.Style():font_size(22):font_weight("bold"):color("#222") },
                        svg.Text { text = "综合演示 — 表单/卡片/数据展示", style = svg.Style():font_size(13):color("#888") },
                    },
                },
                svg.Spacer(),
                Badge { text = "已认证", color = "#2ecc71" },
            },
        },
        -- 统计卡片行
        svg.Box {
            style = svg.Style():direction("row"):gap(16):height(100),
            children = {
                svg.Box {
                    style = svg.Style():flex(1):background("#fff"):border_radius(10):padding(16):direction("column"):gap(6)
                        :shadow({ dx = 0, dy = 2, blur = 6, color = "#000", opacity = 0.08 }),
                    children = {
                        svg.Text { text = "总收入", style = svg.Style():font_size(13):color("#888") },
                        svg.Text { text = "$12,580", style = svg.Style():font_size(26):font_weight("bold"):color("#2ecc71") },
                        svg.Text { text = "较上月增长 8.2%", style = svg.Style():font_size(12):color("#2ecc71") },
                    },
                },
                svg.Box {
                    style = svg.Style():flex(1):background("#fff"):border_radius(10):padding(16):direction("column"):gap(6)
                        :shadow({ dx = 0, dy = 2, blur = 6, color = "#000", opacity = 0.08 }),
                    children = {
                        svg.Text { text = "活跃用户", style = svg.Style():font_size(13):color("#888") },
                        svg.Text { text = "3,421", style = svg.Style():font_size(26):font_weight("bold"):color("#3498db") },
                        svg.Text { text = "较上月增长 5.7%", style = svg.Style():font_size(12):color("#3498db") },
                    },
                },
                svg.Box {
                    style = svg.Style():flex(1):background("#fff"):border_radius(10):padding(16):direction("column"):gap(6)
                        :shadow({ dx = 0, dy = 2, blur = 6, color = "#000", opacity = 0.08 }),
                    children = {
                        svg.Text { text = "订单数", style = svg.Style():font_size(13):color("#888") },
                        svg.Text { text = "856", style = svg.Style():font_size(26):font_weight("bold"):color("#e67e22") },
                        svg.Text { text = "较上月增长 12.3%", style = svg.Style():font_size(12):color("#e67e22") },
                    },
                },
            },
        },
        -- 表单区域
        svg.Box {
            style = svg.Style():direction("row"):gap(16):flex(1),
            children = {
                svg.Box {
                    style = svg.Style():flex(1):background("#fff"):border_radius(10):padding(20):direction("column"):gap(14)
                        :shadow({ dx = 0, dy = 1, blur = 4, color = "#000", opacity = 0.06 }),
                    children = {
                        svg.Text { text = "编辑信息", style = svg.Style():font_size(16):font_weight("bold"):color("#333") },
                        svg.Box {
                            style = svg.Style():direction("column"):gap(4),
                            children = {
                                svg.Text { text = "姓名", style = svg.Style():font_size(13):color("#666") },
                                svg.Rect { style = svg.Style():width("fill"):height(36):fill("#f5f6fa"):border_radius(6):stroke("#ddd"):stroke_width(1) },
                            },
                        },
                        svg.Box {
                            style = svg.Style():direction("column"):gap(4),
                            children = {
                                svg.Text { text = "邮箱", style = svg.Style():font_size(13):color("#666") },
                                svg.Rect { style = svg.Style():width("fill"):height(36):fill("#f5f6fa"):border_radius(6):stroke("#ddd"):stroke_width(1) },
                            },
                        },
                        svg.Box {
                            style = svg.Style():direction("row"):gap(8):height(36):align("center"),
                            children = {
                                svg.Rect { style = svg.Style():flex(1):height(36):fill("#667eea"):border_radius(6) },
                                svg.Rect { style = svg.Style():flex(1):height(36):fill("#e8e8e8"):border_radius(6) },
                            },
                        },
                    },
                },
                svg.Box {
                    style = svg.Style():flex(1):background("#fff"):border_radius(10):padding(20):direction("column"):gap(10)
                        :shadow({ dx = 0, dy = 1, blur = 4, color = "#000", opacity = 0.06 }),
                    children = {
                        svg.Text { text = "最近活动", style = svg.Style():font_size(16):font_weight("bold"):color("#333") },
                        svg.Builder {
                            style = svg.Style():direction("column"):gap(8),
                            build = function()
                                local activities = {
                                    { icon = "#e74c3c", text = "张三 提交了新订单", time = "2 分钟前" },
                                    { icon = "#3498db", text = "李四 更新了个人资料", time = "15 分钟前" },
                                    { icon = "#2ecc71", text = "王五 完成了注册", time = "1 小时前" },
                                    { icon = "#f39c12", text = "赵六 发起了退款申请", time = "3 小时前" },
                                }
                                local items = {}
                                for _, act in ipairs(activities) do
                                    items[#items + 1] = svg.Box {
                                        style = svg.Style():direction("row"):gap(10):height(36):align("center"),
                                        children = {
                                            svg.Circle { style = svg.Style():width(8):height(8):fill(act.icon) },
                                            svg.Text { text = act.text, style = svg.Style():font_size(13):color("#444"):flex(1) },
                                            svg.Text { text = act.time, style = svg.Style():font_size(11):color("#aaa") },
                                        },
                                    }
                                end
                                return items
                            end,
                        },
                    },
                },
            },
        },
    },
}
save_output("10_dashboard.svg", svg.render_svg(doc10))

-- ============================================================================
-- 11. 性能测试
-- ============================================================================
section("11. 性能测试")

-- 11.1 简单渲染性能
print("")
print("--- 11.1 简单渲染（单次） ---")
local simple_doc = svg.Box {
    style = svg.Style():width(800):height(60):direction("row"):gap(8):padding(10):background("#f8f9fa"),
    children = {
        svg.Text { text = "Hello", style = svg.Style():font_size(16):color("#333") },
        svg.Spacer(),
        svg.Rect { style = svg.Style():width(80):height(40):fill("#3498db"):border_radius(6) },
    },
}
perf("render_svg (简单)", function()
    return svg.render_svg(simple_doc)
end)

-- 11.2 大量组件渲染
print("")
print("--- 11.2 大量组件（1000 Box × 3 子组件 = 3000 节点） ---")
local many_items = {}
for i = 1, 1000 do
    many_items[#many_items + 1] = svg.Box {
        style = svg.Style():direction("row"):gap(6):height(20):align("center"),
        children = {
            svg.Rect { style = svg.Style():width(10):height(10):fill("#e74c3c"):border_radius(2) },
            svg.Text { text = "Item " .. i, style = svg.Style():font_size(11):color("#555") },
        },
    }
end
local big_doc = svg.Box {
    style = svg.Style():direction("column"):gap(2):padding(10):background("#fff"),
    children = many_items,
}
perf("render_svg (1000 项)", function()
    return svg.render_svg(big_doc, { width = 400 })
end)

-- 11.3 分页渲染性能
print("")
print("--- 11.3 分页渲染（1000 项, A4 纸） ---")
perf("render_pages (1000 项)", function()
    return svg.render_pages(big_doc, { width = 500, height = 700 })
end)

-- 11.4 文本测量性能
print("")
print("--- 11.4 文本测量 ---")
local long_cjk = ""
for i = 1, 500 do
    long_cjk = long_cjk .. "这是一段用于测试文本测量性能的长文本内容。"
end
perf("text_width (500 句 CJK)", function()
    local measure = require("svglayout.text_measure")
    return measure.text_width(long_cjk, 14)
end)

perf("wrap (500 句 CJK)", function()
    local measure = require("svglayout.text_measure")
    return measure.wrap(long_cjk, 500, 14)
end)

-- 11.5 渐变 + 视觉特效性能
print("")
print("--- 11.5 渐变 + 视觉特效（200 个带阴影的卡片） ---")
local g = svg.LinearGradient {
    x1 = "0%", y1 = "0%", x2 = "100%", y2 = "100%",
    stops = { { offset = 0, color = "#667eea" }, { offset = 1, color = "#764ba2" } },
}
local card_items = {}
for i = 1, 200 do
    card_items[#card_items + 1] = svg.Box {
        style = svg.Style():width(60):height(60):background(g):border_radius(8)
            :shadow({ dx = 2, dy = 3, blur = 4, color = "#000", opacity = 0.25 }),
    }
end
local card_col = svg.Box {
    style = svg.Style():direction("column"):gap(4):padding(10):background("#f0f0f0"),
    children = card_items,
}
perf("render_svg (200 卡片 + 渐变 + 阴影)", function()
    return svg.render_svg(card_col, { width = 800 })
end)

-- 11.6 ZStack + 复合效果
print("")
print("--- 11.6 ZStack + 复合效果 ---")
local zstack_items = {}
for i = 1, 100 do
    zstack_items[#zstack_items + 1] = svg.Box {
        style = svg.Style():width(60):height(60):background("#3498db"):border_radius(8):opacity(0.3 + (i / 100) * 0.5)
            :transform(string.format("rotate(%d)", i * 5)),
    }
end
local zstack_doc = svg.ZStack {
    style = svg.Style():width(400):height(400):background("#f8f9fa"):padding(20),
    children = zstack_items,
}
perf("render_svg (100 ZStack + rotate)", function()
    return svg.render_svg(zstack_doc)
end)

-- 11.7 Builder 动态渲染性能
print("")
print("--- 11.7 Builder 动态渲染 ---")
local builder_doc = svg.Builder {
    style = svg.Style():direction("column"):gap(2):padding(10):background("#fff"),
    build = function(ctx)
        local items = {}
        for i = 1, 500 do
            items[#items + 1] = svg.Text {
                text = "Builder 动态行 #" .. i,
                style = svg.Style():font_size(12):color("#444"):height(18),
            }
        end
        return items
    end,
}
perf("render_svg (Builder 500 行)", function()
    return svg.render_svg(builder_doc, { width = 500 })
end)

-- 11.8 综合渲染（包含全部功能）
print("")
print("--- 11.8 综合渲染（多页仪表盘） ---")
local all_pages = 0
perf("render_pages (综合复杂页面)", function()
    local r = svg.render_pages(doc10, { width = 760, height = 500 })
    all_pages = #r
    return r
end)
print(string.format("  共 %d 页", all_pages))


print("")
print("所有示例已完成！")
print("输出文件位于 output/ 目录：")
local handle = io.popen("dir ..\\output\\*.svg /b 2>nul")
if handle then
    for fname in handle:lines() do
        print("  - " .. fname)
    end
    handle:close()
else
    -- fallback for non-Windows
    local handle2 = io.popen("ls ./output/*.svg 2>/dev/null")
    if handle2 then
        for fname in handle2:lines() do
            print("  - " .. fname)
        end
        handle2:close()
    end
end
