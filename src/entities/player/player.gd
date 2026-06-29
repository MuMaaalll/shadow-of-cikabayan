extends CharacterBody2D
## ==========================================================================
## player.gd — FSM-based Top-Down Player Controller
## Shadow of Cikabayan | Godot 4.6
##
## Implements a Finite State Machine with 4 states:
##   IDLE → WALK → INTERACT → IN_COMBAT
##
## Designed for 8-way directional movement with normalized diagonal speed.
## Integrates with PlayerStats autoload for persistent state tracking.
## ==========================================================================

# ── Enums ──────────────────────────────────────────────────────────────────

enum PlayerState {
	IDLE,
	WALK,
	INTERACT,
	IN_COMBAT,
}

# ── Signals ────────────────────────────────────────────────────────────────

## Emitted when the player enters a combat zone. combat_manager.gd listens.
signal entered_combat
## Emitted when the player state changes (for debugging / HUD).
signal state_changed(new_state: PlayerState)

# ── Constants ──────────────────────────────────────────────────────────────

const SPEED: float = 120.0

## RayCast2D target offsets per direction (used for InteractRay).
const RAY_OFFSETS: Dictionary = {
	"down":  Vector2(0, 64),
	"up":    Vector2(0, -64),
	"left":  Vector2(-64, 0),
	"right": Vector2(64, 0),
}

## Maps facing_direction to walk animation names.
## Matches SpriteFrames names in irving.tscn exactly.
const WALK_ANIMS: Dictionary = {
	"down":  "walk_down",
	"up":    "walk_up",
	"left":  "walk_left",
	"right": "Walk_Right",
}

# ── Node References ───────────────────────────────────────────────────────

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interact_ray: RayCast2D = $InteractRay
@onready var camera: Camera2D = $Camera2D

# ── State Variables ────────────────────────────────────────────────────────

var current_state: PlayerState = PlayerState.IDLE
var facing_direction: String = "down"

# ── Lifecycle ──────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("player")
	# Sync initial facing direction with InteractRay
	_update_interact_ray()
	animated_sprite.play("idle")


func _physics_process(delta: float) -> void:
	match current_state:
		PlayerState.IDLE:
			_state_idle(delta)
		PlayerState.WALK:
			_state_walk(delta)
		PlayerState.INTERACT:
			_state_interact(delta)
		PlayerState.IN_COMBAT:
			# Combat manager takes full control; do nothing here.
			pass

	# Always apply movement (velocity may be zero in IDLE)
	move_and_slide()

# ── FSM State Handlers ────────────────────────────────────────────────────

## IDLE: Waiting for input. Transitions to WALK or INTERACT.
func _state_idle(_delta: float) -> void:
	var input_dir := _get_input_direction()

	if input_dir != Vector2.ZERO:
		_change_state(PlayerState.WALK)
		return

	# Check for interact input (E key)
	if Input.is_action_just_pressed("interact") or Input.is_physical_key_pressed(KEY_E):
		if interact_ray.is_colliding():
			_change_state(PlayerState.INTERACT)
			return

	# Decelerate to zero
	velocity = velocity.move_toward(Vector2.ZERO, SPEED)


## WALK: Moving in 8 directions. Transitions to IDLE when no input.
func _state_walk(_delta: float) -> void:
	var input_dir := _get_input_direction()

	if input_dir == Vector2.ZERO:
		_change_state(PlayerState.IDLE)
		return

	# Normalize to prevent faster diagonal movement
	var normalized_dir := input_dir.normalized()
	velocity = normalized_dir * SPEED

	# Update facing direction based on dominant axis
	_update_facing_direction(normalized_dir)

	# Play walk animation for current direction
	var anim_name: String = WALK_ANIMS.get(facing_direction, "walk_down")
	if animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)

	# Keep InteractRay pointing the right way
	_update_interact_ray()

	# Sync position to PlayerStats for save system
	if Engine.has_singleton("PlayerStats") or has_node("/root/PlayerStats"):
		var stats = get_node_or_null("/root/PlayerStats")
		if stats:
			stats.last_position = global_position
			stats.last_direction = facing_direction


## INTERACT: Playing interaction animation, then returning to IDLE.
func _state_interact(_delta: float) -> void:
	velocity = Vector2.ZERO

	# If we have a collider, trigger its interact method
	var collider = interact_ray.get_collider()
	if collider and collider.has_method("interact"):
		collider.interact()

	# Return to IDLE after interaction (no animation for now)
	_change_state(PlayerState.IDLE)

# ── State Transition ──────────────────────────────────────────────────────

## Central state change function. Handles entry actions for each state.
func _change_state(new_state: PlayerState) -> void:
	if current_state == new_state:
		return

	current_state = new_state
	state_changed.emit(new_state)

	match new_state:
		PlayerState.IDLE:
			animated_sprite.play("idle")
		PlayerState.WALK:
			var anim_name: String = WALK_ANIMS.get(facing_direction, "walk_down")
			animated_sprite.play(anim_name)
		PlayerState.INTERACT:
			# Future: play "interact" animation if it exists
			animated_sprite.play("idle")
		PlayerState.IN_COMBAT:
			velocity = Vector2.ZERO
			animated_sprite.play("idle")
			entered_combat.emit()


## Called by combat_manager.gd when battle ends.
func exit_combat() -> void:
	_change_state(PlayerState.IDLE)


## Called by Area2D combat zones to freeze the player.
func enter_combat() -> void:
	_change_state(PlayerState.IN_COMBAT)

# ── Input Helpers ──────────────────────────────────────────────────────────

## Returns raw (unnormalized) input direction vector.
func _get_input_direction() -> Vector2:
	var dir := Vector2.ZERO

	# Support both Input Map actions and raw key detection
	var left  := Input.is_action_pressed("move_left")  or Input.is_action_pressed("ui_left")  or Input.is_physical_key_pressed(KEY_A)
	var right := Input.is_action_pressed("move_right") or Input.is_action_pressed("ui_right") or Input.is_physical_key_pressed(KEY_D)
	var up    := Input.is_action_pressed("move_up")    or Input.is_action_pressed("ui_up")    or Input.is_physical_key_pressed(KEY_W)
	var down  := Input.is_action_pressed("move_down")  or Input.is_action_pressed("ui_down")  or Input.is_physical_key_pressed(KEY_S)

	if left:  dir.x -= 1
	if right: dir.x += 1
	if up:    dir.y -= 1
	if down:  dir.y += 1

	return dir


## Updates facing_direction based on the dominant axis of movement.
func _update_facing_direction(dir: Vector2) -> void:
	if abs(dir.x) >= abs(dir.y):
		facing_direction = "right" if dir.x > 0 else "left"
	else:
		facing_direction = "down" if dir.y > 0 else "up"


## Points the InteractRay in the current facing direction.
func _update_interact_ray() -> void:
	if interact_ray:
		interact_ray.target_position = RAY_OFFSETS.get(facing_direction, Vector2(0, 64))
