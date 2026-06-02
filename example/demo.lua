package.path = package.path .. ";../?.lua;../?/init.lua;./?/init.lua"
local svg = require("svglayout")

-- 确定输出目录
local output_dir = arg and arg[0] and arg[0]:match("^(.*[\\/])") or "./"
output_dir = output_dir .. "../output/"

-- 保存 SVG 文件到输出目录
local function save(filename, content)
    local path = output_dir .. filename
    local f = io.open(path, "w")
    if f then
        f:write(content)
        f:close()
        print(string.format("  [OK] %s", filename))
    else
        print(string.format("  [ERR] cannot write %s", path))
    end
end

local function step(num, title)
    print("")
    print(string.format("=== Step %d: %s ===", num, title))
end

-- ============================================================
-- Step 1: 基础 Hello World
-- 最简单的 Box + Text 组合，展示基本用法
-- ============================================================
step(1, "Hello World")

local doc1 = svg.Box {
    style = { width = 400, height = 200, background = "#f0f4ff" },
    children = {
        svg.Text {
            text = "Hello, SVG Layout!",
            style = { height = 200, font_size = 28, color = "#333", font_weight = "bold", text_align = "center" },
        },
    },
}
save("01_hello_world.svg", svg.render_svg(doc1))

-- ============================================================
-- Step 2: 基础样式
-- 展示背景色、内边距、圆角和字体样式
-- ============================================================
step(2, "Styling Basics — background, padding, border_radius, font")

local doc2 = svg.Box {
    style = {
        width = 500, background = "#e8ecf1",
        padding = 24, direction = "column", gap = 12,
    },
    children = {
        svg.Text {
            text = "Styled Card",
            style = { height = 32, font_size = 22, font_weight = "bold", color = "#1a1a2e", text_align = "center" },
        },
        svg.Box {
            style = { background = "#fff", padding = 16, border_radius = 10, direction = "column", gap = 8 },
            children = {
                svg.Text { text = "This card has a white background, rounded corners, and inner padding.", style = { font_size = 14, color = "#555" } },
                svg.Text { text = "The outer container has a gray background with 24px padding.", style = { font_size = 14, color = "#777" } },
            },
        },
        svg.Text {
            text = "Text with different font sizes and colors",
            style = { font_size = 12, color = "#999", text_align = "center" },
        },
    },
}
save("02_styling_basics.svg", svg.render_svg(doc2))

-- ============================================================
-- Step 3: 布局方向 — Row & Column
-- 展示水平布局（Row）和垂直布局（Column）的区别
-- ============================================================
step(3, "Layout Directions — Row & Column")

local doc3 = svg.Box {
    style = { width = 500, background = "#f5f5f5", padding = 20, direction = "column", gap = 20 },
    children = {
        svg.Text { text = "Row: children arranged horizontally", style = { font_size = 14, color = "#555" } },
        svg.Box {
            style = { direction = "row", gap = 10, background = "#fff", padding = 12, border_radius = 6 },
            children = {
                svg.Box { style = { width = 60, height = 40, background = "#e74c3c", border_radius = 4 } },
                svg.Box { style = { width = 60, height = 40, background = "#3498db", border_radius = 4 } },
                svg.Box { style = { width = 60, height = 40, background = "#2ecc71", border_radius = 4 } },
                svg.Box { style = { width = 60, height = 40, background = "#f39c12", border_radius = 4 } },
            },
        },
        svg.Text { text = "Column: children arranged vertically", style = { font_size = 14, color = "#555" } },
        svg.Box {
            style = { direction = "column", gap = 6, background = "#fff", padding = 12, border_radius = 6 },
            children = {
                svg.Box { style = { width = "fill", height = 24, background = "#9b59b6", border_radius = 4 } },
                svg.Box { style = { width = "fill", height = 24, background = "#e67e22", border_radius = 4 } },
                svg.Box { style = { width = "fill", height = 24, background = "#1abc9c", border_radius = 4 } },
            },
        },
    },
}
save("03_row_column.svg", svg.render_svg(doc3))

-- ============================================================
-- Step 4: Spacer & 对齐
-- 展示 Spacer 弹性空白和 justify/align 对齐模式
-- ============================================================
step(4, "Spacer & Alignment — justify, align")

local doc4 = svg.Box {
    style = { width = 550, background = "#f5f5f5", padding = 20, direction = "column", gap = 16 },
    children = {
        svg.Text { text = "Spacer pushes elements apart", style = { font_size = 14, color = "#555" } },
        -- Spacer 在 Row 中分隔三个文本块：左-中-右
        svg.Box {
            style = { direction = "row", gap = 6, background = "#fff", padding = 8, border_radius = 6, height = 50, align = "center" },
            children = {
                svg.Text { text = "Left", style = { font_size = 14, color = "#fff", background = "#e74c3c", padding = { 6, 12 }, border_radius = 4 } },
                svg.Spacer(),
                svg.Text { text = "Center", style = { font_size = 14, color = "#fff", background = "#3498db", padding = { 6, 12 }, border_radius = 4 } },
                svg.Spacer(),
                svg.Text { text = "Right", style = { font_size = 14, color = "#fff", background = "#2ecc71", padding = { 6, 12 }, border_radius = 4 } },
            },
        },
        svg.Text { text = "justify: start / center / end / space-between", style = { font_size = 14, color = "#555" } },
        -- justify=start：靠左排列
        svg.Box {
            style = { direction = "row", justify = "start", gap = 4, background = "#fff", padding = 8, border_radius = 4, height = 30 },
            children = {
                svg.Box { style = { width = 30, height = 14, background = "#e74c3c", border_radius = 2 } },
                svg.Box { style = { width = 30, height = 14, background = "#3498db", border_radius = 2 } },
                svg.Box { style = { width = 30, height = 14, background = "#2ecc71", border_radius = 2 } },
            },
        },
        -- justify=center：居中排列
        svg.Box {
            style = { direction = "row", justify = "center", gap = 4, background = "#fff", padding = 8, border_radius = 4, height = 30 },
            children = {
                svg.Box { style = { width = 30, height = 14, background = "#e74c3c", border_radius = 2 } },
                svg.Box { style = { width = 30, height = 14, background = "#3498db", border_radius = 2 } },
                svg.Box { style = { width = 30, height = 14, background = "#2ecc71", border_radius = 2 } },
            },
        },
        -- justify=space-between：两端对齐，中间等距
        svg.Box {
            style = { direction = "row", justify = "space-between", background = "#fff", padding = 8, border_radius = 4, height = 30 },
            children = {
                svg.Box { style = { width = 30, height = 14, background = "#e74c3c", border_radius = 2 } },
                svg.Box { style = { width = 30, height = 14, background = "#3498db", border_radius = 2 } },
                svg.Box { style = { width = 30, height = 14, background = "#2ecc71", border_radius = 2 } },
            },
        },
    },
}
save("04_spacer_alignment.svg", svg.render_svg(doc4))

