extends Area2D

@export_file("*.tscn") var target_level: String = "res://src/levels/hutan_cikabayan/hutan_cikabayan.tscn"

var is_changing_level: bool = false

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if is_changing_level:
		return

	if body.name == "Irving" or body.is_in_group("player"):
		var scene_handler: Node = null
		
		# Cara 1: Ambil bapaknya langsung dari hierarki tree aktif
		if owner and owner.get_parent():
			scene_handler = owner.get_parent()
		
		# Cara 2: Backup kalau cara 1 meleset, cari manual nodenya di tree aktif
		if not scene_handler or not scene_handler.has_method("change_level"):
			scene_handler = get_tree().root.find_child("SceneHandler", true, false)
		if not scene_handler or not scene_handler.has_method("change_level"):
			scene_handler = get_tree().root.find_child("scenehandler", true, false)

		# EKSEKUSI TRANSISI (Menggunakan variabel lokal 'scene_handler' huruf kecil)
		if scene_handler and scene_handler.has_method("change_level"):
			is_changing_level = true
			set_deferred("monitoring", false)
			print("[LevelChanger] Sukses terhubung ke Main Scene! Berpindah ke: ", target_level)
			scene_handler.change_level(target_level)
		else:
			push_error("[LevelChanger] ERROR: Tetap gak ketemu induk SceneHandler! Pastikan level dimainin lewat Main Menu / SceneHandler utama!")
