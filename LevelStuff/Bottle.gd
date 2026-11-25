extends Area2D
var health = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Projectile") :
		on_hit(1)
	#put noisemaker here
	pass # Replace with function body.

func on_hit(dmg:float) :
	health-=dmg
	if(health<=0):
		queue_free()
		pass
	