-- ============================================================
-- Step 5: Flex & Fill — 弹性权重和填充模式
-- 展示 flex 权重分配、fill 充满、百分比宽度和 margin 间距
-- ============================================================
step(5, "Flex & Fill — proportional sizing")

local doc5 = svg.Box {
    style = { width = 550, background = "#f5f5f5", padding = 20, direction = "column", gap = 16 },
    children = {
        svg.Text { text = "flex weights: 1 : 2 : 1", style = { font_size = 14, color = "#555" } },
        -- flex=1 : flex=2 : flex=1，剩余空间按 1:2:1 分配
        svg.Box {
            style = { direction = "row", gap = 4, background = "#fff", padding = 8, border_radius = 6, height = 40 },
            children = {
                svg.Box { style = { flex = 1, height = 24, background = "#e74c3c", border_radius = 4 } },
                svg.Box { style = { flex = 2, height = 24, background = "#3498db", border_radius = 4 } },
                svg.Box { style = { flex = 1, height = 24, background = "#2ecc71", border_radius = 4 } },
            },
        },
        svg.Text { text = "fill width / percentage width", style = { font_size = 14, color = "#555" } },
        -- fill 填满，60% 和 30% 按比例
        svg.Box {
            style = { direction = "column", gap = 6, background = "#fff", padding = 8, border_radius = 6 },
            children = {
                svg.Box { style = { width = "fill", height = 24, background = "#9b59b6", border_radius = 4 } },
                svg.Box { style = { width = "60%", height = 24, background = "#e67e22", border_radius = 4 } },
                svg.Box { style = { width = "30%", height = 24, background = "#1abc9c", border_radius = 4 } },
            },
        },
        svg.Text { text = "margin spacing between elements", style = { font_size = 14, color = "#555" } },
        -- margin 控制元素间的间距偏移
        svg.Box {
            style = { direction = "row", gap = 6, background = "#fff", padding = 8, border_radius = 6, height = 50, align = "center" },
            children = {
                svg.Box { style = { width = 60, height = 30, background = "#e74c3c", border_radius = 4, margin = { 0, 8, 0, 0 } } },
                svg.Box { style = { width = 60, height = 30, background = "#3498db", border_radius = 4, margin = { 0, 8, 0, 0 } } },
                svg.Box { style = { width = 60, height = 30, background = "#2ecc71", border_radius = 4 } },
            },
        },
    },
}
save("05_flex_fill.svg", svg.render_svg(doc5))

-- ============================================================
-- Step 6: 形状组件
-- Rect、Circle、Line、Path 四种基本 SVG 形状
-- ============================================================
step(6, "Shapes — Rect, Circle, Line, Path")

local doc6 = svg.Box {
    style = { width = 550, background = "#f5f5f5", padding = 20, direction = "column", gap = 16 },
    children = {
        svg.Text { text = "Basic Shapes", style = { font_size = 18, font_weight = "bold", color = "#333", text_align = "center" } },
        svg.Box {
            style = { direction = "row", gap = 16, height = 120, align = "center", justify = "center" },
            children = {
                svg.Box {
                    style = { direction = "column", gap = 4, align = "center" },
                    children = {
                        svg.Text { text = "Rect", style = { font_size = 12, color = "#888" } },
                        svg.Rect { style = { width = 80, height = 60, fill = "#e74c3c", border_radius = 8 } },
                    },
                },
                svg.Box {
                    style = { direction = "column", gap = 4, align = "center" },
                    children = {
                        svg.Text { text = "Circle", style = { font_size = 12, color = "#888" } },
                        svg.Circle { style = { width = 60, height = 60, fill = "#3498db" } },
                    },
                },
                svg.Box {
                    style = { direction = "column", gap = 4, align = "center" },
                    children = {
                        svg.Text { text = "Line", style = { font_size = 12, color = "#888" } },
                        svg.Line { style = { width = 80, height = 60, stroke = "#2ecc71", stroke_width = 3 } },
                    },
                },
                svg.Box {
                    style = { direction = "column", gap = 4, align = "center" },
                    children = {
                        svg.Text { text = "Path", style = { font_size = 12, color = "#888" } },
                        svg.Path { d = "M10 50 Q30 0 50 50 Q70 0 90 50", style = { fill = "none", stroke = "#9b59b6", stroke_width = 2 } },
                    },
                },
            },
        },
        -- 带描边和圆角的矩形
        svg.Text { text = "Rect with stroke and border_radius", style = { font_size = 14, color = "#555" } },
        svg.Box {
            style = { direction = "row", gap = 12, height = 50, align = "center" },
            children = {
                svg.Rect { style = { width = 80, height = 36, fill = "#f39c12", stroke = "#e67e22", stroke_width = 2, border_radius = 18 } },
                svg.Rect { style = { width = 80, height = 36, fill = "#1abc9c", stroke = "#16a085", stroke_width = 2, border_radius = 4 } },
                svg.Rect { style = { width = 80, height = 36, fill = "none", stroke = "#e74c3c", stroke_width = 2, border_radius = 4 } },
            },
        },
    },
}
save("06_shapes.svg", svg.render_svg(doc6))

-- ============================================================
-- Step 7: 文本系统
-- TextBlock 多行文本、对齐方式、CJK 混合文本换行
-- ============================================================
step(7, "Text System — TextBlock, alignment, CJK, line_height")

