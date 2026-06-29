extends Node
@export var main_menu_packed: PackedScene


func _ready() -> void:
	load_main_menu("game start")

func load_main_menu(origin: String) -> void:
	var main_menu: Control = main_menu_packed.instantiate()
	main_menu.new_game_pressed.connect(New_game)
	main_menu.continue_pressed.connect(Continue)
	main_menu.settings_pressed.connect(Settings)
	main_menu.about_pressed.connect(About)
	main_menu.quit_game_pressed.connect(quit_game)
	add_child(main_menu)

func New_game(origin: String) -> void:
	pass

func Continue(_origin: String) -> void:
	pass

func Settings(_origin: String) -> void:
	pass

func About(_origin: String) -> void:
	pass

func quit_game(_origin: String) -> void:
	get_tree().quit()
