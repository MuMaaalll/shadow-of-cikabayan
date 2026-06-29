extends Area2D

# Ekspor variabel agar kamu bisa ganti nama level langsung dari Inspector tanpa ubah kode
@export_file("*.tscn") var target_level: String = "res://src/levels/hutan_cikabayan/hutan_cikabayan.tscn"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# Memastikan bahwa yang masuk ke area adalah Player
	# Ganti "Player" sesuai dengan nama Node atau ClassName karakter kamu
	if body.name == "Irving" or body.is_in_group("player"):
		_change_level()

func _change_level() -> void:
	print("Berpindah ke level: ", target_level)
	
	# Memeriksa apakah file scene target memang ada sebelum pindah
	if ResourceLoader.exists(target_level):
		get_tree().change_scene_to_file(target_level)
	else:
		push_error("Gagal memuat level: File " + target_level + " tidak ditemukan!")
