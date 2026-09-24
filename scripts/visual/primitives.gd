class_name Forms
extends RefCounted
static var materials: Dictionary = {}

static func material(color: Color, metallic: float = 0.0, rough: float = 0.55) -> StandardMaterial3D:
	var key = str(color)+str(metallic)+str(rough)
	if materials.has(key):
		return materials[key]
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = rough
	materials[key] = mat
	return mat

static func mesh(parent: Node3D, shape: Mesh, pos: Vector3, color: Color, metallic: float = 0.0) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	node.mesh = shape
	node.material_override = material(color, metallic)
	parent.add_child(node)
	node.position = pos
	return node

static func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, metallic: float = 0.0) -> MeshInstance3D:
	var shape = BoxMesh.new()
	shape.size = size
	return mesh(parent,shape,pos,color,metallic)

static func sphere(parent: Node3D, pos: Vector3, size: Vector3, color: Color, metallic: float = 0.0) -> MeshInstance3D:
	var shape = SphereMesh.new()
	shape.radius = 0.5
	shape.height = 1
	shape.radial_segments = 32
	shape.rings = 16
	var node = mesh(parent,shape,pos,color,metallic)
	node.scale = size
	return node

static func cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color, top: float = -1, metallic: float = 0.0) -> MeshInstance3D:
	var shape = CylinderMesh.new()
	shape.top_radius = radius if top < 0 else top
	shape.bottom_radius = radius
	shape.height = height
	shape.radial_segments = 48
	return mesh(parent,shape,pos,color,metallic)

static func rod(parent: Node3D, a: Vector3, b: Vector3, radius: float, color: Color, metallic: float = 0.0) -> MeshInstance3D:
	var node = cylinder(parent,(a+b)*0.5,radius,a.distance_to(b),color,-1,metallic)
	var direction = (b-a).normalized()
	var side = direction.cross(Vector3.FORWARD)
	if side.length_squared() < 0.01:
		side = direction.cross(Vector3.RIGHT)
	side = side.normalized()
	node.basis = Basis(side, direction, side.cross(direction)).orthonormalized()
	return node

static func torus(parent: Node3D, pos: Vector3, inner: float, outer: float, color: Color) -> MeshInstance3D:
	var shape = TorusMesh.new()
	shape.inner_radius = inner
	shape.outer_radius = outer
	shape.rings = 32
	shape.ring_segments = 12
	return mesh(parent,shape,pos,color)

static func label(parent: Node3D, text: String, pos: Vector3, size: int = 48, color: Color = Color.WHITE) -> Label3D:
	var node = Label3D.new()
	node.text = text
	node.font_size = size
	node.pixel_size = 0.005
	node.modulate = color
	node.outline_size = 0
	parent.add_child(node)
	node.position = pos
	return node
