# Shader Reference — Shadow of Cikabayan

> **For AI Agents:** All shaders use Godot 4 canvas_item shader syntax.
> Owner: Muhammad Irfan Daniswara
> Never suggest 3D shaders or spatial shader_type.

---

## 1. Sanity Distortion Shader

**File:** `src/entities/player/sanity_shader.gdshader`
**Type:** Screen-space post-processing (CanvasItem)
**Trigger:** When Irving's SAN stat drops below 40

### Math Basis

The distortion uses a **sine wave displacement** on UV coordinates:

```
uv.x(t) = uv.x + sin(uv.y × f + t) × A
```

Where:
- `uv.y` = vertical screen coordinate (0.0 → 1.0)
- `f` = frequency (how many wave cycles across screen height)
- `t` = TIME (Godot built-in, seconds elapsed)
- `A` = distortion_intensity (amplitude, driven by SAN value)

Intensity mapping from SAN to shader uniform:
```
A = clamp((40 - SAN) / 40, 0.0, 1.0) × 0.1
```

### Full Shader Code

```glsl
shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;
uniform float distortion_intensity : hint_range(0.0, 0.1) = 0.0;
uniform float frequency : hint_range(0.0, 50.0) = 10.0;
uniform float chromatic_offset : hint_range(0.0, 0.02) = 0.0;

void fragment() {
    vec2 uv = SCREEN_UV;

    // Wave distortion
    uv.x += sin(uv.y * frequency + TIME) * distortion_intensity;

    // Chromatic aberration (RGB channel split)
    float r = texture(SCREEN_TEXTURE, uv + vec2(chromatic_offset, 0.0)).r;
    float g = texture(SCREEN_TEXTURE, uv).g;
    float b = texture(SCREEN_TEXTURE, uv - vec2(chromatic_offset, 0.0)).b;

    COLOR = vec4(r, g, b, 1.0);
}
```

### Godot Scene Setup

```
SanityPostFX (CanvasLayer)
    layer = 10
    └── ColorRect
            anchor_right = 1.0
            anchor_bottom = 1.0
            ShaderMaterial
                shader = sanity_shader.gdshader
```

### Driving from GDScript (Melandri's side)

```gdscript
# In player_stats.gd
func set_sanity(value: int) -> void:
    san = clamp(value, 0, max_san)
    var intensity = 0.0
    var chroma = 0.0
    if san < 40:
        var t = clamp((40.0 - san) / 40.0, 0.0, 1.0)
        intensity = t * 0.1
        chroma = t * 0.015
    var mat = $"/root/SanityPostFX/ColorRect".material
    mat.set_shader_parameter("distortion_intensity", intensity)
    mat.set_shader_parameter("chromatic_offset", chroma)
    emit_signal("sanity_changed", san)
```

---

## 2. Contamination Shield Shader

**File:** `src/entities/enemies/contamination_shield.gdshader`
**Type:** Sprite-level CanvasItem shader
**Applied to:** `AnimatedSprite2D` material on enemies when shield is active

```glsl
shader_type canvas_item;

uniform float pulse_speed : hint_range(0.5, 5.0) = 2.0;
uniform vec4 shield_color : source_color = vec4(0.0, 1.0, 0.5, 1.0);
uniform float rim_width : hint_range(0.0, 0.1) = 0.03;
uniform bool shield_active = true;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    if (!shield_active) {
        COLOR = tex;
        return;
    }

    // Detect sprite edge pixels by sampling neighbors
    float alpha_n = texture(TEXTURE, UV + vec2(0.0,  rim_width)).a;
    float alpha_s = texture(TEXTURE, UV + vec2(0.0, -rim_width)).a;
    float alpha_e = texture(TEXTURE, UV + vec2( rim_width, 0.0)).a;
    float alpha_w = texture(TEXTURE, UV + vec2(-rim_width, 0.0)).a;

    float is_edge = tex.a * (1.0 - min(min(alpha_n, alpha_s), min(alpha_e, alpha_w)));
    float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;

    vec4 glow = shield_color * is_edge * pulse;
    COLOR = tex + glow;
}
```

---

## 3. Lighting Setup Reference

### PointLight2D (Irving's Flashlight)

| Property | Value |
|----------|-------|
| `texture` | `flashlight_cone.png` (custom gradient) |
| `energy` | 1.5 |
| `range_height` | 64 |
| `mode` | ADD |
| `shadow_enabled` | true |
| `shadow_filter` | PCF5 |

### LightOccluder2D (Hikmal places, Irfan verifies)

| Property | Value |
|----------|-------|
| `occluder` | `OccluderPolygon2D` (hand-drawn per object) |
| `culling_mode` | Clockwise |

### Night Atmosphere

| Node | Property | Value |
|------|----------|-------|
| `CanvasModulate` | `color` | `#0D0D1A` (dark blue-black) |
| `WorldEnvironment` | ambient energy | 0.05 |
