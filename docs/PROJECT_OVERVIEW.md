# Shadow of Cikabayan — Master Project Context

> **For AI Agents:** This is the single source of truth for the entire project.
> Always read this file first before reading any task-specific document.

---

## 1. Project Identity

| Field | Value |
|-------|-------|
| **Project Name** | Shadow of Cikabayan |
| **Genre** | Edutainment Horror RPG, Turn-Based Combat |
| **Engine** | Godot 4 (GDScript) |
| **Art Style** | 16-bit JRPG Pixel Art, Top-down 2D |
| **Course** | Grafika Komputer dan Visualisasi (GKV) — IPB University |
| **Institution** | Ilmu Komputer, IPB University (Dramaga, Bogor) |

---

## 2. Core Concept

Players take the role of **Irving**, a student researcher at Kebun & Laboratorium Penelitian Cikabayan (IPB). The game runs on a **Day/Night cycle**:

- **Day (Exploration):** Irving explores Kebun Cikabayan and the Research Lab. He identifies vegetation, collects biopharmaceutical samples, analyzes plant diseases, and unlocks crafting recipes in his **Lab Notebook**.
- **Night (Combat):** Turn-based battles against contamination manifestations (local IPB folklore ghosts). Each enemy is shielded by a **Contamination Shield** that can ONLY be broken by the exact matching science formula.

### The Educational Hook
Every combat action requires applying real science:
- **Physics (Optics)** → defeats Satpam Terbang
- **Bio-Chemistry** → defeats Kuyang
- **Botany / Herbicide** → defeats Zombie Cikabayan
- **Bio-Pharmacy** → defeats Sosok Hitam
- **Agroecology** → defeats Penjaga Hutan (Final Boss)

---

## 3. Team & Roles

| Name | Role | Primary Responsibility |
|------|------|----------------------|
| **Melandri Rasya Arindhi** | Gameplay Programmer & System Designer | FSM, combat logic, player controller, `combat_manager.gd`, `formula_eval.gd` |
| **Muhammad Irfan Daniswara** | GKV Technical Artist & Shader Programmer | Custom shaders, 2D lighting, particle systems, post-processing FX |
| **Muhammad Hikmal Fadhil Agis** | Asset Pipeline, Animator & Level Designer | Spritesheets, tilemaps, scene layout, `LightOccluder2D`, animation frames |

---

## 4. Enemies & Element Matrix

| Enemy | Element Type | Weakness Item | Damage Multiplier | Special Effect |
|-------|-------------|---------------|-------------------|----------------|
| Satpam Terbang | `OPTICS_PHYSICS` | `Reflective_Mirror` | 2.5x | Stun |
| Kuyang | `BIO_CHEMISTRY` | `Acidic_Extract` | 2.0x | — |
| Zombie Cikabayan | `BOTANY_HERBICIDE` | TBD | 2.0x | — |
| Sosok Hitam | `BIO_PHARMACY` | `Aromatherapy` | — | Restores SAN +30 |
| Penjaga Hutan | `AGROECOLOGY` | TBD | TBD | Final Boss |

> Wrong formula → `DamageMultiplier = 0.0x` (Immune + Shield Restored)

---

## 5. Key GKV Technical Requirements

These are **mandatory deliverables** for the GKV course:

1. **Finite State Machine (FSM)** — Irving movement + turn-based battle flow
2. **Dynamic 2D Lighting** — Irving's flashlight via `PointLight2D` + `LightOccluder2D` shadows
3. **Custom Fragment Shader** — Sanity distortion effect when SAN < 40%
4. **Particle System** — Atmospheric fog + ghost disintegration via `GPUParticles2D`
5. **Data-Driven Architecture** — Enemy stats as Godot `Resource` objects

---

## 6. Scope Boundaries (STRICT)

### ✅ In-Scope
- 1 chapter playable area: Kebun Cikabayan + Laboratorium
- Turn-based combat system
- Crafting via Lab Notebook UI
- Day/Night cycle (exploration → combat)

### ❌ Out-of-Scope (Never Implement)
- Real-time hack-and-slash combat
- Open-world or areas beyond 1 chapter
- Multiplayer or cloud saving
- 3D visuals
- High-level AI pathfinding for enemies

---

## 7. Project Directory Structure

```
res://
├── assets/
│   ├── sprites/
│   │   ├── player/
│   │   ├── enemies/
│   │   └── environment/
│   ├── tilesets/
│   ├── music/
│   └── sfx/
└── src/
    ├── core/               # Autoload singletons
    ├── entities/           # Player & enemy scenes
    ├── levels/             # Map scenes & tilemaps
    ├── combat/             # Battle system scripts
    └── ui/                 # HUD, menus, lab book
```

---

## 8. Related Documents

| Document | Path | Description |
|----------|------|-------------|
| Team Tasks | `docs/tasks/` | Per-member breakdown |
| FSM Architecture | `docs/technical/FSM_ARCHITECTURE.md` | State machine spec |
| Shader Reference | `docs/technical/SHADER_REFERENCE.md` | GKV shader code |
| Combat Logic | `docs/technical/COMBAT_LOGIC.md` | Element evaluation |
| Git Workflow | `docs/workflow/GIT_WORKFLOW.md` | Branch & conflict rules |
