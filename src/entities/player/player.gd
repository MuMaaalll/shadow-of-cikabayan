extends CharacterBody2D

const SPEED = 200.0

@onready var animated_sprite = $AnimatedSprite2D

func _physics_process(delta):
	# Deteksi tombol panah atau WASD
	var left = Input.is_action_pressed("ui_left") or Input.is_physical_key_pressed(KEY_A)
	var right = Input.is_action_pressed("ui_right") or Input.is_physical_key_pressed(KEY_D)
	var up = Input.is_action_pressed("ui_up") or Input.is_physical_key_pressed(KEY_W)
	var down = Input.is_action_pressed("ui_down") or Input.is_physical_key_pressed(KEY_S)
	
	# Ambil input arah horizontal (kiri / kanan)
	var direction = 0
	if right: direction += 1
	if left: direction -= 1
	
	if direction != 0:
		velocity.x = direction * SPEED
		
		# Putar animasi sesuai arah
		if direction < 0:
			animated_sprite.play("walk_left")
		else:
			# Nanti sesuaikan namanya kalau ada walk_right
			animated_sprite.play("Walk_Right")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		animated_sprite.play("idle")
		
	# Ambil input arah vertikal (atas / bawah)
	var y_direction = 0
	if down: y_direction += 1
	if up: y_direction -= 1
	
	if y_direction != 0:
		velocity.y = y_direction * SPEED
	else:
		velocity.y = move_toward(velocity.y, 0, SPEED)

	# Terapkan pergerakan
	move_and_slide()
