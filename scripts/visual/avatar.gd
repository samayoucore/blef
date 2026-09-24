class_name BlefAvatar
extends Node3D
var head: Node3D
var hands: Array = []
var pose = "idle"
var clock = 0.0
var color = Color("ffd34f")
var is_self = false
var face_root: FaceSurface
var base_face = "normal"
var visible_face = ""
var animators: Array[AnimationPlayer] = []
var gesture_sequence = -1
var pose_time = 0.0
var case_active = false
var pending_pose: Dictionary = {}
var appearance: Dictionary = {}
var head_look = Vector2.ZERO
const HAND_RADIUS = .350
const HEAD_RADIUS = .45
const HAND_ASSET = preload("res://assets/characters/hand_rig.glb")
const MIRRORED_HAND_ASSET = preload("res://assets/characters/hand_mirrored.glb")
const HEAD_ASSET = preload("res://assets/characters/head.glb")
static var skin_materials: Dictionary = {}
static var accessory_scenes: Dictionary = {}
static var accessory_materials: Dictionary = {}

func build(info: Dictionary, only_hands: bool = false) -> void:
	appearance = info.duplicate(true)
	color = Content.color(int(info.get("head_color_id",0)))
	is_self = only_hands
	base_face = FacePresets.normalize(info.get("face_id","normal"))
	if not only_hands:
		head = Node3D.new()
		head.name = "Head3D"
		add_child(head)
		var sphere = HEAD_ASSET.instantiate()
		head.add_child(sphere)
		_tint_skin(sphere)
		_show_face(base_face)
		_cosmetics(info)
	for side in [-1,1]:
		var hand = Node3D.new()
		add_child(hand)
		var model = (HAND_ASSET if side == -1 else MIRRORED_HAND_ASSET).instantiate()
		hand.add_child(model)
		_tint_skin(model)
		var animator = model.find_child("AnimationPlayer",true,false) as AnimationPlayer
		animators.append(animator)
		hand.position = Vector3(side*.57,-.55,.22)
		hands.append(hand)
	_play_fingers("idle")
	_sample_hands(0.0)

func _tint_skin(node: Node) -> void:
	if node is MeshInstance3D:
		for surface in node.mesh.get_surface_count():
			var source = node.mesh.surface_get_material(surface)
			if source and source.resource_name.begins_with("Skin_"):
				var key = source.resource_path+source.resource_name+str(color.to_rgba32())
				if not skin_materials.has(key):
					var mat = source.duplicate() as StandardMaterial3D
					mat.albedo_color = color
					mat.roughness = .86
					mat.metallic_specular = .20
					skin_materials[key] = mat
				node.set_surface_override_material(surface,skin_materials[key])
	for child in node.get_children(): _tint_skin(child)

func _show_face(value: Variant) -> void:
	var id = FacePresets.normalize(value)
	if not head or visible_face == id: return
	if not face_root:
		face_root = FaceSurface.new()
		head.add_child(face_root)
	face_root.set_face(id)
	visible_face = id

func _play_fingers(clip: String) -> void:
	for animator in animators:
		if not animator: continue
		for key in animator.get_animation_list():
			if str(key).get_slice("/",str(key).get_slice_count("/")-1) == clip:
				animator.play(key,.14)
				return_to_idle_loop(animator,key,clip)
				break

func return_to_idle_loop(animator: AnimationPlayer, key: String, clip: String) -> void:
	# Animation resources are shared; only these two authored cycles loop.
	animator.get_animation(key).loop_mode = Animation.LOOP_LINEAR if clip in ["idle","open"] else Animation.LOOP_NONE

