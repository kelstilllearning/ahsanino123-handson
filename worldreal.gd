extends Node2D

var pause_menu_scene = preload("res://canvas_layer.tscn")

func _ready() -> void:
	var pause_menu = pause_menu_scene.instantiate()
	add_child(pause_menu)
