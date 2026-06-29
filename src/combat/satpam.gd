extends CharacterBody2D
## ==========================================================================
## satpam.gd — Enemy trigger script for Satpam (CharacterBody2D)
## Shadow of Cikabayan | Godot 4.6
##
## Attached to the Satpam CharacterBody2D on the map.
## Triggers a battle via GameManager when player gets close.
## ==========================================================================

@export var enemy_data: EnemyResource

func _ready() -> void:
	# Jika tidak ada custom enemy data di Inspector, buat default data Satpam
	if not enemy_data:
		enemy_data = EnemyResource.new()
		enemy_data.enemy_name = "Satpam"
		enemy_data.max_hp = 120 # Lebih tebal dari Kunti karena fisik terlatih
		enemy_data.contamination_level = 0 # Manusia biasa, kontaminasi 0
		enemy_data.speed = 10 # Speed standar bapak-bapak
		
		# Catatan: Sesuaikan enum element_type dengan yang ada di EnemyResource kamu.
		# Jika ada PHYSICAL atau HUMAN, pakai itu. Sementara diganti ke tipe dasar.
		if "PHYSICAL" in EnemyResource.EnemyElementType:
			enemy_data.element_type = EnemyResource.EnemyElementType.OPTICS_PHYSICS
		else:
			enemy_data.element_type = EnemyResource.EnemyElementType.BIO_CHEMISTRY
			
		enemy_data.attack_damage = 15 # Damage pentungan/senter pos ronda
	
	# Play idle animation jika node memiliki AnimatedSprite2D
	var sprite = get_node_or_null("AnimatedSprite2D")
	if sprite and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")

func _physics_process(_delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# Cek jarak antara Satpam dan Irving
		var distance = global_position.distance_to(player.global_position)
		
		# Jika Irving keciduk Satpam (jarak kurang dari 50 piksel), auto baku hantam!
		if distance < 50.0:
			print("[Satpam] Irving ketahuan kelayapan! Memulai pertarungan...")
			var game_manager = get_node_or_null("/root/GameManager")
			if game_manager:
				game_manager.start_battle(enemy_data)
				# Hapus Satpam dari peta eksplorasi setelah battle ke-trigger
				queue_free()
