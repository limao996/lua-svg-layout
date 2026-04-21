-- 需要把 svglayout 目录放入 package.path
package.path = package.path .. ";./?.lua;./?/init.lua"
local svg = require("svglayout")

-- ========== 示例 A：flex 权重 ==========
local doc_a = svg.Box {
    style = { width = 600, height = 80, direction = "row", gap = 10,
        padding = 10, background = "#eee", align = "center" },
    children = {
        svg.Box { style = { width = 100, height = "85%", background = "#e74c3c" } }, -- 固定
        svg.Box { style = { flex = 1, height = "85%", background = "#3498db" } },    -- 占1份
        svg.Box { style = { flex = 2, height = "85%", background = "#2ecc71" } },    -- 占2份
        svg.Box { style = { width = 100, height = "85%", background = "#f39c12" } }, -- 固定
    },
}

local out = svg.render_svg(doc_a, { width = 600, height = 80 })
local f = io.open("output/4-a.svg", "w"); f:write(out); f:close()
print("wrote 4-a.svg")

-- ========== 示例 B：auto（按内容自适应） ==========
local doc_b = svg.Box {
    style = { width = 500, height = 100, direction = "row", gap = 8,
        padding = 10, background = "#fff", align = "center" },
    children = {
        svg.Box {
            style = { width = "auto", height = "auto",
                padding = 12, background = "#3498db", border_radius = 6 },
            children = {
                svg.Text { text = "Tag1",
                    style = { color = "#fff", font_size = 16 } },
            },
        },
        svg.Box {
            style = { width = "auto", height = "auto",
                padding = 12, background = "#e74c3c", border_radius = 6 },
            children = {
                svg.Text { text = "LongerTag",
                    style = { color = "#fff", font_size = 30 } },
            },
        },
        svg.Box { style = { flex = 1 } }, -- 占位推开
    },
}

local out = svg.render_svg(doc_b, { width = 500, height = 100 })
local f = io.open("output/4-b.svg", "w"); f:write(out); f:close()
print("wrote 4-b.svg")

-- ========== 示例 C：fill ==========
local doc_c = svg.Box {
    style = { width = 400, height = 60, direction = "row", padding = 5,
        background = "#ddd" },
    children = {
        svg.Box { style = { width = 80, background = "#e74c3c" } },
        svg.Box { style = { width = "fill", background = "#3498db" } }, -- 铺满剩余
        svg.Box { style = { width = 80, background = "#2ecc71" } },
    },
}

local out = svg.render_svg(doc_c, { width = 400, height = 60 })
local f = io.open("output/4-c.svg", "w"); f:write(out); f:close()
print("wrote 4-c.svg")