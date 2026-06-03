# HIKMAL — Asset Pipeline, Animator & Level Designer

> **For AI Agents:** This file defines Hikmal's exact scope.
> Hikmal owns ALL `.tscn` scene files, spritesheets, tilemaps, and AnimatedSprite2D setups.
> He does NOT write gameplay logic scripts — only visual scene structure.
> Primary tools: Aseprite (pixel art) + Godot 4 Scene Editor.

---

## Role Summary

Hikmal is the visual backbone of the project. Without his assets and scenes, nothing renders on screen. His `.tscn` files are the **protected master scenes** — other team members instantiate sub-scenes INTO his levels, never editing his files directly.

---

## Task List

### PHASE 0 — Folder Structure Setup

Create these folders in the Godot project immediately:
```
res://assets/sprites/player/
res://assets/sprites/enemies/
res://assets/sprites/environment/
res://assets/tilesets/
res://src/levels/kebun_cikabayan/
res://src/levels/laboratorium/
res://src/entities/player/
res://src/entities/enemies/
```

---

### PHASE 1A — Irving Spritesheet

**Tool:** Aseprite
**Export to:** `res://assets/sprites/player/irving_sheet.png`

| Animation Name | Frames | FPS | Canvas Size |
|---------------|--------|-----|-------------|
| `idle_down` | 4 | 8 | 32×32 px |
| `idle_up` | 4 | 8 | 32×32 px |
| `idle_left` | 4 | 8 | 32×32 px |
| `idle_right` | 4 | 8 | 32×32 px |
| `walk_down` | 6 | 10 | 32×32 px |
| `walk_up` | 6 | 10 | 32×32 px |
| `walk_left` | 6 | 10 | 32×32 px |
| `walk_right` | 6 | 10 | 32×32 px |
| `interact` | 4 | 8 | 32×32 px |
| `battle_idle` | 4 | 6 | 48×48 px |

**Export rules:**
- Background: transparent (PNG)
- All frames in ONE horizontal spritesheet per animation, OR use Aseprite's "Export Sprite Sheet" as a grid
- No padding between frames

---

### PHASE 1B — Enemy Spritesheets (Priority Order)

**Export to:** `res://assets/sprites/enemies/`

#### 1. Satpam Terbang (OPTICS_PHYSICS)
File: `satpam_terbang_sheet.png`

