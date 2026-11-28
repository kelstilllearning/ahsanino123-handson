extends Node

@export var hearing_range: float = 3000.0
@export var arrival_distance: float = 35.0
@export var distraction_duration: float = 5.0

@onready var monster: CharacterBody2D = get_parent()

enum State { NONE, APPROACHING, DISTRACTED }
var _state: State = State.NONE
var _target_pos: Vector2 = Vector2.ZERO
var _distract_timer: float = 0.0

func _ready() -> void:
	add_to_group("noise_listeners")
	process_priority = 100

func on_noise_heard(noise_pos: Vector2) -> void:
	if not is_instance_valid(monster):
		return
	var dist := monster.global_position.distance_to(noise_pos)
	if dist > hearing_range:
		return
		
	_target_pos = noise_pos
	_state = State.APPROACHING
	monster.has_seen_player = false
	monster.first_seen_player = false
	monster.can_move = true
	monster.is_chasing = true

func _process(delta: float) -> void:
	if _state == State.NONE or not is_instance_valid(monster):
		return
		
	monster.has_seen_player = false
	monster.first_seen_player = false
		
	match _state:
		State.APPROACHING:
			monster.is_chasing = true
			monster.can_move = true
			monster.move_to(_target_pos, delta)
			
			if abs(monster.global_position.x - _target_pos.x) <= arrival_distance:
				_state = State.DISTRACTED
				_distract_timer = distraction_duration
				monster.can_move = false
				monster.velocity.x = 0.0
				monster.patrol_pos = monster.position
				
		State.DISTRACTED:
			monster.is_chasing = true
			monster.can_move = false
			monster.velocity.x = 0.0
			_distract_timer -= delta
			
			if _distract_timer <= 0.0:
				_cancel_distraction()

func _cancel_distraction() -> void:
	_state = State.NONE
	_distract_timer = 0.0
	if is_instance_valid(monster):
		monster.can_move = true
		monster.is_chasing = false
		monster.move_reached = true
