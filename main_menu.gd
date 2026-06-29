extends Control

signal new_game_pressed(origin: String)
signal continue_pressed(origin: String)
signal settings_pressed(origin: String)
signal about_pressed(origin: String)
signal quit_game_pressed(origin: String)


func _on_new_game_pressed() -> void:
	new_game_pressed.emit("main_menu")


func _on_continue_pressed() -> void:
	continue_pressed.emit("main_menu")


func _on_settings_pressed() -> void:
	settings_pressed.emit("main_menu")


func _on_about_pressed() -> void:
	about_pressed.emit("main_menu")

func _on_quit_game_pressed() -> void:
	quit_game_pressed.emit("main_menu")
