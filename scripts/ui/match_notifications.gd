extends Control
## The queue survives HUD rebuilds and presents each authoritative event once.
var match_id = ""
var last_id = 0
var modifier_shown = false
var pending: Array = []
var current: Control
var animation: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 20

func sync(snapshot: Dictionary, state: String) -> void:
	if state not in ["LOAD_SCENE","SEATING","DEAL","DISCUSSION","DISCUSSION_READY","TURN","REVEAL"]:
		_clear()
		match_id = ""
		return
	var incoming = str(snapshot.get("match_id",""))
	if incoming != match_id:
		_clear()
		match_id = incoming
	var modifier = snapshot.get("event",{})
	if not modifier_shown and state in ["DISCUSSION","DISCUSSION_READY","TURN"]:
		modifier_shown = true
		if not modifier.is_empty():
			pending.append({"title":"МОДИФИКАТОР МАТЧА", "message":modifier.get("name","") + "\n" + modifier.get("description",""), "duration":6.0})
	for event in snapshot.get("notifications",[]):
		if int(event.id) <= last_id: continue
		last_id = int(event.id)
		pending.append({"title":"ОБМЕН КЕЙСАМИ" if event.kind == "swap" else "РЕШЕНИЕ ИГРОКА", "message":event.message, "duration":3.4})
	if not is_instance_valid(current): _next()

func _clear() -> void:
	if animation and animation.is_valid(): animation.kill()
	if is_instance_valid(current):
		remove_child(current)
		current.queue_free()
	current = null
	pending.clear()
	last_id = 0
	modifier_shown = false

func _next() -> void:
	if pending.is_empty(): return
	var event = pending.pop_front()
	var center = CenterContainer.new()
	current = center
	center.name = "MatchNotification"
	add_child(center)
	UI.full(center)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel = UI.glass(center,22,26)
	panel.custom_minimum_size.x = minf(620,get_viewport_rect().size.x - 96)
	var box = UI.vbox(panel,10)
	var caption = UI.label(box,event.title,14,UI.GREEN)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var message = UI.label(box,event.message,24,UI.INK,true)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.custom_minimum_size.x = minf(560,get_viewport_rect().size.x - 148)
	_ignore_mouse(center)
	center.modulate.a = 0
	animation = create_tween()
	animation.tween_property(center,"modulate:a",1.0,.2)
	animation.tween_interval(float(event.duration))
	animation.tween_property(center,"modulate:a",0.0,.25)
	animation.tween_callback(func():
		remove_child(center)
		center.queue_free()
		current = null
		_next())

func _ignore_mouse(node: Node) -> void:
	if node is Control: node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children(): _ignore_mouse(child)
