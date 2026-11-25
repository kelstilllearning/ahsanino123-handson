extends Camera2D

@export var decay_rate: float = 5.0
var shake_strength: float = 0.0

func apply_shake(intensity: float) -> void:
	shake_strength = intensity

func _process(delta: float) -> void:
	if shake_strength > 0.01:
		# Smoothly reduce the shake strength over time
		shake_strength = lerpf(shake_strength, 0.0, decay_rate * delta)
		
		# Apply a random offset within the current shake strength
		offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
	else:
		shake_strength = 0.0
		offset = Vector2.ZERO