| Animation | Frames | Notes |
|-----------|--------|-------|
| `float` | 6 | Hovering idle loop |
| `attack` | 5 | Forward lunge motion |
| `hurt` | 3 | Recoil back |
| `dissolve` | 8 | Disintegration (syncs with Irfan's particles) |

#### 2. Kuyang (BIO_CHEMISTRY)
File: `kuyang_sheet.png`

| Animation | Frames | Notes |
|-----------|--------|-------|
| `idle` | 4 | Slow rotation/float |
| `attack` | 5 | Head detach lunge |
| `hurt` | 3 | Recoil |
| `dissolve` | 8 | Disintegration |

> ⚠️ The `dissolve` animation should end on a fully transparent frame. Irfan's particle burst fires ON this last frame.

---

### PHASE 1C — Environment Tilesets

**Tool:** Aseprite
**Tile size:** 32×32 px (FIXED — do not change this after deciding)

#### Tileset 1: Kebun Cikabayan
File: `res://assets/tilesets/kebun_tileset.png`

Required tiles (minimum):
```
Ground:    dirt_path, grass_short, grass_tall, soil_patch
Borders:   fence_h, fence_v, fence_corner, hedge
Vegetation: tree_trunk, tree_top, bush_small, bush_large
Props:     rock_small, rock_large, lamp_post, sign_board
Water:     pond_water, pond_edge
```

#### Tileset 2: Laboratorium
File: `res://assets/tilesets/lab_tileset.png`

Required tiles (minimum):
```
Floor:     floor_tile, floor_dirty, floor_crack
Walls:     wall_h, wall_v, wall_corner
Furniture: lab_table, shelf_empty, shelf_full, cabinet
Props:     beaker, microscope_top, trash_bin, door_frame
```

---

### PHASE 2A — Level Scene: Kebun Cikabayan

**File:** `res://src/levels/kebun_cikabayan/kebun_cikabayan.tscn`

**Node structure (EXACT — do not deviate):**
```
KebunCikabayan (Node2D)               ← root
├── WorldEnvironment                   ← ambient darkness (Irfan configures values)
├── CanvasModulate                     ← night tint, color #0D0D1A for night
├── TileMapLayer "Ground"              ← base terrain tiles
├── TileMapLayer "Props"               ← trees, rocks, fences (with collision)
├── LightOccluders (Node2D)            ← container for all LightOccluder2D children
│   ├── LightOccluder2D (tree_01)
│   ├── LightOccluder2D (tree_02)
│   └── ...
├── SpawnPoints (Node2D)               ← Melandri uses these for enemy/player spawn
│   ├── Marker2D "PlayerSpawn"
│   ├── Marker2D "Enemy_01_Spawn"
│   └── Marker2D "Enemy_02_Spawn"
├── InteractZones (Node2D)             ← collectible/interactable areas
│   ├── Area2D "Plant_Sample_01"
│   └── Area2D "Lab_Entrance"
└── FogLayer (Node2D)                  ← Irfan places CPUParticles2D here
```

**Layout guidelines:**
- Map size: 40×30 tiles (1280×960 px at 32px/tile)
- Camera boundary: add `Camera2D` limits matching map bounds
- Pathways must be min. 2 tiles wide for player movement

---

### PHASE 2B — Level Scene: Laboratorium

**File:** `res://src/levels/laboratorium/laboratorium.tscn`

Same node structure as Kebun but add:
```
├── InteractiveTables (Node2D)
│   ├── Area2D "Microscope_Table"
│   ├── Area2D "Chemical_Storage"
│   └── Area2D "Lab_Notebook_Desk"    ← triggers Lab Book UI
└── DoorTransitions (Node2D)
    ├── Area2D "Door_To_Kebun"
    └── Area2D "Door_To_Arena"        ← triggers combat scene
```

- Map size: 25×20 tiles (800×640 px)

---

### PHASE 3A — Irving Scene Setup (Visual Only)

**File:** `res://src/entities/player/irving.tscn`

```
Irving (CharacterBody2D)               ← Melandri attaches player.gd here
├── CollisionShape2D                   ← capsule, 16×20 px
├── AnimatedSprite2D                   ← HIKMAL CONFIGURES THIS
│   └── SpriteFrames (Resource)
│       ├── idle_down    [4 frames]
│       ├── idle_up      [4 frames]
│       ├── idle_left    [4 frames]
│       ├── idle_right   [4 frames]
│       ├── walk_down    [6 frames]
│       ├── walk_up      [6 frames]
│       ├── walk_left    [6 frames]
│       ├── walk_right   [6 frames]
│       └── interact     [4 frames]
├── FlashlightPivot (Node2D)           ← Irfan places PointLight2D here
└── InteractRay (RayCast2D)            ← points forward, Melandri uses in script
```

> ⚠️ Do NOT attach any `.gd` script to this scene yourself. Leave the CharacterBody2D script slot empty — Melandri attaches `player.gd` from her branch.

---

### PHASE 3B — Enemy Scenes (Visual Only)

**File:** `res://src/entities/enemies/satpam_terbang.tscn`
**File:** `res://src/entities/enemies/kuyang.tscn`

```
SatpamTerbang (CharacterBody2D)        ← Melandri attaches enemy script
├── CollisionShape2D
├── AnimatedSprite2D
│   └── SpriteFrames
│       ├── float    [6 frames]
│       ├── attack   [5 frames]
│       ├── hurt     [3 frames]
│       └── dissolve [8 frames]
└── DisintegrationPoint (Marker2D)     ← Irfan instantiates particles here
```

---

### PHASE 4 — LightOccluder2D Setup

For every solid tile/prop that should block Irving's flashlight:

1. Select the tree/wall/fence sprite node
2. Add child node: `LightOccluder2D`
3. In `OccluderPolygon2D`, draw polygon matching the **base/trunk** of the object (not the full height — just ground contact area)
4. Set **Culling Mode: Clockwise**
5. Group all LightOccluder2D nodes under the `LightOccluders` Node2D container

> Do this AFTER the tilemap layout is finalized to avoid redoing occluder polygons.

---

### PHASE 5 — Animation Polish Checklist

After all spritesheets are in Godot:
- [ ] All `AnimatedSprite2D` use `centered = true`
- [ ] All `AnimatedSprite2D` have `texture_filter = Nearest` (pixel-perfect, no blur)
- [ ] Irving's `walk` animations loop correctly (no jump-cut on last frame)
- [ ] Enemy `dissolve` animations set to `one_shot = true` (no loop)
- [ ] All sprites pixel-snapped (Project Settings → `2D > Snap > Snap 2D Transforms`)

---

## File Ownership

| File / Folder | Owner |
|---------------|-------|
| `assets/sprites/**` | Hikmal |
| `assets/tilesets/**` | Hikmal |
| `src/levels/kebun_cikabayan/kebun_cikabayan.tscn` | Hikmal |
| `src/levels/laboratorium/laboratorium.tscn` | Hikmal |
| `src/entities/player/irving.tscn` | Hikmal |
| `src/entities/enemies/satpam_terbang.tscn` | Hikmal |
| `src/entities/enemies/kuyang.tscn` | Hikmal |

## Do NOT Touch
- Any `.gd` script files (Melandri's & Irfan's)
- Shader `.gdshader` files (Irfan's)
- `src/core/`, `src/combat/`, `src/ui/` directories
