-- 需要把 svglayout 目录放入 package.path
package.path = package.path .. ";./?.lua;./?/init.lua"

local svg = require("svglayout")

-- ========== 示例 1：声明式布局 ==========
local doc1 = svg.Box {
    style = {
        width = 800, height = 400,
        background = "#f4f4f8",
        padding = 24,
        direction = "column",
        gap = 16,
    },
    children = {
        svg.Text {
            text = "Hello SVG Layout",
            style = {
                height = 40,
                font_size = 28,
                font_weight = "bold",
                color = "#222",
                text_align = "center",
            },
        },

        svg.Box {
            style = {
                direction = "row", gap = 12, height = 120,
                justify = "space-between", align = "center",
            },
            children = {
                svg.Rect { style = { width = 120, height = 80, fill = "#e74c3c", border_radius = 8,
                    shadow = { dx = 2, dy = 4, blur = 4, color = "#000", opacity = 0.3 } } },
                svg.Circle { style = { width = 80, height = 80, fill = "#3498db" } },
                svg.Rect { style = { width = 120, height = 80, fill = "#2ecc71", border_radius = 8,
                    blur = 1 } },
            },
        },

        svg.Box {
            style = {
                background = "#fff", border = "#ccc", border_width = 1,
                border_radius = 6, padding = 16, height = 120,
            },
            children = {
                svg.Text {
                    text = "A styled card with border & padding.",
                    style = { font_size = 16, color = "#555" },
                },
            },
        },
    },
}

local out = svg.render_svg(doc1, { width = 800, height = 400 })
local f = io.open("output/1-a.svg", "w"); f:write(out); f:close()
print("wrote 1-a.svg")

-- ========== 示例 2：Builder 组件 ==========
local doc2 = svg.Box {
    style = { width = 600, height = 300, padding = 20, background = "#fff" },
    children = {
        svg.Builder {
            style = { direction = "column", gap = 6 },
            build = function(ctx)
                local items = {}
                for i = 1, 5 do
                    items[#items + 1] = svg.Box {
                        style = {
                            direction = "row", gap = 8, height = 30,
                            background = (i % 2 == 1) and "#eef" or "#fff",
                            padding = { 4, 8, 4, 8 },
                        },
                        children = {
                            svg.Text {
                                text = string.format("Item #%d", i),
                                style = { font_size = 14, color = "#333", width = 100 },
                            },
                            svg.Text {
                                text = string.format("Value: %d", i * 100),
                                style = { font_size = 14, color = "#666" },
                            },
                        },
                    }
                end
                return items
            end,
        },
    },
}
local out2 = svg.render_svg(doc2, { width = 600, height = 300 })
local f2 = io.open("output/1-b.svg", "w"); f2:write(out2); f2:close()
print("wrote 1-b.svg")

-- ========== 示例 3：自定义组件 ==========
local Badge = svg.define(function(props)
    return svg.Box {
        style = {
            background = props.color or "#3498db",
            border_radius = 12,
            padding = { 4, 10, 4, 10 },
            width = 80, height = 24,
        },
        children = {
            svg.Text {
                text = props.text or "badge",
                style = { font_size = 12, color = "#fff", text_align = "center" },
            },
        },
    }
end)

local doc3 = svg.Box {
    style = { width = 400, height = 100, padding = 20, direction = "row", gap = 10, background = "#fafafa" },
    children = {
        Badge { text = "NEW", color = "#e74c3c" },
        Badge { text = "SALE", color = "#f39c12" },
        Badge { text = "HOT", color = "#9b59b6" },
    },
}
local out3 = svg.render_svg(doc3, { width = 400, height = 100 })
local f3 = io.open("output/1-c.svg", "w"); f3:write(out3); f3:close()
print("wrote 1-c.svg")

-- ========== 示例 4：分页 ==========
local long_children = {}
for i = 1, 30 do
    long_children[#long_children + 1] = svg.Box {
        style = {
            height = 40, background = (i % 2 == 0) and "#eef" or "#fff",
            padding = { 8, 12, 8, 12 }, border = "#ddd", border_width = 1,
        },
        children = {
            svg.Text {
                text = string.format("Row %d — content line with index %d", i, i),
                style = { font_size = 14, color = "#333" },
            },
        },
    }
end

local long_doc = svg.Box {
    style = { width = 500, height = 700, padding = 20, gap = 6, background = "#fff" },
    children = long_children,
}

local pages = svg.render_pages(long_doc, { width = 500, height = 700 })
for i, pg in ipairs(pages) do
    local fp = io.open(string.format("output/1-d_%d.svg", i), "w")
    fp:write(pg); fp:close()
end
print(string.format("wrote %d pages", #pages))

-- ========== 示例 5：Raw SVG 嵌入 ==========
local doc5 = svg.Box {
    style = { width = 300, height = 200, background = "#fff", padding = 10 },
    children = {
        svg.Raw {
            svg = [[<path d="M50,100 Q150,20 250,100 T450,100" stroke="purple" stroke-width="3" fill="none"/>]],
        },
    },
}
local out5 = svg.render_svg(doc5, { width = 300, height = 200 })
local f5 = io.open("output/1-e.svg", "w"); f5:write(out5); f5:close()
print("wrote 1-e.svg")