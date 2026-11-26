extends CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if get_tree().paused:
			close_pause_menu()
		else:
			open_pause_menu()

func open_pause_menu() -> void:
	show()
	get_tree().paused = true

func close_pause_menu() -> void:
	get_tree().paused = false
	hide()
