extends Control
var app: Node
var active_modal: Control
var public_note_rows: Array = []
const PHASE_NAMES = {"LOAD_SCENE":"Загрузка переговорной", "SEATING":"Занимаем места", "DEAL":"Раздаём кейсы", "DISCUSSION":"Обсуждение", "DISCUSSION_READY":"Все готовы", "TURN":"Ход", "REVEAL":"Вскрытие", "RETURN_TO_LOBBY":"Возвращаемся в лобби"}

func build(owner_app: Node) -> void:
	app = owner_app
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var snapshot = Net.public_state
	var personal = Net.private_state
	var phase = Net.state
	if phase == "TURN":
		var active_id = int(snapshot.get("active_peer",0))
		var turn_panel = UI.glass(self,14,18,.86)
		turn_panel.name = "TurnIndicator"
		turn_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		turn_panel.anchor_left = .5
		turn_panel.anchor_right = .5
		turn_panel.anchor_top = .5
		turn_panel.anchor_bottom = .5
		turn_panel.custom_minimum_size = Vector2(340,72)
		turn_panel.offset_left = -170
		turn_panel.offset_right = 170
		turn_panel.offset_top = -36
		turn_panel.offset_bottom = 36
		var turn_text = "ваш ход" if active_id == Net.my_id() else "ходит " + str(Net.players.get(active_id,{}).get("nickname","игрок"))
		var turn_label = UI.label(turn_panel,turn_text,28,UI.GREEN if active_id == Net.my_id() else UI.INK)
		turn_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		turn_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		turn_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var phase_panel = UI.glass(self,18,18)
	phase_panel.name = "PhaseInfo"
	phase_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	phase_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	phase_panel.offset_left = -430
	phase_panel.offset_right = -24
	phase_panel.offset_top = -146
	phase_panel.offset_bottom = -24
	var phase_row = UI.hbox(phase_panel,16)
	UI.icon(phase_row,"message",46)
	var phase_box = UI.vbox(phase_row,6)
	phase_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UI.label(phase_box,"Фаза обсуждения" if phase == "DISCUSSION" else PHASE_NAMES.get(phase,phase),24,UI.INK,true)
	if phase in ["DISCUSSION","DISCUSSION_READY","TURN"]:
		UI.label(phase_box,"Круг %d из %d" % [snapshot.get("round_number",1),snapshot.get("total_rounds",1)],15,UI.GREEN)
	var descriptions = {"DISCUSSION":"Убеждайте, задавайте вопросы, выясняйте, кто говорит правду!", "DISCUSSION_READY":"Все готовы. Сейчас начнутся ходы.", "TURN":"Решите: оставить свой кейс или обменяться.", "REVEAL":"Кейсы открываются. Узнаём, что внутри!"}
	var description = descriptions.get(phase,"Подготавливаем следующий этап игры…")
	UI.label(phase_box,description,17,UI.MUTED,true)
	var actions = UI.vbox(self,10)
	actions.name = "MatchActions"
	actions.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	actions.grow_vertical = Control.GROW_DIRECTION_BEGIN
	actions.offset_left = 24
	actions.offset_right = 464
	actions.offset_top = -100
	actions.offset_bottom = -24
	var row = UI.hbox(actions,12)
	if phase in ["DISCUSSION","DISCUSSION_READY"]:
		var ready = bool(snapshot.get("ready",{}).get(Net.my_id(),false))
		var ready_button = UI.button(row,"Снять готовность" if ready else "Я ГОТОВ",func(): Net.request("discussion_ready",{"value":not ready}),not ready)
		ready_button.custom_minimum_size = Vector2(248,76)
		ready_button.disabled = phase != "DISCUSSION"
	elif phase == "TURN" and int(snapshot.get("active_peer",0)) == Net.my_id():
		var keep = UI.button(row,"Оставить",func(): Net.request("keep"))
		keep.disabled = personal.get("forced",false)
		keep.tooltip_text = "Обмен обязателен" if keep.disabled else "Оставить свой кейс"
		UI.button(row,"Обменяться",func(): _targets(false),true)
	if phase in ["DISCUSSION","TURN"]:
		var emote = UI.button(row,"",app.toggle_emotes,false,"happy-face")
		emote.tooltip_text = "Эмоции [T]"
		emote.custom_minimum_size = Vector2(76,76)
	if phase == "DISCUSSION" and personal.get("can_peek",false): UI.button(actions,"Мильпупс: подсмотреть",func(): _targets(true))
	var toolbar = UI.vbox(self,8)
	toolbar.position = Vector2(24,24)
	var event = snapshot.get("event",{})
	if not event.is_empty() and phase not in ["LOAD_SCENE","SEATING"]:
		_small_button(toolbar,event.name,_event).tooltip_text = event.description
	if not personal.get("intel",[]).is_empty(): _small_button(toolbar,"Личные сведения (%d)" % personal.intel.size(),_intel)
	public_note_rows.clear()
	for case_id in snapshot.get("public_info",{}):
		var current = 0
		for id in snapshot.get("owners",{}):
			if snapshot.owners[id] == case_id: current = int(id)
		var facts = snapshot.public_info[case_id]
		var title = Net.players.get(current,{}).get("nickname","Игрок") + ": "
		if facts.has("name"): title += str(facts.name)
		if facts.has("base_value"): title += " База " + Content.number(facts.base_value)
		public_note_rows.append(title)
	if not public_note_rows.is_empty(): _small_button(toolbar,"Сведения (%d)" % public_note_rows.size(),func(): _public_notes(public_note_rows))
	if not snapshot.get("log",[]).is_empty(): _small_button(toolbar,"Ход игры",_journal)
	_small_button(toolbar,"Меню · Esc",_menu)

