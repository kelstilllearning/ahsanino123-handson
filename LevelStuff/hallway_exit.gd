extends Area2D

signal interactshow(state: int)

@export_group("Ritual Requirement")
@export var required_rituals: int = 3
@export var locked_text: String = "I can't leave now"
@export var unlocked_text: String = "F"

@export_group("Scene Transition")
@export_file("*.tscn") var target_scene_path: String = ""
@export var fade_duration: float = 0.5
@export var allow_outline: bool = false

@onready var prompt_ui: Control = find_child("Control", true, false)
@onready var prompt_label: Label = find_child("Label", true, false)
@onready var locked_sound: AudioStreamPlayer2D = find_child("LockedSound", true, false)

var _completed_rituals: int = 0
var _is_transitioning: bool = false
var _fade_alpha: float = 0.0
var _fade_canvas: CanvasLayer
var _fade_drawer: Control

func _ready() -> void:
	interactshow.connect(_on_interact_show)
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)
		
	if is_instance_valid(prompt_ui):
		prompt_ui.visible = false
		
	_setup_fade_overlay()
	_update_prompt_text()
	
	await get_tree().process_frame
	_connect_to_rituals()

func _connect_to_rituals() -> void:
	for node in get_tree().current_scene.find_children("*", "", true, false):
		if node.has_signal("ritual_completed") and not node.is_connected("ritual_completed", _on_ritual_completed):
			node.connect("ritual_completed", _on_ritual_completed)

func _on_ritual_completed() -> void:
	_completed_rituals += 1
	_update_prompt_text()

func is_unlocked() -> bool:
	return _completed_rituals >= required_rituals

func _update_prompt_text() -> void:
	if is_instance_valid(prompt_label):
		prompt_label.text = unlocked_text if is_unlocked() else locked_text

func _setup_fade_overlay() -> void:
	_fade_canvas = CanvasLayer.new()
	_fade_canvas.layer = 100
	add_child(_fade_canvas)
	
	_fade_drawer = Control.new()
	_fade_drawer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_drawer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_drawer.draw.connect(_on_fade_draw)
	_fade_canvas.add_child(_fade_drawer)

func _on_fade_draw() -> void:
	if _fade_alpha > 0.0:
		_fade_drawer.draw_rect(
			Rect2(Vector2.ZERO, _fade_drawer.get_viewport_rect().size),
			Color(0.0, 0.0, 0.0, _fade_alpha)
		)

func _find_interaction_manager(body: Node) -> Node:
	var im = body.find_child("InteractionManager", true, false)
	if is_instance_valid(im):
		return im
	for child in body.get_children():
		if "near_interactables" in child:
			return child
	return null

func _on_body_entered(body: Node2D) -> void:
	var im = _find_interaction_manager(body)
	if is_instance_valid(im) and not im.near_interactables.has(self):
		im.near_interactables.append(self)

func _on_body_exited(body: Node2D) -> void:
	var im = _find_interaction_manager(body)
	if is_instance_valid(im):
		im.near_interactables.erase(self)

func _on_interact_show(state: int) -> void:
	if is_instance_valid(prompt_ui):
		_update_prompt_text()
		prompt_ui.visible = (state == 1) and not is_busy()

func is_busy() -> bool:
	return _is_transitioning or _fade_alpha > 0.0

func interact(player: Node2D) -> void:
	if is_busy() or not is_instance_valid(player):
		return
		
	if not is_unlocked():
		_update_prompt_text()
		if is_instance_valid(locked_sound) and locked_sound.stream != null:
			locked_sound.play()
		return
		
	if target_scene_path.is_empty():
		push_warning("RitualExitDoor: Target Scene Path is not assigned in the Inspector.")
		return
		
	_is_transitioning = true
	if is_instance_valid(prompt_ui):
		prompt_ui.visible = false
		
	var im = _find_interaction_manager(player)
	if is_instance_valid(im) and im.has_method("set_frozen"):
		im.set_frozen(true)
		
	# 1. Fade to black
	var fade_out := create_tween()
	fade_out.tween_method(_set_fade_alpha, 0.0, 1.0, fade_duration)
	await fade_out.finished
	
	# 2. Keep fade overlay alive on root across scene reload, then load new scene
	_fade_canvas.reparent(get_tree().root)
	var tree := get_tree()
	var err := tree.change_scene_to_file(target_scene_path)
	if err != OK:
		push_error("RitualExitDoor failed to load scene: " + target_scene_path)
		_fade_canvas.queue_free()
		return
		
	# 3. Fade back in once the new scene enters the tree
	await tree.process_frame
	var fade_in := tree.create_tween()
	fade_in.tween_method(_set_fade_alpha, 1.0, 0.0, fade_duration)
	await fade_in.finished
	
	if is_instance_valid(_fade_canvas):
		_fade_canvas.queue_free()

func _set_fade_alpha(value: float) -> void:
	_fade_alpha = value
	if is_instance_valid(_fade_drawer):
		_fade_drawer.queue_redraw()
