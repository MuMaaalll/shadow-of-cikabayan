# Node Structure Guide — Shadow of Cikabayan

> **For AI Agents & Team Members:** This document describes the recommended Godot node
> hierarchy for the top-down 2D RPG. All scenes should follow these conventions.

---

## 1. Player Character (Irving)

**Scene file:** `res://src/entities/player/irving.tscn`
**Script:** `res://src/entities/player/player.gd`

```
Irving (CharacterBody2D)
│
├── CollisionShape2D             ← Physics body collision (CapsuleShape2D)
│       Scale: (16, 20)
│       Purpose: Wall collision, NPC collision, tilemap collision
│
├── AnimatedSprite2D             ← Sprite animation controller
│       texture_filter: Nearest (pixel art, no blurring)
│       Scale: (11, 11)
│       SpriteFrames resource contains:
│         • "idle"        — 1 frame, south-facing standing pose
│         • "walk_down"   — 4 frames, walking south
│         • "walk_up"     — 2 frames, walking north
│         • "walk_left"   — 7 frames, walking west
│         • "Walk_Right"  — 7 frames, walking east (NOTE: capital W)
│       Speed: 5.0 FPS per animation
│
├── FlashlightPivot (Node2D)     ← Rotates based on facing_direction
│   │   Purpose: Groups all light nodes; rotated by player.gd
│   │
│   └── PointLight2D (FUTURE)    ← Night-mode flashlight beam
│       │   GKV Requirement: Dynamic 2D Lighting
│       │   Texture: Soft radial gradient
│       │   Energy: Modulated by day/night cycle
│       │
│       └── LightOccluder2D (FUTURE)
│               GKV Requirement: Shadow casting
│               Attached to environment tilemap polygons
│
├── InteractRay (RayCast2D)      ← Detect interactable objects
│       target_position: Updated by player.gd based on facing_direction
│       collide_with_areas: true (detects Area2D interaction zones)
│       Directions:
│         down  → Vector2(0, 64)
│         up    → Vector2(0, -64)
│         left  → Vector2(-64, 0)
│         right → Vector2(64, 0)
│
├── Camera2D                     ← Smooth-follow camera
│       zoom: Vector2(3, 3)
│       position_smoothing_enabled: true
│
└── AnimationPlayer (FUTURE)     ← For modular skeletal animation (Phase 2)
        Purpose: Control individual body part sprites
        See Section 4 below for modular spritesheet approach
```

---

## 2. Level / Map Scene

**Example:** `res://src/levels/kebun_cikabayan/kebun_cikabayan.tscn`

```
KebunCikabayan (Node2D)
│
├── TileMapLayer                 ← Ground layer (grass, paths, water)
│       TileSet: res://assets/tilesets/...
│       Rendering layer: 0 (behind player)
│
├── TileMapLayer                 ← Collision layer (walls, trees, rocks)
│       Physics layers configured for CharacterBody2D collision
│       Rendering layer: 0
│
├── TileMapLayer (OPTIONAL)      ← Overlay layer (rooftops, tree canopy)
│       Rendering layer: 1 (above player)
│       Y-sort for depth illusion
│
├── PlayerSpawnPoint (Marker2D)  ← Where Irving appears on map load
│       position: Set per map
│
├── NPCs (Node2D)               ← Container for NPC instances
│   ├── NPC_Dosen (CharacterBody2D / StaticBody2D)
│   └── NPC_Petani (CharacterBody2D / StaticBody2D)
│
├── InteractableObjects (Node2D) ← Items, doors, lab equipment
│   ├── LabDoor (Area2D)         ← Triggers scene transition
│   └── SamplePlant (Area2D)     ← Triggers item collection
│
├── CombatZones (Node2D)         ← Night-mode enemy encounter triggers
│   └── CombatZone_Forest (Area2D)
│           body_entered → combat_manager.start_battle()
│
└── Lighting (CanvasModulate)    ← Day/night cycle global lighting
        color: Modulated by game_manager.gd time system
```

