extends Panel

signal zone_hit
signal lockpick_finished(success: bool)

@onready var movingthing: Control = $MovingKey

# Reaction hit settings
var currenthitcolor: Color
var currenthitlength: float
@export var currenthitamount: int = 1
var hitamountinc: int = 1
var currentlevel: int = 1
@export var successfulhits: int = 0

var level1c: Color = Color.GREEN
var level2c: Color = Color.GREEN_YELLOW
var level3c: Color = Color.SLATE_GRAY
var level1l: float = 45.0
var level2l: float = 30.0
var level3l: float = 15.0

# Stores Vector2(start_angle, end_angle) for ALL active hit zones
@export var hit_zones: Array[Vector2] = []
@export var aman: bool = false

# Circle settings
var currentbasecolor: Color = Color.BLACK
var antialias: bool = true
var tengahlingkaran: Vector2
var radius: float = 12.5

# Rotation settings
var tengahmuter: Vector2
var elapsed_time: float = 0.0
var speed: float = 3.0
@export var derajatlingkaran: float

var on: bool = false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	tengahlingkaran = self.get_rect().size * 0.5
	tengahmuter = movingthing.get_rect().size * 0.5
	if not on:
		currenthitcolor = level1c
		currenthitlength = level1l
		generate_hit_zones()

func generate_hit_zones() -> void:
	hit_zones.clear()
	var arc_rad: float = deg_to_rad(currenthitlength)
	var min_gap: float = deg_to_rad(10.0)
	var max_attempts: int = 10
	
	for i in range(currenthitamount):
		var placed: bool = false
		var attempts: int = 0
		
		while not placed and attempts < max_attempts:
			attempts += 1
			var start_angle: float = randf_range(-PI, PI - arc_rad)
			var end_angle: float = start_angle + arc_rad
			
			if not is_overlapping(start_angle, end_angle, min_gap):
				hit_zones.append(Vector2(start_angle, end_angle))
				placed = true

func is_overlapping(start_a: float, end_a: float, gap: float) -> bool:
	for zone in hit_zones:
		if start_a < (zone.y + gap) and end_a > (zone.x - gap):
			return true
	return false

func _draw() -> void:
	draw_arc(tengahlingkaran, radius, 0, TAU, 64, currentbasecolor, 200, antialias)
	
	for zone in hit_zones:
		draw_arc(tengahlingkaran, radius, zone.x, zone.y, 64, currenthitcolor, 200, antialias)
	draw_arc(tengahlingkaran, radius - 5, 0, TAU, 64, currentbasecolor, 200, antialias)

func _physics_process(delta: float) -> void:
	elapsed_time += delta
	var angle: float = elapsed_time * speed
	movingthing.position = tengahlingkaran + Vector2(cos(angle), sin(angle)) * (9 * radius) - tengahmuter
	
	derajatlingkaran = wrapf(angle, -PI, PI)
	
	aman = false
	for zone in hit_zones:
		if derajatlingkaran >= zone.x and derajatlingkaran <= zone.y:
			aman = true
			break

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Interact"):
		get_viewport().set_input_as_handled()
		lockpick_finished.emit(false)
		return
		
	if aman and event.is_action_pressed("Lockpick"):
		get_viewport().set_input_as_handled()
		zone_hit.emit()
		successfulhits += 1
		remove_hit_zone(hit_zones, derajatlingkaran)
		queue_redraw()
		
		if successfulhits != currenthitamount:
			return
			
		if currentlevel == 3:
			lockpick_finished.emit(true)
			return
			
		currentlevel += 1
		currenthitamount += hitamountinc
		successfulhits = 0
		match currentlevel:
			2:
				currenthitcolor = level2c
				currenthitlength = level2l
			3:
				currenthitcolor = level3c
				currenthitlength = level3l
		
		generate_hit_zones()
		queue_redraw()

func remove_hit_zone(zones: Array, deg: float) -> void:
	for i in range(zones.size()):
		if zones[i].x <= deg and deg <= zones[i].y:
			zones.remove_at(i)
			break
