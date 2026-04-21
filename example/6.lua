-- 功能分类示例：按功能模块组织的示例代码
package.path = package.path .. ";./?.lua;./?/init.lua"
local svg = require("svglayout")

print("=== SVG 布局库功能分类示例 ===")
print("每个示例独立运行，取消注释对应的代码块即可测试")

-- ========== 1. 基础布局示例 ==========
local function basic_layout_example()
    print("运行基础布局示例...")

    local doc = svg.Box {
        style = {
            width = 600, height = 400,
            background = "#f4f4f8",
            padding = 20,
            direction = "column",
            gap = 15,
        },
        children = {
            svg.Text {
                text = "基础布局示例",
                style = {
                    height = 40,
                    font_size = 24,
                    font_weight = "bold",
                    color = "#2c3e50",
                    text_align = "center",
                },
            },

            svg.Box {
                style = {
                    direction = "row",
                    gap = 10,
                    height = 100,
                    justify = "space-around",
                    align = "center",
                },
                children = {
                    svg.Rect {
                        style = {
                            width = 80, height = 80,
                            fill = "#e74c3c",
                            border_radius = 8,
                        },
                    },
                    svg.Circle {
                        style = {
                            width = 80, height = 80,
                            fill = "#3498db",
                        },
                    },
                    svg.Rect {
                        style = {
                            width = 80, height = 80,
                            fill = "#2ecc71",
                            border_radius = 8,
                        },
                    },
                },
            },

            svg.TextBlock {
                text = "这是一个基础布局示例，展示了 Box 容器、Text 文本、Rect 矩形和 Circle 圆形组件的使用。",
                line_height = 1.5,
                style = {
                    background = "#fff",
                    padding = 15,
                    border_radius = 8,
                    font_size = 14,
                    color = "#34495e",
                },
            },
        },
    }

    local out = svg.render_svg(doc, { width = 600, height = 400 })
    local f = io.open("output/6-basic.svg", "w"); f:write(out); f:close()
    print("已生成: output/6-basic.svg")
end

-- ========== 2. 弹性布局示例 ==========
local function flex_layout_example()
    print("运行弹性布局示例...")

    local doc = svg.Box {
        style = {
            width = 700, height = 300,
            background = "#ecf0f1",
            padding = 20,
            direction = "column",
            gap = 20,
        },
        children = {
            svg.Text {
                text = "弹性布局 (Flexbox) 示例",
                style = {
                    height = 30,
                    font_size = 20,
                    font_weight = "bold",
                    color = "#2c3e50",
                    text_align = "center",
                },
            },

            -- 示例 1: justify 属性
            svg.Box {
                style = {
                    direction = "column",
                    gap = 10,
                },
                children = {
                    svg.Text {
                        text = "justify 属性演示:",
                        style = {
                            font_size = 14,
                            color = "#34495e",
                            font_weight = "bold",
                        },
                    },

                    svg.Box {
                        style = {
                            direction = "row",
                            height = 60,
                            background = "#fff",
                            padding = 10,
                            border_radius = 6,
                        },
                        children = {
                            svg.Box { style = { width = 40, height = 40, background = "#e74c3c" } },
                            svg.Box { style = { width = 40, height = 40, background = "#3498db" } },
                            svg.Box { style = { width = 40, height = 40, background = "#2ecc71" } },
                        },
                    },

                    svg.Box {
                        style = {
                            direction = "row",
                            height = 60,
                            background = "#fff",
                            padding = 10,
                            border_radius = 6,
                            justify = "center",
                        },
                        children = {
                            svg.Box { style = { width = 40, height = 40, background = "#e74c3c" } },
                            svg.Box { style = { width = 40, height = 40, background = "#3498db" } },
                            svg.Box { style = { width = 40, height = 40, background = "#2ecc71" } },
                        },
                    },

                    svg.Box {
                        style = {
                            direction = "row",
                            height = 60,
                            background = "#fff",
                            padding = 10,
                            border_radius = 6,
                            justify = "space-between",
                        },
                        children = {
                            svg.Box { style = { width = 40, height = 40, background = "#e74c3c" } },
                            svg.Box { style = { width = 40, height = 40, background = "#3498db" } },
                            svg.Box { style = { width = 40, height = 40, background = "#2ecc71" } },
                        },
                    },
                },
            },

            -- 示例 2: flex 权重
            svg.Box {
                style = {
                    direction = "column",
                    gap = 10,
                },
                children = {
                    svg.Text {
                        text = "flex 权重演示:",
                        style = {
                            font_size = 14,
                            color = "#34495e",
                            font_weight = "bold",
                        },
                    },

                    svg.Box {
                        style = {
                            direction = "row",
                            height = 40,
                            gap = 5,
                        },
                        children = {
                            svg.Box { style = { flex = 1, background = "#e74c3c" } },
                            svg.Box { style = { flex = 2, background = "#3498db" } },
                            svg.Box { style = { flex = 1, background = "#2ecc71" } },
                        },
                    },
                },
            },
        },
    }

    local out = svg.render_svg(doc, { width = 700, height = 300 })
    local f = io.open("output/6-flex.svg", "w"); f:write(out); f:close()
    print("已生成: output/6-flex.svg")
