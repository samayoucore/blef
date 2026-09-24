extends Control
var star = false
var color = Color("75ed75")
func _init(leader: bool = false) -> void:
	star = leader
	custom_minimum_size = Vector2(24,24)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	if star:
		var points = PackedVector2Array()
		for i in 10:
			var a = -PI/2.0 + i*PI/5.0
			points.append(size/2.0 + Vector2(cos(a),sin(a))*(11.0 if i%2==0 else 4.8))
		draw_colored_polygon(points,Color("ffda68"))
	else:
		draw_polyline(PackedVector2Array([Vector2(4,12),Vector2(10,18),Vector2(21,5)]),color,3.0,true)
