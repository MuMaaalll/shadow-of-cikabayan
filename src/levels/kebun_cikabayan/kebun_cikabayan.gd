extends Node2D
## ==========================================================================
## kebun_cikabayan.gd — Level Script for Kebun Cikabayan
## Shadow of Cikabayan | Godot 4.6
## ==========================================================================

func _ready() -> void:
	print("[KebunCikabayan] Level loaded. Spawning transition area to Hutan...")
	
	# Create Area2D programmatically at the right boundary
	var transition_area = Area2D.new()
	transition_area.name = "HutanTransition"
	# Tentukan posisi trigger di bagian kanan map kebun
	transition_area.position = Vector2(800, 40)
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(100, 1000) # Tembok trigger vertikal
	collision.shape = shape
	
	transition_area.add_child(collision)
	add_child(transition_area)
	
	# Hubungkan signal body_entered
	transition_area.body_entered.connect(_on_transition_entered)

func _on_transition_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("[KebunCikabayan] Player crossed transition area! Changing scene to Hutan Cikabayan...")
		
		# Set player stats map name
		var stats = get_node_or_null("/root/PlayerStats")
		if stats:
			stats.current_map_id = "hutan_cikabayan"
			stats.last_position = Vector2(50, 320) # Spawn player di kiri hutan
			
		get_tree().change_scene_to_file("res://src/levels/kebun_cikabayan/hutan_cikabayan.tscn")
