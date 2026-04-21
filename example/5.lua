-- 综合示例：展示 SVG 布局库的所有高级功能
package.path = package.path .. ";./?.lua;./?/init.lua"
local svg = require("svglayout")

-- ========== 示例 A：Path 和 Line 组件 ==========
local doc_a = svg.Box {
    style = {
        width = 600, height = 300,
        background = "#f8f9fa",
        padding = 20,
        direction = "column",
        gap = 15,
    },
    children = {
        svg.Text {
            text = "Path 和 Line 组件演示",
            style = {
                height = 30,
                font_size = 20,
                font_weight = "bold",
                color = "#2c3e50",
                text_align = "center",
            },
        },

        svg.Box {
            style = {
                direction = "row",
                gap = 20,
                height = 200,
                justify = "space-around",
                align = "center",
            },
            children = {
                -- Path 组件：贝塞尔曲线
                svg.Path {
                    d = "M10,80 Q95,10 180,80 T350,80",
                    style = {
                        stroke = "#e74c3c",
                        stroke_width = 3,
                        fill = "none",
                    },
                },

                -- Line 组件：交叉线
                svg.Group {
                    style = {
                        transform = "translate(0, 0)",
                    },
                    children = {
                        svg.Line {
                            x1 = 0, y1 = 0,
                            x2 = 100, y2 = 100,
                            style = {
                                stroke = "#3498db",
                                stroke_width = 2,
                            },
                        },
                        svg.Line {
                            x1 = 100, y1 = 0,
                            x2 = 0, y2 = 100,
                            style = {
                                stroke = "#2ecc71",
                                stroke_width = 2,
                            },
                        },
                    },
                },

                -- 复杂 Path：星星形状
                svg.Path {
                    d = "M50,5 L61,37 L95,37 L68,57 L79,89 L50,70 L21,89 L32,57 L5,37 L39,37 Z",
                    style = {
                        fill = "#f39c12",
                        stroke = "#d35400",
                        stroke_width = 2,
                    },
                },
            },
        },
    },
}

local out_a = svg.render_svg(doc_a, { width = 600, height = 300 })
local f_a = io.open("output/5-a.svg", "w"); f_a:write(out_a); f_a:close()
print("wrote 5-a.svg")

-- ========== 示例 B：Group 组件和变换 ==========
local doc_b = svg.Box {
    style = {
        width = 500, height = 400,
        background = "#ecf0f1",
        padding = 20,
        direction = "column",
        gap = 10,
    },
    children = {
        svg.Text {
            text = "Group 组件和变换演示",
            style = {
                height = 30,
                font_size = 20,
                font_weight = "bold",
                color = "#2c3e50",
                text_align = "center",
            },
        },

        -- 使用 Group 进行整体变换
        svg.Group {
            style = {
                transform = "translate(100, 50) rotate(15)",
            },
            children = {
                svg.Rect {
                    style = {
                        width = 200, height = 100,
                        fill = "#3498db",
                        border_radius = 10,
                        opacity = 0.8,
                    },
                },
                svg.Text {
                    text = "旋转的组",
                    style = {
                        height = 100,
                        font_size = 18,
                        color = "#fff",
                        text_align = "center",
                        font_weight = "bold",
                    },
                },
            },
        },

        -- 嵌套 Group
        svg.Group {
            style = {
                transform = "translate(250, 200)",
            },
            children = {
                svg.Group {
                    style = {
                        transform = "scale(0.8)",
                    },
                    children = {
                        svg.Circle {
                            style = {
                                width = 80, height = 80,
                                fill = "#e74c3c",
                            },
                        },
                        svg.Text {
                            text = "嵌套组",
                            style = {
                                height = 80,
                                font_size = 16,
                                color = "#fff",
                                text_align = "center",
                            },
                        },
                    },
                },
            },
        },

        -- 多个 Group 组合
        svg.Box {
            style = {
                direction = "row",
                gap = 20,
                height = 100,
                justify = "center",
                align = "center",
            },
            children = {
                svg.Group {
                    style = {
                        transform = "skewX(10)",
                    },
                    children = {
                        svg.Rect {
                            style = {
                                width = 60, height = 60,
                                fill = "#9b59b6",
                            },
                        },
                    },
                },
                svg.Group {
                    style = {
                        transform = "skewY(-10)",
                    },
                    children = {
                        svg.Rect {
                            style = {
                                width = 60, height = 60,
                                fill = "#1abc9c",
                            },
                        },
                    },
                },
            },
        },
    },
}

local out_b = svg.render_svg(doc_b, { width = 500, height = 400 })
local f_b = io.open("output/5-b.svg", "w"); f_b:write(out_b); f_b:close()
print("wrote 5-b.svg")

