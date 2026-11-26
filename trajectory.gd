extends Line2D

@export var maxPoints = 60
@export var maxthrowPoints = 200
var projectile_scene: = preload("res://projectile.tscn")
@onready var testCollision = $CharacterBody2D

var thrown_preview: bool = false
var linePosition = Vector2.ZERO
var origin: Vector2
var target_pos: Vector2
var gravity: int
var max_throwing_power: float
var max_throwing_time: float

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func _ready() -> void:
	_refresh()

func _refresh():
	clear_points()
	linePosition = get_parent().get_node("player").position
	
	for i in maxPoints:
		add_point(linePosition)
	visible = false
	thrown_preview = false
	
func get_velocity_for_fixed_speed(start_pos: Vector2, end_pos: Vector2, speed: float, grav: float) -> Vector2:
	var dx: float = abs(end_pos.x - start_pos.x)
	var dy: float = -(end_pos.y - start_pos.y)
	
	if dx < 0.001:
		var vertical_angle: float = -PI / 2.0 if dy >= 0.0 else PI / 2.0
		return Vector2.from_angle(vertical_angle) * speed
	
	var v2: float = speed * speed
	var v4: float = v2 * v2
	var discriminant: float = v4 - grav * (grav * dx * dx + 2.0 * dy * v2)
	
	var angle: float = 0.0
	if discriminant < 0.0:
		var dist: float = sqrt(dx * dx + dy * dy)
		angle = atan2(dy + dist, dx)
	else:
		var root: float = sqrt(discriminant)
		angle = atan((v2 - root) / (grav * dx))
		
	var godot_angle: float = PI + angle if end_pos.x < start_pos.x else -angle
	return Vector2.from_angle(godot_angle) * speed

# Fungsi perhitungan langkah yang mandiri (tidak pakai variabel global)
func _step_trajectory(start_pos: Vector2, current_prev_pos: Vector2, dt: float, v: Vector2, grav: float) -> Dictionary:
	var x := start_pos.x + (v.x * dt)
	var y: float = start_pos.y + (v.y * dt + 0.5 * (grav * dt * dt))
	var next_pos := Vector2(x, y)
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(current_prev_pos, next_pos, 15)
	query.collide_with_areas = true
	var result = space_state.intersect_ray(query)
	
	if result:
		return {"pos": result.position, "hit": result}
	return {"pos": next_pos, "hit": null}

func simulate_throw(obj: Node2D, start_pos: Vector2, end_pos: Vector2, grav: int, power: float):
	# Semua variabel disimpan lokal agar tiap tembakan berjalan mandiri
	var v: Vector2 = get_velocity_for_fixed_speed(start_pos, end_pos, power, grav)
	var t: float = 0.0
	var current_pos: Vector2 = start_pos
	
	obj.global_position = start_pos
	get_tree().current_scene.add_child(obj)
	
	for i in maxthrowPoints:
		if not is_instance_valid(obj):
			return null
			
		var step = _step_trajectory(start_pos, current_pos, t, v, grav)
		current_pos = step.pos
		obj.global_position = current_pos
		
		if step.hit:
			return step
			
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	return null

func throw_preview(origin1, throw_pos1, gravity1, max_throwing_t, max_throwing_p):
	origin = origin1
	target_pos = throw_pos1
	gravity = gravity1
	max_throwing_power = max_throwing_p
	max_throwing_time = max_throwing_t
	thrown_preview = true
	
func throw(origin1, throw_pos1, gravity1, max_throwing_t, max_throwing_p, dmg):
	# Nonaktifkan preview saat menembak
	thrown_preview = false
	clear_points()
	visible = false
	
	var projectile = projectile_scene.instantiate()
	# Kirim parameter langsung agar tidak tertimpa tembakan berikutnya
	var result_step = await simulate_throw(projectile, origin1, throw_pos1, gravity1, max_throwing_p)
	
	if is_instance_valid(projectile):
		projectile.queue_free()
		
	if result_step and result_step.hit:
		var hit_object = result_step.hit.collider
		if is_instance_valid(hit_object) and hit_object.has_method("on_hit"):
			if hit_object != player:
				hit_object.on_hit(dmg, result_step.pos)

func _process(delta: float) -> void:
	if not thrown_preview: return
	clear_points()
	
	var v: Vector2 = get_velocity_for_fixed_speed(origin, target_pos, max_throwing_power, gravity)
	
	var dx: float = abs(target_pos.x - origin.x)
	var dy: float = -(target_pos.y - origin.y)
	
	var v2: float = max_throwing_power * max_throwing_power
	var v4: float = v2 * v2
	var discriminant: float = v4 - gravity * (gravity * dx * dx + 2.0 * dy * v2)
	
	var t: float = 0.0
	var dt: float = max_throwing_time / float(max(1, maxPoints - 1))
	if discriminant >= 0:
		var time_to_reach: float = abs(dx / v.x)
		dt = time_to_reach / float(max(1, maxPoints - 1))
	
	var preview_prev_pos = origin
	for i in maxPoints:
		var step = _step_trajectory(origin, preview_prev_pos, t, v, gravity)
		preview_prev_pos = step.pos
		add_point(to_local(preview_prev_pos))
		if step.hit:
			break
		t += dt
		
	visible = true
