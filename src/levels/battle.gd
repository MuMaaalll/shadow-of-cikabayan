extends Control

signal textbox_closed

func _ready():
	print("READY")
	$textbox.hide()
	$ActionsPanel.hide()
	display_text("A wild enemy appears!")
	await textbox_closed
	$ActionsPanel.show()

func _input(event):
	if Input.is_action_just_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and $textbox.visible:
		$textbox.hide()
		emit_signal("textbox_closed")

func display_text(text):
	print("display_text:", text)
	$textbox.show()
	$textbox/Label.text = text

func _on_run_pressed():
	display_text("Got away safely!")
	await textbox_closed
	await get_tree().create_timer(.25).timeout
	get_tree().quit()
