extends CanvasLayer

func _ready() -> void:
	hide()

	# Allow the pause menu to work while the game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

func open_pause_menu() -> void:
	show()
	get_tree().paused = true

func close_pause_menu() -> void:
	get_tree().paused = false
	hide()


func _on_resume_button_pressed() -> void:
	pass # Replace with function body.
