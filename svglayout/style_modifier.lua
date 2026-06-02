local style_util = require("svglayout.style")

---Style — 链式 API 用于构建样式表，参考 Compose Modifier 设计
---@class svglayout.Style
---@field _props table 内部样式属性表
---@field [string] any 通过元表代理访问 _props
local methods = {}

local style_mt
local function is_style(t) return getmetatable(t) == style_mt end

-- ==================== 尺寸 ====================

---设置宽度
---@param v number|string 宽度值
---@return self
function methods:width(v)
    self._props.width = v; return self
end

---设置高度
---@param v number|string 高度值
---@return self
function methods:height(v)
    self._props.height = v; return self
end

---同时设置宽度和高度
---@param w number|string 宽度
---@param h number|string 高度
---@return self
function methods:size(w, h)
    self._props.width = w; self._props.height = h; return self
end

---设置 flex 权重
---@param v number >0 时按比例分配剩余空间
---@return self
function methods:flex(v)
    self._props.flex = v; return self
end

---设置宽度为 fill
---@return self
function methods:fillMaxWidth()
    self._props.width = "fill"; return self
end

---设置高度为 fill
---@return self
function methods:fillMaxHeight()
    self._props.height = "fill"; return self
end

---同时设置宽高为 fill
---@return self
function methods:fillMaxSize()
    self._props.width = "fill"; self._props.height = "fill"; return self
end

-- ==================== 间距 ====================

---设置内边距（支持数字或数组格式）
---@param v number|number[]|{top:number?,right:number?,bottom:number?,left:number?}
---@return self
function methods:padding(v)
    self._props.padding = type(v) == "table" and style_util.normalize_spacing(v) or v
    return self
end

---设置外边距（支持数字或数组格式）
---@param v number|number[]|{top:number?,right:number?,bottom:number?,left:number?}
---@return self
function methods:margin(v)
    self._props.margin = type(v) == "table" and style_util.normalize_spacing(v) or v
    return self
end

-- ==================== 背景 & 边框 ====================

---设置背景颜色或渐变/图案
---@param v string|table 颜色值或定义对象
---@return self
function methods:background(v)
    self._props.background = v; return self
end

---设置边框颜色
---@param v string|table 颜色值或渐变对象
---@return self
function methods:border(v)
    self._props.border = v; return self
end

---设置边框宽度
---@param v number 像素
---@return self
function methods:border_width(v)
    self._props.border_width = v; return self
end

---设置边框圆角
---@param v number 像素
---@return self
function methods:border_radius(v)
    self._props.border_radius = v; return self
end

-- ==================== 填充 & 描边 ====================

---设置填充色（形状组件用）
---@param v string|table 颜色值或渐变/图案对象
---@return self
function methods:fill(v)
    self._props.fill = v; return self
end

---设置描边色（形状组件用）
---@param v string|table 颜色值或渐变对象
---@return self
function methods:stroke(v)
    self._props.stroke = v; return self
end

---设置描边宽度
---@param v number 像素
---@return self
function methods:stroke_width(v)
    self._props.stroke_width = v; return self
end

-- ==================== 视觉效果 ====================

---设置阴影
---@param v {dx:number?,dy:number?,blur:number?,color:string?,opacity:number?}
---@return self
function methods:shadow(v)
    self._props.shadow = v; return self
end

---设置高斯模糊
---@param v number 模糊半径（像素）
---@return self
function methods:blur(v)
    self._props.blur = v; return self
end

---设置透明度
---@param v number 0~1
---@return self
function methods:opacity(v)
    self._props.opacity = v; return self
end

---设置 SVG 变换
---@param v string 如 "rotate(45)"、"translate(10,20)"
---@return self
function methods:transform(v)
    self._props.transform = v; return self
end

---设置旋转角度
---支持数字（绕中心）或 {angle, cx?, cy?} 表格式
---@param v number|{angle:number, cx:(number|string)?, cy:(number|string)?}
---@return self
function methods:rotate(v)
    self._props.rotate = v; return self
end

---启用裁剪（隐藏溢出内容）
---@param v boolean
---@return self
function methods:clip(v)
    self._props.clip = v; return self
end

-- ==================== 布局 ====================

---设置布局方向
---@param v '"row"'|'"column"'|'"stack"'
---@return self
function methods:direction(v)
    self._props.direction = v; return self
end

---设置子节点间距
---@param v number 像素
---@return self
function methods:gap(v)
    self._props.gap = v; return self
end

---设置主轴对齐
---@param v '"start"'|'"center"'|'"end"'|'"space-between"'|'"space-around"'
---@return self
function methods:justify(v)
    self._props.justify = v; return self
end

---设置交叉轴对齐
---@param v '"start"'|'"center"'|'"end"'|'"stretch"'
---@return self
function methods:align(v)
    self._props.align = v; return self
end

-- ==================== 文本 ====================

---设置字体大小
---@param v number 像素
---@return self
function methods:font_size(v)
    self._props.font_size = v; return self
end

---设置文本颜色
---@param v string 颜色值
---@return self
function methods:color(v)
    self._props.color = v; return self
end

---设置字体系列
---@param v string 如 "Arial, sans-serif"
---@return self
function methods:font_family(v)
    self._props.font_family = v; return self
end

---设置字体粗细
---@param v number|string 如 700 或 "bold"
---@return self
function methods:font_weight(v)
    self._props.font_weight = v; return self
end

---设置文本水平对齐
---@param v '"left"'|'"center"'|'"right"'
---@return self
function methods:text_align(v)
    self._props.text_align = v; return self
end

---设置行高倍率
---@param v number 相对于 font_size
---@return self
function methods:line_height(v)
    self._props.line_height = v; return self
end

-- ==================== 特殊 ====================

---合并另一个样式表到当前样式
---@param other table|svglayout.Style 目标样式
---@return self
function methods:merge(other)
    local src = is_style(other) and other._props or other
    for k, v in pairs(src or {}) do
        if type(v) ~= "function" then self._props[k] = v end
    end
    return self
end

---将当前样式应用到节点
---@param node table? 目标节点
---@return table
function methods:apply_to(node)
    if node then
        if not node.style then node.style = {} end
        for k, v in pairs(self._props) do node.style[k] = v end
    end
    return node ---@type table
end

---返回原始样式属性表
---@return table
function methods:to_table() return self._props end

-- ==================== 元表 ====================

style_mt = {
    _STYLE_MT = true,
    __index = function(self, key)
        if methods[key] then return methods[key] end
        return self._props[key]
    end,
    __newindex = function(self, key, val) self._props[key] = val end,
    __pairs = function(self) return pairs(self._props) end
}

function methods:_new() return setmetatable({ _props = {} }, style_mt) end

-- ==================== 模块导出 ====================

---创建 Style 实例
---支持传入初始属性表，也可通过链式调用构建
---@param initial? table 初始样式
---@return svglayout.Style
local M = function(initial)
    local s = methods:_new()
    if type(initial) == "table" then
        for k, v in pairs(initial) do
            if type(v) ~= "function" then s._props[k] = v end
        end
    end
    return s
end

return M
