extends Node

@export_file("*.tscn") var main_menu_scene_path: String = "res://src/ui/main_menu.tscn"
@export_file("*.tscn") var first_level_path: String = "res://src/levels/kebun_cikabayan/kebun_cikabayan.tscn"
@export_file("*.tscn") var target_level_path: String = "res://src/levels/hutan_cikabayan/hutan_cikabayan.tscn"

func _ready() -> void:
	load_main_menu("game start")

func load_main_menu(_origin: String) -> void:
	print("[SceneHandler] Memuat Main Menu dari: ", main_menu_scene_path)
	
	if main_menu_scene_path and ResourceLoader.exists(main_menu_scene_path):
		var menu_resource = load(main_menu_scene_path)
		var main_menu = menu_resource.instantiate()
		
		main_menu.new_game_pressed.connect(New_game)
		main_menu.continue_pressed.connect(Continue)
		main_menu.settings_pressed.connect(Settings)
		main_menu.about_pressed.connect(About)
		main_menu.quit_game_pressed.connect(quit_game)
		
		add_child(main_menu)
	else:
		push_error("[SceneHandler] File Main Menu gak ketemu di path: " + main_menu_scene_path)

func New_game(origin: String) -> void:
	print("[SceneHandler] Tombol New Game ditekan dari: ", origin)
	
	for child in get_children():
		if child is Control: # Memastikan hanya node UI yang dihapus
			print("[SceneHandler] Menghapus UI Menu: ", child.name)
			child.queue_free()

	change_level(first_level_path)

# FUNGSI UTAMA TRANSISI LEVEL (DIPANGGIL OLEH LEVELCHANGER)
# FUNGSI UTAMA TRANSISI LEVEL (DIPANGGIL OLEH LEVELCHANGER)
func change_level(target_path: String) -> void:
	# Memakai target_path agar log output sesuai dengan tujuan portal
	print("[SceneHandler] Memproses perpindahan level ke: ", target_path)
	
	# 1. Hapus semua map lama yang nempel di SceneHandler
	for child in get_children():
		if not child is Control: 
			print("[SceneHandler] Menghapus map lama: ", child.name)
			child.queue_free()

	# 2. Tunggu 1 frame biar queue_free selesai ngebersihin memori
	await get_tree().process_frame
	
	# 3. Instance dan tampilin map yang baru
	if ResourceLoader.exists(target_path):
		var next_map = load(target_path).instantiate()
		add_child(next_map)
		print("[SceneHandler] Sukses memuat map baru: ", next_map.name)
	else:
		push_error("[SceneHandler] Gagal ganti level: File .tscn tidak ditemukan di " + target_path)
	
func Continue(_origin: String) -> void:
	pass

func Settings(_origin: String) -> void:
	pass

func About(_origin: String) -> void:
	pass

func quit_game(_origin: String) -> void:
	print("[SceneHandler] Keluar dari game.")
	get_tree().quit()
