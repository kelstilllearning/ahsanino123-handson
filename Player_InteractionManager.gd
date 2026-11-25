extends Node2D

const LOCKPICK_TEMPLATE = preload("res://Lockpickingstuff/LockpickPopup.tscn")

signal restartlock
signal targeting
signal locksuccess

@export var near_interactables: Array[Node2D] = []

@onready var parent = get_parent()

var lockpick_status: bool = false
var lockpick_current: Node = null
#fucking gave up
@export var targeted: Node2D = null:
	set(oncoming):
		if targeted == oncoming:
			return
			
		# Hide prompt on the previous target if it still exists
		if is_instance_valid(targeted):
			targeted.interactshow.emit(0)
			
		# Show prompt on the new target if it exists
		if is_instance_valid(oncoming):
			oncoming.interactshow.emit(1)
			
		targeted = oncoming

func _ready() -> void:
	locksuccess.connect(lockpicksuccess)
	restartlock.connect(delete_lock)
	targeting.connect(update_target)

func _process(_delta: float) -> void:
	update_target()

func update_target() -> void:
	# Clean out any freed objects just in case
	near_interactables = near_interactables.filter(func(item): return is_instance_valid(item))
	
	if near_interactables.is_empty():
		targeted = null
	elif near_interactables.size() == 1:
		targeted = near_interactables[0]
	else:
		targeted = get_closest_interactable()

func get_closest_interactable() -> Node2D:
	var closest: Node2D = near_interactables[0]
	var closest_dist: float = global_position.distance_squared_to(closest.global_position)
	
	for item in near_interactables:
		var dist: float = global_position.distance_squared_to(item.global_position)
		if dist < closest_dist:
			closest = item
			closest_dist = dist
			
	return closest

func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(targeted) and event.is_action_pressed("Interact") and not lockpick_status:
		parent.busyness.emit()
		lockpick_status = true
		lockpick_current = LOCKPICK_TEMPLATE.instantiate()
		get_tree().current_scene.find_child("CanvasLayer").add_child(lockpick_current)

func delete_lock() -> void:
	lockpick_status = false
	if is_instance_valid(lockpick_current):
		lockpick_current.queue_free()
		await get_tree().get_frame()
		lockpick_current = null

func lockpicksuccess() :
	targeted.successfullock.emit()
	targeted.find_child("StaticBody2D").queue_free()
	targeted.find_child("CollisionShape2D").queue_free()
	pass
