extends Control

signal textbox_closed


func _on_run_pressed() -> void:
	display_text("CABUTTTT")
	yield(self, "textbox_closed ")
	yield(get_tree().create_timer(0.25), "timeout")
	get_tree().quit()
