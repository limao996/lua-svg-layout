# AGENTS.md - SVG Layout Library

High-signal guidance for OpenCode agents working with this Lua SVG layout library.

## 🎯 Project Overview

**Pure Lua 5.5 library** for declarative SVG layout and rendering with **zero external dependencies**. Provides Flexbox-like layout system, rich component library, and advanced features like gradients, patterns, and automatic pagination.

## 📁 Project Structure

```
svglayout/
├── README.md                    # Main documentation (Chinese)
├── svglayout/                   # Library source code
│   ├── init.lua                # Main entry point, module exports
│   ├── core.lua                # Utilities (XML escaping, ID generation, attr serialization)
│   ├── components.lua          # Built-in component definitions
│   ├── layout.lua              # Flexbox layout engine (measure + layout phases)
│   ├── render.lua              # SVG renderer with filter merging
│   ├── style.lua               # Style normalization (spacing, size resolution)
│   ├── paginate.lua            # Multi-page pagination system
│   ├── builder.lua             # Dynamic content Builder component
│   ├── page_callback.lua       # PageCallback component
│   ├── defs.lua                # Definitions (gradients, patterns)
│   └── text_measure.lua        # UTF-8 text measurement (CJK-aware)
├── example/                    # Example code (demo.lua)
│   └── README.md              # Example documentation
└── output/                     # Generated SVG files
```

## 🚀 Getting Started

### Prerequisites
- **Lua 5.5** (not 5.1, 5.2, 5.3, or 5.4)
- No external dependencies required

### Installation
The library is loaded via Lua's `require` system. Configure `package.path`:

```lua
package.path = package.path .. ";./svglayout/?.lua"
local svg = require("svglayout")
```

### Running Examples
```bash
cd example
lua demo.lua
```

Examples generate SVG files in `./output/` directory.

## ⚠️ Agent Pitfalls

### Common Mistakes
1. **❌ Looking for npm/package.json** - This is Lua, not Node.js
2. **❌ Expecting TypeScript files** - All code is in `.lua` files
3. **❌ Searching for test frameworks** - No test infrastructure found
4. **❌ Assuming English documentation** - Primary docs are in Chinese

### Correct Approach
1. **✅ Read Chinese README** - Use translation if needed
2. **✅ Check example/ directory** - Working code examples
3. **✅ Start with init.lua** - Main module entry point
4. **✅ Use Lua 5.5 syntax** - Not older Lua versions

## 🛠️ Library Architecture

### Two-Phase Layout System
1. **Measure phase** (`layout.measure`) - Computes intrinsic sizes recursively
2. **Layout phase** (`layout.layout_fixed`) - Assigns actual x/y/w/h coordinates based on flex rules

### Core Protocols
Components must implement these protocol methods:

| Method | Signature | Description |
|--------|-----------|-------------|
| `_measure` | `_measure(ctx) → width, height` | Compute intrinsic dimensions |
| `_split` | `_split(avail_h) → first, rest \| nil` | Split for pagination |
| `_render` | `_render(ctx, x, y) → svg_string` | Render to SVG |
| `_register` | `_register(ctx) → nil` | Register definitions (gradients, patterns) - optional |

### Component System
- **Built-in components**: `Box`, `Text`, `TextBlock`, `Rect`, `Circle`, `Line`, `Path`, `Group`, `Image`, `Raw`
- **Custom components**: Use `svg.define()` and `svg.register()`
- **Builder component**: Dynamic content generation with callback
- **PageCallback component**: Page-aware content generation with `build(page, total)`

### Style Properties
- **Box model**: `width`, `height`, `padding`, `margin`, `border`
- **Flex layout**: `direction`, `gap`, `justify`, `align`, `flex` (weight), `fill` (fill available space)
- **Visual effects**: `shadow`, `blur`, `opacity`, `transform`
- **Text styling**: `font_size`, `color`, `text_align`, `line_height`

### Rendering Behavior
- **Height defaults to `math.huge`**: `render_svg(root, {width=800})` with no height uses infinite height then snaps to root's actual measured height
- **Shadow + blur filter merging**: Automatically merges shadow and blur effects into a single SVG filter for efficiency
- **Gradient/Pattern lazy registration**: Definitions only added to `<defs>` when actually used in rendering

### Text Measurement
- **Estimation-based**: Uses character width multipliers (0.55 for ASCII, 1.0 for CJK) - not actual font metrics
- **CJK-aware line wrapping**: `TextBlock` component handles Chinese/Japanese/Korean character boundaries correctly

### Component Node Structure
After layout, components have a `._box` table containing computed geometry:
- `x`, `y`, `width`, `height` - final position and size
- `measured_width`, `measured_height` - intrinsic size from measure phase

## 📝 Development Guide

### Code Style & Conventions
- **Chinese documentation** - README and comments are in Chinese
- **EmmyLua annotations** - Provides IDE type hints
- **Protocol-based design** - Components implement `_measure`, `_split`, `_render` protocols

### Key Development Patterns
1. **Component creation**: Use factory functions that return tables with protocol methods
2. **Style system**: Nested tables with CSS-like properties
3. **Layout engine**: Flexbox-inspired with `direction`, `justify`, `align`, `gap`
4. **Rendering**: SVG string generation with proper XML escaping

### Adding New Components
```lua
local function MyComponent(props)
    return {
        type = "my-component",
        style = props.style or {},
        children = props.children,
        _measure = function(self, ctx) return 100, 50 end,
        _render = function(self, ctx, x, y)
            return string.format('<rect x="%d" y="%d" width="100" height="50"/>', x, y)
        end
    }
end

svg.register("MyComponent", MyComponent)
svg.MyComponent { style = { background = "#ff6b6b" } }
```

### Module Loading
- **Internal requires must include full path**: `require("svglayout.core")` not `require("core")`
- **Package path setup required**: Examples use `package.path = package.path .. ";./?.lua;./?/init.lua"`

## 🔍 Reference

### Understanding the Architecture
1. `svglayout/init.lua` - Module exports and main functions
2. `svglayout/components.lua` - Built-in component implementations
3. `svglayout/layout.lua` - Layout algorithm
4. `svglayout/render.lua` - SVG generation

### Usage Examples
1. `example/demo.lua` - Comprehensive demo covering all features and performance tests

### Documentation
1. `README.md` (root) - Complete library documentation
2. `example/README.md` - Example usage guide
3. Source code comments - EmmyLua annotations

### Performance Notes
- **Lazy computation** - Layout and rendering computed only when needed
- **UTF-8 optimized** - Efficient Chinese text handling
- **Memory efficient** - Minimal temporary object creation

## 🎨 Design Philosophy

1. **Zero dependencies** - Pure Lua 5.5 standard library only
2. **Declarative API** - Nested component trees, not imperative drawing
3. **Protocol-based extensibility** - Implement `_measure`, `_split`, `_render`
4. **Chinese-first documentation** - Primary audience is Chinese developers
5. **IDE support** - EmmyLua annotations for autocomplete

---

**Remember**: This is a Lua library, not a JavaScript/TypeScript project. Focus on `.lua` files, understand the protocol system, and reference the Chinese documentation when needed.
