# 示例说明

## 运行

```bash
cd example
lua demo.lua
```

输出文件位于 `output/` 目录。

## 示例概览

示例 [demo.lua](demo.lua) 按 16 个步骤覆盖了库的所有功能：

| 输出文件 | 功能覆盖 |
|----------|----------|
| `01_hello_world.svg` | 基础 Hello World |
| `02_styling_basics.svg` | 样式基础：背景、内边距、圆角、字体 |
| `03_row_column.svg` | 布局方向：Row 水平、Column 垂直 |
| `04_spacer_alignment.svg` | Spacer 弹性空白 + justify/align 对齐 |
| `05_flex_fill.svg` | flex 权重、fill 填充、百分比宽度、margin |
| `06_shapes.svg` | 形状组件：Rect、Circle、Line、Path |
| `07_text_system.svg` | 文本系统：Text 单行、TextBlock 多行换行、CJK 混合 |
| `08_dividers_zstack.svg` | Divider 分割线 + ZStack 层叠布局 |
| `09_effects.svg` | 视觉效果：shadow、blur、opacity、rotate、clip |
| `10_gradients_patterns.svg` | 渐变与图案：LinearGradient、RadialGradient、Pattern |
| `11_style_api.svg` | 链式 Style API：`svg.Style()` |
| `12_custom_components.svg` | 自定义组件：`svg.define()` + `svg.register()` |
| `13_builder.svg` | Builder 动态内容生成 |
| `14_page_*.svg` | 分页系统 + PageCallback + PageNumber |
| `15_dashboard.svg` | 综合仪表盘：表单 + 数据面板 + Builder 动态列表 |
| `16_nine_patch_comprehensive.svg` | 九宫格完整功能：拉伸、固定区、重复模式 |
