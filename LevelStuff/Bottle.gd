extends Node2D

signal bottle_broken(impact_position: Vector2)

@onready var sprite: Node2D = find_child("Sprite2D", true, false)
@onready var anim_sprite: AnimatedSprite2D = find_child("AnimatedSprite2D", true, false)
@onready var break_sound: AudioStreamPlayer2D = find_child("BreakSound", true, false)

var _is_broken: bool = false

func _ready() -> void:
	if has_signal("body_entered"):
		connect("body_entered", _on_impact)
	if has_signal("area_entered"):
		connect("area_entered", _on_impact)
		
	var hitbox: Area2D = find_child("Area2D", false, false)
	if is_instance_valid(hitbox):
		hitbox.body_entered.connect(_on_impact)
		hitbox.area_entered.connect(_on_impact)

func on_hit(_dmg: float = 0.0, _origin: Vector2 = Vector2.ZERO) -> void:
	shatter()

func _on_impact(other: Node) -> void:
	if _is_broken or not is_instance_valid(other):
		return
	if other.is_in_group("player") or other.is_in_group("enemies") or other is TileMapLayer or other is StaticBody2D:
		return
	shatter()

func shatter() -> void:
	if _is_broken:
		return
	_is_broken = true
	
	var break_pos := global_position
	bottle_broken.emit(break_pos)
	get_tree().call_group("noise_listeners", "on_noise_heard", break_pos)
	
	var col := find_child("CollisionShape2D", true, false)
	if is_instance_valid(col):
		col.set_deferred("disabled", true)
	if "monitoring" in self:
		set_deferred("monitoring", false)
		
	if is_instance_valid(anim_sprite) and anim_sprite.sprite_frames and anim_sprite.sprite_frames.has_animation("broken"):
		anim_sprite.play("broken")
	elif is_instance_valid(sprite):
		sprite.visible = false
		
	if is_instance_valid(break_sound) and break_sound.stream != null:
		break_sound.play()
		await break_sound.finished
		
	queue_free()