end

-- ========== 3. 文本处理示例 ==========
local function text_example()
    print("运行文本处理示例...")

    local doc = svg.Box {
        style = {
            width = 600, height = 510,
            background = "#f8f9fa",
            padding = 25,
            direction = "column",
            gap = 20,
        },
        children = {
            svg.Text {
                text = "文本处理示例",
                style = {
                    height = 40,
                    font_size = 24,
                    font_weight = "bold",
                    color = "#2c3e50",
                    text_align = "center",
                },
            },

            -- 单行文本
            svg.Box {
                style = {
                    direction = "column",
                    gap = 10,
                },
                children = {
                    svg.Text {
                        text = "单行文本:",
                        style = {
                            font_size = 16,
                            color = "#34495e",
                            font_weight = "bold",
                        },
                    },

                    svg.Box {
                        style = {
                            direction = "row",
                            gap = 15,
                            height = 40,
                            align = "center",
                        },
                        children = {
                            svg.Text {
                                text = "左对齐",
                                style = {
                                    width = 100,
                                    font_size = 14,
                                    color = "#2c3e50",
                                    text_align = "left",
                                    background = "#fff",
                                    padding = 8,
                                    border_radius = 4,
                                },
                            },
                            svg.Text {
                                text = "居中",
                                style = {
                                    width = 100,
                                    font_size = 14,
                                    color = "#2c3e50",
                                    text_align = "center",
                                    background = "#fff",
                                    padding = 8,
                                    border_radius = 4,
                                },
                            },
                            svg.Text {
                                text = "右对齐",
                                style = {
                                    width = 100,
                                    font_size = 14,
                                    color = "#2c3e50",
                                    text_align = "right",
                                    background = "#fff",
                                    padding = 8,
                                    border_radius = 4,
                                },
                            },
                        },
                    },
                },
            },

            -- 多行文本
            svg.Box {
                style = {
                    direction = "column",
                    gap = 10,
                },
                children = {
                    svg.Text {
                        text = "多行文本 (TextBlock):",
                        style = {
                            font_size = 16,
                            color = "#34495e",
                            font_weight = "bold",
                        },
                    },

                    svg.TextBlock {
                        text = "这是多行文本示例。TextBlock 组件支持自动换行，适合处理长文本内容。" ..
                            "当文本宽度超过容器宽度时，会自动换行到下一行。" ..
                            "支持设置 line_height 属性来控制行间距，使排版更加美观。" ..
                            "混合中英文内容也能正确处理：Hello World! 你好世界！",
                        line_height = 1.6,
                        style = {
                            background = "#fff",
                            padding = 15,
                            border_radius = 8,
                            font_size = 14,
                            color = "#2c3e50",
                        },
                    },
                },
            },

            -- 字体样式
            svg.Box {
                style = {
                    direction = "column",
                    gap = 10,
                },
                children = {
                    svg.Text {
                        text = "字体样式:",
                        style = {
                            font_size = 16,
                            color = "#34495e",
                            font_weight = "bold",
                        },
                    },

                    svg.Box {
                        style = {
                            direction = "column",
                            gap = 8,
                            background = "#fff",
                            padding = 15,
                            border_radius = 8,
                        },
                        children = {
                            svg.Text {
                                text = "正常字体 - 14px",
                                style = {
                                    font_size = 14,
                                    color = "#2c3e50",
                                },
                            },
                            svg.Text {
                                text = "加粗字体 - bold",
                                style = {
                                    font_size = 14,
                                    color = "#2c3e50",
                                    font_weight = "bold",
                                },
                            },
                            svg.Text {
                                text = "大号字体 - 18px",
                                style = {
                                    font_size = 18,
                                    color = "#e74c3c",
                                },
                            },
                            svg.Text {
                                text = "小号字体 - 12px",
                                style = {
                                    font_size = 12,
                                    color = "#7f8c8d",
                                },
                            },
                        },
                    },
                },
            },
        },
    }

    local out = svg.render_svg(doc, { width = 600, height = 510 })
    local f = io.open("output/6-text.svg", "w"); f:write(out); f:close()
    print("已生成: output/6-text.svg")