func _cosmetics(info: Dictionary) -> void:
	if not head: return
	var dark = Color("242b28")
	var head_anchor = _accessory_anchor("HeadAccessoryAnchor")
	var eyes_anchor = _accessory_anchor("EyesAccessoryAnchor")
	var face_anchor = _accessory_anchor("FaceAccessoryAnchor")
	var head_id = _attach_model(head_anchor,info.get("equipped_head",""),"HEAD")
	match head_id:
		"cap":
			Forms.sphere(head_anchor,Vector3(0,.30,-.03),Vector3(.91,.42,.85),Color("897864"))
			Forms.sphere(head_anchor,Vector3(0,.24,.37),Vector3(.89,.07,.69),Color("706354"))
		"hardhat":
			Forms.sphere(head_anchor,Vector3(0,.28,0),Vector3(.98,.56,.93),Color("ffc32f"))
			Forms.cylinder(head_anchor,Vector3(0,.24,0),.51,.055,Color("f4ad19"))
			Forms.box(head_anchor,Vector3(0,.53,0),Vector3(.07,.08,.58),Color("ffd25f"))
		"wizard":
			Forms.cylinder(head_anchor,Vector3(0,.31,0),.60,.06,Color("3d348d"))
			Forms.cylinder(head_anchor,Vector3(0,.68,0),.40,.80,Color("5048a8"),.02)
			Forms.sphere(head_anchor,Vector3(.02,.91,.12),Vector3(.08,.1,.05),Color("ffeaa0"))

	var eye_id = _attach_model(eyes_anchor,info.get("equipped_eyes",""),"EYES")
	if eye_id == "round":
		eyes_anchor.add_child(preload("res://assets/characters/glasses_round.glb").instantiate())
	elif eye_id in ["3d","pixel"]:
		for side in [-1,1]:
			var pos = Vector3(side*.16,.07,.50)
			Forms.box(eyes_anchor,pos,Vector3(.28,.18,.055),dark if eye_id == "pixel" else Color("f4f0e8"))
			Forms.box(eyes_anchor,pos+Vector3(0,0,.035),Vector3(.21,.115,.018),Color("202a2a") if eye_id == "pixel" else (Color("ee657b") if side == -1 else Color("65cbe5")))
		Forms.rod(eyes_anchor,Vector3(-.06,.07,.50),Vector3(.06,.07,.50),.02,dark)
	var face_id = _attach_model(face_anchor,info.get("equipped_face",""),"FACE")
	match face_id:
		"hamster":
			for side in [-1,1]:
				Forms.sphere(face_anchor,Vector3(side*.18,-.16,.41),Vector3(.28,.23,.17),Color("f7d3a0"))
				Forms.sphere(face_anchor,Vector3(side*.29,.33,.13),Vector3(.22,.26,.10),Color("f7d3a0"))
			Forms.sphere(face_anchor,Vector3(0,-.1,.53),Vector3(.10,.07,.05),Color("df8e9b"))
		"incognito":
			Forms.sphere(face_anchor,Vector3(0,-.22,.31),Vector3(.67,.33,.39),dark)
			Forms.rod(face_anchor,Vector3(-.19,-.28,.50),Vector3(.19,-.28,.50),.012,Color("77847d"))

func _accessory_anchor(anchor_name: String) -> Node3D:
	var existing = head.get_node_or_null(anchor_name)
	if existing:
		for child in existing.get_children():
			existing.remove_child(child)
			child.queue_free()
		return existing
	var anchor = Node3D.new()
	anchor.name = anchor_name
	head.add_child(anchor)
	return anchor

func _attach_model(anchor: Node3D, id: String, slot: String) -> String:
	var definition = Content.cosmetic(id,slot)
	if definition.is_empty(): return ""
	if not definition.has("scene_path"): return id # Existing locally authored items.
	if not accessory_scenes.has(id): accessory_scenes[id] = load(definition.scene_path) as PackedScene
	if accessory_scenes[id] == null: return ""
	var model = accessory_scenes[id].instantiate()
	anchor.add_child(model)
	model.name = "EquippedModel"
	model.set_meta("accessory_id",id)
	model.position = _vector(definition.get("position_offset",[0,0,0]))
	model.rotation_degrees = _vector(definition.get("rotation_offset",[0,0,0]))
	model.scale = _vector(definition.get("scale",[1,1,1]))
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		for surface in mesh.mesh.get_surface_count():
			var source = mesh.mesh.surface_get_material(surface)
			if source is StandardMaterial3D:
				var key = id+source.resource_path+source.resource_name
				if not accessory_materials.has(key):
					var material = source.duplicate() as StandardMaterial3D
					material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
					material.roughness = .40 if slot == "EYES" else .72
					material.metallic = minf(material.metallic,.25)
					accessory_materials[key] = material
				mesh.set_surface_override_material(surface,accessory_materials[key])
	return ""

func _vector(value: Array) -> Vector3:
	return Vector3(value[0],value[1],value[2])

func apply_appearance(info: Dictionary) -> void:
	if info.is_empty(): return
	if info.get("head_color_id",0) != appearance.get("head_color_id",0):
		color = Content.color(int(info.get("head_color_id",0)))
		if head:
			for child in head.get_children():
				if child.name not in ["HeadAccessoryAnchor","EyesAccessoryAnchor","FaceAccessoryAnchor"]: _tint_skin(child)
		for hand in hands: _tint_skin(hand)
	base_face = FacePresets.normalize(info.get("face_id","normal"))
	if not pose in Emotes.IDS: _show_face(base_face)
	var cosmetics_changed = false
	for key in ["equipped_head","equipped_eyes","equipped_face"]:
		if info.get(key,"") != appearance.get(key,""): cosmetics_changed = true
	if cosmetics_changed: _cosmetics(info)
	appearance = info.duplicate(true)

