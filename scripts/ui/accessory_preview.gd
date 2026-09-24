extends SubViewportContainer
## A single rendered view of the actual accessory meshes, without a head/face.
func _init() -> void:
	custom_minimum_size = Vector2(78,78)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	stretch = true

func setup(cosmetic: Dictionary) -> void:
	var viewport = SubViewport.new()
	viewport.size = Vector2i(156,156)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_2X
	add_child(viewport)
	var avatar = BlefAvatar.new()
	viewport.add_child(avatar)
	avatar.set_process(false)
	avatar.head = Node3D.new()
	avatar.add_child(avatar.head)
	avatar._cosmetics({"equipped_"+str(cosmetic.slot).to_lower():cosmetic.id})
	var camera = Camera3D.new()
	viewport.add_child(camera)
	var center = Vector3(0,.42,0) if cosmetic.slot == "HEAD" else Vector3(0,.02,.35)
	camera.position = center+Vector3(.2,.12,2.6)
	camera.look_at(center)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 1.45 if cosmetic.slot == "HEAD" else .92
	var light = DirectionalLight3D.new()
	viewport.add_child(light)
	light.rotation_degrees = Vector3(-35,-25,0)
	light.light_energy = 1.1
	var environment = WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = .6
	viewport.add_child(environment)
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	resized.connect(func(): viewport.render_target_update_mode = SubViewport.UPDATE_ONCE)

