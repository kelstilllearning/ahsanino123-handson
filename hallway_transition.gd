extends Area2D

signal interactshow(state: int)

@export var target_teleporter: Node2D
@export var arrival_offset: Vector2 = Vector2(0, 30)
@export var fade_duration: float = 0.5
@export var unfreeze_offset: float = 0.25 # Seconds after teleport before controls unlock (0.0 to fade_duration)

@onready var prompt_ui: Control = find_child("Control", true, false)

var _is_transitioning: bool = false
var _fade_alpha: float = 0.0
var _fade_canvas: CanvasLayer
var _fade_drawer: Control
@export var allow_outline: bool = false
func _ready() -> void:
	interactshow.connect(_on_interact_show)
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)
		
	if is_instance_valid(prompt_ui):
		prompt_ui.visible = false
		
	_setup_fade_overlay()

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
		prompt_ui.visible = (state == 1) and not is_busy()

func is_busy() -> bool:
	return _is_transitioning or _fade_alpha > 0.0

func set_transitioning(busy: bool) -> void:
	_is_transitioning = busy
	if is_instance_valid(prompt_ui):
		if busy:
			prompt_ui.visible = false
		else:
			for body in get_overlapping_bodies():
				if is_instance_valid(_find_interaction_manager(body)):
					prompt_ui.visible = true
					break

func interact(player: Node2D) -> void:
	if is_busy():
		return
	if not is_instance_valid(target_teleporter) or not is_instance_valid(player):
		return
	if target_teleporter.has_method("is_busy") and target_teleporter.is_busy():
		return
		
	set_transitioning(true)
	if target_teleporter.has_method("set_transitioning"):
		target_teleporter.set_transitioning(true)
		
	var im = _find_interaction_manager(player)
	if is_instance_valid(im) and im.has_method("set_frozen"):
		im.set_frozen(true)
		
	# 1. Darken screen
	var fade_out := create_tween()
	fade_out.tween_method(_set_fade_alpha, 0.0, 1.0, fade_duration)
	await fade_out.finished
	
	# 2. Teleport player while screen is pitch black
	if is_instance_valid(player) and is_instance_valid(target_teleporter):
		player.global_position = target_teleporter.global_position + arrival_offset
		
	# 3. Start undarkening screen and schedule unfreeze at your exact offset
	var fade_in := create_tween()
	fade_in.tween_method(_set_fade_alpha, 1.0, 0.0, fade_duration)
	
	if unfreeze_offset > 0.0:
		await get_tree().create_timer(minf(unfreeze_offset, fade_duration)).timeout
		
	if is_instance_valid(im) and im.has_method("set_frozen"):
		im.set_frozen(false)
		
	if fade_in.is_running():
		await fade_in.finished
	
	set_transitioning(false)
	if target_teleporter.has_method("set_transitioning"):
		target_teleporter.set_transitioning(false)

func _set_fade_alpha(value: float) -> void:
	_fade_alpha = value
	if is_instance_valid(_fade_drawer):
		_fade_drawer.queue_redraw()
