extends Node
## ==========================================================================
## game_manager.gd — Global Game Manager Singleton (Autoload)
## Shadow of Cikabayan | Godot 4.6
##
## Manages global game state, scene transitions, and entering/exiting combat.
## ==========================================================================

signal battle_started(enemy: EnemyResource)
signal battle_ended(victory: bool)

## Path to the combat arena scene
const COMBAT_ARENA_PATH: String = "res://src/combat/combat_arena.tscn"

var current_world_scene: Node = null
var current_combat_instance: Node = null
var is_in_battle: bool = false
var active_enemy: EnemyResource = null

func _ready() -> void:
	print("[GameManager] Singleton loaded.")
	# Store the current scene as the world scene initially
	var root = get_tree().root
	current_world_scene = root.get_child(root.get_child_count() - 1)

## Initiates a battle transition when colliding with an enemy (like Kunti)
## Initiates a battle transition when colliding with an enemy (like Kunti)
func start_battle(enemy_data: EnemyResource) -> void:
	if is_in_battle:
		return
	
	print("[GameManager] Transitioning to battle with: ", enemy_data.enemy_name)
	is_in_battle = true
	active_enemy = enemy_data
	

	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("enter_combat"):
		player.enter_combat()
	
	battle_started.emit(enemy_data)
	
	if ResourceLoader.exists(COMBAT_ARENA_PATH):
		var arena_scene = load(COMBAT_ARENA_PATH)
		if arena_scene:
			current_combat_instance = arena_scene.instantiate()
			
			if current_world_scene:
				current_world_scene.process_mode = Node.PROCESS_MODE_DISABLED
				
				for child in current_world_scene.get_children():
					if "visible" in child:
						child.visible = false
			
			get_tree().root.add_child(current_combat_instance)
			print("[GameManager] Combat Arena instanced.")

## Exits the battle and returns to exploration
func end_battle(victory: bool) -> void:
	if not is_in_battle:
		return
	
	print("[GameManager] Battle ended. Victory: ", victory)
	is_in_battle = false
	active_enemy = null
	
	# Clean up combat instance
	if current_combat_instance and is_instance_valid(current_combat_instance):
		current_combat_instance.queue_free()
		current_combat_instance = null
	
	# PERBAIKAN DI SINI: Kembalikan proses dan wujud map dunia
	if current_world_scene and is_instance_valid(current_world_scene):
		current_world_scene.process_mode = Node.PROCESS_MODE_INHERIT
		
		# Tampilkan kembali semua map 2D di bawah SceneHandler
		for child in current_world_scene.get_children():
			if "visible" in child:
				child.visible = true
	
	# Return player to IDLE state
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("exit_combat"):
		player.exit_combat()
		
	battle_ended.emit(victory)
