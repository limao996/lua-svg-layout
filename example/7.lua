-- 测试stack方向布局
package.path = package.path .. ";./?.lua;./?/init.lua"

local svg = require("svglayout")

-- ========== 示例 7：stack方向布局测试 ==========
local doc = svg.Box {
    style = {
        width = 400,
        background = "#f0f0f0",
        padding = 20,
        direction = "column",
        gap = 20,
    },
    children = {
        svg.Text {
            text = "Stack布局测试",
            style = {
                height = 40,
                font_size = 24,
                font_weight = "bold",
                color = "#222",
                text_align = "center",
            },
        },

        -- 测试1：基本stack布局
        svg.Box {
            style = {
                width = 360,
                height = 100,
                background = "#fff",
                border = "#ccc",
                border_width = 1,
                padding = 10,
                direction = "stack",
            },
            children = {
                svg.Rect {
                    style = {
                        width = "100%",
                        height = "100%",
                        fill = "#e3f2fd",
                        border_radius = 8,
                    }
                },
                svg.Circle {
                    style = {
                        width = 60,
                        height = 60,
                        fill = "#2196f3",
                    }
                },
                svg.Text {
                    text = "居中文本",
                    style = {
                        font_size = 18,
                        color = "#1565c0",
                        text_align = "center",
                    }
                }
            }
        },

        -- 测试2：带align属性的stack布局
        svg.Box {
            style = {
                width = 360,
                height = 100,
                background = "#fff",
                border = "#ccc",
                border_width = 1,
                padding = 10,
                direction = "stack",
                align = "center", -- 垂直居中
            },
            children = {
                svg.Rect {
                    style = {
                        width = "100%",
                        height = 40,
                        fill = "#f3e5f5",
                        border_radius = 6,
                    }
                },
                svg.Text {
                    text = "垂直居中文本",
                    style = {
                        font_size = 16,
                        color = "#7b1fa2",
                        text_align = "center",
                    }
                }
            }
        },

        -- 测试3：多层重叠
        svg.Box {
            style = {
                width = 360,
                height = 100,
                background = "#fff",
                border = "#ccc",
                border_width = 1,
                padding = 10,
                direction = "stack"
            },
            children = {
                svg.Image {
                    href = "https://api.mmp.cc/api/pcwallpaper?category=cartoon&type=jpg",
                    preserve_aspect_ratio = "xMidYMid slice",
                    style = { width = 360, height = 80, border_radius = 8, clip = true, blur = 10 },
                },
                svg.Rect {
                    style = {
                        width = 80,
                        height = 80,
                        fill = "#4caf50",
                        border_radius = 40,
                        opacity = 0.3,
                    }
                },
                svg.Rect {
                    style = {
                        width = 60,
                        height = 60,
                        fill = "#81c784",
                        border_radius = 30,
                        opacity = 0.3,
                    }
                },
                svg.Text {
                    text = "多层重叠",
                    style = {
                        font_size = 20,
                        color = "#1b5e20",
                        font_weight = "bold",
                        text_align = "center",
                    }
                }
            }
        },

        -- 测试4：与Group组件对比
        svg.Box {
            style = {
                direction = "row",
                gap = 20,
                height = 120,
            },
            children = {
                svg.Box {
                    style = {
                        width = 170,
                        height = 120,
                        background = "#fff5f5",
                        border = "#ffcdd2",
                        border_width = 1,
                        padding = 10,
                        direction = "stack",
                    },
                    children = {
                        svg.Rect {
                            style = {
                                width = "100%",
                                height = "100%",
                                fill = "#ffebee",
                            }
                        },
                        svg.Text {
                            text = "使用Stack",
                            style = {
                                font_size = 14,
                                color = "#c62828",
                                text_align = "center",
                            }
                        }
                    }
                },
                svg.Group {
                    style = {
                        width = 170,
                        height = 120,
                    },
                    children = {
                        svg.Rect {
                            style = {
                                width = 170,
                                height = 120,
                                fill = "#e8eaf6",
                            }
                        },
                        svg.Text {
                            text = "使用Group",
                            style = {
                                font_size = 14,
                                color = "#303f9f",
                                text_align = "center",
                            }
                        }
                    }
                }
            }
        }
    }
}

-- 渲染SVG
local svg_str = svg.render_svg(doc, { width = 400 })
local outfile = io.open("output/7-stack-test.svg", "w")
if outfile then
    outfile:write(svg_str)
    outfile:close()
    print("已生成 output/7-stack-test.svg")
else
    print("无法创建输出文件")
end
