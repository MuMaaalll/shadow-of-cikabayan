# MELANDRI — Gameplay Programmer & System Designer

> **For AI Agents:** This file defines Melandri's exact scope.
> Do NOT suggest tasks that belong to Irfan (shaders/lighting) or Hikmal (assets/levels).
> All code lives in GDScript 4.x syntax.

---

## Role Summary

Melandri owns all **game logic, state machines, and system architecture**.
She writes scripts but does NOT directly edit `.tscn` scene files owned by Hikmal.
She interfaces with Hikmal's scenes by **instantiating sub-scenes** programmatically.

---

## Task List

### PHASE 0 — Foundation
- [ ] `src/core/game_manager.gd` — Autoload singleton, manages scene transitions and global game state
- [ ] `src/core/player_stats.gd` — Autoload singleton, holds Irving's HP, SAN, inventory array
- [ ] Register both as Autoloads in `Project > Project Settings > Autoload`

### PHASE 1 — Player Controller FSM

**File:** `src/entities/player/player.gd`
Attach to: `CharacterBody2D` node in Irving's scene

States to implement:
```
IDLE → WALK → INTERACT → IN_COMBAT
```

Key signals to emit:
```gdscript
signal entered_combat_zone(enemy_data: EnemyResource)
signal item_used(formula_id: String)
signal sanity_changed(new_value: int)
```

### PHASE 2 — Combat FSM

**File:** `src/combat/combat_manager.gd`

Battle state flow:
```
InitBattle → CheckSpeed → ActionTurn → EvalFormula → CheckWinLoseCondition
     ↑_______________________________________________|
```

States as enum:
```gdscript
enum BattleState {
    INIT_BATTLE,
    CHECK_SPEED,
    ACTION_TURN,
    EVAL_FORMULA,
    CHECK_WIN_LOSE
}
```

### PHASE 3 — Formula Evaluator

**File:** `src/combat/formula_eval.gd`

Core function signature:
```gdscript
func evaluate(formula_id: String, enemy_element: EnemyElementType) -> EvalResult:
    # Returns: { multiplier: float, effect: String }
```

Element enum:
```gdscript
enum EnemyElementType {
    OPTICS_PHYSICS,    # Satpam Terbang
    BIO_CHEMISTRY,     # Kuyang
    BOTANY_HERBICIDE,  # Zombie Cikabayan
    BIO_PHARMACY,      # Sosok Hitam
    AGROECOLOGY        # Penjaga Hutan
}
```

Evaluation matrix:
```gdscript
const FORMULA_MATRIX = {
    ["Reflective_Mirror", EnemyElementType.OPTICS_PHYSICS]:  { "multiplier": 2.5, "effect": "STUN" },
    ["Acidic_Extract",    EnemyElementType.BIO_CHEMISTRY]:   { "multiplier": 2.0, "effect": "NONE" },
    ["Aromatherapy",      EnemyElementType.BIO_PHARMACY]:    { "multiplier": 0.0, "effect": "RESTORE_SAN_30" },
}
# Default (wrong formula): multiplier = 0.0, effect = "SHIELD_RESTORED"
```

### PHASE 4 — Enemy Resource Data

**File:** `src/entities/enemies/enemy_resource.gd` (extends Resource)

```gdscript
@export var enemy_name: String
@export var max_hp: int
@export var contamination_level: int
@export var speed: int
@export var element_type: EnemyElementType
@export var attack_damage: int
@export var sprite_path: String   # Path to Hikmal's spritesheet
```

Create `.tres` data files per enemy:
- `satpam_terbang.tres`
- `kuyang.tres`

### PHASE 5 — SAN Integration with Shader

Listen for `sanity_changed` signal → pass value to Irfan's shader:
```gdscript
func _on_sanity_changed(new_san: int):
    var intensity = clamp((40.0 - new_san) / 40.0, 0.0, 1.0)
    # Push to shader via ShaderMaterial uniform
    $SanityShaderLayer.material.set_shader_parameter("distortion_intensity", intensity * 0.1)
```

---

## File Ownership

| File | Owner | Notes |
|------|-------|-------|
| `player.gd` | Melandri | Attach to Irving's CharacterBody2D |
| `combat_manager.gd` | Melandri | Central battle FSM |
| `formula_eval.gd` | Melandri | Element evaluation logic |
| `enemy_resource.gd` | Melandri | Data class, Hikmal fills `.tres` values |
| `game_manager.gd` | Melandri | Global autoload |
| `player_stats.gd` | Melandri | Global stats autoload |

## Do NOT Touch
- Any `.tscn` file in `src/levels/` (Hikmal's)
- Shader `.gdshader` files (Irfan's)
- Spritesheet PNGs (Hikmal's)