func _small_button(parent: Node, title: String, callback: Callable) -> Button:
	var button = UI.button(parent,title,callback)
	button.add_theme_font_size_override("font_size",14)
	button.custom_minimum_size.y = 36
	return button

func _menu() -> void:
	app.open_pause()

func _event() -> void:
	app.hud_dialog = "event"
	var event = Net.public_state.get("event",{})
	var list = _modal(event.get("name","Событие"))
	UI.label(list,event.get("description",""),20,UI.INK,true)

func _modal(title: String) -> VBoxContainer:
	if is_instance_valid(active_modal):
		remove_child(active_modal)
		active_modal.queue_free()
	if app.room: app.room.input_blocked = true
	var shade = ColorRect.new()
	active_modal = shade
	shade.color = Color(0,0,0,.56)
	add_child(shade)
	UI.full(shade)
	var margin = MarginContainer.new()
	shade.add_child(margin)
	UI.full(margin)
	margin.anchor_left = .24
	margin.anchor_right = .76
	margin.add_theme_constant_override("margin_top",90)
	margin.add_theme_constant_override("margin_bottom",80)
	var box = UI.vbox(UI.glass(margin),14)
	var header = UI.hbox(box)
	UI.label(header,title,27,UI.INK,true)
	UI.button(header,"Закрыть",func():
		app.hud_dialog = ""
		if app.room: app.room.input_blocked = false
		shade.queue_free()
	)
	return UI.scroll(box)

func _targets(peek: bool) -> void:
	app.hud_dialog = "peek" if peek else "targets"
	var list = _modal("Подсмотреть кейс" if peek else "С кем обменяться?")
	if peek: UI.label(list,"Информацию увидите только вы.",16,UI.MUTED,true)
	var targets = Net.private_state.get("targets",[])
	for id in Net.players:
		if int(id) == Net.my_id(): continue
		var p = Net.players[id]
		var allowed = peek or id in targets
		var button = UI.button(list,p.nickname + ("" if allowed else "  ·  Обратный обмен запрещён"),func():
			app.hud_dialog = ""
			Net.request("peek" if peek else "swap",{"target":int(id)})
		,allowed)
		button.disabled = not allowed

func _intel() -> void:
	app.hud_dialog = "intel"
	var list = _modal("Ваши личные сведения")
	UI.label(list,"Это сведения на момент проверки. После обменов кейс мог сменить владельца.",15,UI.MUTED,true)
	for info in Net.private_state.get("intel",[]):
		var box = UI.vbox(UI.panel(list,Color("2e3e30"),16),7)
		UI.label(box,info.source+" · "+Net.players.get(int(info.peer_id),{}).get("nickname",""),18,UI.GREEN)
		if info.has("card"):
			UI.card(box,info.card)
		else:
			UI.label(box,"Редкость: "+info.rarity,20)

func _public_notes(notes: Array) -> void:
	app.hud_dialog = "public"
	var list = _modal("Публичные сведения")
	for note in notes:
		UI.label(list,note,21,UI.INK,true)

func _leave_dialog() -> void:
	app.hud_dialog = "leave"
	var list = _modal("Выйти из матча?")
	UI.label(list,"Текущий матч будет отменён для всех. Ковришки за незавершённый матч не начисляются.",20,UI.INK,true)
	UI.button(list,"Выйти",func(): Net.leave(),true)

func _journal() -> void:
	app.hud_dialog = "journal"
	var list = _modal("Ход игры")
	for entry in Net.public_state.get("log",[]):
		UI.label(list,entry,20,UI.INK,true)

func restore_dialog() -> void:
	match app.hud_dialog:
		"peek": _targets(true)
		"targets": _targets(false)
		"intel": _intel()
		"journal": _journal()
		"menu": _menu()
		"event": _event()
		"leave": _leave_dialog()
		"public": _public_notes(public_note_rows)
