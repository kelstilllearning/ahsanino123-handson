class_name player
extends CharacterBody2D

# -- character
var player := player
var max_health := 100
var health := max_health
var acceleration := 300
var jump_power := 400
var gravity := 980*2
var speed := Vector2()

# -- slingshot
var max_throwing_range := 400.0
var max_throwing_time := 3.0
var max_throwing_power := 2000
var throwing_charge_speed := 1.5
var slingshot_damage := 50

# -- controls
var max_cam_distance := 150
var min_zoom := 1.5
var max_zoom := 2
var zoom_speed := 0.05
