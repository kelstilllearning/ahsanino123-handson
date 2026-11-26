class_name player
extends CharacterBody2D

# -- character
var player := player
var acceleration := 500
var jump_power := 500
var gravity := 980*2
var speed := Vector2()
var max_throwing_range := 400.0
var max_throwing_time := 3.0
var max_throwing_power := 1200
var throwing_charge_speed := 2.5
var busy:bool = false

# -- controls
var min_zoom := 0.8
var max_zoom := 1.2
var zoom_speed := 0.03
