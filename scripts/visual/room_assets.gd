class_name RoomAssets
extends RefCounted
## Imported resources are shared; each placement has its own transform and collider.
static var scenes: Dictionary = {}
static var materials: Dictionary = {}
const CHARCOAL = Color("303638")
const WHITE = Color("e7e7df")
const GREEN = Color("6e9f3d")

static func place(parent: Node3D, pack: String, asset: String, pos: Vector3, height: float, yaw: float = 0, palette: String = "default", solid: bool = false) -> Node3D:
	var path = "res://assets/environment/"+pack+"/"+asset+".glb"
	if not scenes.has(path): scenes[path] = load(path)
	var pivot = Node3D.new()
	pivot.name = asset
	parent.add_child(pivot)
	var model = scenes[path].instantiate()
	pivot.add_child(model)
	var box = bounds(model)
	var factor = height / maxf(box.size.y,.001)
	model.scale *= factor
	model.position -= Vector3(box.get_center().x,box.position.y,box.get_center().z)*factor
	_palette(model,pack,palette)
	pivot.position = pos
	pivot.rotation.y = yaw
	pivot.set_meta("asset_source",pack)
	pivot.set_meta("bounds",AABB(Vector3(-box.size.x*.5,0,-box.size.z*.5)*factor,box.size*factor))
	if solid:
		collider(pivot,Vector3(0,height*.5,0),box.size*factor)
		if pos.y < .05:
			var footprint = Vector2(box.size.x,box.size.z)*factor
			if palette == "plant": footprint *= .50
			contact_shadow(parent,pos,footprint,yaw)
	return pivot

static func contact_shadow(parent: Node3D, pos: Vector3, footprint: Vector2, yaw: float) -> void:
	var shadow = MeshInstance3D.new()
	shadow.name = "ContactShade"
	var plane = PlaneMesh.new()
	plane.size = footprint*1.3
	shadow.mesh = plane
	var key = "contact_shadow"
	if not materials.has(key):
		var mat = ShaderMaterial.new()
		mat.shader = preload("res://assets/environment/contact_shadow.gdshader")
		materials[key] = mat
	shadow.material_override = materials[key]
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(shadow)
	shadow.position = Vector3(pos.x,.030 if Vector2(pos.x,pos.z).length() < 3.96 else .006,pos.z)
	shadow.rotation.y = yaw

static func bounds(node: Node, inherited: Transform3D = Transform3D.IDENTITY) -> AABB:
	var transform = inherited * node.transform if node is Node3D else inherited
	var result = transform * node.get_aabb() if node is MeshInstance3D else AABB()
	for child in node.get_children():
		var child_box = bounds(child,transform)
		if child_box.size != Vector3.ZERO: result = child_box if result.size == Vector3.ZERO else result.merge(child_box)
	return result

static func collider(parent: Node3D, pos: Vector3, size: Vector3) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.name = "RoomCollision"
	body.collision_layer = 2
	body.collision_mask = 0
	parent.add_child(body)
	body.position = pos
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	return body

static func _palette(node: Node, pack: String, palette: String) -> void:
	if node is AnimationPlayer: node.stop()
	if node is MeshInstance3D:
		for i in node.mesh.get_surface_count():
			var source = node.get_active_material(i)
			if source == null: continue
			var key = pack+":"+source.resource_name+":"+palette
			if not materials.has(key):
				var mat: StandardMaterial3D = source.duplicate()
				mat.roughness = .72
				mat.metallic = 0
				mat.metallic_specular = .32
				if pack in ["nappin_office","kenney_furniture"]:
					mat.albedo_texture = null
					var id = source.resource_name.to_lower()
					var color = CHARCOAL
					if pack == "nappin_office":
						if "grey" in id or "beige" in id: color = WHITE
						if palette == "dark" and ("brown" in id or "grey" in id): color = CHARCOAL.lightened(.05) if "grey" in id else CHARCOAL
						if palette == "plant":
							color = Color("433b2d") if "darkbrown" in id else WHITE
							if "green" in id or "red" in id: color = Color("4f873b") if "dark" in id else Color("78a948")
						if palette == "books" and ("blue" in id or "red" in id or "orange" in id): color = GREEN
						if "emissive" in id:
							color = Color("fff6df")
							mat.emission_enabled = true
							mat.emission = color
							mat.emission_energy_multiplier = .7
					else:
						if "plant" in id: color = Color("639c42")
						if "white" in id or "metal" == id: color = WHITE
						if palette == "green" and "carpet" in id: color = GREEN
						if palette == "plant" and "wood" in id: color = WHITE
					mat.albedo_color = color
					if "metallic" in id or "metal" in id:
						mat.metallic = .35
						mat.roughness = .48
				materials[key] = mat
			node.set_surface_override_material(i,materials[key])
	for child in node.get_children(): _palette(child,pack,palette)
