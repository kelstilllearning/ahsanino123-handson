extends player

var throw := false
var right := false
var left := false
var jump := false
var crouch := false
var direction := "right"
var shooting := false
var throwing_power := 0

@onready var camera: Camera2D = $Camera2D
@onready var anim = $AnimationPlayer
@onready var head_bone := $Skeleton2D/root/torso/head
@onready var front_arm_bone := $Skeleton2D/root/torso/front_arm
@onready var back_arm_bone := $Skeleton2D/root/torso/back_arm
@onready var trajectoryline

func zoom(multiplier: int) -> void:
	var new_zoom = clamp(camera.zoom.x + (multiplier*zoom_speed), min_zoom, max_zoom)
	camera.zoom = Vector2(new_zoom, new_zoom)

#############################
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var lineScene = preload("res://trajectoryline.tscn")
	trajectoryline = lineScene.instantiate()
	get_tree().root.get_node("World").add_child.call_deferred(trajectoryline)
	

func _unhandled_input(event: InputEvent) -> void:
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
		crouch = true
	
	# -------------------------------------------------------
	if event.is_action_released("throw"):
		throw = false
	if event.is_action_released("right"):
		right = false
	if event.is_action_released("left"):
		left = false
	if event.is_action_released("jump"):
		jump = false
	if event.is_action_released("crouch"):
		crouch = false
		
func flip_char(direction: float):
	$Skeleton2D/root.scale.x = abs($Skeleton2D/root.scale.x) * direction

func rotate_to_pos(obj: Bone2D, pos: Vector2, offset: float, max_angle: float):
	offset = deg_to_rad(offset)
	var angle_to_pos: float = obj.get_angle_to(pos) + offset
	var angle_diff: float = wrapf((obj.rotation + angle_to_pos), -PI, PI)
	var max_rad: float = deg_to_rad(max_angle)
	obj.rotation = clampf(angle_diff, -max_rad, max_rad)

func _throw(dt: float) -> void:
	if throw:
		shooting = true
		var throw_pos := get_global_mouse_position()
		var origin = $Skeleton2D/root/torso/back_arm/BackArm.global_position
				# rotate character according to mouse pos
		if (throw_pos.x - global_position.x) <= 0:
			flip_char(-1)
		else:
			flip_char(1)
		
		throwing_power = lerp(throwing_power, max_throwing_power, dt*throwing_charge_speed)
		trajectoryline.throw(origin, throw_pos, gravity, max_throwing_time, throwing_power)
		
		if anim.current_animation != "bow_shot":
			anim.play("bow_shot")
			
		# look-at head
		rotate_to_pos(head_bone, get_global_mouse_position(), 0, 45)
		rotate_to_pos(front_arm_bone, get_global_mouse_position(), -90, 360)
		rotate_to_pos(back_arm_bone, get_global_mouse_position(), -90, 360)
	else:
		trajectoryline._refresh()
		throwing_power = 0
		if shooting:
			head_bone.rotation = 0
		shooting = false
		
func _crouch(dt) -> float:
	if not crouch:
		#$AnimatedSprite2D.modulate = Color.WHITE
		return 1
	
	crouch = true
	$AnimatedSprite2D.modulate = Color.WHITE.darkened(0.5)
	if anim.current_animation != "crouch" and not shooting and (left or right):
		anim.play("crouch")
	
	return 0.5

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(dt: float) -> void:
	var input_direction := Vector2.ZERO
	
	if (left or right) and is_on_floor() and not shooting and not crouch:
		if anim.current_animation != "run":
			anim.play("run")
	elif is_on_floor() and not shooting and not crouch:
		anim.play("idle")
	
	if right:
		input_direction.x += 1
		flip_char(1)
		direction = "right"
	if left:
		input_direction.x -= 1
		flip_char(-1)
		direction = "left"
	if jump and is_on_floor() and not shooting:
		velocity.y -= jump_power
		anim.play("jump")
		
	input_direction = input_direction.normalized()
	
	#gravity
	if not is_on_floor():
		velocity.y += gravity * dt
	
	var multiplier = 1
	multiplier *= _crouch(dt)
	multiplier = multiplier*0.2 if shooting else multiplier
	
	velocity.x = lerp(speed.x, input_direction.x * acceleration * multiplier, dt*7)
	move_and_slide()
	
	speed = velocity
	
	#-------------------------
	_throw(dt)