local doc7 = svg.Box {
    style = { width = 550, background = "#f5f5f5", padding = 20, direction = "column", gap = 12 },
    children = {
        svg.Text { text = "Text Alignment", style = { font_size = 18, font_weight = "bold", color = "#333", text_align = "center" } },
        -- 三种对齐方式
        svg.Text { text = "Left aligned (default)", style = { font_size = 14, color = "#555" } },
        svg.Text { text = "Center aligned text", style = { font_size = 14, color = "#555", text_align = "center" } },
        svg.Text { text = "Right aligned text", style = { font_size = 14, color = "#555", text_align = "right" } },
        svg.Text { text = "Bold Large Text", style = { font_size = 20, font_weight = "bold", color = "#e74c3c" } },
        svg.Divider(),
        svg.Text { text = "TextBlock — auto word wrap:", style = { font_size = 14, font_weight = "bold", color = "#555" } },
        -- TextBlock 自动换行：英文按空格，CJK 逐字
        svg.TextBlock {
            text = "TextBlock automatically wraps long text. It handles CJK characters (中日韩) correctly, wrapping at character boundaries. English words are wrapped at spaces. Mixing Chinese and English works well too.",
            style = { font_size = 13, color = "#444", line_height = 1.5, background = "#fff", padding = 12, border_radius = 6 },
        },
        -- CJK 文本换行演示
        svg.TextBlock {
            text = "CJK 文本演示：日本語の文章も正しく表示されます。한국어도 문제없이 렌더링됩니다。中英混合 long long text 测试换行效果。",
            style = { font_size = 13, color = "#555", line_height = 1.5, background = "#e8f5e9", padding = 10, border_radius = 6 },
        },
    },
}
save("07_text_system.svg", svg.render_svg(doc7))

-- ============================================================
-- Step 8: 分割线与 ZStack
-- Divider 水平和垂直分割线 + ZStack 层叠布局
-- ============================================================
step(8, "Dividers & ZStack")

local doc8 = svg.Box {
    style = { width = 550, background = "#f5f5f5", padding = 20, direction = "column", gap = 16 },
    children = {
        svg.Text { text = "Divider separates content", style = { font_size = 18, font_weight = "bold", color = "#333", text_align = "center" } },
        svg.Column {
            style = { gap = 6, height = 120, background = "#fff", padding = 12, border_radius = 6 },
            children = {
                svg.Text { text = "Section A", style = { font_size = 14, color = "#333" } },
                svg.Divider(),
                svg.Text { text = "Section B", style = { font_size = 14, color = "#333" } },
                svg.Divider { color = "#e74c3c", thickness = 2 },
                svg.Text { text = "Section C", style = { font_size = 14, color = "#333" } },
                svg.Divider { direction = "vertical", color = "#3498db", thickness = 2, margin = { 0, 8 } },
            },
        },
        -- ZStack：子节点在 Z 轴上重叠
        svg.Text { text = "ZStack layers children on top of each other", style = { font_size = 14, color = "#555" } },
        svg.ZStack {
            style = { width = 240, height = 80, align = "center" },
            children = {
                svg.Rect { style = { width = "100%", height = "100%", fill = "#e3f2fd", border_radius = 12 } },
                svg.Text { text = "Overlaid Text", style = { font_size = 18, color = "#1565c0", font_weight = "bold", text_align = "center" } },
            },
        },
    },
}
save("08_dividers_zstack.svg", svg.render_svg(doc8))

-- ============================================================
-- Step 9: 视觉效果
-- 阴影（shadow）、模糊（blur）、透明度（opacity）、旋转（rotate）、裁剪（clip）
-- ============================================================
step(9, "Visual Effects — shadow, blur, opacity, transform, clip")

local doc9 = svg.Box {
    style = { width = 550, background = "#f0f4f8", padding = 24, direction = "column", gap = 20 },
    children = {
        svg.Text { text = "Visual Effects", style = { font_size = 18, font_weight = "bold", color = "#333", text_align = "center" } },
        svg.Box {
            style = { direction = "row", gap = 20, height = 90, align = "center", justify = "center" },
            children = {
                -- 阴影效果
                svg.Box {
                    style = { width = 90, height = 80, background = "#fff", border_radius = 8, direction = "column", align = "center",
                        shadow = { dx = 3, dy = 4, blur = 8, color = "#000", opacity = 0.2 } },
                    children = { svg.Text { text = "Shadow", style = { font_size = 13, color = "#333", text_align = "center" } } },
                },
                -- 透明度效果
                svg.Box {
                    style = { width = 90, height = 80, background = "#3498db", border_radius = 8, opacity = 0.6, direction = "column", align = "center" },
                    children = { svg.Text { text = "Opacity\n0.6", style = { font_size = 13, color = "#fff", text_align = "center" } } },
                },
                -- 模糊效果
                svg.Box {
                    style = { width = 90, height = 80, background = "#2ecc71", border_radius = 8, blur = 3, direction = "column", align = "center" },
                    children = { svg.Text { text = "Blur 3px", style = { font_size = 13, color = "#fff", text_align = "center" } } },
                },
            },
        },
        svg.Box {
            style = { direction = "row", gap = 20, height = 70, align = "center", justify = "center" },
            children = {
                -- 旋转效果
                svg.Box {
                    style = { width = 100, height = 50, background = "#9b59b6", border_radius = 6, rotate = -8, direction = "column", align = "center" },
                    children = { svg.Text { text = "Rotate", style = { font_size = 13, color = "#fff", text_align = "center" } } },
                },
                -- 裁剪效果（溢出部分隐藏）
                svg.Box {
                    style = { width = 100, height = 50, background = "#e67e22", border_radius = 6, clip = true, direction = "column", align = "center" },
                    children = { svg.Circle { style = { width = 60, height = 60, fill = "#fff", opacity = 0.4 } } },
                },
                -- 发光效果（纯色阴影）
                svg.Box {
                    style = { width = 100, height = 50, background = "#1abc9c", border_radius = 6, direction = "column", align = "center",
                        shadow = { dx = 0, dy = 0, blur = 8, color = "#1abc9c", opacity = 0.7 } },
                    children = { svg.Text { text = "Glow", style = { font_size = 13, color = "#fff", text_align = "center" } } },
                },
            },
        },
    },
}
save("09_effects.svg", svg.render_svg(doc9))

