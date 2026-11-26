extends Node2D

const LOCKPICK_TEMPLATE = preload("res://Lockpickingstuff/LockpickPopup.tscn")

const OUTLINE_SHADER_CODE := """
shader_type canvas_item;
uniform vec4 outline_color : source_color = vec4(1.0, 0.9, 0.1, 1.0);
uniform float outline_width : hint_range(0.0, 10.0) = 1.5;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	vec2 ps = TEXTURE_PIXEL_SIZE * outline_width;
	float alpha = col.a;
	alpha = max(alpha, texture(TEXTURE, UV + vec2(ps.x, 0.0)).a);
	alpha = max(alpha, texture(TEXTURE, UV + vec2(-ps.x, 0.0)).a);
	alpha = max(alpha, texture(TEXTURE, UV + vec2(0.0, ps.y)).a);
	alpha = max(alpha, texture(TEXTURE, UV + vec2(0.0, -ps.y)).a);
	alpha = max(alpha, texture(TEXTURE, UV + vec2(ps.x, ps.y)).a);
	alpha = max(alpha, texture(TEXTURE, UV + vec2(-ps.x, ps.y)).a);
	alpha = max(alpha, texture(TEXTURE, UV + vec2(ps.x, -ps.y)).a);
	alpha = max(alpha, texture(TEXTURE, UV + vec2(-ps.x, -ps.y)).a);
	
	vec4 final_color = mix(outline_color, col, col.a);
	final_color.a = alpha;
	COLOR = final_color;
}
"""

signal restartlock
signal targeting
signal locksuccess
signal interaction_started
signal interaction_ended
signal lockpick_state_changed(is_active: bool)
signal candle_lit(current_count: int, max_count: int)
signal game_ended

@export var near_interactables: Array[Node2D] = []
@export var highlight_color: Color = Color(1.0, 0.9, 0.15, 1.0)
@export var highlight_width: float = 1.5
@export var max_candles: int = 3

@onready var parent: Node = get_parent()
@onready var ui_layer: CanvasLayer = find_child("CanvasLayer", false, false)

var lit_candles: int = 0
var lockpick_status: bool = false
var lockpick_current: Node = null
var _outline_material: ShaderMaterial

@export var targeted: Node2D = null:
	set(oncoming):
		if targeted == oncoming:
			return
			
		if is_instance_valid(targeted):
			_set_target_highlight(targeted, false)
			if targeted.has_signal("interactshow"):
				targeted.interactshow.emit(0)
			
		if is_instance_valid(oncoming):
			_set_target_highlight(oncoming, true)
			if oncoming.has_signal("interactshow"):
				oncoming.interactshow.emit(1)
			
		targeted = oncoming

func _ready() -> void:
	locksuccess.connect(lockpicksuccess)
	restartlock.connect(delete_lock)
	targeting.connect(update_target)
	
	var shader := Shader.new()
	shader.code = OUTLINE_SHADER_CODE
	_outline_material = ShaderMaterial.new()
	_outline_material.shader = shader
	_outline_material.set_shader_parameter("outline_color", highlight_color)
	_outline_material.set_shader_parameter("outline_width", highlight_width)
	
	if not is_instance_valid(ui_layer):
		ui_layer = CanvasLayer.new()
		ui_layer.name = "CanvasLayer"
		add_child(ui_layer)

func _set_target_highlight(target_node: Node, enabled: bool) -> void:
	if enabled and "allow_outline" in target_node and target_node.allow_outline == false:
		return
		
	for child in target_node.find_children("*", "", true, false):
		if child is Sprite2D or child is AnimatedSprite2D:
			if enabled:
				if not child.has_meta("orig_material"):
					child.set_meta("orig_material", child.material)
				child.material = _outline_material
			else:
				if child.has_meta("orig_material"):
					child.material = child.get_meta("orig_material")
					child.remove_meta("orig_material")
				else:
					child.material = null

func _process(_delta: float) -> void:
	update_target()

func update_target() -> void:
	near_interactables = near_interactables.filter(func(item): return is_instance_valid(item))
	
	if near_interactables.is_empty():
		targeted = null
	elif near_interactables.size() == 1:
		targeted = near_interactables[0]
	else:
		targeted = get_closest_interactable()

func get_closest_interactable() -> Node2D:
	var closest: Node2D = near_interactables[0]
	var closest_dist: float = global_position.distance_squared_to(closest.global_position)
	
	for item in near_interactables:
		var dist: float = global_position.distance_squared_to(item.global_position)
		if dist < closest_dist:
			closest = item
			closest_dist = dist
			
	return closest

func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(targeted) and event.is_action_pressed("Interact") and not lockpick_status:
		if targeted.has_method("interact"):
			get_viewport().set_input_as_handled()
			targeted.interact(parent)
			return
			
		_start_lockpick()

func _start_lockpick() -> void:
	lockpick_status = true
	if is_instance_valid(parent) and parent.has_signal("busyness"):
		parent.busyness.emit()
	interaction_started.emit()
	lockpick_state_changed.emit(true)
	
	var scene_to_spawn: PackedScene = LOCKPICK_TEMPLATE
	if is_instance_valid(targeted) and "minigame_scene" in targeted and targeted.minigame_scene != null:
		scene_to_spawn = targeted.minigame_scene
		
	lockpick_current = scene_to_spawn.instantiate()
	if lockpick_current.has_signal("zone_hit"):
		lockpick_current.zone_hit.connect(_on_lockpick_zone_hit)
	if lockpick_current.has_signal("lockpick_finished"):
		lockpick_current.lockpick_finished.connect(_on_lockpick_finished)
	ui_layer.add_child(lockpick_current)

func _on_lockpick_zone_hit() -> void:
	if is_instance_valid(targeted) and targeted.has_signal("lockpick_hit"):
		targeted.lockpick_hit.emit()

func _on_lockpick_finished(success: bool) -> void:
	interaction_ended.emit()
	lockpick_state_changed.emit(false)
	
	if success:
		locksuccess.emit()
	delete_lock()

func delete_lock() -> void:
	lockpick_status = false
	if is_instance_valid(lockpick_current):
		lockpick_current.queue_free()
		await get_tree().process_frame
		lockpick_current = null
	if is_instance_valid(parent) and parent.has_signal("busyness"):
		parent.busyness.emit()

func lockpicksuccess() -> void:
	if is_instance_valid(targeted):
		if targeted.has_signal("successfullock"):
			targeted.successfullock.emit()
			
		# Only count ritual circles toward the candle counter (ignores normal lockpicked doors)
		if targeted.has_signal("ritual_completed"):
			add_lit_candle()

func add_lit_candle() -> void:
	lit_candles += 1
	candle_lit.emit(lit_candles, max_candles)
	
	if lit_candles >= max_candles:
		_on_game_ended()

func _on_game_ended() -> void:
	game_ended.emit()
	print("I HATE NIGGERS")
	pass
