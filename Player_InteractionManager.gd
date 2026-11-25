extends Node2D

const LOCKPICK_TEMPLATE = preload("res://Lockpickingstuff/LockpickPopup.tscn")

signal restartlock
signal targeting
signal locksuccess
signal lockpick_state_changed(is_active: bool)

@export var near_interactables: Array[Node2D] = []

@onready var parent: Node = get_parent()
@onready var ui_layer: CanvasLayer = find_child("CanvasLayer", false, false)

var lockpick_status: bool = false
var lockpick_current: Node = null

@export var targeted: Node2D = null:
	set(oncoming):
		if targeted == oncoming:
			return
			
		if is_instance_valid(targeted) and targeted.has_signal("interactshow"):
			targeted.interactshow.emit(0)
			
		if is_instance_valid(oncoming) and oncoming.has_signal("interactshow"):
			oncoming.interactshow.emit(1)
			
		targeted = oncoming

func _ready() -> void:
	locksuccess.connect(lockpicksuccess)
	restartlock.connect(delete_lock)
	targeting.connect(update_target)
	
	if not is_instance_valid(ui_layer):
		ui_layer = CanvasLayer.new()
		ui_layer.name = "CanvasLayer"
		add_child(ui_layer)

func _process(_delta: float) -> void:
	update_target()

func update_target() -> void:
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
		_start_lockpick()

func _start_lockpick() -> void:
	lockpick_status = true
	lockpick_state_changed.emit(true)
	if is_instance_valid(parent) and parent.has_signal("busyness"):
		parent.emit_signal("busyness")
		
	lockpick_current = LOCKPICK_TEMPLATE.instantiate()
	if lockpick_current.has_signal("zone_hit"):
		lockpick_current.zone_hit.connect(_on_lockpick_zone_hit)
	if lockpick_current.has_signal("lockpick_finished"):
		lockpick_current.lockpick_finished.connect(_on_lockpick_finished)
	ui_layer.add_child(lockpick_current)
	
	if lockpick_current is Control:
		lockpick_current.set_anchors_and_offsets_preset(Control.PRESET_CENTER)

func _on_lockpick_zone_hit() -> void:
	if is_instance_valid(targeted) and targeted.has_signal("lockpick_hit"):
		targeted.lockpick_hit.emit()

func _on_lockpick_finished(success: bool) -> void:
	if is_instance_valid(parent) and parent.has_signal("busyness"):
		parent.emit_signal("busyness")
	lockpick_state_changed.emit(false)
	
	if success:
		locksuccess.emit()
	delete_lock()

func delete_lock() -> void:
	lockpick_status = false
	if is_instance_valid(lockpick_current):
		lockpick_current.queue_free()
		await get_tree().process_frame
		lockpick_current = null

func lockpicksuccess() -> void:
	if is_instance_valid(targeted) and targeted.has_signal("successfullock"):
		targeted.successfullock.emit()
