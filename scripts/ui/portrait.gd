class_name Portrait
extends SubViewportContainer
var viewport: SubViewport
var avatar: BlefAvatar
var stage: Node3D
var hero = false

func _init() -> void:
	custom_minimum_size = Vector2(300,300)
	stretch = true
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func setup(info: Dictionary, with_case: bool = false) -> void:
	hero = with_case
	viewport = SubViewport.new()
	viewport.size = Vector2i(600,600)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_2X
	add_child(viewport)
	stage = Node3D.new()
	viewport.add_child(stage)
	var cam = Camera3D.new()
	stage.add_child(cam)
	cam.position = Vector3(0,.27,3.3)
	cam.look_at(Vector3(0,-.15,0))
	cam.fov = 38
	cam.keep_aspect = Camera3D.KEEP_HEIGHT if hero else Camera3D.KEEP_WIDTH
	if not hero: cam.fov = 40
	cam.current = true
	var light = DirectionalLight3D.new()
	stage.add_child(light)
	light.rotation_degrees = Vector3(-30,-28,0)
	light.light_energy = .72
	var world = WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("d8ecd1")
	world.environment.ambient_light_energy = .40
	stage.add_child(world)
	set_avatar(info)
	if with_case:
		var case_node = preload("res://gameplay/case/player_case.tscn").instantiate()
		stage.add_child(case_node)
		case_node.position = Vector3(0,-.84,.23)
		case_node.rotation_degrees.y = -12
		Forms.cylinder(stage,Vector3(0,-1.03,0),.96,.16,Color("466846"))

func set_avatar(info: Dictionary) -> void:
	if avatar:
		stage.remove_child(avatar)
		avatar.queue_free()
	avatar = BlefAvatar.new()
	stage.add_child(avatar)
	avatar.build(info)
	avatar.rotation_degrees.y = -9 if hero else 0
	avatar.set_pose("thinking" if hero else "open")
