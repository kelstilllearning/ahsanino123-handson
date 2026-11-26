extends Node

var scene: Node
var player_scene: PackedScene
var monster_scene: PackedScene

var current_scene: Node
var player: CharacterBody2D
var monster: CharacterBody2D

var is_resetting := false

func create_new_scene() -> void:
	var cloned_scene := scene.duplicate()
	get_tree().root.add_child(cloned_scene)
	get_tree().current_scene = cloned_scene
	current_scene = cloned_scene

func insert_player() -> void:
	var player_instance: Node = player_scene.instantiate()
	current_scene.add_child(player_instance)
	player_instance.owner = current_scene
	player = player_instance
	
	# find spawn_pos
	var spawn_pos : Vector2 = current_scene.find_child("player_spawn", true, false).global_position
	player.global_position = spawn_pos
	
	# activate cam
	var cam := player.find_child("Camera2D", true, false)
	if cam:
		cam.make_current()

func insert_monster() -> void:
	# insert for every spawn there is
	for spawn_area in get_tree().get_nodes_in_group("monster_spawn_area"):
		var monster_instance: Node = monster_scene.instantiate()
		current_scene.add_child(monster_instance)
		monster_instance.owner = current_scene
		monster = monster_instance
		
		var spawn_shape : CollisionShape2D = spawn_area.find_child("*", true, false) as CollisionShape2D
		var rect := spawn_shape.shape as RectangleShape2D
		
		var spawn_area_size : Vector2 = rect.size
		var spawn_area_pos : Vector2 = spawn_shape.global_position - spawn_area_size / 2.0
		var spawn_pos = Vector2(
			randf_range(spawn_area_pos.x, spawn_area_pos.x + spawn_area_size.x),
			randf_range(spawn_area_pos.y, spawn_area_pos.y + spawn_area_size.y)
		)
		monster.position = spawn_pos

func clear() -> void:
	if is_instance_valid(current_scene):
		get_tree().root.remove_child(current_scene)
		current_scene.queue_free() # Deletes current_scene 
	player = null
	monster = null
	current_scene = null

func setup() -> void:
	create_new_scene()
	insert_player()
	insert_monster()

func _ready() -> void:
	player_scene = load("res://player.tscn")
	monster_scene = load("res://monster.tscn")
	
	# Wait 1 frame so the main scene is guaranteed to exist, then detach it ONCE as your clean template
	await get_tree().process_frame
	scene = get_tree().current_scene
	get_tree().root.remove_child(scene)
	
	setup()

func _process(_delta: float) -> void:
	if scene == null or is_resetting:
		return
	if not is_instance_valid(player):
		is_resetting = true
		clear()
		await get_tree().create_timer(1.0).timeout
		setup()
		is_resetting = false
