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
var first_seen_player := false
var is_chasing := false

var objects_hit_cd := {}
var dmg_cooldown := 1.0

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
		is_chasing = false

func see_infront() -> Dictionary: #more like raycast to player
	var ray_dir: Vector2 = (player.global_position - global_position).normalized()
	var ray_pos: Vector2 = global_position + ray_dir * 1000.0
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(position, ray_pos)
	var result = space_state.intersect_ray(query)
	
	return result

func _on_area_2d_body_entered(body: Node2D) -> void:
	if objects_hit_cd.has(body) and objects_hit_cd[body] > 0: return
	
	if body != self and body.has_method("on_hit"):
		objects_hit_cd[body] = dmg_cooldown
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
	
	var char_v := get_real_velocity().length()
	if move_reached or (char_v < 0.1): # kalo diam, anggap gagal mencapai tujuan
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

func play_sound():
	var char_v := get_real_velocity().length()
	if char_v > 0.1 and is_on_floor():
		if not $walk.is_playing(): $walk.play()
	else:
		$walk.stop()

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
	
	# check if player is inside monster
	for body in $Area2D.get_overlapping_bodies():
		_on_area_2d_body_entered(body)
	
	can_patrol = true
	var ray_result = see_infront()
	if ray_result:
		if ray_result.collider == player and not player.crouch:
			has_seen_player = true
			if not first_seen_player:
				first_seen_player = true
				$scream.play()
		else:
			has_seen_player = false
	else:
		has_seen_player = false
	
	if has_seen_player:
		can_patrol = false
		#stare()
		chase(delta)
	else:
		first_seen_player = false
	patrol(delta)
	
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	move_and_slide()
	
	play_sound()
	for object in objects_hit_cd:
		objects_hit_cd[object] -= delta
		if objects_hit_cd[object] <= 0:
			objects_hit_cd.erase(object)
