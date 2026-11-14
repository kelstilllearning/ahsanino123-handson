extends Line2D

@export var maxPoints = 60
@onready var testCollision = $CharacterBody2D
var thrown
var collision
var linePosition = Vector2.ZERO
var origin: Vector2
var target_pos: Vector2
var gravity: int
var max_throwing_power: float
var max_throwing_time: float
var prev_pos: Vector2 = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_refresh()

func _refresh():
	clear_points()
	linePosition = get_parent().get_node("player").position
	
	for i in maxPoints:
		add_point(linePosition)
	collision = null
	visible = false
	thrown = false
	
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
	
func throw(origin1, throw_pos1, gravity1, max_throwing_t, max_throwing_p):
	origin = origin1
	target_pos = throw_pos1
	gravity = gravity1
	max_throwing_power = max_throwing_p
	max_throwing_time = max_throwing_t
	prev_pos = origin1
	thrown = true
	collision = null

func _update_trajectory(i, dt: float, v: Vector2):
	if not thrown: return
	
	# calculate x & y axis
	var x := origin.x + (v.x*dt)
	var y : float =  origin.y + (v.y*dt + 0.5*(gravity*dt*dt))
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(prev_pos, Vector2(x, y))
	var result = space_state.intersect_ray(query)
	
	collision = result
	if collision:
		add_point(to_local(result.position))
		return
	
	add_point(to_local(Vector2(x, y)))
	prev_pos = Vector2(x,y)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not thrown: return
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