end

-- ========== 4. 视觉特效示例 ==========
local function visual_effects_example()
    print("运行视觉特效示例...")

    local doc = svg.Box {
        style = {
            width = 800, height = 400,
            background = "#2c3e50",
            padding = 30,
            direction = "column",
            gap = 25,
        },
        children = {
            svg.Text {
                text = "视觉特效示例",
                style = {
                    height = 40,
                    font_size = 28,
                    font_weight = "bold",
                    color = "#fff",
                    text_align = "center",
                    shadow = { dx = 2, dy = 2, blur = 4, color = "#000", opacity = 0.5 },
                },
            },

            svg.Box {
                style = {
                    direction = "row",
                    gap = 20,
                    height = 280,
                    justify = "space-around",
                    align = "center",
                },
                children = {
                    -- 阴影效果
                    svg.Box {
                        style = {
                            width = 120, height = 120,
                            background = "#e74c3c",
                            border_radius = 15,
                            shadow = { dx = 8, dy = 8, blur = 12, color = "#000", opacity = 0.4 },
                        },
                        children = {
                            svg.Text {
                                text = "阴影",
                                style = {
                                    height = 120,
                                    font_size = 20,
                                    color = "#fff",
                                    text_align = "center",
                                    font_weight = "bold",
                                },
                            },
                        },
                    },

                    -- 模糊效果
                    svg.Box {
                        style = {
                            width = 120, height = 120,
                            background = "#3498db",
                            border_radius = 15,
                            blur = 15,
                        },
                        children = {
                            svg.Text {
                                text = "模糊",
                                style = {
                                    height = 120,
                                    font_size = 20,
                                    color = "#fff",
                                    text_align = "center",
                                    font_weight = "bold",
                                },
                            },
                        },
                    },

                    -- 阴影+模糊组合
                    svg.Box {
                        style = {
                            width = 120, height = 120,
                            background = "#2ecc71",
                            border_radius = 15,
                            shadow = { dx = 6, dy = 6, blur = 10, color = "#000", opacity = 0.3 },
                            blur = 5,
                        },
                        children = {
                            svg.Text {
                                text = "组合",
                                style = {
                                    height = 120,
                                    font_size = 20,
                                    color = "#fff",
                                    text_align = "center",
                                    font_weight = "bold",
                                },
                            },
                        },
                    },

                    -- 透明度
                    svg.Box {
                        style = {
                            width = 120, height = 120,
                            background = "#9b59b6",
                            border_radius = 15,
                            opacity = 0.3,
                        },
                        children = {
                            svg.Text {
                                text = "透明",
                                style = {
                                    height = 120,
                                    font_size = 20,
                                    color = "#fff",
                                    text_align = "center",
                                    font_weight = "bold",
                                },
                            },
                        },
                    },
                },
            },

            svg.Text {
                text = "支持阴影、模糊、透明度等多种视觉特效",
                style = {
                    height = 30,
                    font_size = 16,
                    color = "#bdc3c7",
                    text_align = "center",
                },
            },
        },
    }

    local out = svg.render_svg(doc, { width = 800, height = 400 })
    local f = io.open("output/6-effects.svg", "w"); f:write(out); f:close()
    print("已生成: output/6-effects.svg")
end

