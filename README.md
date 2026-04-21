# Lua SVG 布局库

![Lua 5.4](https://img.shields.io/badge/Lua-5.4-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)
![Vibe Coding](https://img.shields.io/badge/Vibe-Coding-brightgreen.svg)

一个纯 Lua 5.4 库，用于声明式 SVG 布局和渲染，**零外部依赖**，**项目完全使用AI开发**
> **该文档由AI编写**。

## ✨ 特性亮点

### 🎨 强大的布局系统
- **完整的盒模型布局系统**，支持类 Flexbox 布局
- **声明式语法**，使用嵌套组件树构建界面
- **自动分页系统**，支持拆分协议进行精细控制

### 🧩 丰富的内置组件
- **文本组件**：支持字体、对齐、多行文本（通过 `TextBlock`）
- **形状组件**：矩形、圆形、线条、路径
- **容器组件**：Box（弹性容器）、Group（SVG 组）
- **图像组件**：支持宽高比控制
- **原始 SVG 嵌入**：直接嵌入 SVG 代码

### ⚡ 高级功能
- **Builder 组件**：动态内容生成，支持回调模式
- **渐变和图案支持**：线性渐变、径向渐变、自定义图案
- **视觉特效**：模糊、阴影作为标准组件属性
- **自定义组件扩展**：通过 `define()` 和 `register()` API
- **完整的 EmmyLua 注解**：提供 IDE 智能提示支持

### 🌍 国际化支持
- **UTF-8 完全支持**：正确处理 CJK 和混合脚本文本
- **内存高效**：尽可能使用惰性计算
- **协议化扩展**：实现 `_measure`、`_split`、`_register` 协议

## 🚀 快速开始

### 安装

将 `svglayout` 目录放入 Lua 路径，或调整 `package.path`：

```lua
package.path = package.path .. ";./svglayout/?.lua"
local svg = require("svglayout")
```

### 第一个示例

```lua
local svg = require("svglayout")

-- 创建一个简单的文档
local doc = svg.Box {
    style = {
        width = 800,
        height = 400,
        background = "#f4f4f8",
        padding = 24,
        direction = "column",  -- 垂直布局
        gap = 16,              -- 子元素间距
    },
    children = {
        svg.Text {
            text = "你好，SVG 布局库！",
            style = {
                height = 40,
                font_size = 28,
                font_weight = "bold",
                color = "#222",
                text_align = "center",
            },
        },
        svg.Rect {
            style = {
                width = 200,
                height = 100,
                fill = "#e74c3c",
                border_radius = 8,
                shadow = { 
                    dx = 2, dy = 4, blur = 4, 
                    color = "#000", opacity = 0.3 
                },
            },
        },
    },
}

-- 渲染为 SVG 字符串
local svg_string = svg.render_svg(doc, { width = 800, height = 400 })

-- 保存到文件
local f = io.open("output.svg", "w")
f:write(svg_string)
f:close()
```

### Stack 布局示例

```lua
-- 创建一个重叠布局的文档
local stack_doc = svg.Box {
    style = {
        width = 300,
        height = 200,
        background = "#f0f0f0",
        padding = 20,
        direction = "stack",  -- 使用stack方向，子元素将重叠
    },
    children = {
        svg.Rect {
            style = {
                width = "100%",
                height = "100%",
                fill = "#e3f2fd",
                border_radius = 12,
            }
        },
        svg.Circle {
            style = {
                width = 120,
                height = 120,
                fill = "#2196f3",
                opacity = 0.8,
            }
        },
        svg.Text {
            text = "重叠布局",
            style = {
                font_size = 24,
                color = "#1565c0",
                font_weight = "bold",
                text_align = "center",
            }
        }
    }
}

-- 渲染stack布局
local stack_svg = svg.render_svg(stack_doc, { width = 300, height = 200 })
```

## 📚 核心 API

### 组件系统

#### 容器组件
- `svg.Box(props)` - 弹性容器，支持布局
- `svg.Group(props)` - SVG `<g>` 变换组

#### 文本组件
- `svg.Text(props)` - 单行文本
- `svg.TextBlock(props)` - 多行文本，支持自动换行

#### 形状组件
- `svg.Rect(props)` - 矩形
- `svg.Circle(props)` - 圆形
- `svg.Line(props)` - 线条
- `svg.Path(props)` - 路径

#### 其他组件
- `svg.Image(props)` - 图像嵌入
- `svg.Raw(props)` - 原始 SVG 代码嵌入
- `svg.Builder(props)` - 动态内容生成器

### 布局与渲染
- `svg.render_svg(root, opts)` - 渲染单页
- `svg.render_pages(root, opts)` - 渲染多页，支持分页
- `svg.paginate_nodes(root, opts)` - 获取分页后的节点数组（不渲染）
- `svg.define(render_fn)` - 定义自定义组件
- `svg.register(name, factory)` - 全局注册组件

### 渐变与图案
- `svg.LinearGradient(props)` - 线性渐变定义
- `svg.RadialGradient(props)` - 径向渐变定义
- `svg.Pattern(props)` - 自定义图案定义

## 🎨 样式属性

### 盒模型属性
| 属性 | 类型 | 说明 |
|------|------|------|
| `width`, `height` | 数字或字符串 | 尺寸（如 `800` 或 `"100%"`） |
| `padding`, `margin` | 数字、表格或数组 | 内边距/外边距（如 `24` 或 `{top=10, right=20}`） |
| `background` | 颜色字符串或渐变对象 | 背景色或渐变 |
| `border`, `border_width` | 颜色字符串、数字 | 边框样式 |
| `border_radius` | 数字 | 边框圆角半径 |

### 弹性布局属性
| 属性 | 值 | 说明 |
|------|-----|------|
| `direction` | `"row"`, `"column"` 或 `"stack"` | 布局方向。`"stack"`表示子元素重叠排列 |
| `gap` | 数字 | 子元素间距（对`"stack"`方向无效） |
| `justify` | `"start"`, `"center"`, `"end"`, `"space-between"`, `"space-around"` | 主轴对齐（对`"stack"`方向无效） |
| `align` | `"start"`, `"center"`, `"end"`, `"stretch"` | 交叉轴对齐 |

### 文本属性
| 属性 | 类型 | 说明 |
|------|------|------|
| `font_family` | 字符串 | 字体族 |
| `font_size` | 数字 | 字体大小 |
| `font_weight` | 字符串 | 字体粗细（如 `"bold"`） |
| `color` | 颜色字符串 | 文本颜色 |
| `text_align` | `"left"`, `"center"`, `"right"` | 文本对齐 |
| `line_height` | 数字 | 行高（仅 `TextBlock`） |

### 视觉特效
| 属性 | 类型 | 说明 |
|------|------|------|
| `blur` | 数字 | 高斯模糊量 |
| `shadow` | 表格 | 阴影效果 `{dx, dy, blur, color, opacity}` |
| `opacity` | 数字 (0-1) | 透明度 |
| `transform` | 字符串 | SVG 变换字符串 |
| `clip` | 布尔值 | 是否裁剪到边界 |

### 形状属性
| 属性 | 类型 | 说明 |
|------|------|------|
| `fill` | 颜色字符串或渐变对象 | 填充色或渐变 |
| `stroke`, `stroke_width` | 颜色字符串、数字 | 描边样式 |

## 🚀 高级功能

### Builder 组件 - 动态内容生成

```lua
svg.Builder {
    style = { direction = "column", gap = 6 },
    build = function(ctx)
        -- ctx 提供 width, height 和 add() 方法
        local items = {}
        for i = 1, 5 do
            items[#items + 1] = svg.Text {
                text = "项目 " .. i,
                style = { font_size = 14 },
            }
        end
        return items
    end,
}
```

### 自定义组件 - 创建可复用组件

```lua
-- 定义徽章组件
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
                style = { 
                    font_size = 12, 
                    color = "#fff", 
                    text_align = "center" 
                },
            },
        },
    }
end)

-- 像内置组件一样使用
Badge { text = "新功能", color = "#e74c3c" }
```

### 分页与拆分协议

```lua
-- TextBlock 自动实现拆分协议
local pages = svg.render_pages(长文档, { width = 500, height = 700 })

-- 自定义组件可以实现拆分协议：
function MyComponent:_split(avail_h)
    -- 返回 (第一部分, 剩余部分) 或 nil
    return first_node, rest_node
end
```

### 渐变与图案

```lua
-- 创建线性渐变
local gradient = svg.LinearGradient {
    stops = {
        { offset = 0, color = "#667eea" },
        { offset = 1, color = "#764ba2" },
    },
}

-- 创建图案
local pattern = svg.Pattern {
    width = 20, height = 20,
    content = '<circle cx="10" cy="10" r="2" fill="#3498db"/>',
}

-- 在样式中使用
style = {
    background = gradient,  -- 渐变背景
    fill = pattern,         -- 图案填充
}
```

## 📖 完整示例

### 示例 1：基础布局

```lua
local doc = svg.Box {
    style = {
        width = 800, height = 400,
        background = "#f4f4f8",
        padding = 24,
        direction = "column",
        gap = 16,
    },
    children = {
        svg.Text {
            text = "SVG 布局演示",
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
                direction = "row", 
                gap = 12, 
                height = 120,
                justify = "space-between", 
                align = "center",
            },
            children = {
                svg.Rect { 
                    style = { 
                        width = 120, height = 80, 
                        fill = "#e74c3c", 
                        border_radius = 8,
                        shadow = { dx = 2, dy = 4, blur = 4, color = "#000", opacity = 0.3 }
                    } 
                },
                svg.Circle { 
                    style = { width = 80, height = 80, fill = "#3498db" } 
                },
                svg.Rect { 
                    style = { 
                        width = 120, height = 80, 
                        fill = "#2ecc71", 
                        border_radius = 8,
                        blur = 1 
                    } 
                },
            },
        },
    },
}
```

### 示例 2：渐变背景与多行文本

```lua
-- 创建渐变背景
local bg_grad = svg.LinearGradient {
    x1 = "0%", y1 = "0%", x2 = "0%", y2 = "100%",
    stops = {
        { offset = 0, color = "#667eea" },
        { offset = 1, color = "#764ba2" },
    },
}

local doc = svg.Box {
    style = {
        width = 600, height = 400, padding = 30,
        background = bg_grad,  -- 直接使用渐变对象
        direction = "column", gap = 16,
    },
    children = {
        svg.Text {
            text = "渐变与多行文本演示",
            style = {
                height = 40, 
                font_size = 24, 
                font_weight = "bold",
                color = "#fff", 
                text_align = "center",
            },
        },
        
        svg.TextBlock {
            text = "这是一个多行文本演示。SVG 布局库支持自动换行和文本对齐。你可以使用 TextBlock 组件来处理长文本内容，它会自动根据容器宽度进行换行。",
            style = {
                background = "rgba(255,255,255,0.9)",
                padding = 16,
                border_radius = 8,
                font_size = 16,
                line_height = 1.5,
                color = "#333",
            },
        },
    },
}
```

### 示例 3：阴影与模糊效果

```lua
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
                background = "#e74c3c", 
                border_radius = 12,
                shadow = { 
                    dx = 4, dy = 6, blur = 8, 
                    color = "#000", opacity = 0.4 
                },
            },
            children = {
                svg.Text {
                    text = "阴影",
                    style = { 
                        height = 140, 
                        font_size = 18, 
                        color = "#fff",
                        font_weight = "bold", 
                        text_align = "center" 
                    },
                },
            },
        },
        
        -- 仅描边 + 阴影
        svg.Box {
            style = {
                width = 140, height = 140,
                border = "#3498db", 
                border_width = 3, 
                border_radius = 12,
                shadow = { 
                    dx = 3, dy = 3, blur = 5, 
                    color = "#3498db", opacity = 0.6 
                },
            },
        },
        
        -- 模糊效果
        svg.Box {
            style = {
                width = 140, height = 140,
                background = "#2ecc71", 
                border_radius = 12,
                blur = 20,  -- 高斯模糊
            },
        },
    },
}
```

## 📁 项目结构

```
svglayout/
├── README.md                    # 本文档
├── svglayout/                   # 库源代码
│   ├── init.lua                # 主入口文件
│   ├── core.lua                # 核心功能
│   ├── components.lua          # 组件定义
│   ├── layout.lua              # 布局引擎
│   ├── render.lua              # 渲染器
│   ├── style.lua               # 样式处理
│   ├── paginate.lua            # 分页系统
│   ├── builder.lua             # Builder 组件
│   ├── defs.lua                # 定义管理
│   ├── text_measure.lua        # 文本测量
│   └── ...                     # 其他模块
├── example/                    # 示例代码
│   ├── 1.lua                   # 基础布局示例
│   ├── 2.lua                   # 渐变与文本示例
│   ├── 3.lua                   # 阴影效果示例
│   ├── 4.lua                   # 弹性布局进阶
│   ├── 5.lua                   # 综合高级示例
│   ├── 6.lua                   # 功能分类示例
│   ├── 7.lua                   # Stack 布局测试
│   └── README.md               # 示例说明文档
└── output/                     # 生成的 SVG 文件
```

## 🔧 技术细节

### 零依赖设计
- 仅使用 Lua 5.4 标准库，无需安装任何外部依赖
- 纯 Lua 实现，跨平台兼容

### 性能优化
- **惰性计算**：仅在需要时计算布局和渲染
- **内存高效**：最小化临时对象创建
- **UTF-8 优化**：高效处理中文字符和混合脚本

### 扩展性
- **协议化设计**：通过实现协议扩展功能
- **插件化架构**：轻松添加新组件和功能
- **类型注解**：完整的 EmmyLua 注解，提供 IDE 支持

### 支持的协议
1. `_measure` - 测量组件尺寸
2. `_split` - 拆分组件用于分页
3. `_register` - 注册组件定义

## 📝 开发指南

### 添加新组件

```lua
-- 1. 定义组件工厂函数
local function MyComponent(props)
    return {
        type = "my-component",
        style = props.style or {},
        children = props.children,
        -- 实现必要协议
        _measure = function(self, ctx)
            return 100, 50  -- 返回宽度和高度
        end,
        _render = function(self, ctx, x, y)
            -- 渲染逻辑
            return string.format(
                '<rect x="%d" y="%d" width="100" height="50" fill="%s"/>',
                x, y, self.style.background or "#ccc"
            )
        end
    }
end

-- 2. 注册组件
svg.register("MyComponent", MyComponent)

-- 3. 使用组件
svg.MyComponent {
    style = { background = "#ff6b6b" },
    children = { ... }
}
```

### 性能分析

```lua
local start_time = os.clock()
local result = svg.render_svg(doc, options)
local elapsed = os.clock() - start_time
print(string.format("渲染耗时: %.3f 秒", elapsed))
```

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 开启 Pull Request

### 代码规范
- 遵循 Lua 代码风格指南
- 添加 EmmyLua 类型注解
- 编写清晰的注释（中英文均可）
- 添加测试用例

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🙏 致谢

感谢所有贡献者和用户的支持！
