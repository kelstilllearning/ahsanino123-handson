extends Node2D

const LOCKPICK_TEMPLATE = preload("res://Lockpickingstuff/LockpickPopup.tscn")

const OUTLINE_SHADER_CODE := """
shader_type canvas_item;
uniform vec4 outline_color : source_color = vec4(1.0, 0.9, 0.1, 1.0);
uniform float outline_width : hint_range(0.0, 10.0) = 2.0;

float sample_alpha(sampler2D tex, vec2 uv) {
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		return 0.0;
	}
	return texture(tex, uv).a;
}

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	vec2 ps = TEXTURE_PIXEL_SIZE * outline_width;
	
	float a_right = sample_alpha(TEXTURE, UV + vec2(ps.x, 0.0));
	float a_left  = sample_alpha(TEXTURE, UV + vec2(-ps.x, 0.0));
	float a_down  = sample_alpha(TEXTURE, UV + vec2(0.0, ps.y));
	float a_up    = sample_alpha(TEXTURE, UV + vec2(0.0, -ps.y));
	
	float max_neighbor = max(max(a_right, a_left), max(a_down, a_up));
	float min_neighbor = min(min(a_right, a_left), min(a_down, a_up));
	
	// Outer outline (around transparent edges) OR inner edge border (for full-bleed rectangular sprites)
	if (col.a < 0.1 && max_neighbor > 0.1) {
		COLOR = outline_color;
	} else if (col.a > 0.1 && min_neighbor < 0.1) {
		COLOR = outline_color;
	} else {
		COLOR = col;
	}
}
"""

signal restartlock
signal targeting
signal locksuccess
signal lockpick_state_changed(is_active: bool)

@export var near_interactables: Array[Node2D] = []
@export var highlight_color: Color = Color(1.0, 0.9, 0.15, 1.0)
@export var highlight_width: float = 1.5

@onready var parent: Node = get_parent()
@onready var ui_layer: CanvasLayer = find_child("CanvasLayer", false, false)

var lockpick_status: bool = false
var lockpick_current: Node = null
var _freeze_locks: int = 0
var _outline_material: ShaderMaterial
var is_frozen: bool:
	get:
		return _freeze_locks > 0

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

func set_frozen(active: bool) -> void:
	var was_frozen := is_frozen
	if active:
		_freeze_locks += 1
	else:
		_freeze_locks = maxi(0, _freeze_locks - 1)
		
	if was_frozen != is_frozen and is_instance_valid(parent):
		_apply_player_freeze(is_frozen)

func _apply_player_freeze(frozen: bool) -> void:
	parent.set_process(not frozen)
	parent.set_physics_process(not frozen)
	parent.set_process_unhandled_input(not frozen)
	
	if frozen:
		for prop in ["right", "left", "jump", "throw"]:
			if prop in parent:
				parent.set(prop, false)
		if "throwing_power" in parent:
			parent.set("throwing_power", 0)
		if "velocity" in parent:
			parent.velocity.x = 0.0
		if "speed" in parent:
			parent.speed.x = 0.0
		if "trajectoryline" in parent and is_instance_valid(parent.trajectoryline) and parent.trajectoryline.has_method("_refresh"):
			parent.trajectoryline._refresh()
			
		var sprite: AnimatedSprite2D = parent.find_child("AnimatedSprite2D", true, false)
		if is_instance_valid(sprite) and sprite.sprite_frames and sprite.sprite_frames.has_animation("idle"):
			sprite.play("idle")

func _process(delta: float) -> void:
	update_target()
	
	if is_frozen and parent is CharacterBody2D:
		if not parent.is_on_floor():
			var grav: float = parent.get("gravity") if "gravity" in parent else 980.0
			parent.velocity.y += grav * delta
			parent.move_and_slide()

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
	if is_instance_valid(targeted) and event.is_action_pressed("Interact") and not lockpick_status and not is_frozen:
		if targeted.has_method("interact"):
			get_viewport().set_input_as_handled()
			targeted.interact(parent)
			return
			
		_start_lockpick()

func _start_lockpick() -> void:
	lockpick_status = true
	set_frozen(true)
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
	set_frozen(false)
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

func lockpicksuccess() -> void:
	if is_instance_valid(targeted) and targeted.has_signal("successfullock"):
		targeted.successfullock.emit()