-- ========== 5. 渐变和图案示例 ==========
local function gradient_pattern_example()
    print("运行渐变和图案示例...")

    -- 创建渐变
    local linear_grad = svg.LinearGradient {
        x1 = "0%", y1 = "0%", x2 = "100%", y2 = "0%",
        stops = {
            { offset = 0,   color = "#667eea" },
            { offset = 0.5, color = "#764ba2" },
            { offset = 1,   color = "#f093fb" },
        },
    }

    local radial_grad = svg.RadialGradient {
        stops = {
            { offset = 0, color = "#ff9a9e" },
            { offset = 1, color = "#fad0c4" },
        },
    }

    -- 创建图案
    local stripe_pattern = svg.Pattern {
        width = 20, height = 20,
        content = [[
            <rect width="20" height="20" fill="#3498db"/>
            <line x1="0" y1="0" x2="20" y2="20" stroke="#fff" stroke-width="2"/>
            <line x1="20" y1="0" x2="0" y2="20" stroke="#fff" stroke-width="2"/>
        ]],
    }

    local dot_pattern = svg.Pattern {
        width = 10, height = 10,
        content = '<circle cx="5" cy="5" r="2" fill="#e74c3c"/>',
    }

    local doc = svg.Box {
        style = {
            width = 700, height = 600,
            background = "#f5f7fa",
            padding = 25,
            direction = "column",
            gap = 20,
        },
        children = {
            svg.Text {
                text = "渐变和图案示例",
                style = {
                    height = 40,
                    font_size = 24,
                    font_weight = "bold",
                    color = "#2c3e50",
                    text_align = "center",
                },
            },

            svg.Box {
                style = {
                    direction = "row",
                    gap = 20,
                    height = 180,
                    justify = "space-around",
                    align = "center",
                },
                children = {
                    -- 线性渐变
                    svg.Rect {
                        style = {
                            width = 150, height = 150,
                            fill = linear_grad,
                            border_radius = 10,
                            shadow = { dx = 4, dy = 4, blur = 8, color = "#000", opacity = 0.2 },
                        },
                    },

                    -- 径向渐变
                    svg.Circle {
                        style = {
                            width = 150, height = 150,
                            fill = radial_grad,
                            shadow = { dx = 4, dy = 4, blur = 8, color = "#000", opacity = 0.2 },
                        },
                    },
                },
            },

            svg.Box {
                style = {
                    direction = "row",
                    gap = 20,
                    height = 180,
                    justify = "space-around",
                    align = "center",
                },
                children = {
                    -- 条纹图案
                    svg.Rect {
                        style = {
                            width = 150, height = 150,
                            fill = stripe_pattern,
                            border_radius = 10,
                            stroke = "#2980b9",
                            stroke_width = 2,
                            shadow = { dx = 4, dy = 4, blur = 8, color = "#000", opacity = 0.2 },
                        },
                    },

                    -- 圆点图案
                    svg.Rect {
                        style = {
                            width = 150, height = 150,
                            fill = dot_pattern,
                            border_radius = 10,
                            stroke = "#c0392b",
                            stroke_width = 2,
                            shadow = { dx = 4, dy = 4, blur = 8, color = "#000", opacity = 0.2 },
                        },
                    },
                },
            },

            svg.TextBlock {
                text = "渐变和图案可以应用于任何支持 fill 或 background 属性的组件。" ..
                    "LinearGradient 创建线性渐变，RadialGradient 创建径向渐变，Pattern 创建自定义图案。" ..
                    "这些对象可以直接传递给样式属性，实现丰富的视觉效果。",
                line_height = 1.6,
                style = {
                    background = "#fff",
                    padding = 15,
                    border_radius = 8,
                    font_size = 14,
                    color = "#34495e",
                },
            },
        },
    }

    local out = svg.render_svg(doc, { width = 700, height = 600 })
    local f = io.open("output/6-gradient.svg", "w"); f:write(out); f:close()
    print("已生成: output/6-gradient.svg")
end

