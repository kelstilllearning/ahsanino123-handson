extends player

var right := false
var left := false
var jump := false

@onready var camera: Camera2D = $Camera2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func zoom(multiplier: int) -> void:
	var new_zoom = clamp(camera.zoom.x + (multiplier*zoom_speed), min_zoom, max_zoom)
	camera.zoom = Vector2(new_zoom, new_zoom)

#############################
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	

func _unhandled_input(event: InputEvent) -> void:
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
	
	# -------------------------------------------------------
	if event.is_action_released("right"):
		right = false
	if event.is_action_released("left"):
		left = false
	if event.is_action_released("jump"):
		jump = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(dt: float) -> void:
	var input_direction := Vector2.ZERO
	
	if left or right:
		if sprite.animation != "run":
			sprite.play("run")
	else:
		sprite.play("idle")
	
	if right:
		input_direction.x += 1
		sprite.flip_h = false
	if left:
		input_direction.x -= 1
		sprite.flip_h = true
	if jump and is_on_floor():
		velocity.y -= jump_power
		
	input_direction = input_direction.normalized()
	
	#gravity
	if not is_on_floor():
		velocity.y += gravity * dt
	
	velocity.x = lerp(speed.x, input_direction.x * acceleration, dt*7)
	move_and_slide()
	
	speed = velocity
	pass