func set_pose(value: String, sequence: int = -1) -> void:
	# Repeated network snapshots must not restart a one-shot animation.
	if sequence >= 0:
		if sequence <= gesture_sequence: return
		gesture_sequence = sequence
	elif value == pose: return
	if case_active:
		pending_pose = {"value":value}
		return
	_begin_pose(value)

func _begin_pose(value: String) -> void:
	pose = value
	pose_time = 0.0
	var clip = value
	if value in ["ready","thinking"]: clip = "thumbs_up" if value == "ready" else "open"
	_play_fingers(clip)
	var face_index = Emotes.IDS.find(value)
	_show_face(Emotes.FACE_IDS[face_index] if face_index >= 0 else base_face)

func open_case() -> void:
	case_active = true
	_begin_pose("case_open")

func set_head_look(pitch: float, yaw: float) -> void:
	head_look = Vector2(clampf(pitch,-.55,.5),clampf(yaw,-1.2,1.2))

func _process(delta: float) -> void:
	clock += delta
	pose_time += delta
	if head:
		head.position.y = sin(clock*1.5)*.025
		head.rotation.x = lerpf(head.rotation.x,head_look.x,minf(delta*12.0,1.0))
		head.rotation.y = lerp_angle(head.rotation.y,head_look.y,minf(delta*12.0,1.0))
	if pose_time >= Emotes.DURATION and pose not in ["idle","open","thinking"]:
		case_active = false
		_begin_pose(pending_pose.get("value","idle"))
		pending_pose.clear()
	_sample_hands(delta)

func _sample_hands(delta: float) -> void:
	var t = clampf(pose_time/Emotes.DURATION,0,1)
	var envelope = smoothstep(0.0,.18,t)*(1.0-smoothstep(.78,1.0,t))
	if pose in ["open","thinking"]: envelope = 1.0
	for i in hands.size():
		var side = -1 if i == 0 else 1
		var hand = hands[i]
		var rest = Vector3(side*.57,-.55,.22)
		var target = rest
		var rotation_target = Vector3(0,0,-side*.16)
		match pose:
			"wave":
				if side == 1:
					target = Vector3(.71,.03,.31)
					rotation_target.z = sin(t*TAU*3)*.38
			"ready", "thumbs_up":
				target = Vector3(side*.55,-.43,.44)
				rotation_target = Vector3(0,0,-side*1.2)
			"open", "shrug":
				target = Vector3(side*.70,-.35,.35)
				rotation_target = Vector3(-.20,side*.30,-side*.60)
			"thinking":
				target = Vector3(side*.28,-.65,.47)
				rotation_target = Vector3(.20,-side*.42,side*.64)
			"point":
				target = Vector3(side*.52,-.40,.58)
				rotation_target = Vector3(.18,-side*.30,side*1.05)
			"clap":
				var spread = .077 + (1.0+cos(t*TAU*4))*.14
				target = Vector3(side*spread,-.59,.61)
				rotation_target = Vector3(0,-side*PI*.5,0)
			"rock":
				target = Vector3(side*.63,-.24,.42)
				rotation_target = Vector3(0,0,-side*(.14+sin(t*TAU*2)*.13))
			"case_open":
				# Stay on the player's side of the imported case (front at z=.68).
				# The full finger envelope extends .35 beyond the wrist: a long
				# forward reach would enter the body and the animated lid.
				var lift = smoothstep(.20,.49,t)
				target = Vector3(side*lerpf(.62,.73,lift),lerpf(-.50,-.24,lift),lerpf(.29,.26,lift))
				rotation_target = Vector3(lerpf(.55,.10,lift),0,-side*.10)
		var desired = rest.lerp(target,envelope)
		desired.y += sin(clock*2+i)*.012*(1-envelope)
		var desired_rotation = Vector3(0,0,-side*.16).lerp(rotation_target,envelope)
		hand.position = desired if delta == 0 else hand.position.lerp(desired,minf(delta*18,1))
		hand.quaternion = Quaternion.from_euler(desired_rotation) if delta == 0 else hand.quaternion.slerp(Quaternion.from_euler(desired_rotation),minf(delta*18,1))
		# Conservatively enclose ALL skinned finger poses. Apply after blending,
		# so even interrupted gestures and the path between keys remain clear.
		var center = head.position if head else Vector3(0,sin(clock*1.5)*.025,0)
		var offset = hand.position-center
		var clearance = HEAD_RADIUS+HAND_RADIUS+.02
		if offset.length() < clearance:
			hand.position = center+offset.normalized()*clearance