-- ============================================================
-- Step 10: 渐变与图案
-- LinearGradient、RadialGradient、Pattern 三种定义
-- ============================================================
step(10, "Gradients & Patterns")

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

local doc10 = svg.Box {
    style = { width = 550, background = "#f5f5f5", padding = 20, direction = "column", gap = 16 },
    children = {
        svg.Text { text = "Gradients & Patterns", style = { font_size = 18, font_weight = "bold", color = "#333", text_align = "center" } },
        svg.Box {
            style = { direction = "row", gap = 16, height = 180, align = "center", justify = "center" },
            children = {
                -- 线性渐变背景
                svg.Box {
                    style = { width = 140, height = 140, background = grad1, border_radius = 12, direction = "column", align = "center" },
                    children = { svg.Text { text = "Linear\nGradient", style = { font_size = 16, color = "#fff", font_weight = "bold", text_align = "center" } } },
                },
                -- 径向渐变背景
                svg.Box {
                    style = { width = 140, height = 140, background = grad2, border_radius = 12, direction = "column", align = "center" },
                    children = { svg.Text { text = "Radial\nGradient", style = { font_size = 16, color = "#fff", font_weight = "bold", text_align = "center" } } },
                },
                -- 图案填充背景
                svg.Box {
                    style = { width = 140, height = 140, background = pattern, border = "#3498db", border_width = 1, border_radius = 12, direction = "column", align = "center" },
                    children = { svg.Text { text = "Pattern\nFill", style = { font_size = 16, color = "#333", font_weight = "bold", text_align = "center" } } },
                },
            },
        },
    },
}
save("10_gradients_patterns.svg", svg.render_svg(doc10))

-- ============================================================
-- Step 11: 链式 Style API
-- svg.Style() 的完整用法，包括 merge() 合并
-- ============================================================
step(11, "Style Chain API — svg.Style()")

local doc11 = svg.Box {
    style = svg.Style():width(550):height(280):align("center"):background("#f5f5f5"):padding(20):direction("column"):gap(16),
    children = {
        svg.Text {
            text = "Chain API — svg.Style()",
            style = svg.Style():font_size(18):font_weight("bold"):color("#333"):text_align("center"),
        },
        svg.Box {
            style = svg.Style():direction("row"):gap(12):height(80),
            children = {
                svg.Box {
                    style = svg.Style():width(130):height(60):background("#e74c3c"):border_radius(8)
                        :shadow({ dx = 2, dy = 3, blur = 4, color = "#000", opacity = 0.3 }),
                    children = {
                        svg.Text { text = "Chained", style = svg.Style():height(60):font_size(14):color("#fff"):text_align("center") },
                    },
                },
                svg.Rect {
                    style = svg.Style():width(130):height(60):fill("#3498db"):border_radius(4):stroke("#2c3e50"):stroke_width(2),
                },
                svg.Circle {
                    style = svg.Style():width(60):height(60):fill("#2ecc71"):stroke("#1abc9c"):stroke_width(2),
                },
            },
        },
        -- merge() 合并链式 API 与普通样式表
        svg.Text {
            text = "Use merge() to combine with plain tables",
            style = svg.Style():font_size(13):color("#666"):text_align("center")
                :merge({ background = "#fff", padding = 8, border_radius = 4 }),
        },
    },
}
save("11_style_api.svg", svg.render_svg(doc11))

-- ============================================================
-- Step 12: 自定义组件
-- svg.define() + svg.register() 两种自定义方式
-- ============================================================
step(12, "Custom Components — svg.define() & svg.register()")

-- define：创建可复用的无状态组件
local Badge = svg.define(function(props)
    return svg.Box {
        style = {
            background = props.color or "#3498db",
            border_radius = 12,
            padding = { 4, 10, 4, 10 },
        },
        children = {
            svg.Text {
                text = props.text or "Badge",
                style = { font_size = 12, color = "#fff", text_align = "center" },
            },
        },
    }
end)

-- register：全局注册组件，可通过 svg.WarningBadge 访问
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
                text = props.text or "Warning",
                style = { font_size = 14, color = props.outline and "#f39c12" or "#fff", font_weight = "bold", text_align = "center" },
            },
        },
    }
end)

local doc12 = svg.Box {
    style = svg.Style():width(550):background("#f5f5f5"):padding(20):direction("column"):gap(16),
    children = {
        svg.Text {
            text = "Custom Components",
            style = svg.Style():font_size(18):font_weight("bold"):color("#333"):text_align("center"),
        },
        svg.Text { text = "svg.define() creates reusable components:", style = { font_size = 13, color = "#666" } },
        svg.Box {
            style = svg.Style():direction("row"):gap(10):height(30):align("center"),
            children = {
                Badge { text = "New", color = "#e74c3c" },
                Badge { text = "Recommended", color = "#2ecc71" },
                Badge { text = "Popular", color = "#3498db" },
                Badge { text = "Beta", color = "#9b59b6" },
            },
        },
        svg.Text { text = "svg.register() adds named components:", style = { font_size = 13, color = "#666" } },
        svg.Box {
            style = svg.Style():direction("row"):gap(10):height(34):align("center"),
            children = {
                svg.WarningBadge { text = "!! Important Notice" },
                svg.WarningBadge { text = "External Link", outline = true },
            },
        },
    },
}
save("12_custom_components.svg", svg.render_svg(doc12))

-- ============================================================
-- Step 13: Builder 动态内容
-- Builder 在渲染阶段回调生成子节点，可根据运行时上下文自适应
-- ============================================================
step(13, "Builder — Dynamic Content Generation")

