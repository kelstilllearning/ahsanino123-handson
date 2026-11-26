extends Line2D

@export var maxPoints = 60
@export var maxthrowPoints = 200
var projectile_scene: = preload("res://projectile.tscn")
@onready var testCollision = $CharacterBody2D
var thrown
var thrown_preview
var collision
var linePosition = Vector2.ZERO
var origin: Vector2
var target_pos: Vector2
var gravity: int
var max_throwing_power: float
var max_throwing_time: float
var prev_pos: Vector2 = Vector2.ZERO

# wait function
func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_refresh()

func _refresh():
	clear_points()
	linePosition = position
	
	for i in maxPoints:
		add_point(linePosition)
	collision = null
	visible = false
	thrown_preview = false
	
func get_velocity_for_fixed_speed(start_pos: Vector2, target_pos: Vector2, speed: float, grav: float) -> Vector2:
	var dx: float = abs(target_pos.x - start_pos.x)
	var dy: float = -(target_pos.y - start_pos.y) # Invert Y because +Y is down in Godot 2D
	
	# Avoid division by zero when aiming straight up/down
	if dx < 0.001:
		var vertical_angle: float = -PI / 2.0 if dy >= 0.0 else PI / 2.0
		return Vector2.from_angle(vertical_angle) * speed
	
	var v2: float = speed * speed
	var v4: float = v2 * v2
	var discriminant: float = v4 - grav * (grav * dx * dx + 2.0 * dy * v2)
	
	var angle: float = 0.0
	if discriminant < 0.0:
		# Target is out of range: fallback to the optimal max-range angle
		var dist: float = sqrt(dx * dx + dy * dy)
		angle = atan2(dy + dist, dx)
	else:
		var root: float = sqrt(discriminant)
		angle = atan((v2 - root) / (grav * dx))
		
	# Convert back to Godot 2D coordinates (handling left vs right)
	var godot_angle: float = PI + angle if target_pos.x < start_pos.x else -angle
	var vel: Vector2 = Vector2.from_angle(godot_angle) * speed
	return vel

func simulate_throw(obj: Node2D):
	clear_points()
	
	# get v
	var v: Vector2 = get_velocity_for_fixed_speed(origin, target_pos, max_throwing_power, gravity)
	
	# check if can reach target_pos
	var dx: float = abs(target_pos.x - origin.x)
	var dy: float = -(target_pos.y - origin.y)
	
	var v2: float = max_throwing_power * max_throwing_power
	var v4: float = v2 * v2
	var discriminant: float = v4 - gravity * (gravity * dx * dx + 2.0 * dy * v2)
	
	var t: float = 0.0
	var dt: float = max_throwing_time / float(max(1, maxPoints - 1))
	if discriminant >= 0:
		var time_to_reach : float = abs(dx/v.x)
		dt = time_to_reach / float(max(1, maxPoints - 1))
	
	get_tree().current_scene.add_child(obj)
	for i in maxthrowPoints:
		_update_trajectory(i, t, v)
		obj.global_position = prev_pos
		if collision:
			return collision
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	
func throw_preview(origin1, throw_pos1, gravity1, max_throwing_t, max_throwing_p):
	origin = origin1
	target_pos = throw_pos1
	gravity = gravity1
	max_throwing_power = max_throwing_p
	max_throwing_time = max_throwing_t
	prev_pos = origin1
	thrown_preview = true
	collision = null
	
func throw(origin1, throw_pos1, gravity1, max_throwing_t, max_throwing_p, dmg):
	origin = origin1
	target_pos = throw_pos1
	gravity = gravity1
	max_throwing_power = max_throwing_p
	max_throwing_time = max_throwing_t
	prev_pos = origin1
	thrown = true
	thrown_preview = false
	collision = null
	
	var projectile = projectile_scene.instantiate()
	var hit_object = await simulate_throw(projectile)
	hit_object = hit_object.collider if is_instance_valid(hit_object.collider)else hit_object
	thrown = false
	
	# delete
	if is_instance_valid(projectile):
		projectile.queue_free()
		
	# check if it has on_hit function
	if is_instance_valid(hit_object) and hit_object.has_method("on_hit"):
		hit_object.on_hit(dmg)

func _update_trajectory(i, dt: float, v: Vector2):
	if not (thrown_preview or thrown): return
	
	# calculate x & y axis
	var x := origin.x + (v.x*dt)
	var y : float =  origin.y + (v.y*dt + 0.5*(gravity*dt*dt))
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(prev_pos, Vector2(x, y))
	var result = space_state.intersect_ray(query)
	
	collision = result
	if collision:
		add_point(to_local(result.position))
		prev_pos = to_local(result.position)
		return result
	
	add_point(to_local(Vector2(x, y)))
	prev_pos = Vector2(x,y)
	return

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not thrown_preview: return
	clear_points()
	
	# get v
	var v: Vector2 = get_velocity_for_fixed_speed(origin, target_pos, max_throwing_power, gravity)
	
	# check if can reach target_pos
	var dx: float = abs(target_pos.x - origin.x)
	var dy: float = -(target_pos.y - origin.y)
	
	var v2: float = max_throwing_power * max_throwing_power
	var v4: float = v2 * v2
	var discriminant: float = v4 - gravity * (gravity * dx * dx + 2.0 * dy * v2)
	
	var t: float = 0.0
	var dt: float = max_throwing_time / float(max(1, maxPoints - 1))
	if discriminant >= 0:
		var time_to_reach : float = abs(dx/v.x)
		dt = time_to_reach / float(max(1, maxPoints - 1))
	
	for i in maxPoints:
		_update_trajectory(i, t, v)
		if collision:
			break
		t += dt
		
	visible = true
