class_name AvatarBadge
extends Control
var info: Dictionary = {}

func _init(value: Dictionary = {}, extent: int = 48) -> void:
	info = value
	custom_minimum_size = Vector2(extent,extent)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

func _draw() -> void:
	var radius = minf(size.x,size.y)*.45
	var center = size*.5
	var color = Content.color(int(info.get("head_color_id",0)))
	draw_circle(center+Vector2(0,2),radius,Color("0b130e"),true,-1,true)
	draw_circle(center,radius,color.darkened(.10),true,-1,true)
	draw_circle(center+Vector2(-radius*.09,-radius*.10),radius*.86,color,true,-1,true)
	draw_texture_rect(FacePresets.texture(info.get("face_id","normal")),Rect2(center-Vector2.ONE*radius,Vector2.ONE*radius*2),false)