local doc13 = svg.Box {
    style = svg.Style():width(550):background("#f5f5f5"):padding(20):direction("column"):gap(12),
    children = {
        svg.Text {
            text = "Builder — Dynamic Content",
            style = svg.Style():font_size(18):font_weight("bold"):color("#333"):text_align("center"),
        },
        svg.Text {
            text = "Builder generates children at render time based on runtime context.",
            style = { font_size = 13, color = "#666", text_align = "center" },
        },
        svg.Builder {
            style = svg.Style():direction("column"):gap(6):background("#fff"):padding(12):border_radius(6),
            build = function(ctx)
                local items = {}
                for i = 1, 6 do
                    items[#items + 1] = svg.Box {
                        style = svg.Style():direction("row"):gap(8):height(26):align("center"),
                        children = {
                            svg.Circle { style = svg.Style():width(8):height(8):fill(i % 2 == 0 and "#3498db" or "#e74c3c") },
                            svg.Text {
                                text = string.format("Dynamic Item #%d (ctx width: %dpx)", i, math.floor(ctx.width)),
                                style = { font_size = 13, color = "#444" },
                            },
                        },
                    }
                end
                return items
            end,
        },
    },
}
save("13_builder.svg", svg.render_svg(doc13))

-- ============================================================
-- Step 14: 分页功能
-- render_pages 自动分页 + PageCallback 页码组件 + PageNumber 模板页码
-- ============================================================
step(14, "Pagination — render_pages & PageCallback")

-- 生成 40 个列表项用于分页演示
local items = {}
for i = 1, 40 do
    items[#items + 1] = svg.Row {
        style = svg.Style():gap(8):height(24):align("center"):background(i % 2 == 0 and "#f5f5f5" or "#fff"):padding({ 0, 8 }),
        children = {
            svg.Text { text = string.format("Item %02d", i), style = { font_size = 12, color = "#333", width = 50 } },
            svg.Text { text = "Description text for this list item", style = { font_size = 12, color = "#888" } },
        },
    }
end

-- 构建分页文档：标题 + 列表 + 页码
local doc14 = svg.Column {
    style = svg.Style():fillMaxSize():gap(4):padding(16):background("#f0f4f8"),
    children = {
        svg.Row {
            children = {
                svg.Text { text = "Pagination Demo", style = svg.Style():flex(1):font_size(18):font_weight("bold"):color("#333") },
                svg.Spacer { style = svg.Style():flex(1) },
                -- PageNumber 使用模板字符串
                svg.PageNumber {
                    template = "{page} / {total}",
                    text_style = svg.Style():font_size(10):color("#999"),
                },
            },
        },
        svg.Divider(),
        svg.Column {
            style = svg.Style():fillMaxSize():gap(4):padding(12):background("#fff"):border_radius(6),
            children = items,
        },
        svg.Divider(),
        -- PageCallback 使用 build(page, total) 回调
        svg.PageCallback {
            style = svg.Style():height(28):direction("row"):align("center"):justify("center"):gap(6),
            build = function(page, total)
                return {
                    svg.Text { text = "Page", style = { font_size = 12, color = "#888" } },
                    svg.Text { text = tostring(page), style = { font_size = 14, color = "#3498db", font_weight = "bold" } },
                    svg.Text { text = "/", style = { font_size = 12, color = "#ccc" } },
                    svg.Text { text = tostring(total), style = { font_size = 14, color = "#333", font_weight = "bold" } },
                }
            end,
        },
    },
}

local pages14 = svg.render_pages(doc14, { width = 480, height = 400 })
for i, page in ipairs(pages14) do
    save(string.format("14_page_%d.svg", i), page)
