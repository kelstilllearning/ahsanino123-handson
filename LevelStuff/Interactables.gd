extends Area2D

signal interactshow(state: int)
signal lockpick_hit
signal successfullock

@onready var control: Control = find_child("Control")
@onready var animationsprite: AnimatedSprite2D = find_child("AnimatedSprite2D")
@onready var open_sound: AudioStreamPlayer2D = find_child("Opensound")
@onready var success_sound: AudioStreamPlayer2D = find_child("Successsound")

func _ready() -> void:
	lockpick_hit.connect(play_hit_sound)
	successfullock.connect(opendoor)
	interactshow.connect(switchinteract)
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)
		
	if is_instance_valid(animationsprite):
		animationsprite.play("Idle_Closed")
	if is_instance_valid(control):
		control.visible = false

func _on_body_entered(body: Node2D) -> void:
	var im = body.find_child("InteractionManager", true, false)
	if is_instance_valid(im) and not im.near_interactables.has(self):
		im.near_interactables.append(self)

func _on_body_exited(body: Node2D) -> void:
	var im = body.find_child("InteractionManager", true, false)
	if is_instance_valid(im):
		im.near_interactables.erase(self)

func switchinteract(state: int) -> void:
	if is_instance_valid(control):
		control.visible = (state == 1)

func play_hit_sound() -> void:
	if is_instance_valid(success_sound) and success_sound.stream != null:
		success_sound.play()

func opendoor() -> void:
	if is_instance_valid(open_sound) and open_sound.stream != null:
		open_sound.play()
		
	if is_instance_valid(animationsprite):
		animationsprite.play("Opening")
		
	var static_body = find_child("StaticBody2D")
	if is_instance_valid(static_body):
		static_body.queue_free()
		
	set_deferred("monitoring", false)
	switchinteract(0)
