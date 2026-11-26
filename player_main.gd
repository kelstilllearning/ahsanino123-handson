extends player

var throw := false
var right := false
var left := false
var running := false
var jump := false
var crouch := false
var direction := "right"
var shooting := false
var throwing_power := 0
var busy := false
var ext_force := Vector2.ZERO

signal busyness

@onready var camera: Camera2D = $Camera2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var trajectoryline

func zoom(multiplier: int) -> void:
	var new_zoom = clamp(camera.zoom.x + (multiplier*zoom_speed), min_zoom, max_zoom)
	camera.zoom = Vector2(new_zoom, new_zoom)

func busytoggle(x: bool):
	busy = x

func on_hit(dmg: float, origin: Vector2):
	health -= dmg
	if health <= 0:
		await get_tree().physics_frame
		queue_free()
	
	if player:
		var push_dir: Vector2 = (global_position - origin).normalized()
		ext_force = push_dir * 2000
		await get_tree().physics_frame
		await get_tree().physics_frame
		ext_force = Vector2.ZERO

#############################
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var lineScene = preload("res://trajectoryline.tscn")
	trajectoryline = lineScene.instantiate()
	get_tree().root.get_node("World").add_child.call_deferred(trajectoryline)
	
	# setup canvaslayer
	var canvas = $"../CanvasLayer"
	var offset_val = get_viewport().get_visible_rect().size / 2
	canvas.offset = offset_val
	
	# setup signal
	connect("busyness", busytoggle)

func _unhandled_input(event: InputEvent) -> void:
	if busy: return
	
	if event.is_action_pressed("throw"):
		throw = true
	if event.is_action_pressed("right"):
		right = true
	if event.is_action_pressed("left"):
		left = true
	if event.is_action_pressed("jump"):
		jump = true
	if event.is_action_pressed("zoom_in"):
		zoom(1)
	if event.is_action_pressed("zoom_out"):
		zoom(-1)
	if event.is_action_pressed("crouch"):
		# make toggle
		crouch = not crouch
	
	# -------------------------------------------------------
	if event.is_action_released("throw"):
		throw = false
		_throw(1, true)
	if event.is_action_released("right"):
		right = false
	if event.is_action_released("left"):
		left = false
	if event.is_action_released("jump"):
		jump = false
	if event.is_action_released("crouch"):
		#crouch = false
		pass

func _throw(dt: float, release: bool) -> void:
	if not is_instance_valid(player): return
	
	if not release:
		if throw:
			shooting = true
			var throw_pos := get_global_mouse_position()
			var origin := global_position + Vector2(0, -20)
					# rotate character according to mouse pos
			if (throw_pos.x - global_position.x) <= 0:
				sprite.flip_h = true
				origin = global_position + Vector2(-0, -20)
			else:
				sprite.flip_h = false
			
			throwing_power = lerp(throwing_power, max_throwing_power, dt*throwing_charge_speed)
			trajectoryline.throw_preview(origin, throw_pos, gravity, max_throwing_time, throwing_power)
			
			if sprite.animation != "bow_shot":
				sprite.play("bow_shot")
				
			# move camera
			var cam_pos = global_position + (throw_pos - global_position).limit_length(max_cam_distance)
			camera.global_position = lerp(camera.global_position, cam_pos, dt/2)
		else:
			trajectoryline._refresh()
			throwing_power = 0
			shooting = false
			
			#reset camera
			$Camera2D.position = Vector2.ZERO
			
	else: #releaase: shoot
		var throw_pos := get_global_mouse_position()
		var origin := global_position + Vector2(0, -20)
		if (throw_pos.x - global_position.x) <= 0:
			origin = global_position + Vector2(-0, -20)
			
		trajectoryline.throw(origin, throw_pos, gravity, max_throwing_time, throwing_power, slingshot_damage)
		
func _crouch(dt) -> float:
	if not crouch:
		$AnimatedSprite2D.scale = Vector2(0.04, 0.04)
		$AnimatedSprite2D.position = Vector2(0, 2)
		$CollisionShape2D.scale = Vector2(5, 5)
		$CollisionShape2D.position = Vector2(0, 0)
		return 1
	
	if shooting:
		crouch = false
		return 1
	
	crouch = true
	$AnimatedSprite2D.scale = Vector2(0.03, 0.03)
	$AnimatedSprite2D.position = Vector2(0, 12) # terpaksa hardcoded
	$CollisionShape2D.scale = Vector2(5, 3.4)
	$CollisionShape2D.position = Vector2(0, 12.5)
	var char_v := get_real_velocity().length()
	if sprite.animation != "crouch" or not (char_v > 0.1):
		sprite.play("crouch")
		sprite.stop()
	
	if not sprite.is_playing() and not shooting and (char_v > 0.1):
		sprite.play("crouch")
	
	return 0.5

func play_sound():
	var char_v := get_real_velocity().length()
	if char_v > 0.1 and running and is_on_floor():
		if not $walk.is_playing(): $walk.play()
	else:
		$walk.stop()
	
	if char_v > 0.1 and crouch and is_on_floor():
		if not $crouch.is_playing(): $crouch.play()
	else:
		$crouch.stop()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(dt: float) -> void:
	var input_direction := Vector2.ZERO
	
	if (get_real_velocity().length() > acceleration/3) and is_on_floor() and not shooting and not crouch:
		running = true
		if sprite.animation != "run":
			sprite.play("run")
	elif is_on_floor() and not shooting and not crouch:
		sprite.play("idle")
		running = false
	
	if right:
		input_direction.x = 1
		sprite.flip_h = false
		direction = "right"
	if left:
		input_direction.x = -1
		sprite.flip_h = true
		direction = "left"
	if jump and is_on_floor() and not (shooting or crouch):
		velocity.y -= jump_power
	if not is_on_floor():
		sprite.play("jump")
		
	input_direction = input_direction.normalized()
	
	#gravity
	if not is_on_floor():
		velocity.y += get_gravity().y * dt
	
	var multiplier = 1
	multiplier *= _crouch(dt)
	multiplier = multiplier*0 if shooting else multiplier
	
	velocity.x = lerp(speed.x, input_direction.x * acceleration * multiplier, dt*7)
	velocity += ext_force
	move_and_slide()
	
	speed = velocity
	
	#-------------------------
	_throw(dt, false)
	play_sound()
	#-----------------------------
	var enemy = get_tree().get_first_node_in_group("enemies")
	if enemy:
		var dist = (enemy.position - position).length()
		var max_dist = 1400
		var shake_multiplier = 0.004
		var shake_power = (max_dist - dist) * shake_multiplier if dist < max_dist else 0.0
		$Camera2D.apply_shake(shake_power)
