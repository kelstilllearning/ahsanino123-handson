extends Panel

signal zone_hit
signal lockpick_finished(success: bool)

# Inspector Configuration
@export var target_sizes: Array[int] = [3, 1, 2]
@export var step_interval: float = 2.0

# Placeholder textures for sizes 4, 3, 2, 1 (drop your sprites here in the Inspector)
@export var texture_size_4: Texture2D
@export var texture_size_3: Texture2D
@export var texture_size_2: Texture2D
@export var texture_size_1: Texture2D

# Placeholder flame/smoke textures
@export var red_flame_texture: Texture2D
@export var blue_flame_texture: Texture2D
@export var smoke_texture: Texture2D

@onready var candles: Array[Control] = [$Candle1, $Candle2, $Candle3]

var current_candle_index: int = 0
var current_size: int = 4
var is_holding: bool = false
var hold_timer: float = 0.0
var is_resetting: bool = false

# Tracks visual state per candle for fallback drawing when textures are unassigned
var _candle_sizes: Array[int] = [4, 4, 4]
var _flame_states: Array[String] = ["red", "red", "red"]
var _smoke_states: Array[bool] = [false, false, false]

const PLACEHOLDER_HEIGHTS := {
	4: 160.0,
	3: 120.0,
	2: 80.0,
	1: 40.0,
	0: 0.0
}

func _ready() -> void:
	var half_size: Vector2 = size * 0.5
	if half_size == Vector2.ZERO:
		half_size = custom_minimum_size * 0.5
	anchor_left = 0.5
	anchor_top = 0.5
	anchor_right = 0.5
	anchor_bottom = 0.5
	offset_left = -half_size.x
	offset_top = -half_size.y
	offset_right = half_size.x
	offset_bottom = half_size.y
	
	_reset_all_candles()

func _reset_all_candles() -> void:
	current_candle_index = 0
	current_size = 4
	is_holding = false
	hold_timer = 0.0
	is_resetting = false
	
	for i in range(candles.size()):
		_apply_candle_size(i, 4)
		_set_flame_state(i, "red")
		_set_smoke_visible(i, false)
	queue_redraw()

func _process(delta: float) -> void:
	if is_resetting or not is_holding:
		return
		
	hold_timer += delta
	if hold_timer >= step_interval:
		hold_timer -= step_interval
		current_size -= 1
		
		if current_size < 1:
			_apply_candle_size(current_candle_index, 0)
			_trigger_fail(current_candle_index)
		else:
			_apply_candle_size(current_candle_index, current_size)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Interact"):
		get_viewport().set_input_as_handled()
		lockpick_finished.emit(false)
		return
		
	if is_resetting:
		return
		
	if event.is_action_pressed("Lockpick") and not event.is_echo():
		get_viewport().set_input_as_handled()
		is_holding = true
		hold_timer = 0.0
		
	elif event.is_action_released("Lockpick") and is_holding:
		get_viewport().set_input_as_handled()
		is_holding = false
		_evaluate_release()

func _evaluate_release() -> void:
	var expected_size: int = target_sizes[current_candle_index]
	
	if current_size == expected_size:
		_set_flame_state(current_candle_index, "blue")
		zone_hit.emit()
		current_candle_index += 1
		
		if current_candle_index >= candles.size() or current_candle_index >= target_sizes.size():
			is_resetting = true
			await get_tree().create_timer(0.6).timeout
			lockpick_finished.emit(true)
		else:
			current_size = 4
			hold_timer = 0.0
	else:
		_trigger_fail(current_candle_index)

func _trigger_fail(failed_index: int) -> void:
	is_holding = false
	is_resetting = true
	_set_flame_state(failed_index, "off")
	_set_smoke_visible(failed_index, true)
	
	await get_tree().create_timer(1.0).timeout
	_reset_all_candles()

func _apply_candle_size(index: int, size_step: int) -> void:
	_candle_sizes[index] = size_step
	var candle := candles[index]
	var tex: Texture2D = null
	match size_step:
		4: tex = texture_size_4
		3: tex = texture_size_3
		2: tex = texture_size_2
		1: tex = texture_size_1
		
	if candle is TextureRect and tex != null:
		candle.texture = tex
		candle.visible = true
	else:
		# Ensure non-zero width even when TextureRect has no texture assigned
		if candle.size.x < 10.0:
			candle.size.x = 50.0
		var target_h: float = PLACEHOLDER_HEIGHTS.get(size_step, 0.0)
		var bottom_y: float = candle.position.y + candle.size.y
		candle.size.y = target_h
		candle.position.y = bottom_y - target_h
		candle.visible = (size_step > 0)
		
	var flame := candle.find_child("Flame", false, false)
	if is_instance_valid(flame):
		flame.position.y = -24.0
	var smoke := candle.find_child("Smoke", false, false)
	if is_instance_valid(smoke):
		smoke.position.y = -32.0
	queue_redraw()

func _set_flame_state(index: int, state: String) -> void:
	_flame_states[index] = state
	var flame := candles[index].find_child("Flame", false, false)
	if is_instance_valid(flame):
		if state == "off":
			flame.visible = false
		else:
			flame.visible = true
			if flame is TextureRect:
				var tex := blue_flame_texture if state == "blue" else red_flame_texture
				if tex != null:
					flame.texture = tex
	queue_redraw()

func _set_smoke_visible(index: int, show_smoke: bool) -> void:
	_smoke_states[index] = show_smoke
	var smoke := candles[index].find_child("Smoke", false, false)
	if is_instance_valid(smoke):
		smoke.visible = show_smoke
		if show_smoke and smoke is TextureRect and smoke_texture != null:
			smoke.texture = smoke_texture
	queue_redraw()

func _draw() -> void:
	# Fallback visual blocks whenever textures are not assigned yet
	for i in range(candles.size()):
		var candle := candles[i]
		var size_step := _candle_sizes[i]
		if size_step <= 0:
			continue
			
		var has_candle_tex := (candle is TextureRect and candle.texture != null)
		if not has_candle_tex:
			var rect := Rect2(candle.position, Vector2(maxf(candle.size.x, 50.0), candle.size.y))
			draw_rect(rect, Color(0.92, 0.88, 0.78)) # Wax color
			draw_rect(rect, Color(0.2, 0.2, 0.2), false, 2.0) # Outline
			
		var flame := candle.find_child("Flame", false, false)
		var has_flame_tex := (flame is TextureRect and flame.texture != null)
		if not has_flame_tex:
			var top_center := Vector2(candle.position.x + maxf(candle.size.x, 50.0) * 0.5, candle.position.y - 14.0)
			if _flame_states[i] == "red":
				draw_circle(top_center, 10.0, Color.ORANGE_RED)
			elif _flame_states[i] == "blue":
				draw_circle(top_center, 10.0, Color.DEEP_SKY_BLUE)
				
		if _smoke_states[i]:
			var smoke_pos := Vector2(candle.position.x + maxf(candle.size.x, 50.0) * 0.5, candle.position.y - 24.0)
			draw_circle(smoke_pos, 12.0, Color(0.7, 0.7, 0.7, 0.7))
