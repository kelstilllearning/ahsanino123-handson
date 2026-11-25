extends RigidBody2D
@onready var Collider = $CollisionShape2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.add_to_group("Projectile")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_body_entered(body: Node) -> void:
	#if !body.is_in_group("Player") :
		#queue_free()
	pass
