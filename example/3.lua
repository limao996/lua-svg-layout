-- shadow_test.lua
package.path = package.path .. ";./?.lua;./?/init.lua"
local svg = require("svglayout")

local doc = svg.Box {
    style = {
        width = 760, height = 260, padding = 30,
        background = "#f0f4f8",
        direction = "row", gap = 24, align = "center",
    },
    children = {
        -- 实心 + 阴影
        svg.Box {
            style = {
                width = 140, height = 140,
                background = "#e74c3c", border_radius = 12,
                shadow = { dx = 4, dy = 6, blur = 8, color = "#000", opacity = 0.4 },
            },
            children = {
                svg.Text {
                    text = "Shadow",
                    style = { height = 140, font_size = 18, color = "#fff",
                              font_weight = "bold", text_align = "center" },
                },
            },
        },
        -- 仅描边 + 阴影（验证对 fill=none 也生效）
        svg.Box {
            style = {
                width = 140, height = 140,
                border = "#3498db", border_width = 3, border_radius = 12,
                shadow = { dx = 3, dy = 3, blur = 5, color = "#3498db", opacity = 0.6 },
            },
        },
        -- 模糊
        svg.Box {
            style = {
                width = 140, height = 140,
                background = "#2ecc71", border_radius = 12,
                blur = 20,
            },
        },
        -- 阴影 + 模糊
        svg.Box {
            style = {
                width = 140, height = 140,
                background = "#f39c12", border_radius = 12,
                blur = 1.5,
                shadow = { dx = 2, dy = 4, blur = 6, color = "#000", opacity = 0.5 },
            },
        },
    },
}

local out = svg.render_svg(doc, { width = 760, height = 260 })
local f = io.open("output/3.svg", "w"); f:write(out); f:close()
print("wrote 3.svg")
