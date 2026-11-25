extends Node2D

var mousepos;
const Projectile = preload("res://slingshot_projectile.tscn")
var initialforce : float = 2500
var charging : bool = false
var circleradius : float = 200
@onready var Line = $Line2D
@onready var Ray = $RayCast2D
@onready var ChargingTimer = $ChargingTimer

func _ready() -> void:
	pass 

func _process(delta: float) -> void:
	self.look_at(mousepos)

func _physics_process(delta: float) -> void:
	mousepos = get_global_mouse_position()
	Line.set_point_position(0, self.global_position)
	if(!charging) : 
		Line.set_point_position(1, global_position + (mousepos-global_position).limit_length(circleradius))
	else :
		Line.set_point_position(1, (global_position + (ChargingTimer.wait_time-ChargingTimer.time_left)/(ChargingTimer.wait_time)*(mousepos-global_position).limit_length(circleradius)))

func _input(event: InputEvent) -> void:
	if (Input.is_action_just_pressed("shoot")) :
		ChargingTimer.start()
		charging = true
	if (Input.is_action_just_released("shoot")) :
		var FUCK = Projectile.instantiate()
		FUCK.linear_velocity = mousepos.normalized() * ((ChargingTimer.wait_time-ChargingTimer.time_left)/(ChargingTimer.wait_time))*initialforce
		get_tree().current_scene.add_child(FUCK)
		charging = false
		ChargingTimer.stop()
