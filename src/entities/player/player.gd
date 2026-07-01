extends CharacterBody2D

# Hubungkan dengan TileMapLayer kamu melalui Inspector
@export var tilemap_layer: TileMapLayer 

# ── SISTEM INVENTORY LANGSUNG DI SINI ──────────────────────────────────────
var inventory: Dictionary = {}

func add_item(item_name: String, amount: int = 1) -> void:
	if inventory.has(item_name):
		inventory[item_name] += amount
	else:
		inventory[item_name] = amount
	print("ISI KANTONG PLAYER: ", inventory) # Akan muncul di Output bawah

# ── Enums ──────────────────────────────────────────────────────────────────

enum PlayerState {
	IDLE,
	WALK,
	INTERACT,
	IN_COMBAT,
}

# ── Signals ────────────────────────────────────────────────────────────────

signal entered_combat
signal state_changed(new_state: PlayerState)

# ── Constants ──────────────────────────────────────────────────────────────

const SPEED: float = 120.0

const RAY_OFFSETS: Dictionary = {
	"down":  Vector2(0, 24),   
	"up":    Vector2(0, -24),  
	"left":  Vector2(-20, 0),  
	"right": Vector2(20, 0),   
}

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
			pass

	move_and_slide()

# ── FSM State Handlers ────────────────────────────────────────────────────

func _state_idle(_delta: float) -> void:
	var input_dir := _get_input_direction()

	if input_dir != Vector2.ZERO:
		_change_state(PlayerState.WALK)
		return

	if Input.is_action_just_pressed("interact") or Input.is_physical_key_pressed(KEY_E):
		_change_state(PlayerState.INTERACT)
		return

	velocity = velocity.move_toward(Vector2.ZERO, SPEED)


func _state_walk(_delta: float) -> void:
	var input_dir := _get_input_direction()

	if input_dir == Vector2.ZERO:
		_change_state(PlayerState.IDLE)
		return

	var normalized_dir := input_dir.normalized()
	velocity = normalized_dir * SPEED

	_update_facing_direction(normalized_dir)

	var anim_name: String = WALK_ANIMS.get(facing_direction, "walk_down")
	if animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)

	_update_interact_ray()

	if Engine.has_singleton("PlayerStats") or has_node("/root/PlayerStats"):
		var stats = get_node_or_null("/root/PlayerStats")
		if stats:
			stats.last_position = global_position
			stats.last_direction = facing_direction


func _state_interact(_delta: float) -> void:
	velocity = Vector2.ZERO

	if interact_ray.is_colliding():
		var collider = interact_ray.get_collider()
		if collider and collider.has_method("interact"):
			collider.interact()
	else:
		check_and_take_plant()

	_change_state(PlayerState.IDLE)

# ── State Transition ──────────────────────────────────────────────────────

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
			animated_sprite.play("idle")
		PlayerState.IN_COMBAT:
			velocity = Vector2.ZERO
			animated_sprite.play("idle")
			entered_combat.emit()

# ── MEKANISME AMBIL TANAMAN & SIMPAN ITEM ──────────────────────────────────

func check_and_take_plant() -> void:
	if not tilemap_layer: return
	
	var target_global_pos = interact_ray.to_global(interact_ray.target_position)
	var hit_grid_pos = tilemap_layer.local_to_map(tilemap_layer.to_local(target_global_pos))
	
	var tile_data = tilemap_layer.get_cell_tile_data(hit_grid_pos)
	
	if tile_data and tile_data.get_custom_data("is_plant"):
		# MASUKIN KE INVENTORY PLAYER LANGSUNG
		add_item("Gandum", 1)
		
		# Hapus tile yang kena hit
		tilemap_layer.set_cell(hit_grid_pos, -1)
		
		# Cek tetangga bawah
		var bottom_neighbor = hit_grid_pos + Vector2i(0, 1)
		var bottom_data = tilemap_layer.get_cell_tile_data(bottom_neighbor)
		if bottom_data and bottom_data.get_custom_data("is_plant"):
			tilemap_layer.set_cell(bottom_neighbor, -1)
			
		# Cek tetangga atas
		var top_neighbor = hit_grid_pos + Vector2i(0, -1)
		var top_data = tilemap_layer.get_cell_tile_data(top_neighbor)
		if top_data and top_data.get_custom_data("is_plant"):
			tilemap_layer.set_cell(top_neighbor, -1)

# ── Combat Helpers ──────────────────────────────────────────────────────────

func exit_combat() -> void:
	_change_state(PlayerState.IDLE)

func enter_combat() -> void:
	_change_state(PlayerState.IN_COMBAT)

# ── Input Helpers ──────────────────────────────────────────────────────────

func _get_input_direction() -> Vector2:
	var dir := Vector2.ZERO

	var left  := Input.is_action_pressed("move_left")  or Input.is_action_pressed("ui_left")  or Input.is_physical_key_pressed(KEY_A)
	var right := Input.is_action_pressed("move_right") or Input.is_action_pressed("ui_right") or Input.is_physical_key_pressed(KEY_D)
	var up    := Input.is_action_pressed("move_up")    or Input.is_action_pressed("ui_up")    or Input.is_physical_key_pressed(KEY_W)
	var down  := Input.is_action_pressed("move_down")  or Input.is_action_pressed("ui_down")  or Input.is_physical_key_pressed(KEY_S)

	if left:  dir.x -= 1
	if right: dir.x += 1
	if up:    dir.y -= 1
	if down:  dir.y += 1

	return dir


func _update_facing_direction(dir: Vector2) -> void:
	if abs(dir.x) >= abs(dir.y):
		facing_direction = "right" if dir.x > 0 else "left"
	else:
		facing_direction = "down" if dir.y > 0 else "up"


func _update_interact_ray() -> void:
	if interact_ray:
		interact_ray.target_position = RAY_OFFSETS.get(facing_direction, Vector2(0, 24))
