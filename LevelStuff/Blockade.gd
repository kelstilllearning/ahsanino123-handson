extends StaticBody2D
var health = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func on_hit(dmg:float, origin: Vector2):
	health -= dmg
	if (health<= 0) :
		print("Blockade Rusak")
		queue_free()
		pass
