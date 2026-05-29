# Git Workflow — Shadow of Cikabayan

> **For AI Agents:** These rules prevent merge conflicts in a 3-person team
> where one member owns scene files and two others own scripts.

---

## 1. Branch Strategy

```
main
├── hikmal/level-design       ← .tscn scene files, spritesheets, tilesets
├── melandri/gameplay         ← .gd gameplay scripts, combat logic
└── irfan/shaders             ← .gdshader files, particle scene
```

**Merge order:** Each member merges to `main` only via Pull Request.
Never push directly to `main`.

---

## 2. File Ownership Rules

| File Type | Owner Branch | Other branches CANNOT |
|-----------|-------------|----------------------|
| `.tscn` in `src/levels/` | `hikmal/level-design` | Edit or commit |
| `.tscn` in `src/entities/` | `hikmal/level-design` | Edit or commit |
| `.gd` scripts | `melandri/gameplay` | Edit Melandri's scripts |
| `.gdshader` files | `irfan/shaders` | Edit or commit |
| `assets/sprites/` | `hikmal/level-design` | Edit PNG files |

---

## 3. How Melandri Attaches Scripts Without Editing .tscn

Instead of opening Hikmal's scene and saving it, Melandri uses **code-based instantiation**:

```gdscript
# In game_manager.gd — spawn Irving from Melandri's branch
var irving_scene = preload("res://src/entities/player/irving.tscn")
var irving = irving_scene.instantiate()
irving.set_script(preload("res://src/entities/player/player.gd"))
get_tree().current_scene.add_child(irving)
irving.position = $SpawnPoints/PlayerSpawn.position
```

> ⚠️ This way Melandri never touches `irving.tscn` directly.

---

## 4. How Irfan Adds Particles Without Editing .tscn

Irfan creates `disintegration_particles.tscn` as a **standalone sub-scene**.
It gets instantiated by Melandri's combat script when enemy HP = 0:

```gdscript
# In combat_manager.gd
func _play_disintegration(enemy_node: Node2D) -> void:
    var burst = preload("res://src/entities/enemies/disintegration_particles.tscn").instantiate()
    enemy_node.get_parent().add_child(burst)
    burst.global_position = enemy_node.get_node("DisintegrationPoint").global_position
    burst.emitting = true
```

---

## 5. Commit Message Convention

```
[HIKMAL] Add kebun_cikabayan tilemap layer
[MELANDRI] Implement combat FSM ActionTurn state
[IRFAN] Add chromatic aberration to sanity shader
[ALL] Merge sprint-1 to main
```

---

## 6. What To Do When There's a Conflict

1. STOP — do not force push
2. Call the file owner (check ownership table above)
3. The **owner** resolves the conflict on their branch
4. Non-owner discards their changes to that file
5. Re-merge cleanly
