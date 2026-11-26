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
	
	# activate cam
	var cam := player.find_child("Camera2D", true, false)
	if cam:
		cam.make_current()

func insert_monster() -> void:
	var monster_instance: Node = monster_scene.instantiate()
	current_scene.add_child(monster_instance)
	monster_instance.owner = current_scene
	monster = monster_instance
	
	var x_pos = randi_range(-2000, 2000)
	monster.position = Vector2(x_pos, -100)

func clear() -> void:
	if is_instance_valid(current_scene):
		get_tree().root.remove_child(current_scene)
		current_scene.queue_free() # Deletes current_scene AND the old monster inside it
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
		setup()
		is_resetting = false
