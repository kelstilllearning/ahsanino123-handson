class_name player
extends CharacterBody2D

# -- character
var player := player
var acceleration := 300
var jump_power := 400
var gravity := 980*2
var speed := Vector2()
var max_throwing_range := 400.0
var max_throwing_time := 3.0
var max_throwing_power := 2000
var throwing_charge_speed := 2.5
var slingshot_damage := 50

# -- controls
var min_zoom := 0.4
var max_zoom := 4
var zoom_speed := 0.03
