class_name GlassPanel
extends PanelContainer
## All panels in a canvas share Godot's single automatic screen copy.
## Nine texture samples are evaluated only within each panel's rectangle.
const BLUR = preload("res://scripts/ui/glass.gdshader")
var blur_strength = 5.0
var background_opacity = 0.76
var tint = Color("101411")
var border_opacity = 0.32
var corner_radius = 20
var shadow_strength = 0.28
var padding = 24
var backdrop: ColorRect

func _ready() -> void:
	var frame = UI.style(Color.TRANSPARENT,corner_radius,Color(0.85,0.90,0.86,border_opacity),padding)
	frame.shadow_color = Color(0,0,0,shadow_strength)
	frame.shadow_size = 14
	frame.shadow_offset = Vector2(0,5)
	add_theme_stylebox_override("panel",frame)
	backdrop = ColorRect.new()
	backdrop.show_behind_parent = true
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	move_child(backdrop,0)
	var shader_material = ShaderMaterial.new()
	shader_material.shader = BLUR
	shader_material.set_shader_parameter("blur_strength",blur_strength)
	shader_material.set_shader_parameter("background_opacity",background_opacity)
	shader_material.set_shader_parameter("tint",tint)
	shader_material.set_shader_parameter("corner_radius",float(corner_radius))
	backdrop.material = shader_material
	resized.connect(_resize_backdrop)
	sort_children.connect(func(): _resize_backdrop.call_deferred())
	_resize_backdrop()

func _resize_backdrop() -> void:
	backdrop.position = Vector2.ZERO
	backdrop.size = size
	backdrop.material.set_shader_parameter("panel_size",size)
