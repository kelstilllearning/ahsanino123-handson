extends Area2D

func _ready() -> void:
	pass 

func _process(delta: float) -> void:
	pass

func _on_body_entered(body: Node2D) -> void:
	print("FUCK")
	body.queue_free()
	if body.is_in_group("Projectile") :
		self.queue_free()
