extends Area2D

@export var table_z_when_hiding: int = 10

@onready var table_sprite: CanvasItem = find_child("Sprite2D", false, false)
@onready var ray_blocker: StaticBody2D = find_child("RayBlocker", false, false)
@onready var zone_shape: CollisionShape2D = find_child("CollisionShape2D", false, false)

var _is_hidden: bool = false
var _saved_table_z: int = 0

func _ready() -> void:
	# Run BEFORE the monster's _process so hit immunity is set first
	process_priority = -100
	
	if is_instance_valid(table_sprite):
		_saved_table_z = table_sprite.z_index
	else:
		_saved_table_z = z_index
	_set_ray_blocker(false)
	print("[HidingTable] Ready. zone_shape=", zone_shape, " ray_blocker=", ray_blocker)

func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if not is_instance_valid(player):
		return

	var inside_table := _is_player_inside_bounds(player)
	var is_crouching: bool = ("crouch" in player and player.crouch == true)
	var should_hide: bool = inside_table and is_crouching

	# Visual debug indicator on the table sprite
	if is_instance_valid(table_sprite):
		if should_hide:
			table_sprite.modulate = Color(0.5, 1.0, 0.5) # Green = HIDDEN
		elif inside_table:
			table_sprite.modulate = Color(1.0, 0.5, 0.5) # Red = INSIDE TABLE BUT NOT CROUCHED
		else:
			table_sprite.modulate = Color.WHITE          # Normal = OUTSIDE

	if should_hide != _is_hidden:
		_set_hidden(should_hide, player)

	if _is_hidden:
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if "has_seen_player" in enemy:
				enemy.has_seen_player = false
			if "is_chasing" in enemy:
				enemy.is_chasing = false
			if "objects_hit_cd" in enemy:
				enemy.objects_hit_cd[player] = 1.0
	elif not inside_table and is_crouching:
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy.has_method("see_infront"):
				var ray_result: Dictionary = enemy.see_infront()
				if ray_result and ray_result.get("collider") == player:
					enemy.has_seen_player = true

func _is_player_inside_bounds(player: CharacterBody2D) -> bool:
	if is_instance_valid(zone_shape) and zone_shape.shape is RectangleShape2D:
		var rect_shape := zone_shape.shape as RectangleShape2D
		var half_size := (rect_shape.size * zone_shape.global_scale) * 0.5
		var local_offset := player.global_position - zone_shape.global_position
		return abs(local_offset.x) <= half_size.x and abs(local_offset.y) <= half_size.y
	return overlaps_body(player)

func _set_hidden(hide_player: bool, player: CharacterBody2D) -> void:
	_is_hidden = hide_player
	print("[HidingTable] Hidden state changed -> ", _is_hidden)

	if hide_player:
		if is_instance_valid(table_sprite):
			table_sprite.z_index = player.z_index + table_z_when_hiding
		else:
			z_index = player.z_index + table_z_when_hiding

		_set_ray_blocker(true)
		var enemies := get_tree().get_nodes_in_group("enemies")
		print("[HidingTable] Clearing aggro on ", enemies.size(), " enemies")
		for enemy in enemies:
			if "has_seen_player" in enemy:
				enemy.has_seen_player = false
			if "is_chasing" in enemy:
				enemy.is_chasing = false
			if "first_seen_player" in enemy:
				enemy.first_seen_player = false
			if "move_reached" in enemy:
				enemy.move_reached = true
			if "objects_hit_cd" in enemy:
				enemy.objects_hit_cd[player] = 1.0
	else:
		if is_instance_valid(table_sprite):
			table_sprite.z_index = _saved_table_z
		else:
			z_index = _saved_table_z
		_set_ray_blocker(false)

		for enemy in get_tree().get_nodes_in_group("enemies"):
			if "objects_hit_cd" in enemy:
				enemy.objects_hit_cd.erase(player)

func _set_ray_blocker(active: bool) -> void:
	if not is_instance_valid(ray_blocker):
		return
	for child in ray_blocker.get_children():
		if child is CollisionShape2D:
			child.disabled = not active
