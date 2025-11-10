# 🧭 Super Language Quest of Fury — Codex Task: DevTools (v2.2)

## 🎯 Purpose
This Codex session is **dedicated to building and extending the in-game DevTools system** for *Super Language Quest of Fury* (SLQOF).
It focuses on developing real-time control, debugging, and input-mapping tools fully integrated into the existing Godot project.

The generated code must remain **fully consistent** with the project’s architecture and conventions as defined in *Brief of Transmission – v2.2 Coordination*.

---

## 🧩 Technical Context
| Element | Value |
|----------|--------|
| 🎮 Engine | Godot Engine 4.5 (GDScript) |
| 🧱 Active branch | `refacto` |
| 🌐 Repository | [github.com/SubUuboot/language-quest-of-fury](https://github.com/SubUuboot/language-quest-of-fury) |
| ⚙️ Conventions | - Tabs only (no spaces)<br>- Explicit typing for all local variables<br>- No `?` ternary operator (use `a if condition else b`)<br>- Keep names and styles consistent with SLQOF core scripts |

---

## 🧠 Expected Behavior
Codex acts as the **primary code generator** for this module.
It must:
1. Produce complete, functional and consistent GDScript code.
2. Align all function names, variables and node paths with the repository conventions.
3. Generate scripts or `.tscn` scene definitions compatible with `GameBootstrap`, `InputBootstrap`, and `TankController2D`.

After generation, the Chat session will handle **review, annotation, and fine-tuning**.

---

## 🎛️ DevTools Modules to Implement

| Module | Description | Goal |
|---------|--------------|------|
| **1. Tank Mechanics Interface** | Interactive sliders for torque, friction, clutch strength, RPM, etc. | Real-time mechanical tuning of the tank. |
| **2. Input Remapper** | In-game key reassignment system (keyboard/gamepad). | Dynamic input rebinding linked to `InputBootstrap`. |
| **3. Debug Panels** | Tabbed panels (Physics, Dialogue, Signals, MotherAI). | Live display of core system values. |
| **4. Sandbox Safety Layer** | Prevent DevTools adjustments from affecting gameplay during normal stages. | Full isolation between debug and production modes. |

---

## 🧰 Key Files and Dependencies
- `GameBootstrap.gd` and `GameBootstrap_Plan.md`
- `StageManager.gd`
- `TankController2D.gd`
- `InputBootstrap.gd`
- `DialogueSystem.gd`
- `Documentation/StageFlow.md` and `.puml`
- `Brief_de_Transmission_v2.2.md`

---

## 🧪 Development Rules
- Must follow the initialization order:
  `Bootstrap → Input → DevTools → Stage → Tank`
- Code must be reversible and non-persistent outside of debug mode.
- DevTools must be **easily disabled** in production builds.
- Avoid hard-coding file paths; use Godot’s `preload` or `get_node()` safely.
- Ensure all UI nodes are **instantiated dynamically** or linked to a dedicated `DevTools.tscn`.

---

## 📘 Mission Objective
Deliver a **robust, modular, and extendable DevTools subsystem** that can:
- Adjust tank physics parameters in real time 🛞
- Remap inputs dynamically ⌨️
- Display live debug data from all systems 🔍
- Remain fully optional in release builds 🚫

---

> 🧭 *SLQOF – DevTools v2.2*: Codex generates consistent, production-grade GDScript aligned with the architecture of the Super Language Quest of Fury project.
> Do not break conventions, dependencies, or initialization order.
