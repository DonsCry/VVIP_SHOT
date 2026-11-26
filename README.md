# 🎮 VVIP // Universal Aimbot & ESP (Roblox Lua)

[![Roblox](https://img.shields.io/badge/Roblox-Luau-00A2FF?style=for-the-badge&logo=roblox&logoColor=white)](https://developer.roblox.com/)
[![Executor](https://img.shields.io/badge/Executor-Xeno%20Compatible-10B981?style=for-the-badge)](https://github.com/EdgeIY/xenova)
[![Renderer](https://img.shields.io/badge/Renderer-Drawing%20API-8B5CF6?style=for-the-badge)](https://developer.roblox.com/en-us/articles/Drawing)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

---

## ✨ Overview
A **single‑file**, **global‑scope** script that delivers **premium‑grade** Aimbot and ESP capabilities for Roblox. It works out‑of‑the‑box with the **Xeno** executor (or any executor that supports the built‑in `Drawing` API) and ships with a **dark‑luxury, glass‑morphism UI** that feels right at home in any game.

---

## 📚 Table of Contents
- [Features](#-features)
- [Installation](#-installation)
- [Quick‑Start Guide](#-quick-start-guide)
- [Configuration](#-configuration)
- [Control Panel UI](#-control-panel-ui)
- [Keybinds & Presets](#-keybinds--presets)
- [Contributing](#-contributing)
- [License](#-license)
- [Disclaimer](#-disclaimer)

---

## 🚀 Features
| Category | Highlights |
| :--- | :--- |
| **Aimbot** | • **Smooth** Camera or Mouse turn (`Lerp` 0.1‑0.2) <br>• **Dynamic FOV** circle – filled, rainbow, thickness options <br>• **Velocity prediction** & Head/Root targeting <br>• **Priority weighting** – crosshair, distance, health <br>• **Sticky lock**, optional **RMB‑hold** mode, **Auto‑Fire** (`mouse1click`) |
| **ESP / Wallhack** | • 3D Wireframe & 2D Box rendering <br>• R15 & R6 **Skeleton** support <br>• **Chams** & team‑based coloring <br>• Tracers (Center ↔ Feet/Root/Head) <br>• Health bars & name‑distance labels (Drawing or optional `BillboardGui`) <br>• `SeeThroughWalls` toggle |
| **Visibility** | • Raycast `Workspace:Raycast` line‑of‑sight with transparency filtering (`≥ 0.95`) |
| **Control Panel** | • Draggable, glass‑morphism UI <br>• Live FPS / target / entity status <br>• **Presets** – *Full VIP* (max power) & *Legit* (subtle) <br>• Customizable themes, sliders, and real‑time config editing |

---

## 📦 Installation
```bash
# Clone the repository (or download the ZIP)
git clone https://github.com/DonsCry/VVIP_SHOT.git
```
The repository contains a single script: `UniversalAimbotESP.lua`. No extra dependencies are required.

> **Note** – Ensure your executor (Xeno, Synapse, etc.) supports the global `Drawing.new` API.

---

## 🎮 Quick‑Start Guide
1. Open your executor (**Xeno** recommended).
2. Paste the **entire** contents of [`UniversalAimbotESP.lua`](./UniversalAimbotESP.lua) and execute **or** load it directly from the repo with a one‑liner:
   ```lua
   loadstring(game:HttpGet("https://raw.githubusercontent.com/DonsCry/VVIP_SHOT/main/UniversalAimbotESP.lua"))()
   ```
3. The **VVIP Control Panel** will appear in‑game. Press `Q` (default) to toggle the aimbot.

---

## ⚙️ Configuration
All options live in the top‑level **`Config`** table. You can edit them in the script **or** adjust them live via the UI.
```lua
Config.Aim.ToggleKey      = Enum.KeyCode.Q      -- Toggle aimbot
Config.Aim.FOV            = 140                 -- Radius of FOV circle (px)
Config.Aim.Smoothing      = 0.16                -- Lerp factor (lower = smoother)
Config.Aim.AimMethod      = "Camera"          -- "Camera" or "Mouse"

Config.ESP.SeeThroughWalls = true              -- Render through walls
Config.ESP.BoxStyle        = "3D"              -- "3D" or "2D"
Config.ESP.UseBillboard    = false              -- Use BillboardGui for labels
```
For a comprehensive list of options, open the **Settings** tab in the control panel.

---

## 🎨 Control Panel UI (Dark Luxury)
![Control Panel](https://raw.githubusercontent.com/DonsCry/VVIP_SHOT/main/assets/control_panel.png)
*The panel utilizes glass‑morphism, soft gradients, and subtle animations to give a premium feel.*

- **Tabs** – Aimbot, ESP, Settings, Presets
- **Presets** – *Full VIP* (all features) & *Legit* (minimal)
- **Watermark** – Shows script version & a VVIP badge
- **Live Stats** – FPS, target distance, entity count

---

## ⌨️ Keybinds & Presets
| Key | Action |
| :--- | :--- |
| `Q` | Toggle Aimbot ON / OFF |
| `RightControl` | Show / Hide VVIP Control Panel |
| `RightShift` | Unload script & clean up all drawings / connections |

All keys are **remappable** from the Settings tab.

---

## 🤝 Contributing
Contributions are welcome! Feel free to:
- Open an **issue** for bugs or feature requests.
- Submit a **pull request** with improvements or new UI themes.
- Add additional **presets** or **config options**.

Please follow the existing code style and keep the script **single‑file** and **global‑scope**.

---

## 📄 License
This project is licensed under the **MIT License** – you may use, modify, and distribute it freely. Attribution is appreciated but not required.

---

## ⚠️ Disclaimer
*This script is provided for **educational** and **authorized testing** purposes only.* Using it in multiplayer games may violate Roblox's Terms of Service. Use responsibly and respect the rules set by game creators.
