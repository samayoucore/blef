class_name OfficeRoom
extends Node3D
const AvatarScript = preload("res://scripts/visual/avatar.gd")
const CaseScript = preload("res://gameplay/case/player_case.tscn")
var camera: Camera3D
var avatars: Dictionary = {}
var cases: Dictionary = {}
var positions: Dictionary = {}
var seating: Array = []
var own_avatar: BlefAvatar
var base_rotation = Vector3.ZERO
var look = Vector2.ZERO
var look_send_elapsed = 0.0
var last_sent_look = Vector2.INF
var camera_drag = false
var ready_to_ack = false
var last_turn = -1
var moving: Dictionary = {}
var opened_cases: Dictionary = {}
var input_blocked = false
var local_peer_id = 1
var case_presentations: Dictionary = {}
var interaction_hint: Label
var environment_room: OfficeEnvironment

func build(snapshot: Dictionary, local_id: int) -> void:
	local_peer_id = local_id
	environment_room = OfficeEnvironment.new()
	add_child(environment_room)
	environment_room.build()
	seating = snapshot.get("seats",[])
	for i in seating.size():
		var id = int(seating[i])
		var angle = TAU*i/seating.size()
		var radial = Vector3(sin(angle),0,cos(angle))
		environment_room.chair(radial*3.1,angle)
		positions[id] = radial*1.91 + Vector3(0,1.36,0)
		var case_id = snapshot.get("owners",{}).get(id,"")
		var briefcase = CaseScript.instantiate()
		briefcase.case_id = case_id
		briefcase.owner_id = id
		add_child(briefcase)
		briefcase.position = positions[id]
		briefcase.rotation.y = angle
		cases[case_id] = briefcase
		var info = snapshot.players[id]
		if id == local_id:
			camera = Camera3D.new()
			add_child(camera)
			camera.position = radial*3.45 + Vector3(0,2.22,0)
			camera.fov = 82
			camera.near = .04
			camera.look_at(Vector3(0,1.65,0))
			base_rotation = camera.rotation
			camera.current = true
			own_avatar = AvatarScript.new()
			add_child(own_avatar)
			own_avatar.position = radial*3.02 + Vector3(0,2.11,0)
			own_avatar.rotation.y = angle+PI
			own_avatar.build(info,true)
		else:
			var avatar = AvatarScript.new()
			add_child(avatar)
			avatar.position = radial*3.02 + Vector3(0,2.11,0)
			avatar.rotation.y = angle+PI
			avatar.build(info)
			avatars[id] = avatar
			var tag = Forms.label(avatar,info.nickname,Vector3(0,.73,0),29,Color("2d4939"))
			tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	ready_to_ack = true
	for id in Net.look_angles:
		var angles: Vector2 = Net.look_angles[id]
		set_remote_look(int(id),angles.x,angles.y)
	var hints = CanvasLayer.new()
	add_child(hints)
	interaction_hint = Label.new()
	hints.add_child(interaction_hint)
	interaction_hint.add_theme_font_size_override("font_size",20)
	interaction_hint.add_theme_color_override("font_color",Color("f3ffe8"))
	interaction_hint.add_theme_color_override("font_shadow_color",Color("122218"))
	interaction_hint.add_theme_constant_override("shadow_offset_x",2)
	interaction_hint.add_theme_constant_override("shadow_offset_y",2)
	interaction_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE

func sync_gestures(roster: Dictionary) -> void:
	for id in avatars:
		var player = roster.get(id,{})
		avatars[id].apply_appearance(player)
		avatars[id].set_pose(player.get("gesture","idle"),int(player.get("gesture_seq",-1)))
	if own_avatar:
		var player = roster.get(local_peer_id,{})
		own_avatar.apply_appearance(player)
		own_avatar.set_pose(player.get("gesture","idle"),int(player.get("gesture_seq",-1)))

func set_remote_look(id: int, pitch: float, yaw: float) -> void:
	if avatars.has(id): avatars[id].set_head_look(pitch,yaw)

