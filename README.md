# Lua SVG 布局库

![Lua 5.5](https://img.shields.io/badge/Lua-5.5-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)
![Dependencies](https://img.shields.io/badge/Dependencies-0-brightgreen.svg)

纯 Lua 5.5 实现的声明式 SVG 布局和渲染库，**零外部依赖**，提供 Flexbox 风格的布局系统、丰富的内置组件和自动分页能力。

## 特性

- **Flexbox 风格布局** — 支持 `row`（水平）、`column`（纵向）、`stack`（重叠）三种方向，完整支持 `justify`、`align`、`flex`、`gap`、`fill` 属性
- **丰富的内置组件** — Box、Text、TextBlock、Rect、Circle、Line、Path、Row、Column、ZStack、Spacer、Divider、Group、Image、Raw
- **链式样式 API** — 参考 Compose Modifier 设计的 `svg.Style()` 链式调用
- **自动分页** — 支持多页渲染，自动识别页眉/内容/页脚区域
- **渐变与图案** — LinearGradient、RadialGradient、Pattern 定义系统
- **视觉特效** — 阴影（shadow）、高斯模糊（blur）、透明度（opacity）、SVG 变换（transform）、裁剪（clip）、旋转（rotate）
- **Builder 动态内容** — 渲染时回调动态构建子节点
- **PageCallback / PageNumber** — 分页时感知页码和页数的组件
- **九宫格（9-Patch）** — 支持图片九宫格拉伸和重复模式
- **自定义组件** — 通过 `svg.define()` 和 `svg.register()` 扩展
- **UTF-8 文本测量** — CJK 感知的文本宽度估算和自动换行
- **EmmyLua 注解** — 完整的类型注解，支持 IDE 智能提示

## 快速开始

### 安装

将 `svglayout/` 目录放入 Lua 模块路径即可：

```lua
package.path = package.path .. ";./svglayout/?.lua"
local svg = require("svglayout")
```

### 第一个示例

```lua
local svg = require("svglayout")

local doc = svg.Box {
    style = {
        width = 800,
        height = 400,
        background = "#f4f4f8",
        padding = 24,
        direction = "column",
        gap = 16,
    },
    children = {
        svg.Text {
            text = "Hello, SVG Layout!",
            style = { height = 40, font_size = 28, font_weight = "bold", color = "#222", text_align = "center" },
        },
        svg.Rect {
            style = { width = 200, height = 100, fill = "#e74c3c", border_radius = 8,
                shadow = { dx = 2, dy = 4, blur = 4, color = "#000", opacity = 0.3 } },
        },
    },
}

local svg_string = svg.render_svg(doc, { width = 800, height = 400 })

local f = io.open("output.svg", "w")
f:write(svg_string)
f:close()
```

## 组件参考

### 容器组件

| 组件 | 说明 |
|------|------|
| `svg.Box` | 通用弹性容器，通过 `direction` 控制布局方向 |
| `svg.Row` | 水平容器，等价于 `Box { style = { direction = "row" } }` |
| `svg.Column` | 纵向容器，等价于 `Box { style = { direction = "column" } }` |
| `svg.ZStack` | 层叠容器，等价于 `Box { style = { direction = "stack" } }` |
| `svg.Group` | SVG `<g>` 组，统一应用 transform 等效果 |
| `svg.Spacer` | 弹性空白填充，等价于 `Box { style = { flex = 1 } }` |
| `svg.Divider` | 分割线，支持水平和垂直方向 |

### 文本组件

| 组件 | 说明 |
|------|------|
| `svg.Text` | 单行文本 |
| `svg.TextBlock` | 多行文本，支持自动换行和分页拆分 |

### 形状组件

| 组件 | 说明 |
|------|------|
| `svg.Rect` | 矩形，支持 `border_radius` 圆角 |
| `svg.Circle` | 圆形 |
| `svg.Line` | 线条 |
| `svg.Path` | SVG 路径 |

### 其他组件

| 组件 | 说明 |
|------|------|
| `svg.Image` | 图片嵌入，支持 `preserveAspectRatio` 和九宫格 |
| `svg.Raw` | 原始 SVG 代码直接嵌入 |
| `svg.Builder` | 动态内容生成器，渲染时回调构建子节点 |
| `svg.PageCallback` | 分页页码组件，接收 `build(page, total)` 回调 |
| `svg.PageNumber` | 模板页码组件，支持 `{page}/{total}` 模板变量 |

### 渐变与图案

| 组件 | 说明 |
|------|------|
| `svg.LinearGradient` | 线性渐变 |
| `svg.RadialGradient` | 径向渐变 |
| `svg.Pattern` | 图案填充 |

创建后通过 `.ref` 属性引用：

```lua
local grad = svg.LinearGradient {
    x1 = "0%", y1 = "0%", x2 = "100%", y2 = "100%",
    stops = {
        { offset = 0, color = "#667eea" },
        { offset = 1, color = "#764ba2" },
    },
}
-- 通过 background = grad 或 background = grad.ref 引用
svg.Box { style = { width = 100, height = 100, background = grad } }
```

## 样式系统

### 盒模型

| 属性 | 类型 | 说明 |
|------|------|------|
| `width` / `height` | number / string | 数字（固定值）、`"50%"`（百分比）、`"fill"`（填满）、`"auto"`（自适应） |
| `padding` / `margin` | number / table | 数字统一间距；表支持 `{t,r,b,l}`、`{t,r}`（上下/左右）、`{top,right,bottom,left}` 命名键 |
| `background` | string / def object | 背景色或渐变/图案定义对象 |
| `border` | string / def object | 边框颜色 |
| `border_width` | number | 边框线宽 |
| `border_radius` | number | 圆角半径 |

### 弹性布局

| 属性 | 值 | 说明 |
|------|-----|------|
| `direction` | `"row"` / `"column"` / `"stack"` | 布局方向 |
| `gap` | number | 子元素间距（像素） |
| `justify` | `"start"` / `"center"` / `"end"` / `"space-between"` / `"space-around"` | 主轴对齐 |
| `align` | `"start"` / `"center"` / `"end"` / `"stretch"` | 交叉轴对齐 |
| `flex` | number | 弹性权重，>0 时按比例分配剩余空间 |
| `fill` | `"fill"` 字符串 | 填满父容器剩余空间（等价于 `flex=1`） |

### 文本样式

| 属性 | 类型 | 说明 |
|------|------|------|
| `font_family` | string | 字体族 |
| `font_size` | number | 字体大小（px） |
| `font_weight` | string / number | 字重，如 `"bold"` 或 `700` |
| `color` | string | 文本颜色 |
| `text_align` | `"left"` / `"center"` / `"right"` | 水平对齐 |
| `line_height` | number | 行高倍率（相对 font_size，仅 TextBlock 生效） |

### 视觉特效

| 属性 | 类型 | 说明 |
|------|------|------|
| `shadow` | table | `{ dx?, dy?, blur?, color?, opacity? }` |
| `blur` | number | 高斯模糊半径（px） |
| `opacity` | number | 透明度 0~1 |
| `transform` | string | SVG transform 属性值 |
| `rotate` | number / table | 旋转角度；支持数字或 `{angle, cx?, cy?}` |
| `clip` | boolean | 是否裁剪到边界 |

### 形状属性

| 属性 | 类型 | 说明 |
|------|------|------|
| `fill` | string / def object | 填充色或渐变/图案 |
| `stroke` | string / def object | 描边色 |
| `stroke_width` | number | 描边线宽 |

## 链式样式 API

`svg.Style()` 提供 Compose Modifier 风格的链式调用：

```lua
local s = svg.Style()
    :width(200)
    :height(100)
    :background("#e74c3c")
    :border_radius(8)
    :padding(16)
    :shadow({ dx = 2, dy = 3, blur = 4, color = "#000", opacity = 0.3 })
    :direction("column")
    :gap(8)
    :font_size(14)
    :color("#fff")
    :text_align("center")

-- 在组件中使用
local box = svg.Box { style = s, children = { ... } }

-- 合并已有样式
local merged = svg.Style():font_size(16):merge({ background = "#f00", padding = 8 })

-- 转换为普通样式表
local plain = merged:to_table()
```

完整方法：`width` / `height` / `size` / `flex` / `fillMaxWidth` / `fillMaxHeight` / `fillMaxSize` / `padding` / `margin` / `background` / `border` / `border_width` / `border_radius` / `fill` / `stroke` / `stroke_width` / `shadow` / `blur` / `opacity` / `transform` / `rotate` / `clip` / `direction` / `gap` / `justify` / `align` / `font_size` / `color` / `font_family` / `font_weight` / `text_align` / `line_height` / `merge` / `apply_to` / `to_table`

## 核心 API

### 渲染

```lua
-- 单页渲染：高度自动裁剪（nil 或 "auto" 时按内容自适应）
svg.render_svg(root, { width = 800, height = 400 })

-- 多页渲染（自动分页）
local pages = svg.render_pages(root, { width = 500, height = 700 })
-- 返回字符串数组，每页一个 SVG 文档

-- 获取分页节点数组（不渲染，便于自定义处理）
local nodes = svg.paginate_nodes(root, { width = 500, height = 700 })
```

### 自定义组件

```lua
-- svg.define()：创建无状态组件工厂
local Badge = svg.define(function(props)
    return svg.Box {
        style = { background = props.color or "#3498db", border_radius = 12, padding = { 4, 10 } },
        children = {
            svg.Text { text = props.text or "Badge", style = { font_size = 12, color = "#fff", text_align = "center" } },
        },
    }
end)
Badge { text = "New", color = "#e74c3c" }

-- svg.register()：全局注册，可通过 svg[name] 访问
svg.register("Badge", Badge)
svg.Badge { text = "Global" }
```

### 组件协议

自定义组件通过实现以下方法集成到布局系统：

| 方法 | 说明 |
|------|------|
| `_measure(self, hint_w, hint_h)` | 测量自然尺寸，返回 `width, height` |
| `_render(self, ctx)` | 渲染为 SVG 字符串 |
| `_split(self, avail_h)` | 分页拆分，返回 `first, rest` 或 `nil` |
| `_register(self, ctx)` | 注册渐变/图案等 defs 到渲染上下文 |

## 分页系统

纵向（`direction = "column"`）Box 且未指定固定高度时自动获得分页能力。分页算法自动识别三类节点：

| 分区 | 说明 | 示例 |
|------|------|------|
| `pre_fixed` | 首个溢出节点之前能容纳的节点，在**每页顶部**重复 | 标题、表头 |
| `overflow` | 需要跨页拆分的内容 | 数据列表、长文本 |
| `post_fixed` | 末位溢出节点之后能容纳的节点，在**每页底部**重复 | 页码、页脚 |

支持 `_split` 协议的组件（如 TextBlock）可跨页拆分；不可拆分的整块组件超出一页时独占一页。

```lua
-- 长列表分页
local items = {}
for i = 1, 50 do
    items[#items + 1] = svg.Text { text = "Item " .. i, style = { font_size = 14, height = 24 } }
end

local doc = svg.Column {
    style = { gap = 4, padding = 16, background = "#fff" },
    children = items,
}

local pages = svg.render_pages(doc, { width = 500, height = 400 })
print(#pages .. " pages")
```

### PageCallback 页码组件

在分页渲染时根据当前页码和总页数动态生成内容：

```lua
svg.PageCallback {
    style = { height = 32, direction = "row", align = "center", justify = "center", gap = 8 },
    build = function(page, total)
        return {
            svg.Text { text = "第", style = { font_size = 12, color = "#888" } },
            svg.Text { text = tostring(page), style = { font_size = 14, color = "#3498db", font_weight = "bold" } },
            svg.Text { text = "/", style = { font_size = 12, color = "#ccc" } },
            svg.Text { text = tostring(total), style = { font_size = 14, color = "#333", font_weight = "bold" } },
            svg.Text { text = "页", style = { font_size = 12, color = "#888" } },
        }
    end,
}
```

### PageNumber 模板页码组件

比 PageCallback 更简洁，适合纯文本页码：

```lua
svg.PageNumber {
    template = "{page} / {total}",
    text_style = { font_size = 10, color = "#999" },
}
```

## Builder 动态内容

Builder 组件在渲染阶段回调构建子节点，适合数据驱动的动态内容：

```lua
svg.Builder {
    style = { direction = "column", gap = 6 },
    build = function(ctx)
        -- ctx: { width, height, x, y, add(node) }
        local items = {}
        for i = 1, #data do
            items[#items + 1] = svg.Text {
                text = data[i].name,
                style = { font_size = 14, color = "#333" },
            }
        end
        return items
    end,
}
```

## 九宫格 (9-Patch)

支持图片九宫格拉伸和重复模式渲染，适用于可伸缩的 UI 边框和背景。

```lua
svg.Image {
    href = "frame.png",
    style = { width = 200, height = 150 },
    nine_patch = {
        src_width = 100,   -- 源图内容区宽度
        src_height = 100,  -- 源图内容区高度
        left = 20,         -- 左侧固定区
        right = 20,        -- 右侧固定区
        top = 20,          -- 顶部固定区
        bottom = 20,       -- 底部固定区
        repeat_mode = "no-repeat",  -- 重复模式
    },
}
```

## 项目结构

```
svglayout/
├── README.md                    # 本文档
├── svglayout/                   # 库源代码
│   ├── init.lua                # 主入口，模块导出
│   ├── core.lua                # 工具函数（XML 转义、浅拷贝、ID 生成）
│   ├── components.lua          # 所有内置组件定义
│   ├── layout.lua              # Flexbox 布局引擎（measure + layout 双阶段）
│   ├── render.lua              # SVG 渲染器（滤镜、裁剪、背景、边框）
│   ├── style.lua               # 样式工具（间距规范化、尺寸解析）
│   ├── style_modifier.lua      # 链式 Style API
│   ├── text_measure.lua        # UTF-8 文本测量和换行
│   ├── paginate.lua            # 分页系统
│   ├── builder.lua             # Builder 动态内容组件
│   ├── page_callback.lua       # PageCallback 页码组件
│   ├── page_number.lua         # PageNumber 模板页码组件
│   ├── defs.lua                # 渐变和图案定义
│   └── nine_patch.lua          # 九宫格渲染引擎
├── example/                    # 示例
│   └── demo.lua                # 综合示例（覆盖所有功能）
└── output/                     # 生成的 SVG 文件（运行示例后生成）
```

## 示例运行

```bash
cd example
lua demo.lua
```

示例输出位于 `output/` 目录，包含 16 个分类演示文件以及分页测试文件。

## 许可

MIT
