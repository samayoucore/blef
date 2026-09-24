class_name MoneyCase
extends Node3D
enum State { CLOSED, OPENING, OPEN, CLOSING }
var state = State.CLOSED
const OPEN_ANIMATION = "OpeningBaked"
const ANIMATION_DURATION = 1.32
var imported_model: Node3D
var animation_player: AnimationPlayer
var card_anchor: Node3D
var owner_id = 0
var case_id = ""
var card_node: ItemCard3D
var card_data: Dictionary = {}
var lid_sequence = -1
var motion: Tween
var card_motion: Tween
var first_reveals = 0
var repeat_reveals = 0
var public_card = false

func _ready() -> void:
	imported_model = get_node("ImportedCaseModel")
	card_anchor = get_node("CardAnchor")
	animation_player = imported_model.get_node("AnimationPlayer")
	animation_player.play(OPEN_ANIMATION)
	animation_player.pause()
	animation_player.seek(0,true)
	for instance in imported_model.find_children("*","MeshInstance3D",true,false):
		for surface in instance.mesh.get_surface_count():
			var original = instance.mesh.surface_get_material(surface)
			if original is StandardMaterial3D:
				var material = original.duplicate()
				material.metallic = .38
				material.roughness = .48
				instance.set_surface_override_material(surface,material)

func _sample_animation(time: float) -> void:
	animation_player.seek(time,true)

func open_case() -> void:
	apply_lid({"state":"OPENING","seq":lid_sequence+1},{},false)

func clear_card() -> void:
	if card_motion and card_motion.is_valid(): card_motion.kill()
	if is_instance_valid(card_node):
		card_node.get_parent().remove_child(card_node)
		card_node.queue_free()
	card_node = null
	card_data.clear()
	public_card = false

func reset_for_transfer() -> void:
	if motion and motion.is_valid(): motion.kill()
	clear_card()
	animation_player.pause()
	_sample_animation(0)
	state = State.CLOSED
	lid_sequence = -1

func apply_lid(lid: Dictionary, allowed_card: Dictionary, first: bool, is_public: bool = false) -> void:
	var sequence = int(lid.get("seq",0))
	if sequence < lid_sequence: return
	if allowed_card.is_empty():
		clear_card()
	else:
		card_data = allowed_card.duplicate(true)
		public_card = is_public
	var target = str(lid.get("state","CLOSED"))
	if sequence == lid_sequence:
		# OPEN is the server's acknowledgement of the same transition, not a
		# second command. Never restart the card tween on unrelated snapshots.
		if target == "CLOSED" and state == State.CLOSING:
			if motion and motion.is_valid(): motion.kill()
			animation_player.pause()
			_sample_animation(0)
			state = State.CLOSED
		elif target == "OPEN" and state == State.OPENING:
			animation_player.pause()
			_sample_animation(ANIMATION_DURATION)
			state = State.OPEN
		if (target == "OPEN" and state == State.OPEN or public_card and target in ["CLOSING","CLOSED"]) and not card_data.is_empty() and not card_node:
			_show_card(false)
		return
	lid_sequence = sequence
	if motion and motion.is_valid(): motion.kill()
	motion = create_tween()
	match target:
		"OPENING":
			state = State.OPENING
			animation_player.play(OPEN_ANIMATION)
			animation_player.seek(0,true)
			motion.tween_interval(1.0)
			motion.tween_callback(func(): _show_card(first))
			motion.tween_interval(.90)
			motion.tween_callback(func(): state = State.OPEN)
		"OPEN":
			state = State.OPEN
			animation_player.pause()
			_sample_animation(ANIMATION_DURATION)
			_show_card(false)
		_:
			state = State.CLOSING if target == "CLOSING" else State.CLOSED
			if public_card:
				_show_card(false)
			else:
				clear_card()
			if target == "CLOSING":
				animation_player.play_backwards(OPEN_ANIMATION)
				animation_player.seek(ANIMATION_DURATION,true)
				motion.tween_interval(ANIMATION_DURATION)
			else:
				animation_player.pause()
				_sample_animation(0)
			motion.tween_callback(func(): state = State.CLOSED)

func _show_card(first: bool) -> void:
	if card_data.is_empty() or is_instance_valid(card_node): return
	card_node = ItemCard3D.new()
	card_anchor.add_child(card_node)
	# Public reveal starts on the common BACK and flips to the item FRONT for
	# every peer. Private owner previews start directly on FRONT.
	card_node.build(card_data, public_card)
	var destination = Vector3(0,.66,.16)
	var angle = Vector3(deg_to_rad(-15),0,0)
	card_node.position = destination
	var viewer = get_viewport().get_camera_3d()
	if viewer:
		card_node.look_at(viewer.global_position,Vector3.UP,true)
		angle = card_node.rotation
	card_node.position = Vector3(0,.19,.02) if first else destination-Vector3(0,.06,0)
	card_node.rotation = Vector3(deg_to_rad(-80),0,deg_to_rad(-5)) if first else angle
	card_node.scale = Vector3.ONE * (.75 if first else .96)
	card_motion = create_tween().set_parallel()
	if first:
		first_reveals += 1
		card_motion.tween_property(card_node,"position",destination,.36).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		card_motion.tween_property(card_node,"rotation",angle,.36).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		card_motion.tween_property(card_node,"scale",Vector3.ONE*1.05,.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		card_motion.chain().tween_property(card_node,"scale",Vector3.ONE,.14)
	else:
		repeat_reveals += 1
		card_motion.tween_property(card_node,"position",destination,.16)
		card_motion.tween_property(card_node,"scale",Vector3.ONE,.16)
	if public_card:
		card_motion.chain().tween_callback(func():
			if is_instance_valid(card_node): card_node.reveal_front())