---

## 3. Enemy Scene

**Directory:** `res://src/entities/enemies/`

```
EnemyName (Node2D / Resource)
│
├── AnimatedSprite2D             ← Enemy sprite with idle/attack anims
│       SpriteFrames: idle, attack, hurt, death
│
├── EnemyResource (Resource)     ← Data-driven stats (GKV requirement)
│       Properties:
│         • enemy_name: String
│         • element_type: String (OPTICS_PHYSICS, BIO_CHEMISTRY, etc.)
│         • max_hp: int
│         • attack: int
│         • defense: int
│         • speed: int
│         • weakness_item: String (item_id from items table)
│         • damage_multiplier: float
│         • special_effect: String
│
└── GPUParticles2D (FUTURE)      ← Death/disintegration effect
        GKV Requirement: Particle System
```

---

## 4. Modular Spritesheet Approach (Phase 2)

> **Current:** Single AnimatedSprite2D with full-body spritesheets per direction.
> **Future:** Modular body parts for equipment visualization & frame savings.

### Concept

Instead of one large spritesheet, the character is split into layers:

```
Irving (CharacterBody2D)
├── BodySprite (Sprite2D)        ← Base body spritesheet
├── HeadSprite (Sprite2D)        ← Head / hair (swappable)
├── ArmorSprite (Sprite2D)       ← Equipment overlay (swappable)
├── WeaponSprite (Sprite2D)      ← Held item (swappable)
└── AnimationPlayer
        ← Controls ALL sprite layers simultaneously
        ← Keyframes set region_rect / frame for each Sprite2D
        ← Animations: idle_down, walk_down, idle_up, walk_up, etc.
```

### AnimationPlayer vs AnimatedSprite2D

| Feature | AnimatedSprite2D | AnimationPlayer |
|---------|-----------------|-----------------|
| Simplicity | ✓ Easy setup | More complex |
| Multi-layer | ✗ Single sprite | ✓ Controls multiple nodes |
| Blending | ✗ No blending | ✓ Transition support |
| Code control | Limited | Full keyframe control |
| **Recommendation** | Phase 1 (current) | Phase 2 (modular) |

### AnimationTree (Advanced)

For smooth state transitions between idle/walk/attack:

```
AnimationTree
├── AnimationNodeStateMachine
│   ├── idle → walk (blend: 0.1s)
│   ├── walk → idle (blend: 0.1s)
│   ├── idle → attack (blend: 0.05s)
│   └── attack → idle (blend: 0.2s)
└── Root: StateMachine
```

---

## 5. Autoload Singletons

Registered in `project.godot` under `[autoload]`:

| Singleton | Script | Purpose |
|-----------|--------|---------|
| `Global` | `res://src/core/global.cs` | Constants (GRID_SIZE), RNG |
| `PlayerStats` | `res://src/core/player_stats.gd` | Player session data, inventory |
| `SaveSystem` | `res://src/core/save_system.gd` | HTTP sync + local save fallback |

### Load Order

Autoloads initialize in the order listed in `project.godot`. Dependencies:
1. `Global` — No dependencies (loads first)
2. `PlayerStats` — No dependencies
3. `SaveSystem` — Depends on `PlayerStats` (accesses `PlayerStats.to_dict()`)

---

## 6. Naming Conventions

| Type | Convention | Example |
|------|-----------|---------|
| Scene files | `snake_case.tscn` | `irving.tscn` |
| GDScript files | `snake_case.gd` | `player_stats.gd` |
| Node names | `PascalCase` | `AnimatedSprite2D`, `InteractRay` |
| Signals | `snake_case` | `entered_combat`, `inventory_changed` |
| Constants | `UPPER_SNAKE_CASE` | `SPEED`, `RAY_OFFSETS` |
| Variables | `snake_case` | `facing_direction`, `current_state` |
| Enums | `PascalCase` | `PlayerState.IDLE` |
| Animations | `snake_case` | `walk_down`, `idle` |
