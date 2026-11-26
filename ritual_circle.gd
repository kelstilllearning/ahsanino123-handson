extends Area2D

signal interactshow(state: int)
signal lockpick_hit
signal successfullock
signal ritual_completed

@export var minigame_scene: PackedScene
@export var target_sizes: Array[int] = [3, 1, 2] # Override the combo per ritual circle if needed

@onready var prompt_ui: Control = find_child("Control", true, false)
@onready var sprite: AnimatedSprite2D = find_child("AnimatedSprite2D", true, false)
@onready var match_sound: AudioStreamPlayer2D = find_child("Successsound", true, false)
@onready var complete_sound: AudioStreamPlayer2D = find_child("Opensound", true, false)

func _ready() -> void:
	interactshow.connect(_on_interact_show)
	lockpick_hit.connect(_on_candle_matched)
	successfullock.connect(_on_ritual_success)
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)
		
	if is_instance_valid(prompt_ui):
		prompt_ui.visible = false
	if is_instance_valid(sprite) and sprite.sprite_frames and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")

func _find_interaction_manager(body: Node) -> Node:
	var im = body.find_child("InteractionManager", true, false)
	if is_instance_valid(im):
		return im
	for child in body.get_children():
		if "near_interactables" in child:
			return child
	return null

func _on_body_entered(body: Node2D) -> void:
	var im = _find_interaction_manager(body)
	if is_instance_valid(im) and not im.near_interactables.has(self):
		im.near_interactables.append(self)

func _on_body_exited(body: Node2D) -> void:
	var im = _find_interaction_manager(body)
	if is_instance_valid(im):
		im.near_interactables.erase(self)

func _on_interact_show(state: int) -> void:
	if is_instance_valid(prompt_ui):
		prompt_ui.visible = (state == 1)

func _on_candle_matched() -> void:
	if is_instance_valid(match_sound) and match_sound.stream != null:
		match_sound.play()

func _on_ritual_success() -> void:
	if is_instance_valid(complete_sound) and complete_sound.stream != null:
		complete_sound.play()
	if is_instance_valid(sprite) and sprite.sprite_frames and sprite.sprite_frames.has_animation("activated"):
		sprite.play("activated")
		
	# Disable interaction once solved
	set_deferred("monitoring", false)
	_on_interact_show(0)
	ritual_completed.emit()
