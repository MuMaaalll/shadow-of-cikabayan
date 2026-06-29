extends Node
## ==========================================================================
## player_stats.gd — Player Session Data Singleton (Autoload)
## Shadow of Cikabayan | Godot 4.6
##
## Holds all player session data that persists across scene transitions.
## Accessed globally via: PlayerStats.player_name, PlayerStats.inventory, etc.
##
## Register as Autoload in Project Settings:
##   PlayerStats = "res://src/core/player_stats.gd"
## ==========================================================================

# ── Signals ────────────────────────────────────────────────────────────────

## Emitted when inventory changes (for HUD updates).
signal inventory_changed
## Emitted when player data is loaded from server.
signal data_loaded

# ── Player Identity (from Google OAuth) ────────────────────────────────────

var player_id: String = ""
var player_name: String = ""
var player_email: String = ""
var avatar_url: String = ""
var session_token: String = ""

# ── Position & Map State ──────────────────────────────────────────────────

var current_map_id: String = "kebun_cikabayan"
var last_position: Vector2 = Vector2(570, 321)
var last_direction: String = "down"

# ── Combat Stats ──────────────────────────────────────────────────────────

var max_hp: int = 100
var current_hp: int = 100
var max_sanity: int = 100
var current_sanity: int = 100
var speed: int = 10
var attack: int = 15
var defense: int = 10

# ── Inventory ─────────────────────────────────────────────────────────────
## Each entry: { "item_id": String, "name": String, "quantity": int, "slot_index": int }
var inventory: Array[Dictionary] = []

# ── Game State Flags ──────────────────────────────────────────────────────
## Key-value store for flexible game progress tracking.
## Example: { "boss_defeated_kuyang": true, "lab_notebook_unlocked": true }
var game_flags: Dictionary = {}

# ── Lifecycle ──────────────────────────────────────────────────────────────

func _ready() -> void:
	print("[PlayerStats] Singleton loaded.")

# ── Inventory Management ─────────────────────────────────────────────────

## Add an item to inventory. Stacks if item_id already exists.
func add_item(item_id: String, item_name: String, quantity: int = 1) -> void:
	# Check if item already exists in inventory
	for item in inventory:
		if item["item_id"] == item_id:
			item["quantity"] += quantity
			inventory_changed.emit()
			return

	# Add new item to first available slot
	var slot := inventory.size()
	inventory.append({
		"item_id": item_id,
		"name": item_name,
		"quantity": quantity,
		"slot_index": slot,
	})
	inventory_changed.emit()


## Remove quantity of an item. Returns true if successful.
func remove_item(item_id: String, quantity: int = 1) -> bool:
	for i in range(inventory.size()):
		if inventory[i]["item_id"] == item_id:
			inventory[i]["quantity"] -= quantity
			if inventory[i]["quantity"] <= 0:
				inventory.remove_at(i)
			inventory_changed.emit()
			return true
	return false


## Check if player has at least `quantity` of an item.
func has_item(item_id: String, quantity: int = 1) -> bool:
	for item in inventory:
		if item["item_id"] == item_id and item["quantity"] >= quantity:
			return true
	return false


## Get the quantity of a specific item. Returns 0 if not found.
func get_item_quantity(item_id: String) -> int:
	for item in inventory:
		if item["item_id"] == item_id:
			return item["quantity"]
	return 0

# ── Game Flags ────────────────────────────────────────────────────────────

## Set a game progress flag.
func set_flag(key: String, value: Variant = true) -> void:
	game_flags[key] = value


## Get a game progress flag. Returns default if not set.
func get_flag(key: String, default: Variant = false) -> Variant:
	return game_flags.get(key, default)


## Check if a flag is set and truthy.
func has_flag(key: String) -> bool:
	return game_flags.get(key, false) == true

# ── Serialization ─────────────────────────────────────────────────────────

## Export all player data as a Dictionary (for HTTP sync / local save).
func to_dict() -> Dictionary:
	return {
		"player_id": player_id,
		"player_name": player_name,
		"player_email": player_email,
		"session_token": session_token,
		"current_map_id": current_map_id,
		"x": last_position.x,
		"y": last_position.y,
		"direction": last_direction,
		"hp": current_hp,
		"sanity": current_sanity,
		"inventory": inventory.duplicate(true),
		"game_flags": game_flags.duplicate(true),
	}


## Import player data from a Dictionary (from HTTP response / local save).
func from_dict(data: Dictionary) -> void:
	player_id = data.get("player_id", "")
	player_name = data.get("player_name", "")
	player_email = data.get("player_email", "")
	session_token = data.get("session_token", "")
	current_map_id = data.get("current_map_id", "kebun_cikabayan")
	last_position = Vector2(data.get("x", 570.0), data.get("y", 321.0))
	last_direction = data.get("direction", "down")
	current_hp = data.get("hp", max_hp)
	current_sanity = data.get("sanity", max_sanity)

	# Rebuild inventory array
	inventory.clear()
	var inv_data: Array = data.get("inventory", [])
	for item in inv_data:
		inventory.append(item)

	# Rebuild game flags
	game_flags = data.get("game_flags", {})

	data_loaded.emit()
	inventory_changed.emit()
	print("[PlayerStats] Data loaded from dict.")