-- ========== 6. 自定义组件示例 ==========
local function custom_components_example()
    print("运行自定义组件示例...")

    -- 定义自定义组件
    local Alert = svg.define(function(props)
        local type_color = {
            info = "#3498db",
            success = "#2ecc71",
            warning = "#f39c12",
            error = "#e74c3c",
        }

        return svg.Box {
            style = {
                background = type_color[props.type or "info"],
                border_radius = 8,
                padding = 16,
                direction = "row",
                gap = 12,
                align = "center",
            },
            children = {
                svg.Circle {
                    style = {
                        width = 24, height = 24,
                        background = "#fff",
                        opacity = 0.9,
                    },
                    children = {
                        svg.Text {
                            text = props.icon or "i",
                            style = {
                                height = 24,
                                font_size = 14,
                                color = type_color[props.type or "info"],
                                text_align = "center",
                                font_weight = "bold",
                            },
                        },
                    },
                },

                svg.Box {
                    style = {
                        flex = 1,
                        direction = "column",
                        gap = 4,
                    },
                    children = {
                        svg.Text {
                            text = props.title or "提示",
                            style = {
                                font_size = 16,
                                color = "#fff",
                                font_weight = "bold",
                            },
                        },

                        svg.TextBlock {
                            text = props.message or "这是提示信息",
                            line_height = 1.4,
                            style = {
                                font_size = 14,
                                color = "rgba(255,255,255,0.9)",
                            },
                        },
                    },
                },
            },
        }
    end)

    local ProgressBar = svg.define(function(props)
        local percent = props.percent or 0
        local color = props.color or "#3498db"

        return svg.Box {
            style = {
                direction = "column",
                gap = 6,
            },
            children = {
                svg.Box {
                    style = {
                        direction = "row",
                        justify = "space-between",
                        align = "center",
                    },
                    children = {
                        svg.Text {
                            text = props.label or "进度",
                            style = {
                                font_size = 14,
                                color = "#2c3e50",
                            },
                        },
                        svg.Text {
                            text = string.format("%d%%", percent),
                            style = {
                                font_size = 14,
                                color = "#7f8c8d",
                                font_weight = "bold",
                            },
                        },
                    },
                },

                svg.Box {
                    style = {
                        height = 10,
                        background = "#ecf0f1",
                        border_radius = 5,
                        clip = true,
                    },
                    children = {
                        svg.Rect {
                            style = {
                                width = percent .. "%",
                                height = "100%",
                                fill = color,
                            },
                        },
                    },
                },
            },
        }
    end)

    local doc = svg.Box {
        style = {
            width = 600, height = 850,
            background = "#f8f9fa",
            padding = 25,
            direction = "column",
            gap = 20,
        },
        children = {
            svg.Text {
                text = "自定义组件示例",
                style = {
                    height = 40,
                    font_size = 24,
                    font_weight = "bold",
                    color = "#2c3e50",
                    text_align = "center",
                },
            },

            -- 使用自定义组件
            Alert {
                type = "info",
                title = "信息提示",
                message = "这是一个信息类型的提示组件，使用 svg.define() 定义。",
                icon = "i",
            },

            Alert {
                type = "success",
                title = "操作成功",
                message = "任务已完成，所有数据已保存到服务器。",
                icon = "✓",
            },

            Alert {
                type = "warning",
                title = "警告",
                message = "磁盘空间不足，请及时清理不必要的文件。",
                icon = "!",
            },

            Alert {
                type = "error",
                title = "错误",
                message = "无法连接到服务器，请检查网络连接后重试。",
                icon = "×",
            },

            svg.Box {
                style = {
                    direction = "column",
                    gap = 15,
                    background = "#fff",
                    padding = 20,
                    border_radius = 8,
                },
                children = {
                    svg.Text {
                        text = "进度条组件:",
                        style = {
                            font_size = 16,
                            color = "#2c3e50",
                            font_weight = "bold",
                            margin = { bottom = 10 },
                        },
                    },

                    ProgressBar { label = "项目完成度", percent = 75, color = "#3498db" },
                    ProgressBar { label = "代码覆盖率", percent = 92, color = "#2ecc71" },
                    ProgressBar { label = "测试通过率", percent = 88, color = "#f39c12" },
                    ProgressBar { label = "文档完整度", percent = 60, color = "#9b59b6" },
                },
            },

            svg.TextBlock {
                text = "自定义组件通过 svg.define() 函数创建，可以像内置组件一样使用。" ..
                    "组件可以接收 props 参数，根据参数动态生成不同的内容和样式。" ..
                    "这使得代码更加模块化和可复用。",
                line_height = 1.6,
                style = {
                    background = "#fff",
                    padding = 15,
                    border_radius = 8,
                    font_size = 14,
                    color = "#34495e",
                },
            },
        },
    }

    local out = svg.render_svg(doc, { width = 600, height = 850 })
    local f = io.open("output/6-custom.svg", "w"); f:write(out); f:close()
    print("已生成: output/6-custom.svg")
end

-- ========== 主程序：选择要运行的示例 ==========
print("\n请选择要运行的示例 (输入数字):")
print("1. 基础布局示例")
print("2. 弹性布局示例")
print("3. 文本处理示例")
print("4. 视觉特效示例")
print("5. 渐变和图案示例")
print("6. 自定义组件示例")
print("7. 运行所有示例")
print("0. 退出")

-- 注释掉交互部分，默认运行所有示例
-- 在实际使用中，可以取消注释以下代码实现交互选择

-- 默认运行所有示例
print("\n默认运行所有示例...\n")

basic_layout_example()
print()
flex_layout_example()
print()
text_example()
print()
visual_effects_example()
print()
gradient_pattern_example()
print()
custom_components_example()

print("\n=== 所有示例生成完成 ===")
print("生成的 SVG 文件保存在 output/ 目录下：")
print("  6-basic.svg    - 基础布局示例")
print("  6-flex.svg     - 弹性布局示例")
print("  6-text.svg     - 文本处理示例")
print("  6-effects.svg  - 视觉特效示例")
print("  6-gradient.svg - 渐变和图案示例")
print("  6-custom.svg   - 自定义组件示例")