end
print(string.format("  Total: %d pages", #pages14))

-- ============================================================
-- Step 15: 综合仪表盘
-- 结合渐变、圆角、阴影、flex 布局、Builder 动态内容的自定义组件
-- ============================================================
step(15, "Dashboard — Putting It All Together")

local dash_grad = svg.LinearGradient {
    x1 = "0%", y1 = "0%", x2 = "100%", y2 = "100%",
    stops = { { offset = 0, color = "#667eea" }, { offset = 1, color = "#764ba2" } },
}

-- 统计卡片自定义组件
local stat_card = svg.define(function(props)
    return svg.Box {
        style = svg.Style():flex(1):background("#fff"):border_radius(10):padding(16):direction("column"):gap(6)
            :shadow({ dx = 0, dy = 2, blur = 6, color = "#000", opacity = 0.08 }),
        children = {
            svg.Text { text = props.label, style = { font_size = 13, color = "#888" } },
            svg.Text { text = props.value, style = { font_size = 24, font_weight = "bold", color = props.color or "#333" } },
            svg.Text { text = props.trend, style = { font_size = 12, color = props.color or "#333" } },
        },
    }
end)

local doc15 = svg.Box {
    style = svg.Style():width(760):background("#eef1f5"):padding(24):direction("column"):gap(20),
    children = {
        -- 标题栏：渐变装饰条 + 标题 + Badge
        svg.Box {
            style = svg.Style():direction("row"):height(56):align("center"):gap(14),
            children = {
                svg.Rect { style = svg.Style():width(6):height(36):fill(dash_grad):border_radius(3) },
                svg.Box {
                    style = svg.Style():direction("column"):gap(2),
                    children = {
                        svg.Text { text = "Dashboard", style = svg.Style():font_size(22):font_weight("bold"):color("#222") },
                        svg.Text { text = "Comprehensive demo — forms, cards, data display", style = svg.Style():font_size(13):color("#888") },
                    },
                },
                svg.Spacer(),
                Badge { text = "Live", color = "#2ecc71" },
            },
        },
        -- 统计卡片行
        svg.Box {
            style = svg.Style():direction("row"):gap(14):height(90),
            children = {
                stat_card { label = "Total Revenue", value = "$12,580", color = "#2ecc71", trend = "+8.2% vs last month" },
                stat_card { label = "Active Users", value = "3,421", color = "#3498db", trend = "+5.7% vs last month" },
                stat_card { label = "Orders", value = "856", color = "#e67e22", trend = "+12.3% vs last month" },
            },
        },
        -- 编辑表单 + 动态活动列表
        svg.Box {
            style = svg.Style():direction("row"):gap(14):flex(1),
            children = {
                -- 左侧：编辑表单
                svg.Box {
                    style = svg.Style():flex(1):background("#fff"):border_radius(10):padding(20):direction("column"):gap(14)
                        :shadow({ dx = 0, dy = 1, blur = 4, color = "#000", opacity = 0.06 }),
                    children = {
                        svg.Text { text = "Edit Profile", style = svg.Style():font_size(16):font_weight("bold"):color("#333") },
                        svg.Box {
                            style = svg.Style():direction("column"):gap(4),
                            children = {
                                svg.Text { text = "Name", style = { font_size = 13, color = "#666" } },
                                svg.Rect { style = svg.Style():width("fill"):height(34):fill("#f5f6fa"):border_radius(6):stroke("#ddd"):stroke_width(1) },
                            },
                        },
                        svg.Box {
                            style = svg.Style():direction("column"):gap(4),
                            children = {
                                svg.Text { text = "Email", style = { font_size = 13, color = "#666" } },
                                svg.Rect { style = svg.Style():width("fill"):height(34):fill("#f5f6fa"):border_radius(6):stroke("#ddd"):stroke_width(1) },
                            },
                        },
                        -- 操作按钮
                        svg.Box {
                            style = svg.Style():direction("row"):gap(8):height(34):align("center"),
                            children = {
                                svg.Rect { style = svg.Style():flex(1):height(34):fill("#667eea"):border_radius(6) },
                                svg.Rect { style = svg.Style():flex(1):height(34):fill("#e8e8e8"):border_radius(6) },
                            },
                        },
                    },
                },
                -- 右侧：Builder 动态活动列表
                svg.Box {
                    style = svg.Style():flex(1):background("#fff"):border_radius(10):padding(20):direction("column"):gap(10)
                        :shadow({ dx = 0, dy = 1, blur = 4, color = "#000", opacity = 0.06 }),
                    children = {
                        svg.Text { text = "Recent Activity", style = svg.Style():font_size(16):font_weight("bold"):color("#333") },
                        svg.Builder {
                            style = svg.Style():direction("column"):gap(8),
                            build = function()
                                local activities = {
                                    { color = "#e74c3c", text = "Alice submitted a new order",  time = "2 min ago" },
                                    { color = "#3498db", text = "Bob updated profile",          time = "15 min ago" },
                                    { color = "#2ecc71", text = "Carol completed registration", time = "1 hr ago" },
                                    { color = "#f39c12", text = "Dave requested refund",        time = "3 hr ago" },
                                }
                                local items = {}
                                for _, act in ipairs(activities) do
                                    items[#items + 1] = svg.Box {
                                        style = svg.Style():direction("row"):gap(8):height(32):align("center"),
                                        children = {
                                            svg.Circle { style = svg.Style():width(6):height(6):fill(act.color) },
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
save("15_dashboard.svg", svg.render_svg(doc15))

-- ============================================================
-- Step 16: 九宫格 (Nine-Patch) 完整功能展示
-- 使用 svg.Image + nine_patch 配置，支持拉伸和重复模式
-- ============================================================
step(16, "Nine-Patch (九宫格) — 完整功能展示")

local np_frame = "nine_patch_src.svg"
local np_pattern = "nine_patch_ptn_src.svg"

-- 生成九宫格素材源图：102×102 渐变边框素材
local function gen_nine_patch_src()
    local grad = svg.LinearGradient {
        x1 = "0%", y1 = "0%", x2 = "100%", y2 = "100%",
        stops = {
            { offset = 0, color = "#667eea" },
            { offset = 1, color = "#764ba2" },
        },
    }
    local doc = svg.Box {
        style = svg.Style():width(102):height(102):direction("stack"):padding(1):background("#f0f4ff"),
        children = {
            svg.Rect { style = svg.Style():width(100):height(100):border_radius(12):fill("#f0f4ff"):stroke(grad):stroke_width(4) },
            -- 四角 L 形装饰
            svg.Path { d = "M 11 6 L 11 11 L 6 11", style = { stroke = "#667eea", stroke_width = 2.5, fill = "none", stroke_linecap = "round" } },
            svg.Path { d = "M 91 6 L 91 11 L 96 11", style = { stroke = "#667eea", stroke_width = 2.5, fill = "none", stroke_linecap = "round" } },
            svg.Path { d = "M 6 91 L 11 91 L 11 96", style = { stroke = "#667eea", stroke_width = 2.5, fill = "none", stroke_linecap = "round" } },
            svg.Path { d = "M 91 96 L 91 91 L 96 91", style = { stroke = "#667eea", stroke_width = 2.5, fill = "none", stroke_linecap = "round" } },
            svg.Circle { r = 8, style = { fill = "#667eea", opacity = 0.15 } },
        },
    }
    return svg.render_svg(doc)
end

-- 生成图案素材源图：102×102 的色块网格
local function gen_nine_patch_ptn_src()
    local doc = svg.Box {
        style = svg.Style():width(102):height(102):direction("column"):background("#f8f9fa"):border("#ddd"):border_width(1):padding(1),
        children = {
            svg.Box { style = svg.Style():direction("row"):height(20),
                children = {
                    svg.Rect { style = { width = 20, height = 20, fill = "#e74c3c" } },
                    svg.Box { style = svg.Style():flex(1):direction("row"):height(20),
                        children = {
                            svg.Rect { style = { width = 14, height = 20, fill = "#f39c12" } },
                            svg.Box { style = { width = 12 } },
                            svg.Rect { style = { width = 14, height = 20, fill = "#f39c12" } },
                            svg.Box { style = { width = 12 } },
                            svg.Rect { style = { width = 8, height = 20, fill = "#f39c12" } },
                        }
                    },
                    svg.Rect { style = { width = 20, height = 20, fill = "#e74c3c" } },
                }
            },
            svg.Box { style = svg.Style():direction("row"):flex(1),
                children = {
                    svg.Box { style = svg.Style():width(20):direction("column"),
                        children = {
                            svg.Rect { style = { width = 20, height = 14, fill = "#2ecc71" } },
                            svg.Box { style = { height = 12 } },
                            svg.Rect { style = { width = 20, height = 14, fill = "#2ecc71" } },
                            svg.Box { style = { height = 12 } },
                            svg.Rect { style = { width = 20, height = 8, fill = "#2ecc71" } },
                        }
                    },
                    svg.Box { style = svg.Style():flex(1):direction("column"):justify("center"):align("center"):gap(20),
                        children = {
                            svg.Box { style = svg.Style():direction("row"):gap(20),
                                children = {
                                    svg.Circle { r = 3, style = { fill = "#3498db" } },
                                    svg.Circle { r = 3, style = { fill = "#3498db" } },
                                    svg.Circle { r = 3, style = { fill = "#3498db" } },
                                }
                            },
                            svg.Box { style = svg.Style():direction("row"):gap(20),
                                children = {
                                    svg.Circle { r = 3, style = { fill = "#3498db" } },
                                    svg.Circle { r = 3, style = { fill = "#3498db" } },
                                    svg.Circle { r = 3, style = { fill = "#3498db" } },
                                }
                            },
                            svg.Box { style = svg.Style():direction("row"):gap(20),
                                children = {
                                    svg.Circle { r = 3, style = { fill = "#3498db" } },
                                    svg.Circle { r = 3, style = { fill = "#3498db" } },
                                    svg.Circle { r = 3, style = { fill = "#3498db" } },
                                }
                            },
                        }
                    },
                    svg.Box { style = svg.Style():width(20):direction("column"),
                        children = {
                            svg.Rect { style = { width = 20, height = 14, fill = "#2ecc71" } },
                            svg.Box { style = { height = 12 } },
                            svg.Rect { style = { width = 20, height = 14, fill = "#2ecc71" } },
                            svg.Box { style = { height = 12 } },
                            svg.Rect { style = { width = 20, height = 8, fill = "#2ecc71" } },
                        }
                    },
                }
            },
            svg.Box { style = svg.Style():direction("row"):height(20),
                children = {
                    svg.Rect { style = { width = 20, height = 20, fill = "#e74c3c" } },
                    svg.Box { style = svg.Style():flex(1):direction("row"):height(20),
                        children = {
                            svg.Rect { style = { width = 14, height = 20, fill = "#f39c12" } },
                            svg.Box { style = { width = 12 } },
                            svg.Rect { style = { width = 14, height = 20, fill = "#f39c12" } },
                            svg.Box { style = { width = 12 } },
                            svg.Rect { style = { width = 8, height = 20, fill = "#f39c12" } },
                        }
                    },
                    svg.Rect { style = { width = 20, height = 20, fill = "#e74c3c" } },
                }
            },
        },
    }
    return svg.render_svg(doc)
end

save(np_frame, gen_nine_patch_src())
save(np_pattern, gen_nine_patch_ptn_src())

-- 九宫格示例卡片辅助函数
local function np_card(href, cfg, w, h, label)
    return svg.Box {
        style = svg.Style():direction("column"):gap(4):align("center"):flex(1),
        children = {
            svg.Text { text = label, style = svg.Style():font_size(11):color("#555"):text_align("center") },
            svg.Image { href = href, style = { width = w, height = h }, nine_patch = cfg },
        },
    }
end

local function img_card(href, w, h, label)
    return svg.Box {
        style = svg.Style():direction("column"):gap(4):align("center"):flex(1),
        children = {
            svg.Text { text = label, style = svg.Style():font_size(11):color("#555"):text_align("center") },
            svg.Image { href = href, style = { width = w, height = h } },
        },
    }
end

local function h2(text)
    return svg.Text { text = text, style = svg.Style():font_size(16):font_weight("bold"):color("#2c3e50"):margin({ 20, 0, 2, 0 }) }
end

local function p(text)
    return svg.Text { text = text, style = svg.Style():font_size(12):color("#888"):margin({ 0, 0, 6, 0 }) }
end

local function row(...)
    local children = { ... }
    return svg.Box {
        style = svg.Style():direction("row"):flex(1):gap(12):background("#fff"):padding(16):border_radius(8):align("end"),
        children = children,
    }
end

-- 九宫格综合演示文档
local doc16 = svg.Box {
    style = svg.Style():width(1500):background("#f5f6fa"):padding(24):direction("column"):gap(0),
    children = {
        svg.Text { text = "Nine-Patch (九宫格) 完整功能展示", style = svg.Style():font_size(22):font_weight("bold"):color("#2c3e50"):text_align("center"):margin({ 0, 0, 4, 0 }) },
        svg.Divider { style = { margin = { 0, 0, 8, 0 } } },

        -- 素材源图展示
        h2("素材源图"),
        p("两张 102×102 的九宫格素材（100×100 内容区 + 1px 边框），固定区域均为 20px"),
        row(
            img_card(np_frame, 102, 102, "渐变边框素材\n四角带 L 形装饰"),
            img_card(np_pattern, 102, 102, "图案素材\n用于重复模式演示")
        ),

        -- 基础拉伸演示
        h2("1. 基础九宫格拉伸"),
        p("固定区域保持原尺寸，可拉伸区域自适应填充目标空间。"),
        row(
            img_card(np_frame, 102, 102, "原图 102×102"),
            np_card(np_frame, { src_width = 100, src_height = 100, left = 20, right = 20, top = 20, bottom = 20 }, 240, 102, "水平拉伸\n240×102"),
            np_card(np_frame, { src_width = 100, src_height = 100, left = 20, right = 20, top = 20, bottom = 20 }, 102, 180, "垂直拉伸\n102×180"),
            np_card(np_frame, { src_width = 100, src_height = 100, left = 20, right = 20, top = 20, bottom = 20 }, 340, 220, "双向拉伸\n340×220")
        ),

        -- 不同固定区域配置
        h2("2. 不同固定区域配置"),
        p("调整 left/right/top/bottom 控制固定区域大小（均拉伸至 300×200）。"),
        row(
            np_card(np_frame, { src_width = 100, src_height = 100, left = 5, right = 5, top = 5, bottom = 5 }, 300, 200, "小角 (5px)"),
            np_card(np_frame, { src_width = 100, src_height = 100, left = 35, right = 35, top = 35, bottom = 35 }, 300, 200, "大角 (35px)"),
            np_card(np_frame, { src_width = 100, src_height = 100, left = 10, right = 25, top = 15, bottom = 30 }, 300, 200, "不对称\nL10/R25/T15/B30")
        ),

        -- 百分比配置
        h2("3. 百分比配置"),
        p("left/right/top/bottom 支持百分比字符串。"),
        row(
            np_card(np_frame, { src_width = 100, src_height = 100, left = "20%", right = "20%", top = "20%", bottom = "20%" }, 300, 200, 'left/right/top/bottom = "20%"')
        ),

        -- 源素材缩放
        h2("4. 源素材缩放 (scale)"),
        p("scale 参数对源素材整体缩放，同时影响固定区和可拉伸区。"),
        row(
            np_card(np_frame, { src_width = 100, src_height = 100, left = 20, right = 20, top = 20, bottom = 20, scale = 1 }, 300, 200, "scale=1"),
            np_card(np_frame, { src_width = 50, src_height = 50, left = 10, right = 10, top = 10, bottom = 10, scale = 2 }, 300, 200, "scale=2")
        ),

        -- 重复模式
        h2("5. 重复模式 (repeat_mode)"),
        p("可拉伸区域支持平铺重复模式。"),
        row(
            np_card(np_pattern, { src_width = 100, src_height = 100, left = 20, right = 20, top = 20, bottom = 20, repeat_mode = "no-repeat" }, 300, 200, "no-repeat"),
            np_card(np_pattern, { src_width = 100, src_height = 100, left = 20, right = 20, top = 20, bottom = 20, repeat_mode = "repeat" }, 300, 200, "repeat"),
            np_card(np_pattern, { src_width = 100, src_height = 100, left = 20, right = 20, top = 20, bottom = 20, repeat_mode = "repeat-x" }, 300, 200, "repeat-x"),
            np_card(np_pattern, { src_width = 100, src_height = 100, left = 20, right = 20, top = 20, bottom = 20, repeat_mode = "repeat-y" }, 300, 200, "repeat-y")
        ),

        -- 逐块重复覆盖
        h2("6. 逐块重复覆盖 (block_repeat)"),
        p("block_repeat 可为每个九宫格块单独指定重复模式。"),
        row(
            np_card(np_pattern, { src_width = 100, src_height = 100, left = 20, right = 20, top = 20, bottom = 20, repeat_mode = "no-repeat", block_repeat = { c = "repeat", t = "repeat-x", b = "repeat-x", l = "repeat-y", r = "repeat-y" } }, 300, 200, "中心=repeat\n上下=repeat-x\n左右=repeat-y\n四角=no-repeat")
        ),
    },
}

save("16_nine_patch_comprehensive.svg", svg.render_svg(doc16))

-- ============================================================
-- Step 17: 模板变量系统 — var()
-- 展示 svg.var() 声明动态变量，最终 SVG 输出 {{name}} 占位符，
-- 可供 Jinja2、Mustache 等外部模板引擎后续替换
-- ============================================================
step(17, "Template Variables — svg.var()")

-- 基础变量：所有核心属性均使用 var() 声明
-- 输出 SVG 中 width/height 保持固定值，background/text/font_size 变为 {{name}}
-- 验证：变量不会影响布局测量，font_size 在测量阶段使用默认值 14
local doc17a = svg.Box {
    style = { width = 400, height = 200, background = svg.var("background") },
    children = {
        svg.Text {
            text = svg.var("text"),
            style = { height = 200, font_size = svg.var("font_size"), color = "#333", font_weight = "bold", text_align = "center" },
        },
    },
}
save("17a_template_variables.svg", svg.render_svg(doc17a))

-- 混合使用：变量与固定值混合在同一个组件树中
-- 固定值（如 #f5f5f5、22、#666）保持原样输出
-- 变量如 title/title_color/description/button_bg 输出 {{name}}
-- 验证：同一变量可在多处复用（button_bg 在两个 Rect 中使用）
local doc17b = svg.Box {
    style = { width = 500, padding = 20, direction = "column", gap = 12, background = "#f5f5f5" },
    children = {
        svg.Text {
            text = svg.var("title"),
            style = { font_size = 22, font_weight = "bold", color = svg.var("title_color"), text_align = "center" },
        },
        svg.TextBlock {
            text = svg.var("description"),
            style = { font_size = 14, color = "#666", line_height = 1.5, background = "#fff", padding = 12, border_radius = 6 },
        },
        svg.Box {
            style = { direction = "row", gap = 10, height = 40 },
            children = {
                svg.Rect { style = { flex = 1, height = 40, fill = svg.var("button_bg"), border_radius = 6 } },
                svg.Rect { style = { flex = 1, height = 40, fill = svg.var("button_bg"), border_radius = 6 } },
            },
        },
    },
}
save("17b_mixed_variables.svg", svg.render_svg(doc17b))

-- 形状组件中：Circle 的 fill、Rect 的 fill 和 border_radius 均可使用变量
-- 固定值（"#e74c3c"）保持原样，变量输出 {{name}}
-- 验证：border_radius 作为数值型变量也可正确输出 {{corner_radius}}
local doc17c = svg.Box {
    style = { width = 400, height = 150, direction = "row", gap = 20, align = "center", justify = "center", background = "#f8f9fa" },
    children = {
        svg.Circle { style = { width = 60, height = 60, fill = svg.var("circle_color") } },
        svg.Rect { style = { width = 80, height = 50, fill = svg.var("rect_color"), border_radius = 8 } },
        svg.Rect { style = { width = 80, height = 50, fill = "#e74c3c", border_radius = svg.var("corner_radius") } },
    },
}
save("17c_shape_variables.svg", svg.render_svg(doc17c))

print("  Template variable placeholders: {{variable_name}}")
print("  Compatible with Jinja2, Mustache, Handlebars, dotLiquid, etc.")

print("")
print("All 17 steps completed successfully!")
print("Output files are in the output/ directory:")
local handle = io.popen("dir ..\\output\\*.svg /b 2>nul")
if handle then
    for fname in handle:lines() do
        print("  - " .. fname)
    end
    handle:close()
end
