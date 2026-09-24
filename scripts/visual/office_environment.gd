class_name OfficeEnvironment
extends Node3D
const A = preload("res://scripts/visual/room_assets.gd")
var ceiling: Node3D
var key_light: SpotLight3D
var shadow_fill: DirectionalLight3D
var world: WorldEnvironment

func build() -> void:
	name = "OfficeEnvironment"
	_shell()
	_table()
	_furniture()
	_lighting()
	apply_quality()
	Profile.graphics_changed.connect(apply_quality)

func _surface(color: Color, kind: int) -> ShaderMaterial:
	var mat = ShaderMaterial.new()
	mat.shader = preload("res://assets/environment/room_surface.gdshader")
	mat.set_shader_parameter("base_color",color)
	mat.set_shader_parameter("surface_kind",kind)
	return mat

func _block(pos: Vector3, size: Vector3, color: Color, solid: bool = true, parent: Node3D = null) -> MeshInstance3D:
	if parent == null: parent = self
	var mesh = Forms.box(parent,pos,size,color)
	mesh.material_override = Forms.material(color,0,.78)
	if solid: A.collider(parent,pos,size)
	return mesh

func _shell() -> void:
	_block(Vector3(0,-.08,0),Vector3(12.8,.16,12.0),Color("c7c5bc")).material_override = _surface(Color("c7c5bc"),0)
	_block(Vector3(-6.3,2.3,0),Vector3(.18,4.6,12),A.WHITE)
	_block(Vector3(6.3,2.3,0),Vector3(.18,4.6,12),A.WHITE)
	_block(Vector3(0,2.3,5.9),Vector3(12.6,4.6,.18),Color("e3e5df"))
	# A real opening, with a short neutral corridor behind it.
	_block(Vector3(-1.3,2.3,-5.9),Vector3(10,4.6,.18),A.WHITE)
	_block(Vector3(5.7,2.3,-5.9),Vector3(1.2,4.6,.18),A.WHITE)
	_block(Vector3(4.4,3.9,-5.9),Vector3(1.4,1.4,.18),A.WHITE)
	_block(Vector3(4.4,-.08,-6.75),Vector3(1.6,.16,1.7),Color("bdbeb6"))
	_block(Vector3(4.4,1.6,-7.5),Vector3(1.6,3.2,.18),Color("c9d0c7"))
	for x in [3.63,5.17]: _block(Vector3(x,1.6,-6.7),Vector3(.16,3.2,1.7),A.WHITE)
	_block(Vector3(-.9,2.25,-5.78),Vector3(7.4,4.5,.10),Color("47723d"))
	for x in [-4.68,2.91]: _block(Vector3(x,2.3,-5.65),Vector3(.20,4.6,.38),A.WHITE)
	# Small plinths give the walls contact with the tiled floor.
	for x in [-6.18,6.18]: _block(Vector3(x,.09,0),Vector3(.055,.18,11.8),Color("c4c7bd"),false)
	_block(Vector3(-1.3,.09,-5.76),Vector3(10,.18,.055),Color("adb8a3"),false)
	_block(Vector3(0,.09,5.78),Vector3(12.5,.18,.055),Color("c4c7bd"),false)
	ceiling = Node3D.new()
	ceiling.name = "Ceiling"
	add_child(ceiling)
	_block(Vector3(0,4.65,0),Vector3(12.8,.16,12),Color("e8e9e3"),true,ceiling)
	for x in [-4.2,4.2]:
		for z in [-3.2,2.8]:
			_block(Vector3(x,4.55,z),Vector3(.8,.035,.26),Color("565e59"),false,ceiling)
	for x in [-1.65,0,1.65]:
		A.place(ceiling,"nappin_office","CeilingLight1",Vector3(x,3.95,0),.62,0,"default")
	var rug = Forms.cylinder(self,Vector3(0,.013,0),3.96,.024,Color("779c46"))
	rug.name = "GreenRug"
	rug.material_override = _surface(Color("779c46"),2)

