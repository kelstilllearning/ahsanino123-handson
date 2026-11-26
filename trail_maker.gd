extends Line2D

@export var max_trail_length: float = 100.0 # Panjang maksimal garis dalam pixel (atur angka ini!)
@export var max_points: int = 10

var target: Node2D
var has_reparented: bool = false

func _ready() -> void:
	target = get_parent()
	clear_points()
	reparent.call_deferred(get_tree().current_scene, false)
	# Tunggu 1 frame sampai reparent benar-benar selesai sebelum mulai menggambar
	await get_tree().process_frame
	position = Vector2.ZERO
	has_reparented = true

func _physics_process(_delta: float) -> void:
	if not has_reparented:
		return
		
	if not is_instance_valid(target):
		if get_point_count() > 0:
			remove_point(0)
		else:
			queue_free()
		return
		
	var current_pos = target.global_position
	add_point(current_pos)
	
	# Hapus titik paling belakang jika jumlah titik berlebih
	while get_point_count() > max_points:
		remove_point(0)
		
	# Hapus titik paling belakang jika jarak ekor ke kepala melebihi max_trail_length
	while get_point_count() > 2 and points[0].distance_to(current_pos) > max_trail_length:
		remove_point(0)