-- ========== 示例 C：复杂嵌套布局（仪表板） ==========
-- 定义仪表板卡片组件
local DashboardCard = svg.define(function(props)
    return svg.Box {
        style = {
            background = "#fff",
            border = "#ddd",
            border_width = 1,
            border_radius = 8,
            padding = 16,
            direction = "column",
            gap = 12,
            shadow = { dx = 2, dy = 3, blur = 6, color = "#000", opacity = 0.1 },
        },
        children = {
            svg.Box {
                style = {
                    direction = "row",
                    justify = "space-between",
                    align = "center",
                    height = 24,
                },
                children = {
                    svg.Text {
                        text = props.title or "标题",
                        style = {
                            font_size = 16,
                            font_weight = "bold",
                            color = "#2c3e50",
                        },
                    },
                    svg.Text {
                        text = props.value or "0",
                        style = {
                            font_size = 20,
                            font_weight = "bold",
                            color = props.color or "#3498db",
                        },
                    },
                },
            },

            svg.TextBlock {
                text = props.description or "描述文字",
                line_height = 1.5,
                style = {
                    font_size = 14,
                    color = "#7f8c8d",
                },
            },

            -- 进度条
            svg.Box {
                style = {
                    height = 8,
                    background = "#ecf0f1",
                    border_radius = 4,
                    clip = true,
                },
                children = {
                    svg.Rect {
                        style = {
                            width = (props.progress or 0.5) * 100 .. "%",
                            height = "100%",
                            fill = props.color or "#3498db",
                        },
                    },
                },
            },
        },
    }
end)

-- 定义图表组件
local SimpleChart = svg.define(function(props)
    local data = props.data or { 30, 50, 80, 60, 90, 40, 70 }
    local max_val = math.max(table.unpack(data))
    local bar_width = 20
    local gap = 10
    local total_width = #data * (bar_width + gap) - gap

    local bars = {}
    for i, value in ipairs(data) do
        local height = (value / max_val) * 100
        bars[#bars + 1] = svg.Group {
            style = {
                transform = string.format("translate(%d, 0)", (i - 1) * (bar_width + gap)),
            },
            children = {
                svg.Rect {
                    style = {
                        width = bar_width,
                        height = height,
                        fill = props.color or "#3498db",
                        y = 100 - height, -- SVG 坐标系 y 向下
                    },
                },
                svg.Text {
                    text = tostring(value),
                    style = {
                        font_size = 10,
                        color = "#2c3e50",
                        text_align = "center",
                        y = 90 - height,
                        width = bar_width,
                    },
                },
            },
        }
    end

    return svg.Box {
        style = {
            direction = "column",
            gap = 8,
        },
        children = {
            svg.Text {
                text = props.title or "图表",
                style = {
                    font_size = 14,
                    font_weight = "bold",
                    color = "#2c3e50",
                },
            },
            svg.Box {
                style = {
                    height = 120,
                    padding = { top = 10, bottom = 20 },
                },
                children = {
                    svg.Group {
                        style = {
                            direction = "row",
                            transform = "translate(0, 0)",
                        },
                        children = bars,
                    },
                },
            },
        },
    }
end)