func _table() -> void:
	# Original dimensions and every gameplay anchor are retained.
	var table = Node3D.new()
	table.name = "OriginalTable"
	add_child(table)
	Forms.cylinder(table,Vector3(0,1.18,0),2.64,.18,A.WHITE).material_override = _surface(Color("ddc59f"),1)
	Forms.cylinder(table,Vector3(0,1.085,0),2.55,.035,A.CHARCOAL)
	Forms.cylinder(table,Vector3(0,.56,0),.62,1.03,A.CHARCOAL,.44)
	Forms.cylinder(table,Vector3(0,.08,0),1.10,.10,A.CHARCOAL)
	Forms.cylinder(table,Vector3(0,1.275,0),.73,.011,Color("373b3c"))
	A.contact_shadow(self,Vector3.ZERO,Vector2(2.3,2.3),0)
	var body = StaticBody3D.new()
	body.collision_layer = 2
	body.collision_mask = 0
	table.add_child(body)
	for dims in [Vector3(2.64,.18,1.18),Vector3(.62,1.03,.56)]:
		var collision = CollisionShape3D.new()
		var shape = CylinderShape3D.new()
		shape.radius = dims.x
		shape.height = dims.y
		collision.shape = shape
		collision.position.y = dims.z
		body.add_child(collision)

func _prop(asset: String, pos: Vector3, height: float, yaw: float = 0, palette: String = "default", solid: bool = false) -> Node3D:
	return A.place(self,"nappin_office",asset,pos,height,yaw,palette,solid)

func _furniture() -> void:
	# Back wall, left toy cabinet, and right coffee counter follow the plan.
	var credenza = _prop("BigDrawer",Vector3(-.9,0,-5.18),1.03,0,"dark",true)
	credenza.scale.x = 1.45
	_block(Vector3(-.9,2.82,-5.61),Vector3(4.45,2.42,.12),A.CHARCOAL)
	_block(Vector3(-.9,2.82,-5.534),Vector3(4.27,2.24,.022),Color("bdccd2"),false)
	_prop("Plant2",Vector3(-4.25,0,-5.03),2.15,0,"plant",true)
	_prop("Plant1",Vector3(2.65,0,-5.04),2.10,.3,"plant",true)
	_prop("DeskPlant",Vector3(.36,1.03,-5.14),.43,0,"plant")
	_prop("BookPile1",Vector3(-2.12,1.03,-5.10),.08,.1,"books")
	_prop("BigDrawer",Vector3(-5.64,0,-1.85),1.10,PI/2,"dark",true)
	for i in 3:
		A.place(self,"kenney_cube_pets",["animal-cat","animal-panda","animal-penguin"][i],Vector3(-5.56,1.10,-2.85+i*.7),.38,PI/2)
	_prop("DeskPlant",Vector3(-5.58,1.10,-.50),.46,0,"plant")
	_prop("Plant2",Vector3(-5.53,0,-4.25),1.90,.8,"plant",true)
	_prop("KitchenModule",Vector3(5.60,0,-1.05),2.66,-PI/2,"default",true)
	# Counter surface at 1.05 m; the imported module includes wall shelves.
	A.place(self,"kenney_furniture","kitchenCoffeeMachine",Vector3(5.35,1.075,-2.52),.51,-PI/2)
	_prop("CoffePot",Vector3(5.34,1.075,-1.87),.29,.4)
	for z in [-1.30,-.94]: _prop("Mug",Vector3(5.28,1.075,z),.19,-.4)
	A.place(self,"kenney_food","bowl",Vector3(5.37,1.075,-.33),.17)
	for entry in [["banana",Vector3(5.36,1.16,-.35),.17],["apple",Vector3(5.3,1.16,-.30),.16],["orange",Vector3(5.42,1.16,-.22),.14],["plate",Vector3(5.27,1.075,.32),.028],["croissant",Vector3(5.27,1.105,.32),.09]]:
		A.place(self,"kenney_food",entry[0],entry[1],entry[2])
	_prop("DeskPlant",Vector3(5.52,1.075,1.14),.47,0,"plant")
	_prop("PlantBox",Vector3(5.59,2.54,-.1),.29,-PI/2,"plant")
	# Relaxation corner outside the circle of players.
	A.place(self,"kenney_furniture","loungeSofa",Vector3(-4.77,0,4.3),1.12,PI/2,"dark",true)
	for z in [3.55,4.85]: A.place(self,"kenney_furniture","pillow",Vector3(-4.82,.62,z),.40,PI/2,"green")
	A.place(self,"kenney_furniture","tableCoffee",Vector3(-3.75,0,4.5),.49,PI/2,"dark",true)
	_prop("DeskPlant",Vector3(-3.73,.49,4.76),.35,0,"plant")
	_prop("BookPile1",Vector3(-3.70,.49,4.14),.09,.25,"books")
	_prop("Plant2",Vector3(5.46,0,4.72),1.92,.7,"plant",true)

