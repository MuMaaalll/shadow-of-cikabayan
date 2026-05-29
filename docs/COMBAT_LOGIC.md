# Combat Logic — Shadow of Cikabayan

> **For AI Agents:** This document defines the element evaluation system.
> File: `src/combat/formula_eval.gd`
> Owner: Melandri Rasya Arindhi

---

## 1. Element Type Enum

```gdscript
enum EnemyElementType {
    OPTICS_PHYSICS,    # Satpam Terbang — weakness: light reflection
    BIO_CHEMISTRY,     # Kuyang — weakness: acidic compounds
    BOTANY_HERBICIDE,  # Zombie Cikabayan — weakness: herbicide formulas
    BIO_PHARMACY,      # Sosok Hitam — weakness: aromatherapy / calming agents
    AGROECOLOGY        # Penjaga Hutan (Final Boss) — weakness: ecosystem restoration
}
```

---

## 2. Formula→Element Weakness Matrix

| Formula ID | Target Element | Damage Multiplier | Special Effect |
|------------|---------------|-------------------|----------------|
| `Reflective_Mirror` | `OPTICS_PHYSICS` | 2.5x | STUN (skip 1 enemy turn) |
| `Acidic_Extract` | `BIO_CHEMISTRY` | 2.0x | — |
| `Herbicide_Spray` | `BOTANY_HERBICIDE` | 2.0x | — |
| `Aromatherapy` | `BIO_PHARMACY` | 0.0x (no dmg) | RESTORE_SAN +30 |
| `Compost_Enzyme` | `AGROECOLOGY` | 2.0x | WEAKEN (−1 atk) |
| **(wrong formula)** | **(any)** | 0.0x | SHIELD_RESTORED |

---

## 3. GDScript Implementation

```gdscript
# src/combat/formula_eval.gd

extends Node

enum EnemyElementType {
    OPTICS_PHYSICS,
    BIO_CHEMISTRY,
    BOTANY_HERBICIDE,
    BIO_PHARMACY,
    AGROECOLOGY
}

const FORMULA_MATRIX: Dictionary = {
    # Key format: "FormulaID|ElementType"
    "Reflective_Mirror|0":  { "multiplier": 2.5, "effect": "STUN" },
    "Acidic_Extract|1":     { "multiplier": 2.0, "effect": "NONE" },
    "Herbicide_Spray|2":    { "multiplier": 2.0, "effect": "NONE" },
    "Aromatherapy|3":       { "multiplier": 0.0, "effect": "RESTORE_SAN_30" },
    "Compost_Enzyme|4":     { "multiplier": 2.0, "effect": "WEAKEN" },
}

const DEFAULT_WRONG_RESULT = { "multiplier": 0.0, "effect": "SHIELD_RESTORED" }
const DEFAULT_NORMAL_RESULT = { "multiplier": 1.0, "effect": "NONE" }

func evaluate(formula_id: String, element: EnemyElementType) -> Dictionary:
    var key = formula_id + "|" + str(int(element))
    if FORMULA_MATRIX.has(key):
        return FORMULA_MATRIX[key]
    # Formula used but wrong element → immune
    return DEFAULT_WRONG_RESULT
```

---

## 4. Damage Calculation

```gdscript
# Applied in combat_manager.gd after EvalFormula state

func _calculate_damage(base_damage: int, eval_result: Dictionary) -> int:
    return int(base_damage * eval_result["multiplier"])

func _apply_effect(effect: String) -> void:
    match effect:
        "STUN":
            current_enemy.is_stunned = true
        "RESTORE_SAN_30":
            PlayerStats.set_sanity(PlayerStats.san + 30)
        "SHIELD_RESTORED":
            current_enemy.contamination_shield += 20  # Punish wrong answer
        "WEAKEN":
            current_enemy.attack_damage = max(0, current_enemy.attack_damage - 1)
        "NONE":
            pass
```

---

## 5. Shield Mechanic

Every enemy starts with a `contamination_shield` value (e.g., 100).

- Correct formula hit → `contamination_shield -= damage`
- Wrong formula → `contamination_shield += 20` (shield grows back, punishes player)
- When `contamination_shield <= 0` → enemy vulnerable, `hp` can be reduced
- When `hp <= 0` → trigger `dissolve` animation → Victory state
