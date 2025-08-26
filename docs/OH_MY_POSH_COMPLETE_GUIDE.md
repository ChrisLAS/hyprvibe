# Complete Oh My Posh Guide: Research, Themes & Configurations

## 📊 Research Summary

Based on extensive research of popular Oh My Posh setups, here are the key findings:

### **Most Popular Themes**
1. **Agnoster** - Classic powerline style, feature-rich
2. **Atomic** - Modern diamond style, distinctive appearance
3. **Robby Russell** - Minimalist, clean design
4. **Jan De Dobbeleer** - Creator's comprehensive theme
5. **Paradox** - Enhanced Agnoster with better colors

### **Most Valued Features**
1. **Git Integration** - Branch, status, changes, stash count
2. **Path Display** - Smart truncation with folder icons
3. **Development Tools** - Language/framework detection
4. **Execution Time** - Performance monitoring for slow commands
5. **Exit Status** - Visual feedback for command success/failure
6. **Time Display** - Current time in right prompt
7. **Session Info** - Username and hostname

### **Popular Visual Styles**
- **Powerline** - Angled separators, most popular
- **Diamond** - Modern, distinctive appearance
- **Plain** - Minimalist, distraction-free
- **Lean** - Clean, uncluttered

## 🎨 Available Configurations

### **1. Default Theme (Tokyo Night)**
**File**: `~/.config/oh-my-posh/config.json`
**Style**: Plain with Tokyo Night colors
**Best for**: Daily development work
**Features**:
- Tokyo Night color scheme
- Development tool detection
- Execution time tracking
- Exit status display
- Time in right prompt

### **2. Enhanced Theme (Agnoster-inspired)**
**File**: `~/.config/oh-my-posh/config-enhanced.json`
**Style**: Powerline with comprehensive features
**Best for**: Feature-rich development environment
**Features**:
- Root indicator with lightning bolt
- Session info (username@hostname)
- Agnoster-style path with folder icons
- Dynamic Git backgrounds
- Comprehensive dev tool detection
- Execution time and exit status

### **3. Minimal Theme (Robby Russell-inspired)**
**File**: `~/.config/oh-my-posh/config-minimal.json`
**Style**: Plain, distraction-free
**Best for**: Focused work, presentations
**Features**:
- Clean arrow separator
- Minimal Git information
- Simple path display
- Error indicator with X mark
- Time in right prompt

### **4. Professional Theme (Atomic-inspired)**
**File**: `~/.config/oh-my-posh/config-professional.json`
**Style**: Diamond with modern appearance
**Best for**: Professional presentations, modern look
**Features**:
- Diamond separators
- Shell type indicator
- Root warning with skull icon
- Dynamic Git backgrounds
- Comprehensive tool detection
- Professional color scheme

## 🚀 Quick Start Guide

### **Installation**
```bash
# Oh My Posh is already installed via NixOS
oh-my-posh --version
```

### **Switch Themes**
```bash
# Use the theme switcher script
./switch-oh-my-posh-theme.sh enhanced
./switch-oh-my-posh-theme.sh minimal
./switch-oh-my-posh-theme.sh professional
./switch-oh-my-posh-theme.sh default
```

### **Manual Theme Switching**
```bash
# Copy desired theme to main config
cp ~/.config/oh-my-posh/config-enhanced.json ~/.config/oh-my-posh/config.json

# Restart shell to see changes
exec fish
```

## 🎯 Popular Segments & Their Uses

### **Essential Segments**

#### **Path Segment**
```json
{
  "type": "path",
  "style": "powerline",
  "properties": {
    "style": "folder",
    "max_depth": 2,
    "max_width": 50,
    "folder_icon": "\uf115",
    "home_icon": "~"
  }
}
```
**Use**: Shows current directory with smart truncation

#### **Git Segment**
```json
{
  "type": "git",
  "style": "powerline",
  "properties": {
    "fetch_status": true,
    "fetch_upstream": true,
    "display_stash_count": true
  }
}
```
**Use**: Shows Git branch, status, changes, and stash count

#### **Session Segment**
```json
{
  "type": "session",
  "style": "powerline",
  "template": " {{ .UserName }}@{{ .HostName }} "
}
```
**Use**: Shows username and hostname

### **Development Tool Segments**

#### **Node.js**
```json
{
  "type": "node",
  "template": " \ue718 {{ .Full }} "
}
```
**Icon**: 📦 **Use**: Shows Node.js version when in Node.js projects

#### **Python**
```json
{
  "type": "python",
  "template": " \ue235 {{ if .Venv }}{{ .Venv }} {{ end }}{{ .Full }} "
}
```
**Icon**: 🐍 **Use**: Shows Python version and virtual environment

#### **Go**
```json
{
  "type": "go",
  "template": " \ue626 {{ .Full }} "
}
```
**Icon**: 🐹 **Use**: Shows Go version when in Go projects

#### **Rust**
```json
{
  "type": "rust",
  "template": " \ue7a8 {{ .Full }} "
}
```
**Icon**: 🦀 **Use**: Shows Rust version when in Rust projects

