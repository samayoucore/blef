class_name FaceSurface
extends MeshInstance3D
## Shared spherical patch, registered to the unchanged 0.45 m head (+Z front).
## The whole PNG canvas uses identical UVs for every expression. No bound fitting.
const RADIUS = 0.4535
const CANVAS_ANGLE = 2.2
const SEGMENTS = 48
static var shared_mesh: ArrayMesh
static var shared_materials: Dictionary = {}
var face_id = "normal"
var face_material: StandardMaterial3D

func _init() -> void:
	name = "FaceSurface"
	if shared_mesh == null: shared_mesh = _make_mesh()
	mesh = shared_mesh
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	set_face("normal")

func set_face(value: Variant) -> void:
	face_id = FacePresets.normalize(value)
	if not shared_materials.has(face_id):
		shared_materials[face_id] = _make_material(face_id)
	# Materials are immutable and shared, so changing one avatar never changes
	# another. Their lifetime also outlasts queued rendering dependencies.
	face_material = shared_materials[face_id]
	material_override = face_material

static func _make_material(id: String) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.resource_name = "FacePNG_"+id
	# Source PNGs already contain their highlights; keep their RGB independent
	# of the skin material. Depth testing keeps glasses and masks in front.
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material.texture_repeat = false
	material.albedo_texture = FacePresets.texture(id)
	return material

static func _make_mesh() -> ArrayMesh:
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	for row in SEGMENTS+1:
		for column in SEGMENTS+1:
			var uv = Vector2(float(column)/SEGMENTS, float(row)/SEGMENTS)
			var longitude = (uv.x-.5)*CANVAS_ANGLE
			var latitude = (.5-uv.y)*CANVAS_ANGLE
			var normal = Vector3(sin(longitude)*cos(latitude),sin(latitude),cos(longitude)*cos(latitude))
			vertices.append(normal*RADIUS)
			normals.append(normal)
			uvs.append(uv)
	for row in SEGMENTS:
		for column in SEGMENTS:
			var a = row*(SEGMENTS+1)+column
			var b = a+1
			var c = a+SEGMENTS+1
			indices.append_array(PackedInt32Array([a,b,c,b,c+1,c]))
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var result = ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return result