func chair(pos: Vector3, yaw: float) -> void:
	A.place(self,"rr_office","OfficeChair",pos,1.75,yaw+PI,"default",true)

func _lighting() -> void:
	world = WorldEnvironment.new()
	add_child(world)
	var env = Environment.new()
	world.environment = env
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("d6ded9")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("e6eced")
	env.ambient_light_energy = .45
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	# A sky is used for broad metallic highlights; no real-time reflection probes.
	var sky = Sky.new()
	var sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("829ba8")
	sky_mat.sky_horizon_color = Color("e9eee9")
	sky_mat.ground_bottom_color = Color("697469")
	sky_mat.ground_horizon_color = Color("d8dcd1")
	sky.sky_material = sky_mat
	env.sky = sky
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	# Godot 4.6 Compatibility provides a lightweight SSAO implementation.
	# Only radius and intensity are supported by this renderer.
	env.ssao_radius = .65
	env.ssao_intensity = 1.1
	key_light = SpotLight3D.new()
	add_child(key_light)
	key_light.position = Vector3(0,4.43,.25)
	key_light.rotation_degrees.x = -90
	key_light.spot_range = 11
	key_light.spot_angle = 76
	key_light.spot_attenuation = .45
	key_light.spot_angle_attenuation = .5
	key_light.light_color = Color("fff9ef")
	key_light.light_energy = .25
	key_light.shadow_bias = .10
	key_light.shadow_normal_bias = 1.5
	key_light.shadow_blur = 4.0
	key_light.shadow_opacity = .48
	key_light.light_size = .8
	shadow_fill = DirectionalLight3D.new()
	add_child(shadow_fill)
	shadow_fill.rotation_degrees = Vector3(-38,-35,0)
	shadow_fill.light_color = Color("edf5ff")
	shadow_fill.light_energy = .18
	shadow_fill.shadow_enabled = false
	for pos in [Vector3(3.8,3.65,-3.7),Vector3(-4.3,3.6,2.8)]:
		var fill = OmniLight3D.new()
		add_child(fill)
		fill.position = pos
		fill.omni_range = 7
		fill.omni_attenuation = .6
		fill.light_energy = .07
		fill.light_color = Color("fff8eb")

func apply_quality() -> void:
	var quality = clampi(int(Profile.settings.get("graphics",1)),0,2)
	world.environment.ssao_enabled = quality > 0
	key_light.shadow_enabled = true
	get_viewport().positional_shadow_atlas_size = [1024,2048,4096][quality]
	get_viewport().positional_shadow_atlas_quad_0 = Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_1
	get_viewport().msaa_3d = [Viewport.MSAA_DISABLED,Viewport.MSAA_2X,Viewport.MSAA_4X][quality]
	RenderingServer.positional_soft_shadow_filter_set_quality([RenderingServer.SHADOW_QUALITY_HARD,RenderingServer.SHADOW_QUALITY_SOFT_LOW,RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM][quality])
