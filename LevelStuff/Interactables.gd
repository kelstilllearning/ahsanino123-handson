extends Area2D
@export var player : Node2D 
var deltapos : float
@export var IM : Node
signal interactshow(hey : int)
var control
var animationsprite
signal successfullock

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect("successfullock", opendoor)
	animationsprite = find_child("AnimatedSprite2D")
	control = find_child("Control")
	connect("interactshow", switchinteract)
	animationsprite.play("Idle_Closed")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	deltapos = ((self.position - player.position) if player!=null else Vector2.ZERO).length()

func _on_body_entered(body: Node2D) -> void:
	if body.name == "player":
		IM = body.find_child("InteractionManager", true, false)
		IM.near_interactables.append(self)
		#IM.targeting.emit()

func _on_body_exited(body: Node2D) -> void:
	if body.name == "player":
		IM = body.find_child("InteractionManager", true, false)
		IM.near_interactables.remove_at(IM.near_interactables.find(self))
		#IM.targeting.emit()
		
func switchinteract(fuck: int) :
	match fuck :
		0 :#matiin
			control.visible = false
		1 :#nyalain
			control.visible = true
			
func opendoor():
	animationsprite.play("Opening")
	$StaticBody2D.set_collision_layer_value(2, false)
