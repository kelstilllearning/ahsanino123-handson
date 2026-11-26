extends CharacterBody2D
var player: CharacterBody2D

@onready var sprite: = $AnimatedSprite2D

var dir := 1.0
var can_move := true
var can_patrol := false
var is_move := false
var move_reached := true
var patrol_pos : Vector2

var has_seen_player := false
var is_chasing := false

func stare() -> void:
	if not is_instance_valid(player): return
	
	var diff := (player.position.x - position.x)
	if diff < 0:
		$AnimatedSprite2D.flip_h = true
	else:
		$AnimatedSprite2D.flip_h = false

func chase(dt):
	is_chasing = true
	var reached_player = move_to(player.global_position, dt)
	if reached_player:
		reset()
		is_chasing = false

func see_infront() -> Dictionary:
	var ray_pos = Vector2(200*dir, position.y)
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(position, ray_pos)
	var result = space_state.intersect_ray(query)
	
	return result

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body != self and body.has_method("on_hit"):
		body.on_hit(35, global_position)

func move_to(move_pos, dt):
	if not can_move: return
	move_reached = false
	
	var input_direction = (move_pos - position).normalized()
	var acceleration = 300
	velocity.x = lerp(velocity.x, input_direction.x * acceleration, dt*7)
	is_move = true
	
	var dist = abs(position.x - move_pos.x)
	if dist <= 1:
		move_reached = true
		return true

func patrol(dt: float):
	if is_chasing: return
	
	if move_reached:
		var x_pos = randi_range(-2000, 2000)
		patrol_pos = Vector2(x_pos, position.y)
		move_reached = false
	
	move_to(patrol_pos, dt)

func reset():
	# reset pos for now
	position = Vector2.ZERO
	patrol_pos = position
	velocity = Vector2.ZERO
	
	has_seen_player = false
	can_move = true
	can_patrol = true
	is_chasing = false
	move_reached = true
	
func on_hit(dmg, origin: Vector2):
	has_seen_player= true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	player = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player): return
	
	# flip based on velocity
	dir = velocity.normalized().x
	if dir == 1.0:
		$AnimatedSprite2D.flip_h = true
	elif dir == -1.0:
		$AnimatedSprite2D.flip_h = false
	
	if get_real_velocity().length() > 0.1:
		if sprite.animation != "run":
			sprite.play("run")
	else:
		sprite.play("idle")
	
	
	can_patrol = true
	var ray_result = see_infront()
	if ray_result:
		if ray_result.collider == player:
			has_seen_player = true
	
	if has_seen_player:
		can_patrol = false
		#stare()
		chase(delta)
	patrol(delta)
	
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	move_and_slide()