#### **Docker**
```json
{
  "type": "docker_context",
  "template": " \uf308 {{ .Context }} "
}
```
**Icon**: 🐳 **Use**: Shows Docker context when not default

### **System Segments**

#### **Execution Time**
```json
{
  "type": "execution_time",
  "properties": {
    "threshold": 5000
  },
  "template": " {{ .FormattedMs }} "
}
```
**Use**: Shows execution time for commands taking >5 seconds

#### **Exit Status**
```json
{
  "type": "exit",
  "properties": {
    "display_exit_code": true
  },
  "template": " {{ if gt .Code 0 }}\uf071 {{ .Code }}{{ end }} "
}
```
**Icon**: ⚠️ **Use**: Shows error icon and code for failed commands

#### **Time**
```json
{
  "type": "time",
  "properties": {
    "time_format": "15:04"
  },
  "template": " {{ .CurrentDate | date .Format }} "
}
```
**Use**: Shows current time in right prompt

## 🎨 Popular Color Schemes

### **Tokyo Night**
- Background: `#1a1b26`
- Foreground: `#c0caf5`
- Accent: `#7aa2f7`
- Success: `#9ece6a`
- Error: `#f7768e`

### **Agnoster**
- Root: `#ffe9aa` (yellow)
- Session: `#ffffff` (white)
- Path: `#91ddff` (light blue)
- Git: `#95ffa4` (light green)
- Python: `#906cff` (purple)

### **Atomic**
- Shell: `#0077c2` (blue)
- Root: `#ef5350` (red)
- Path: `#FF9248` (orange)
- Git: `#FFFB38` (yellow)

## 🔧 Advanced Features

### **Dynamic Backgrounds**
```json
"background_templates": [
  "{{ if or (.Working.Changed) (.Staging.Changed) }}#FF9248{{ end }}",
  "{{ if gt .Ahead 0 }}#B388FF{{ end }}",
  "{{ if gt .Behind 0 }}#B388FF{{ end }}"
]
```
**Use**: Changes Git segment background based on status

### **Conditional Display**
```json
"template": "{{ if .Venv }}{{ .Venv }} {{ end }}{{ .Full }}"
```
**Use**: Only shows virtual environment when active

### **Truncation**
```json
"properties": {
  "branch_template": "{{ trunc 25 .Branch }}"
}
```
**Use**: Limits branch name to 25 characters

### **Right Prompt**
```json
{
  "type": "rprompt",
  "segments": [
    {
      "type": "time",
      "template": " {{ .CurrentDate | date .Format }} "
    }
  ]
}
```
**Use**: Shows time on the right side of the prompt

## 📱 Popular Icons & Symbols

### **Nerd Font Icons**
- **Folder**: `\uf115` (📁)
- **Home**: `\ueb06` (🏠)
- **Git Branch**: `\ue725` (🌿)
- **Python**: `\ue235` (🐍)
- **Node.js**: `\ue718` (📦)
- **Go**: `\ue626` (🐹)
- **Rust**: `\ue7a8` (🦀)
- **Docker**: `\uf308` (🐳)
- **Root**: `\uf0e7` (⚡)
- **Error**: `\uf071` (⚠️)
- **Stash**: `\ueb4b` (📦)

### **Powerline Symbols**
- **Right Arrow**: `\ue0b0`
- **Left Arrow**: `\ue0b2`
- **Diamond**: `\ue0b6`
- **Folder Separator**: `\ue0b1`

## 🎯 Usage Recommendations

### **For Development Work**
- **Theme**: Enhanced or Professional
- **Features**: Git integration, dev tools, execution time
- **Style**: Powerline or Diamond

### **For Productivity/Focus**
- **Theme**: Minimal
- **Features**: Essential info only
- **Style**: Plain

### **For Presentations**
- **Theme**: Professional
- **Features**: Clean, modern appearance
- **Style**: Diamond

### **For Daily Use**
- **Theme**: Default (Tokyo Night)
- **Features**: Balanced functionality
- **Style**: Plain with colors

## 🔄 Theme Switching Workflow

1. **Choose your theme** based on current task
2. **Switch using the script**: `./switch-oh-my-posh-theme.sh [theme]`
3. **Restart shell**: `exec fish`
4. **Enjoy your new prompt!**

## 📈 Performance Tips

- **Use thresholds** for execution time (only show for slow commands)
- **Limit path depth** to 2-3 levels maximum
- **Use conditional display** to hide irrelevant segments
- **Cache results** (Oh My Posh does this automatically)
- **Async loading** for non-blocking updates

## 🎨 Customization Ideas

### **Personal Branding**
- Add custom emoji or symbols
- Use your favorite colors
- Include personal information

### **Work-Specific**
- Add company/project indicators
- Include environment information
- Show relevant tool versions

### **Productivity**
- Add task indicators
- Show focus mode status
- Include time tracking

This comprehensive guide provides everything you need to create beautiful, functional Oh My Posh prompts that enhance your development workflow!
