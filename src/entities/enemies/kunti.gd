extends CharacterBody2D
## ==========================================================================
## kunti.gd — Enemy trigger script for Kunti (CharacterBody2D)
## Shadow of Cikabayan | Godot 4.6
##
## Attached to the Kunti CharacterBody2D on the map.
## Triggers a battle via GameManager when player gets close.
## ==========================================================================

@export var enemy_data: EnemyResource

func _ready() -> void:
	# If no custom enemy data is assigned, create a default Kunti resource
	if not enemy_data:
		enemy_data = EnemyResource.new()
		enemy_data.enemy_name = "Kunti"
		enemy_data.max_hp = 80
		enemy_data.contamination_level = 100
		enemy_data.speed = 12
		enemy_data.element_type = EnemyResource.EnemyElementType.BIO_CHEMISTRY
		enemy_data.attack_damage = 10
	
	# Play idle animation if the node has AnimatedSprite2D
	var sprite = get_node_or_null("AnimatedSprite2D")
	if sprite and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")

func _physics_process(_delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# Check distance between this enemy and player
		var distance = global_position.distance_to(player.global_position)
		
		# If Irving is close enough (50 pixels), trigger the battle!
		if distance < 50.0:
			print("[Kunti] Player collided! Starting battle...")
			var game_manager = get_node_or_null("/root/GameManager")
			if game_manager:
				game_manager.start_battle(enemy_data)
				# Remove enemy from the exploration map
				queue_free()
