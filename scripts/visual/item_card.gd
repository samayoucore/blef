class_name ItemCard3D
extends Node3D
## Universal two-sided card. Hidden item data is supplied by the caller.
const CARD_SIZE = Vector2(.84, 1.05)
const CARD_THICKNESS = .009
const CARD_SHADER = preload("res://scripts/visual/card_surface.gdshader")
const BACK_TEXTURE = preload("res://assets/cards/back/card_back.png")
var data: Dictionary = {}
var front_mesh: MeshInstance3D
var back_mesh: MeshInstance3D
var shell: Node3D
var panel: Control
var front_texture: Texture2D
var flip_motion: Tween

func build(card_data: Dictionary, start_back: bool = false) -> void:
	data = card_data.duplicate(true)
	front_texture = _load_front_texture()
	if front_texture:
		panel = TextureRect.new()
		panel.custom_minimum_size = Vector2(640,800)
		panel.visible = false
		add_child(panel)
	else:
		_create_placeholder()
	shell = Node3D.new()
	shell.name = "CardController"
	add_child(shell)
	front_mesh = _make_side(front_texture if front_texture else _viewport_texture(), false)
	back_mesh = _make_side(BACK_TEXTURE, true)
	shell.add_child(front_mesh)
	shell.add_child(back_mesh)
	if start_back:
		shell.rotation.y = PI

func _load_front_texture() -> Texture2D:
	var path = str(data.get("card_texture_path",""))
	if path.is_empty() or not ResourceLoader.exists(path): return null
	return load(path) as Texture2D

func _create_placeholder() -> void:
	var viewport = SubViewport.new()
	viewport.name = "CardPlaceholderViewport"
	viewport.size = Vector2i(640,800)
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var root = PanelContainer.new()
	panel = root
	root.size = Vector2(640,800)
	root.theme = UI.theme()
	root.add_theme_stylebox_override("panel",UI.style(Color("fff8e6"),28,Color("54895d"),30))
	viewport.add_child(root)
	var box = UI.vbox(root,16)
	UI.label(box,"БЛЕФ  /  ПРЕДМЕТ",24,Color("47714d"))
	UI.label(box,str(data.get("rarity","")),27,Color("47714d"))
	UI.label(box,str(data.get("name","")),43,Color("192c20"),true)
	UI.spacer(box)
	UI.label(box,"База: "+Content.number(data.get("base_value",0)),38,Color("1f6636"))
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

func _viewport_texture() -> Texture2D:
	for child in get_children():
		if child is SubViewport: return child.get_texture()
	return null

func _make_side(texture: Texture2D, reverse: bool) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "Back" if reverse else "Front"
	var quad = QuadMesh.new()
	quad.size = CARD_SIZE
	mesh_instance.mesh = quad
	mesh_instance.position.z = -CARD_THICKNESS if reverse else CARD_THICKNESS
	if reverse: mesh_instance.rotation.y = PI
	var material = ShaderMaterial.new()
	material.shader = CARD_SHADER
	material.set_shader_parameter("card_texture",texture)
	material.set_shader_parameter("source_aspect",float(texture.get_width())/texture.get_height())
	mesh_instance.material_override = material
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mesh_instance

func reveal_front(duration: float = .52) -> void:
	if not shell: return
	if flip_motion and flip_motion.is_valid(): flip_motion.kill()
	flip_motion = create_tween()
	flip_motion.tween_property(shell,"rotation:y",0.0,duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _fit_text() -> void:
	return