-- 创建仪表板
local dashboard = svg.Box {
    style = {
        width = 900, height = 600,
        background = "#f5f7fa",
        padding = 24,
        direction = "column",
        gap = 20,
    },
    children = {
        -- 标题栏
        svg.Box {
            style = {
                direction = "row",
                justify = "space-between",
                align = "center",
                height = 50,
            },
            children = {
                svg.Text {
                    text = "数据分析仪表板",
                    style = {
                        font_size = 24,
                        font_weight = "bold",
                        color = "#2c3e50",
                    },
                },
                svg.Text {
                    text = os.date("%Y-%m-%d"),
                    style = {
                        font_size = 14,
                        color = "#7f8c8d",
                    },
                },
            },
        },

        -- 卡片行
        svg.Box {
            style = {
                direction = "row",
                gap = 20,
                height = 140,
            },
            children = {
                DashboardCard {
                    title = "用户总数",
                    value = "1,234",
                    description = "本月新增用户 128 人",
                    progress = 0.75,
                    color = "#3498db",
                },
                DashboardCard {
                    title = "订单数量",
                    value = "456",
                    description = "同比增长 12.5%",
                    progress = 0.6,
                    color = "#2ecc71",
                },
                DashboardCard {
                    title = "销售额",
                    value = "¥89,200",
                    description = "完成月度目标 85%",
                    progress = 0.85,
                    color = "#e74c3c",
                },
                DashboardCard {
                    title = "转化率",
                    value = "3.2%",
                    description = "行业平均 2.8%",
                    progress = 0.45,
                    color = "#9b59b6",
                },
            },
        },

        -- 图表区域
        svg.Box {
            style = {
                direction = "row",
                gap = 20,
                flex = 1, -- 占据剩余空间
            },
            children = {
                svg.Box {
                    style = {
                        flex = 2,
                        background = "#fff",
                        border_radius = 8,
                        padding = 20,
                        shadow = { dx = 1, dy = 2, blur = 4, color = "#000", opacity = 0.05 },
                    },
                    children = {
                        SimpleChart {
                            title = "月度销售趋势",
                            data = { 45, 60, 75, 55, 80, 65, 90, 100, 21, 16 },
                            color = "#3498db",
                        },
                    },
                },

                svg.Box {
                    style = {
                        flex = 1,
                        direction = "column",
                        gap = 20,
                    },
                    children = {
                        svg.Box {
                            style = {
                                height = "fill",
                                background = "#fff",
                                border_radius = 8,
                                padding = 20,
                                shadow = { dx = 1, dy = 2, blur = 4, color = "#000", opacity = 0.05 },
                            },
                            children = {
                                svg.Text {
                                    text = "任务列表",
                                    style = {
                                        font_size = 16,
                                        font_weight = "bold",
                                        color = "#2c3e50",
                                        margin = { bottom = 12 },
                                    },
                                },
                                svg.Builder {
                                    style = { direction = "column", gap = 8 },
                                    build = function(ctx)
                                        local tasks = {
                                            { text = "完成季度报告", done = true },
                                            { text = "用户反馈分析", done = true },
                                            { text = "系统性能优化", done = false },
                                            { text = "新功能开发", done = false },
                                            { text = "团队培训", done = false },
                                        }

                                        local items = {}
                                        for i, task in ipairs(tasks) do
                                            items[#items + 1] = svg.Box {
                                                style = {
                                                    direction = "row",
                                                    gap = 8,
                                                    align = "center",
                                                    height = 24,
                                                },
                                                children = {
                                                    svg.Circle {
                                                        style = {
                                                            width = 12, height = 12,
                                                            fill = task.done and "#2ecc71" or "#ecf0f1",
                                                            stroke = task.done and "#27ae60" or "#bdc3c7",
                                                            stroke_width = 2,
                                                        },
                                                    },
                                                    svg.Text {
                                                        text = task.text,
                                                        style = {
                                                            font_size = 14,
                                                            color = task.done and "#7f8c8d" or "#2c3e50",
                                                            text_decoration = task.done and "line-through" or "none",
                                                        },
                                                    },
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
        },

        -- 页脚
        svg.Box {
            style = {
                direction = "row",
                justify = "space-between",
                align = "center",
                height = 40,
                border = { top = "#ddd", top_width = 1 },
                padding = { top = 10 },
            },
            children = {
                svg.Text {
                    text = "SVG 布局库生成",
                    style = {
                        font_size = 12,
                        color = "#95a5a6",
                    },
                },
                svg.Text {
                    text = "数据更新时间: " .. os.date("%H:%M:%S"),
                    style = {
                        font_size = 12,
                        color = "#95a5a6",
                    },
                },
            },
        },
    },
}

local out_c = svg.render_svg(dashboard, { width = 900, height = 600 })
local f_c = io.open("output/5-c.svg", "w"); f_c:write(out_c); f_c:close()
print("wrote 5-c.svg")

-- ========== 示例 D：自定义拆分协议 ==========
-- 创建支持拆分的自定义组件
local SplitableComponent
SplitableComponent = svg.define(function(props)
    local node = {
        type = "splitable-component",
        text = props.text or "默认文本",
        parts = props.parts or { "第一部分", "第二部分", "第三部分" },
        style = props.style or {},
    }

    -- 测量组件尺寸
    function node:_measure(hint_w, hint_h)
        -- 每个部分高度 30px，加上间距
        local part_height = 30
        local gap = 5
        local total_height = #self.parts * (part_height + gap) - gap
        return 200, total_height -- 固定宽度 200，动态高度
    end

    -- 渲染组件
    function node:_render(ctx)
        local b = self._box
        local parts = {}

        for i, part_text in ipairs(self.parts) do
            local y = (i - 1) * 35 -- 30px 高度 + 5px 间距
            parts[#parts + 1] = string.format(
                '<rect x="%d" y="%d" width="%d" height="30" fill="%s" rx="4"/>',
                b.x, b.y + y, b.w, i % 2 == 0 and "#a29bfe" or "#6c5ce7"
            )
            parts[#parts + 1] = string.format(
                '<text x="%d" y="%d" font-size="14" fill="#fff" text-anchor="middle" dominant-baseline="middle">%s</text>',
                b.x + b.w / 2, b.y + y + 15, part_text
            )
        end

        return table.concat(parts, "\n")
    end

    -- 实现拆分协议
    function node:_split(avail_h)
        if #self.parts <= 1 then
            return nil -- 无法拆分
        end

        local part_height = 30
        local gap = 5
        local max_parts = math.floor(avail_h / (part_height + gap))

        if max_parts >= #self.parts then
            return nil -- 全部能放下，无需拆分
        end

        if max_parts <= 0 then
            return nil -- 连一个部分都放不下
        end

        -- 创建第一部分
        local first_parts = {}
        for i = 1, max_parts do
            first_parts[i] = self.parts[i]
        end

        -- 创建剩余部分
        local rest_parts = {}
        for i = max_parts + 1, #self.parts do
            rest_parts[#rest_parts + 1] = self.parts[i]
        end

        local first_node = SplitableComponent {
            text = self.text .. " (第1部分)",
            parts = first_parts,
            style = self.style,
        }

        local rest_node = SplitableComponent {
            text = self.text .. " (剩余部分)",
            parts = rest_parts,
            style = self.style,
        }

        return first_node, rest_node
    end

    -- 标记为可拆分
    node._splittable = true

    return node
end)

-- 测试拆分协议
local split_test = svg.Box {
    style = {
        width = 400, height = 150, -- 较小的高度以触发拆分
        padding = 20,
        background = "#f8f9fa",
        direction = "column",
        gap = 10,
    },
    children = {
        svg.Text {
            text = "自定义拆分协议演示",
            style = {
                height = 30,
                font_size = 18,
                font_weight = "bold",
                color = "#2c3e50",
                text_align = "center",
            },
        },
        SplitableComponent {
            text = "可拆分组件",
            parts = { "项目A", "项目B", "项目C", "项目D", "项目E", "项目F", "项目G", "项目H" },
            style = { margin = { top = 10 } },
        },
    },
}

-- 渲染分页以测试拆分
local pages = svg.render_pages(split_test, { width = 400, height = 150 })
for i, page in ipairs(pages) do
    local f_d = io.open(string.format("output/5-d_page_%d.svg", i), "w")
    f_d:write(page); f_d:close()
end
print(string.format("wrote %d pages of 5-d", #pages))

-- ========== 示例 E：性能测试 - 大量数据渲染 ==========
local perf_test = svg.Box {
    style = {
        width = 800, height = 600,
        padding = 20,
        background = "#fff",
        direction = "column",
        gap = 2,
    },
    children = {
        svg.Text {
            text = "性能测试: 1000 个数据项",
            style = {
                height = 40,
                font_size = 20,
                font_weight = "bold",
                color = "#2c3e50",
                text_align = "center",
                margin = { bottom = 10 },
            },
        },

        svg.Builder {
            style = { direction = "column", gap = 1 },
            build = function(ctx)
                local start_time = os.clock()
                local items = {}

                -- 生成 1000 个数据项
                for i = 1, 1000 do
                    local value = math.random(1, 100)
                    local width_percent = value .. "%"

                    items[#items + 1] = svg.Box {
                        style = {
                            direction = "row",
                            align = "center",
                            height = 20,
                            gap = 10,
                        },
                        children = {
                            svg.Text {
                                text = string.format("项目 %04d", i),
                                style = {
                                    width = 80,
                                    font_size = 10,
                                    color = "#34495e",
                                },
                            },

                            svg.Box {
                                style = {
                                    flex = 1,
                                    height = 12,
                                    background = "#ecf0f1",
                                    border_radius = 6,
                                    clip = true,
                                },
                                children = {
                                    svg.Rect {
                                        style = {
                                            width = width_percent,
                                            height = "100%",
                                            fill = value > 80 and "#e74c3c" or
                                                value > 50 and "#f39c12" or
                                                value > 30 and "#3498db" or "#2ecc71",
                                        },
                                    },
                                },
                            },

                            svg.Text {
                                text = string.format("%d%%", value),
                                style = {
                                    width = 40,
                                    font_size = 10,
                                    color = "#7f8c8d",
                                    text_align = "right",
                                },
                            },
                        },
                    }
                end

                local end_time = os.clock()
                print(string.format("生成 1000 个数据项耗时: %.3f 秒", end_time - start_time))

                return items
            end,
        },
    },
}

local perf_start = os.clock()
local out_e = svg.render_svg(perf_test, { width = 800, height = 600 })
local perf_end = os.clock()
local f_e = io.open("output/5-e.svg", "w"); f_e:write(out_e); f_e:close()
print(string.format("wrote 5-e.svg (渲染耗时: %.3f 秒)", perf_end - perf_start))

print("\n=== 综合示例完成 ===")
print("生成的 SVG 文件保存在 output/ 目录下：")
print("  5-a.svg  - Path 和 Line 组件演示")
print("  5-b.svg  - Group 组件和变换演示")
print("  5-c.svg  - 复杂仪表板示例")
print("  5-d_page_*.svg - 自定义拆分协议演示")
print("  5-e.svg  - 性能测试 (1000 个数据项)")
