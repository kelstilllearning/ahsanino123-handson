extends Panel

@onready var movingthing = $MovingKey

# Reaction hit settings
var currenthitcolor : Color
var currenthitlength : float
@export var currenthitamount : int = 1
var hitamountinc : int = 1
var currentlevel : int = 1
@export var successfulhits : int = 0

var level1c : Color = Color.GREEN
var level2c : Color = Color.DARK_SEA_GREEN
var level3c : Color = Color.SLATE_GRAY
var level1l : float = 45.0
var level2l : float = 30.0
var level3l : float = 15.0

# Stores Vector2(start_angle, end_angle) for ALL active hit zones
@export var hit_zones : Array[Vector2] = []
@export var aman : bool = false

# Circle settings
var currentbasecolor : Color = Color.DIM_GRAY
var antialias : bool = true
var tengahlingkaran : Vector2
var radius : float = 100.0

# Rotation settings
var tengahmuter : Vector2
var fuck : float = 0.0
var speed : float = 2.0
@export var derajatlingkaran : float

var on : bool = false

var IM
var playerobject

func _ready() -> void:
	playerobject = get_tree().current_scene.find_child("player")
	IM = playerobject.find_child("InteractionManager")
	tengahlingkaran = self.get_rect().size * 0.5
	tengahmuter = movingthing.get_rect().size * 0.5
	if (!on) :
		currenthitcolor = level1c
		currenthitlength = level1l
		generate_hit_zones()

func generate_hit_zones() -> void:
	hit_zones.clear()
	var arc_rad : float = deg_to_rad(currenthitlength)
	var min_gap : float = deg_to_rad(10.0) # Minimum spacing between arcs
	var max_attempts : int = 10 # Prevents infinite loop if zones can't fit
	
	for i in range(currenthitamount):
		var placed : bool = false
		var attempts : int = 0
		
		while not placed and attempts < max_attempts:
			attempts += 1
			var start_angle : float = randf_range(-PI, PI - arc_rad)
			var end_angle : float = start_angle + arc_rad
			
			if not is_overlapping(start_angle, end_angle, min_gap):
				hit_zones.append(Vector2(start_angle, end_angle))
				placed = true


func is_overlapping(start_a: float, end_a: float, gap: float) -> bool:
	for zone in hit_zones:
		# Check if [start_a, end_a] intersects [zone.x, zone.y] with a buffer gap
		if start_a < (zone.y + gap) and end_a > (zone.x - gap):
			return true
	return false


func _draw() -> void:
	# Draw background circle
	draw_arc(tengahlingkaran, radius, 0, TAU, 64, currentbasecolor, 200, antialias)
	
	# Draw all stored hit zones
	for zone in hit_zones:
		draw_arc(tengahlingkaran, radius, zone.x, zone.y, 64, currenthitcolor, 200, antialias)


func _physics_process(delta: float) -> void:
	fuck += delta
	var angle : float = fuck * speed
	movingthing.position = tengahlingkaran + Vector2(cos(angle), sin(angle)) * (2.0 * radius) - tengahmuter
	
	# Wrap angle cleanly into [-PI, PI] to match hit_zones
	derajatlingkaran = wrapf(angle, -PI, PI)
	
	# Check ALL hit zones
	aman = false
	for zone in hit_zones:
		if derajatlingkaran >= zone.x and derajatlingkaran <= zone.y:
			aman = true
			break


func _input(event: InputEvent) -> void:
	if (event.is_action_pressed("Interact")) :
		await get_tree().process_frame 
		IM.restartlock.emit()
		playerobject.busyness.emit()
		self.queue_free()
	if aman and Input.is_action_just_pressed("Lockpick"):
		successfulhits = successfulhits + 1
		cycling(hit_zones, derajatlingkaran)
		queue_redraw()
		if successfulhits != currenthitamount :
			return
		if currentlevel == 3 :
			await get_tree().process_frame 
			IM.restartlock.emit()
			playerobject.busyness.emit()
			self.queue_free()
			
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

func cycling(fucks: Array, deg: float) :
	for i in range(0, fucks.size()) :
		if (fucks[i].x <= deg  and deg <= fucks[i].y) :
			print("WORKING!")
			fucks.remove_at(i)
			break
		else : print("NOT WORKING, RETARD!")