func sync(snapshot: Dictionary, personal: Dictionary = {}) -> void:
	sync_gestures(snapshot.get("players",{}))
	for id in snapshot.get("owners",{}):
		var case_id = snapshot.owners[id]
		if not cases.has(case_id):
			continue
		var briefcase = cases[case_id]
		if briefcase.owner_id != int(id):
			briefcase.reset_for_transfer()
			briefcase.owner_id = int(id)
			var angle = TAU*seating.find(id)/seating.size()
			if moving.has(case_id) and moving[case_id].is_valid():
				moving[case_id].kill()
			var tween = create_tween().set_parallel()
			moving[case_id] = tween
			tween.tween_property(briefcase,"position",positions[id],.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(briefcase,"rotation:y",angle,.7)
	var revealed_cards = {}
	for result in snapshot.get("revealed",[]):
		var data = result.card.duplicate(true)
		data.score = result.score
		data.changes = result.get("changes",[])
		revealed_cards[result.case_id] = data
	for case_id in cases:
		var briefcase = cases[case_id]
		var lid = snapshot.get("case_lids",{}).get(case_id,{"state":"CLOSED","seq":0})
		var allowed_card = {}
		var is_public = revealed_cards.has(case_id)
		if is_public:
			allowed_card = revealed_cards[case_id]
		elif briefcase.owner_id == local_peer_id and personal.get("own",{}).get("case_id","") == case_id:
			allowed_card = personal.own
		briefcase.apply_lid(lid,allowed_card,is_public or bool(personal.get("first_open",false)),is_public)
		if lid.state == "OPENING" and int(case_presentations.get(case_id,-1)) != int(lid.seq):
			case_presentations[case_id] = lid.seq
			var actor = own_avatar if briefcase.owner_id == local_peer_id else avatars.get(briefcase.owner_id)
			if actor: actor.open_case()

func own_case() -> MoneyCase:
	return cases.get(Net.public_state.get("owners",{}).get(local_peer_id,""))

func case_action_text() -> String:
	if Net.state not in MatchRules.CASE_PHASES: return ""
	var briefcase = own_case()
	if not briefcase: return ""
	var lid = Net.public_state.get("case_lids",{}).get(briefcase.case_id,{})
	if lid.get("state","") not in ["CLOSED","OPEN"]:
		return ""
	return "E — закрыть" if lid.state == "OPEN" else "E — открыть"

func interact_own_case() -> void:
	if input_blocked or Net.state not in MatchRules.CASE_PHASES: return
	var briefcase = own_case()
	if not briefcase or briefcase.state in [MoneyCase.State.OPENING,MoneyCase.State.CLOSING]: return
	var lid = Net.public_state.get("case_lids",{}).get(briefcase.case_id,{})
	if lid.get("state","") not in ["CLOSED","OPEN"]: return
	Net.request("case_interact",{"case_id":briefcase.case_id,"seq":int(lid.seq)})

func _process(delta: float) -> void:
	look_send_elapsed += delta
	var current_look = Vector2(-look.y,-look.x)
	if Net.state in ["DISCUSSION","DISCUSSION_READY","TURN","REVEAL"] and look_send_elapsed >= .05 and current_look.distance_squared_to(last_sent_look) > .00001:
		Net.send_look(current_look.x,current_look.y)
		last_sent_look = current_look
		look_send_elapsed = 0.0
	if not interaction_hint or not camera: return
	var briefcase = own_case()
	interaction_hint.visible = false
	if not briefcase or input_blocked: return
	var text = case_action_text()
	if text.is_empty() or camera.is_position_behind(briefcase.global_position): return
	var screen_size = get_viewport().get_visible_rect().size
	var screen_pos = camera.unproject_position(briefcase.global_position)
	# The hint follows only our case, including while cases cross the table.
	if screen_pos.x < 80 or screen_pos.x > screen_size.x-80 or screen_pos.y < 140 or screen_pos.y > screen_size.y-35: return
	if absf(screen_pos.x-screen_size.x*.5) > screen_size.x*.28: return
	interaction_hint.text = text
	interaction_hint.size = Vector2(360,36)
	interaction_hint.position = screen_pos+Vector2(-180,35)
	interaction_hint.visible = true

func _unhandled_input(event: InputEvent) -> void:
	if input_blocked: return
	if event is InputEventKey and event.pressed and not event.echo and (event.physical_keycode == KEY_E or event.keycode == KEY_E):
		interact_own_case()
		get_viewport().set_input_as_handled()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		camera_drag = event.pressed
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if camera_drag else Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseMotion and camera_drag and camera:
		look += event.relative * .002 * float(Profile.settings.sensitivity)
		look.x = clampf(look.x,-1.20,1.20)
		look.y = clampf(look.y,-.50,.55)
		camera.rotation = base_rotation + Vector3(-look.y,-look.x,0)
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		camera_drag = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
