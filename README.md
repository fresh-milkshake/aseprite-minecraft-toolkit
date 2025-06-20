<div align="center">
  <img src="https://github.com/fresh-milkshake/aseprite-minecraft-toolkit/header.png" alt="MC Toolkit">
</div>

**A comprehensive toolset for creating and editing Minecraft textures in Aseprite**

![Version](https://img.shields.io/badge/Version-2.1.0-blue)
![Aseprite](https://img.shields.io/badge/Aseprite-1.2.10+-green)
![License](https://img.shields.io/badge/License-MIT-yellow)

## Overview

MC Toolkit is an Aseprite extension for Minecraft texture creators. It offers tools to create, edit, and export pixel art textures. Basically, it's a collection of random tools that i've made for myself.

## Features

### `Hue Shift` - Hue variants generation
Creates up to 8 color variants from a single texture with configurable hue shift angles (5°-180°). Features advanced color correction including saturation, brightness, and contrast adjustments, plus an accent color system with customizable strength and color temperature controls.

### `3D Block Render` - Interactive block preview
Provides real-time 3D visualization of your textures with mouse rotation and scroll wheel scaling. Includes auto-rotation with adjustable speed, customizable background colors, and automatic updates when selection changes.

> This tool is highy inspired by [Block Preview](https://astropulse.itch.io/block-preview) extension, but i wanted it to work for a selection, not for a whole sprite.

### `Render Adjacent` - Tiling verification
Displays your texture in a 3×3 grid pattern to verify seamless tiling. Offers scalable preview with 1x-8x zoom, grid and background customization, and export options to new sprite or clipboard.

### `Intermediate Colors` - Smoothing with nice preview
Applies one of 5 processing algorithms (edge_smoothing, bilinear, anti_aliasing, selective_smooth, smart_dither) to smooth textures. Includes intensity control, color sensitivity threshold adjustment, brightness and contrast controls, and palette reduction options.

### `Export Selection` - Quick export
Provides quick export functionality for 16×16 selections using Aseprite's native export dialog accessible directly from the MC Toolkit submenu.

## Installation

### **Method 1: Extension Package**
1. Download `mc-toolkit-2.1.0.aseprite-extension` from [releases](https://github.com/fresh-milkshake/aseprite-minecraft-toolkit/releases)
2. In Aseprite: **Edit > Preferences > Extensions**
3. Click **Add Extension** and select the downloaded file
4. Restart Aseprite

### **Method 2: Manual Installation**
1. Clone the repository or download the source
2. Copy the `scripts` folder contents to your Aseprite extensions directory:
   - **Windows**: `%APPDATA%\Roaming\Aseprite\extensions\mc-toolkit\`
   - **macOS**: `~/Library/Application Support/Aseprite/extensions/mc-toolkit/`
   - **Linux**: `~/.config/aseprite/extensions/mc-toolkit/`
3. Copy `package.json` and `extension-keys.aseprite-keys` to the same directory
4. Restart Aseprite

---

## Usage Guide

### **Basic Workflow**
1. Open your texture in Aseprite
2. Select a 16×16 pixel area using the selection tool
3. Navigate to **Edit → MC Toolkit** and choose your desired tool
4. Configure parameters in the dialog window
5. Apply changes or export results

### **Tool Access**
- All functions available via: **Sprite → MC Toolkit**
- Requires active sprite with 16×16 selection
- Export Selection functions as `Ctrl + Shift + Alt + S`

## Project Structure

```
scripts/
├── extension.lua               # Entry point
├── core/                       # Core utilities
│   ├── constants.lua           # Configuration constants
│   ├── math_utils.lua          # 3D mathematics
│   ├── color_utils.lua         # Color space conversions
│   └── selection_utils.lua     # Selection handling
├── features/                   # Main functionality
│   ├── render_3d.lua           # 3D block renderer
│   ├── hue_shift.lua           # Color variant generator
│   ├── intermediate_colors.lua # Some kind of color interpolation
│   ├── render_adjacent.lua     # Tiling preview
│   └── export.lua              # Alias to Aseprite's export dialog in fact
└── ui/
    └── background_renderer.lua # Redundant module, but I'm too lazy to remove it
```

## Disclaimer

*MC Toolkit is not affiliated with Mojang Studios or Microsoft. Minecraft is a trademark of Mojang Studios.*
