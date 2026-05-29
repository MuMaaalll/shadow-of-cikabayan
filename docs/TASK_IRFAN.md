# IRFAN — GKV Technical Artist & Shader Programmer

> **For AI Agents:** This file defines Irfan's exact scope.
> Irfan owns ALL visual effects, shaders, lighting, and particles.
> He does NOT write gameplay logic — only rendering and visual systems.
> All shaders use Godot 4 GLSL-based shader syntax (`shader_type canvas_item`).

---

## Role Summary

Irfan is responsible for every pixel-level visual effect that makes the game *feel* like a horror RPG. His three core deliverables are:
1. **Sanity Distortion Shader** (GKV core requirement)
2. **Dynamic 2D Lighting** with Irving's flashlight
3. **Particle Systems** for atmosphere and combat FX

---

## Task List

### PHASE 1 — Sanity Distortion Shader (PRIORITY #1 — GKV Requirement)

**File:** `src/entities/player/sanity_shader.gdshader`

This is a **screen-space post-processing shader** applied to a `CanvasLayer` node that sits on top of the entire game viewport.

```glsl
shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;
uniform float distortion_intensity : hint_range(0.0, 0.1) = 0.0;
uniform float frequency : hint_range(0.0, 50.0) = 10.0;
uniform float chromatic_offset : hint_range(0.0, 0.02) = 0.0;

void fragment() {
    vec2 uv = SCREEN_UV;

    // Wave distortion (sine-based glitch)
    uv.x += sin(uv.y * frequency + TIME) * distortion_intensity;

    // Chromatic aberration (RGB channel split)
    float r = texture(SCREEN_TEXTURE, uv + vec2(chromatic_offset, 0.0)).r;
    float g = texture(SCREEN_TEXTURE, uv).g;
    float b = texture(SCREEN_TEXTURE, uv - vec2(chromatic_offset, 0.0)).b;

    COLOR = vec4(r, g, b, 1.0);
}
```

**Scene setup:**
```
SanityShaderLayer (CanvasLayer)  ← layer = 10 (above everything)
└── ColorRect (full viewport)
    └── ShaderMaterial → sanity_shader.gdshader
```

**Activation rule:**
- `distortion_intensity` = 0.0 when SAN ≥ 40
- `distortion_intensity` scales from 0.0 → 0.1 as SAN drops 40 → 0
- Melandri's `player_stats.gd` will call `set_shader_parameter()` to drive this value

---

### PHASE 2 — Irving's Flashlight (Dynamic 2D Lighting)

**Implemented inside:** `src/entities/player/irving.tscn` (coordinate with Hikmal)

Node setup inside Irving's scene:
```
Irving (CharacterBody2D)
└── FlashlightPivot (Node2D)   ← rotates with player facing direction
    └── PointLight2D
            texture: [cone_gradient.png]   ← custom texture, gradien dari terang ke gelap
            energy: 1.5
            range_height: 64
            mode: ADD
            shadow_enabled: true
```

**Cone texture requirements:**
- Create `assets/sprites/player/flashlight_cone.png`
- 64×64 px, gradient: white center → transparent edges, elongated vertically
- Simulates directional cone light, not omnidirectional circle

**Lighting environment:**
- Set `WorldEnvironment` ambient light to near-black (`Color(0.05, 0.05, 0.08)`) for night scenes
- `CanvasModulate` node set to dark blue `#0D0D1A` in night scenes

---

### PHASE 3 — LightOccluder Integration (Coordinate with Hikmal)

Irfan does NOT place LightOccluders — Hikmal does.
Irfan's job: **verify the shadow rendering is correct** after Hikmal places them.

Checklist:
- [ ] Occluder culling mode = `Clockwise` on all solid objects
- [ ] Irving's `PointLight2D` → `shadow_filter` = PCF5 (soft shadows)
- [ ] Test: walk Irving near a tree/wall, shadow should project away from light source

---

### PHASE 4 — Atmospheric Fog Particles

**File:** Add `CPUParticles2D` node to `kebun_cikabayan.tscn` (coordinate with Hikmal)

Settings:
```
amount: 80
lifetime: 6.0
emission_shape: Rectangle (full map width)
direction: (1, -0.2)     ← slow diagonal drift
spread: 30
initial_velocity: 8
color: Color(0.8, 0.9, 1.0, 0.15)   ← pale blue-white, very transparent
scale: 4.0 → 12.0 (random range)
```

---

### PHASE 5 — Ghost Disintegration Effect

**File:** `src/entities/enemies/disintegration_particles.tscn` (standalone sub-scene)

```
DisintegrationBurst (CPUParticles2D)
    amount: 120
    one_shot: true
    explosiveness: 0.9
    lifetime: 1.2
    emission_shape: Point
    direction: (0, -1)
    spread: 180
    gravity: (0, 98)
    color_ramp: enemy_color → transparent
    scale: 2.0 → 0.5
```

Hikmal's enemy scene will have an empty `Marker2D` node called `DisintegrationPoint`. Irfan instantiates this particle scene there when enemy HP = 0.

---

### PHASE 6 — Shield Contamination Shader (Enemy Visual)

**File:** `src/entities/enemies/contamination_shield.gdshader`

Pulsing rim-light effect on enemy sprite when shield is active:

```glsl
shader_type canvas_item;

uniform float pulse_speed : hint_range(0.5, 5.0) = 2.0;
uniform vec4 shield_color : source_color = vec4(0.0, 1.0, 0.5, 1.0);
uniform float rim_width : hint_range(0.0, 0.1) = 0.03;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    float alpha_edge = tex.a;

    // Rim glow on sprite edges
    float rim = step(1.0 - rim_width, alpha_edge) * sin(TIME * pulse_speed) * 0.5 + 0.5;
    vec4 rim_glow = shield_color * rim;

    COLOR = mix(tex, tex + rim_glow, rim);
}
```

---

## File Ownership

| File | Owner | Notes |
|------|-------|-------|
| `sanity_shader.gdshader` | Irfan | Screen-space post FX |
| `contamination_shield.gdshader` | Irfan | Enemy rim light shader |
| `flashlight_cone.png` | Irfan | Gradient texture for PointLight2D |
| `disintegration_particles.tscn` | Irfan | Standalone particle sub-scene |

## Do NOT Touch
- `combat_manager.gd`, `formula_eval.gd` (Melandri's)
- Tileset PNGs and level `.tscn` files (Hikmal's)
- `enemy_resource.gd` data files (Melandri's)
