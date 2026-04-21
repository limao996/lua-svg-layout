package.path = package.path .. ";./?.lua;./?/init.lua"
local svg = require("svglayout")

-- ========== A. 渐变背景 + 多行文本 ==========
local bg_grad = svg.LinearGradient {
    x1 = "0%", y1 = "0%", x2 = "0%", y2 = "100%",
    stops = {
        { offset = 0,   color = "#667eea" },
        { offset = 1,   color = "#764ba2" },
    },
}

local radial = svg.RadialGradient {
    stops = {
        { offset = 0, color = "#fff", opacity = 0.8 },
        { offset = 1, color = "#fff", opacity = 0 },
    },
}

local doc_a = svg.Box {
    style = {
        width = 600, height = 400, padding = 30,
        background = bg_grad,     -- 注意：直接传渐变对象
        direction = "column", gap = 16,
    },
    children = {
        svg.Text {
            text = "Gradient & TextBlock Demo",
            style = {
                height = 40, font_size = 24, font_weight = "bold",
                color = "#fff", text_align = "center",
            },
        },
        svg.Box {
            style = {
                background = "#ffffff22", border_radius = 8,
                padding = 16,
                -- 注意：不指定 height，让 TextBlock 自撑高
            },
            children = {
                svg.TextBlock {
                    text = "这是一段较长的文字，用于演示多行文本自动换行的能力。" ..
                           "TextBlock supports mixed CJK and English content, " ..
                           "and will wrap according to the available content width. " ..
                           "换行高度会自动计算并传回父容器。",
                    line_height = 1.5,
                    style = { font_size = 14, color = "#fff" },
                },
            },
        },
        svg.Circle {
            style = {
                width = 80, height = 80, fill = radial,  -- 径向渐变填充
            },
        },
    },
}

local f = io.open("output/2-a.svg", "w"); f:write(svg.render_svg(doc_a, { width = 600, height = 400 })); f:close()
print("wrote 2-a.svg")

-- ========== B. Pattern 图案填充 ==========
local dots = svg.Pattern {
    width = 20, height = 20,
    content = '<circle cx="10" cy="10" r="2" fill="#3498db"/>',
}

local doc_b = svg.Box {
    style = { width = 400, height = 200, padding = 20, background = "#fff" },
    children = {
        svg.Rect {
            style = {
                width = 360, height = 160,
                fill = dots,              -- 使用图案填充
                stroke = "#2980b9", stroke_width = 2,
                border_radius = 8,
            },
        },
    },
}
local fb = io.open("output/2-b.svg", "w"); fb:write(svg.render_svg(doc_b, { width = 400, height = 200 })); fb:close()
print("wrote 2-b.svg")

-- ========== C. 图片组件 ==========
local doc_c = svg.Box {
    style = { width = 400, height = 300, padding = 20, background = "#eee",
              direction = "column", gap = 10 },
    children = {
        svg.Image {
            href = "https://api.mmp.cc/api/pcwallpaper?category=cartoon&type=jpg",
            preserve_aspect_ratio = "xMidYMid slice",
            style = { width = 360, height = 200, border_radius = 8, clip = true },
        },
        svg.Text {
            text = "Image caption",
            style = { height = 20, font_size = 14, color = "#333", text_align = "center" },
        },
    },
}
local fc = io.open("output/2-c.svg", "w"); fc:write(svg.render_svg(doc_c, { width = 400, height = 300 })); fc:close()
print("wrote 2-c.svg")

-- ========== D. 长文本精细分页 ==========
local long_text = table.concat({
    "第一章　介绍",
    "这是一个用于测试分页功能的长文本示例。它混合了中文和 English words ",
    "to test mixed-script wrapping. Lorem ipsum dolor sit amet, consectetur ",
    "adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore ",
    "magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco ",
    "laboris nisi ut aliquip ex ea commodo consequat.",
    "",
    "第二章　分页测试",
    "当 TextBlock 的内容高度超出父容器剩余空间时，分页器会调用节点的 _split ",
    "方法，把文本按行数拆分：能放下的部分留在当前页，剩余部分作为新的 TextBlock ",
    "节点进入下一页。这种机制允许任意自定义节点参与精细分页，只要实现 _splittable ",
    "与 _split 协议即可。",
    "",
    "第三章　更多内容",
    "继续堆叠更多内容以强制产生多页输出。Each line contributes to the total height, ",
    "and once the accumulated height exceeds the page content area, the paginator ",
    "triggers splitting. 重复、重复、再重复，直到我们看到足够多的分页结果为止。",
    "再来一段：这一段作为额外填充内容，使总高度明显大于单页容量，触发多次拆分。",
    "最后一段：分页结束。",
}, " ")

local doc_d = svg.Box {
    style = {
        width = 500, height = 400,  -- 故意较小以触发分页
        padding = 24, background = "#fff",
        direction = "column", gap = 12,
    },
    children = {
        svg.Text {
            text = "Pagination Demo",
            style = { height = 28, font_size = 20, font_weight = "bold",
                      color = "#222", text_align = "center" },
        },
        svg.TextBlock {
            text = long_text,
            line_height = 1.6,
            style = { font_size = 14, color = "#333" },
        },
        svg.Text {
            text = "— END —",
            style = { height = 20, font_size = 12, color = "#999", text_align = "center" },
        },
    },
}

local pages = svg.render_pages(doc_d, { width = 500, height = 400 })
for i, svgstr in ipairs(pages) do
    local fp = io.open(string.format("output/2-d_page_%d.svg", i), "w")
    fp:write(svgstr); fp:close()
end
print(string.format("wrote %d pages of 2-d", #pages))