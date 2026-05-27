# 示例说明

## 运行

```bash
cd example
lua demo.lua
```

输出文件位于 `output/` 目录。

## 示例概览

综合示例 [demo.lua](demo.lua) 按功能分类演示了库的所有特性，并包含性能基准测试。

| 输出文件 | 功能覆盖 |
|----------|----------|
| `1_basic_components.svg` | 基础组件：Box、Text、TextBlock、Rect、Circle、Line、Path |
| `2_containers.svg` | 进阶容器：Row、Column、ZStack、Spacer、Divider、Group、Image、Raw |
| `3_effects.svg` | 视觉特效：shadow、blur、opacity、transform、clip |
| `4_layout.svg` | 布局系统：justify 五种模式、align 四种模式、flex 权重、fill、百分比 |
| `5_style_api.svg` | 链式 Style API：`svg.Style()` 的完整用法 |
| `6_gradients.svg` | 渐变与图案：LinearGradient、RadialGradient、Pattern |
| `7_builder.svg` | Builder 动态内容 + `svg.define()` 自定义组件 |
| `8_text.svg` | 文本系统：Text 单行、TextBlock 多行换行、CJK 混合文本 |
| `9_page_*.svg` | 分页系统：30 项列表按 A4 尺寸分页 |
| `10_dashboard.svg` | 综合复杂场景：表单卡片 + 数据面板 + Builder 动态列表 |

## 性能测试

示例运行时会自动执行以下性能测试，输出耗时信息：

| 测试内容 | 规模 |
|----------|------|
| 简单渲染 | 单次 |
| 大量组件 | 1000 Box × 3 子组件 = 3000 节点 |
| 分页渲染 | 1000 项列表 |
| 文本测量 | 500 句 CJK 文本 |
| 文本换行 | 500 句 CJK 文本 |
| 渐变 + 阴影 | 200 个卡片 |
| ZStack + 变换 | 100 个旋转元素 |
| Builder 动态渲染 | 500 行 |
| 综合页面分页 | 复杂仪表盘 |
