extends Node
const ProfileScreen = preload("res://scripts/ui/profile_screen.gd")
const HUDScreen = preload("res://scripts/ui/hud.gd")
var root: Control
var screen_root: Control
var toast: PanelContainer
var screen = "menu"
var room: OfficeRoom
var search_list: VBoxContainer
var search_signature = ""
var refresh_pending = false
var toast_timer: Timer
var last_net_state = "MAIN_MENU"
var profile_view: Control
var smoke
var hud_dialog = ""
var emote_wheel: EmoteWheel
var pause_open = false
var pause_overlay: Control
var match_notices: Control

func _ready() -> void:
	get_tree().auto_accept_quit = false
	var canvas = CanvasLayer.new()
	add_child(canvas)
	root = Control.new()
	canvas.add_child(root)
	UI.full(root)
	root.theme = UI.theme()
	toast_timer = Timer.new()
	toast_timer.one_shot = true
	add_child(toast_timer)
	toast_timer.timeout.connect(func():
		if is_instance_valid(toast): toast.queue_free()
	)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_root = Control.new()
	root.add_child(screen_root)
	UI.full(screen_root)
	screen_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	match_notices = preload("res://scripts/ui/match_notifications.gd").new()
	root.add_child(match_notices)
	UI.full(match_notices)
	Net.changed.connect(func(): match_notices.sync(Net.public_state,Net.state))
	Net.changed.connect(_schedule_refresh)
	Net.gestures_received.connect(func(_roster):
		if room: room.sync(Net.public_state,Net.private_state)
	)
	Net.look_received.connect(func(id, pitch, yaw):
		if room: room.set_remote_look(id,pitch,yaw)
	)
	Net.notice.connect(show_notice)
	Profile.save_failed.connect(show_notice)
	Net.discovery.changed.connect(_update_search)
	_open("menu")
	for arg in OS.get_cmdline_user_args():
		if arg == "--character-preview":
			_open.call_deferred("profile")
		if arg.begins_with("--smoke=") or arg.begins_with("--qa="):
			smoke = load("res://tests/smoke_agent.gd").new()
			add_child(smoke)
			smoke.setup(self,arg)
			break

func _schedule_refresh() -> void:
	if not refresh_pending:
		refresh_pending = true
		_refresh.call_deferred()

func _refresh() -> void:
	refresh_pending = false
	var state = Net.state
	if state != last_net_state:
		hud_dialog = ""
		close_emotes()
	if state == "MAIN_MENU":
		if last_net_state not in ["MAIN_MENU","CREATE_LOBBY","FIND_GAME"]:
			_open("menu")
	elif state in ["LOBBY","LOBBY_READY"]:
		_destroy_room()
		screen = "lobby"
		_lobby()
	elif state == "CONNECTING":
		_connecting()
	elif state not in ["CREATE_LOBBY","FIND_GAME"]:
		if not room and Net.public_state.has("seats"):
			room = OfficeRoom.new()
			add_child(room)
			room.build(Net.public_state,Net.my_id())
			_ack_load.call_deferred()
		if room:
			room.sync(Net.public_state,Net.private_state)
		if screen == "settings" and pause_open and state != "RESULTS":
			last_net_state = state
			return
		if state == "RESULTS": close_pause()
		screen = "match"
		UI.clear(screen_root)
		if state == "RESULTS":
			_results()
		else:
			var hud = HUDScreen.new()
			screen_root.add_child(hud)
			UI.full(hud)
			hud.build(self)
			hud.restore_dialog()
		if room: room.input_blocked = pause_open or not hud_dialog.is_empty() or is_instance_valid(emote_wheel)
		screen_root.visible = not pause_open and not is_instance_valid(emote_wheel)
		if pause_open: _pause_menu()
	last_net_state = state

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Net.leave()
		get_tree().quit()

func _ack_load() -> void:
	if Net.state == "LOAD_SCENE":
		Net.request("loaded")

func _destroy_room() -> void:
	close_pause()
	close_emotes()
	if room:
		remove_child(room)
		room.queue_free()
		room = null

func _open(page: String) -> void:
	screen = page
	_destroy_room()
	search_list = null
	Net.discovery.stop()
	match page:
		"menu":
			Net.local_state("MAIN_MENU")
			_main_menu()
		"create":
			Net.local_state("CREATE_LOBBY")
			_create()
		"find":
			Net.local_state("FIND_GAME")
			_find()
		"profile":
			_profile()
		"settings":
			_settings()

func background(path: String = "res://assets/ui/backgrounds/main_menu.png", shade: float = 0.12) -> void:
	UI.background_image(screen_root,path,shade)
	var capture = BackBufferCopy.new()
	capture.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	screen_root.add_child(capture)

func page(title: String, subtitle: String = "", back: bool = true) -> VBoxContainer:
	UI.clear(screen_root)
	background("res://assets/ui/backgrounds/settings_profile.png",0.03)
	var margin = MarginContainer.new()
	screen_root.add_child(margin)
	UI.full(margin)
	margin.anchor_left = 0.095
	margin.anchor_right = 0.905
	margin.anchor_top = 0.06
	margin.anchor_bottom = 0.93
	var outer = UI.vbox(margin,18)
	if back:
		var button = UI.button(outer,"Назад",_back_from_page,false,"right-arrow")
		button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		button.custom_minimum_size.y = 48
	UI.label(outer,title,48)
	if not subtitle.is_empty(): UI.label(outer,subtitle,16,UI.MUTED,true)
	return outer

func _back_from_page() -> void:
	if pause_open:
		screen = "match"
		_refresh()
	else: _open("menu")

func _main_menu() -> void:
	UI.clear(screen_root)
	background("res://assets/ui/backgrounds/main_menu.png",0.02)
	var left = UI.vbox(screen_root,22)
	left.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	left.anchor_left = 0.025
	left.anchor_right = 0.247
	left.anchor_top = 0.12
	left.anchor_bottom = 0.82
	UI.logo(left,0).custom_minimum_size.y = 130
	var menu_panel = UI.glass(left,18,22)
	var menu = UI.vbox(menu_panel,10)
	for entry in [["Создать лобби","create","multiple-users-silhouette"],["Найти лобби","find","search"],["Профиль","profile","user"],["Настройки","settings","settings"],["Выйти","quit","logout"]]:
		var destination = entry[1]
		var button = UI.button(menu,entry[0],func():
			if destination == "quit": get_tree().quit()
			else: _open(destination)
		,destination == "create",entry[2])
		button.custom_minimum_size.y = 70

func _create() -> void:
	var box = _left_page(0.34,0.12,0.88)
	UI.button(box,"Назад",func(): _open("menu"),false,"right-arrow").size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	UI.label(box,"Создать лобби",44)
	var name_box = UI.vbox(UI.glass(box,18,18),12)
	UI.label(name_box,"Название",22)
	var input = UI.line(name_box,"","Например, Вечерний Блеф")
	input.max_length = 24
	input.text = ("Лобби " + Profile.data.nickname).left(24)
	input.custom_minimum_size.y = 62
	var count_box = UI.vbox(UI.glass(box,18,18),12)
	UI.label(count_box,"Количество игроков",22)
	var maximum = OptionButton.new()
	maximum.name = "PlayerCount"
	maximum.custom_minimum_size.y = 64
	for count in range(3,9): maximum.add_item(str(count)+" игроков",count)
	maximum.select(3)
	count_box.add_child(maximum)
	UI.spacer(box)
	UI.button(box,"Создать лобби",func():
		var error = Net.create_lobby(input.text,maximum.get_selected_id())
		if not error.is_empty(): show_notice(error)
	,true,"play-button").custom_minimum_size.y = 86

func _left_page(width: float, top: float, bottom: float) -> VBoxContainer:
	UI.clear(screen_root)
	background("res://assets/ui/backgrounds/main_menu.png",0.02)
	var panel = UI.glass(screen_root,26,24)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.anchor_left = 0.025
	panel.anchor_right = 0.025 + width
	panel.anchor_top = top
	panel.anchor_bottom = bottom
	return UI.vbox(panel,20)

func _find() -> void:
	search_signature = ""
	var box = _left_page(0.44,0.12,0.88)
	var header = UI.hbox(box)
	UI.button(header,"Назад",func(): _open("menu"),false,"right-arrow")
	var gap = Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(gap)
	UI.button(header,"Обновить",func(): Net.discovery.search(),false,"search")
	UI.label(box,"Найти лобби",44)
	UI.label(box,"Лобби в локальной сети",19,UI.MUTED)
	var panel = UI.glass(box,16,18)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	search_list = UI.scroll(panel)
	Net.discovery.search()

func _update_search() -> void:
	if screen != "find" or not is_instance_valid(search_list):
		return
	var entries = Net.discovery.found.values().duplicate(true)
	entries.sort_custom(func(a,b): return str(a.name) < str(b.name))
	for entry in entries: entry.erase("seen")
	var signature = JSON.stringify(entries)+Net.discovery.bind_error
	if signature == search_signature: return
	search_signature = signature
	UI.clear(search_list)
	if Net.discovery.found.is_empty():
		UI.icon(search_list,"search",46,UI.MUTED)
		UI.label(search_list,"Ищем открытые лобби…",23,UI.INK,true)
		UI.label(search_list,"Созданные друзьями лобби появятся здесь. Подключитесь к одной локальной сети.",17,UI.MUTED,true)
		if not Net.discovery.bind_error.is_empty(): UI.label(search_list,Net.discovery.bind_error,17,UI.MUTED,true)
	for info in entries:
		var row = UI.hbox(UI.panel(search_list,Color(0.22,0.25,0.23,0.55),16),14)
		var desc = UI.vbox(row,4)
		desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UI.label(desc,str(info.name).left(24),24,UI.INK,true)
		UI.label(desc,"Хост: %s\nИгроков %d / %d" % [str(info.host).left(20),int(info.count),int(info.max)],16,UI.MUTED,true)
		var button = UI.button(row,"Подключиться",func(): _join(info.ip,int(info.port)),true)
		button.custom_minimum_size.x = 168
		button.disabled = int(info.version) != Net.PROTOCOL or int(info.count) >= int(info.max)
		if int(info.version) != Net.PROTOCOL: button.tooltip_text = "У хоста другая версия игры"
		elif int(info.count) >= int(info.max): button.tooltip_text = "В лобби нет свободных мест"

func _join(ip: String, port: int = Net.GAME_PORT) -> void:
	var error = Net.join_lobby(ip,port)
	if not error.is_empty():
		show_notice(error)

func _connecting() -> void:
	screen = "connecting"
	var box = _left_page(.44,.12,.88)
	UI.label(box,"Подключение",44)
	UI.label(box,"Устанавливаем соединение с хостом…",22,UI.INK,true)
	UI.label(box,"Если хост не ответит, игра вернёт вас в меню через 10 секунд.",18,UI.MUTED,true)
	UI.spacer(box)
	UI.button(box,"Отмена",func(): Net.leave())

func _lobby() -> void:
	var box = _left_page(0.41,0.06,0.93)
	var top = UI.hbox(box,18)
	UI.button(top,"Назад",func(): Net.leave(),false,"right-arrow").tooltip_text = "Выйти из лобби"
	var address = Net.local_addresses() if Net.is_host or not Net.peer else Net.peer.get_peer(1).get_remote_address()
	var ip = UI.label(top,"IP: "+address,16,UI.MUTED,true)
	ip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ip.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UI.label(box,Net.lobby_name,38,UI.INK,true)
	var list = UI.vbox(UI.glass(box,16,18),10)
	list.get_parent().size_flags_vertical = Control.SIZE_EXPAND_FILL
	UI.label(list,"Игроки   %d / %d" % [Net.players.size(),Net.max_players],22)
	var rows = UI.scroll(list)
	for id in Net.players:
		var player = Net.players[id]
		var row = UI.hbox(UI.panel(rows,Color(0.20,0.23,0.21,0.45),10),12)
		row.add_child(AvatarBadge.new(player,46))
		var description = UI.vbox(row,2)
		description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var name_row = UI.hbox(description,6)
		var title = UI.label(name_row,player.nickname + (" (Вы)" if int(id) == Net.my_id() else ""),20)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		if int(id) == 1: name_row.add_child(preload("res://scripts/ui/status_mark.gd").new(true))
		UI.label(description,Content.number(player.rating)+" ковришек",15,UI.MUTED)
		if player.ready: row.add_child(preload("res://scripts/ui/status_mark.gd").new())
		else: UI.label(row,"Не готов",14,UI.MUTED)
	for i in maxi(0,mini(Net.max_players,6)-Net.players.size()):
		var empty = UI.hbox(UI.panel(rows,Color(0.16,0.19,0.17,0.2),12))
		empty.custom_minimum_size.y = 54
		UI.label(empty,"Ожидание игрока…",17,UI.MUTED)
	var ready = bool(Net.players.get(Net.my_id(),{}).get("ready",false))
	var buttons = UI.hbox(box,12)
	UI.button(buttons,"Снять готовность" if ready else "Готов",func(): Net.request("lobby_ready",{"value":not ready}),not ready).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if Net.is_host:
		var start = UI.button(buttons,"Начать игру",func(): Net.request("start"),true,"play-button")
		start.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		start.disabled = Net.state != "LOBBY_READY"
		start.tooltip_text = "Минимум 3 игрока. Все должны быть готовы."
	if not Net.discovery.bind_error.is_empty(): UI.label(box,Net.discovery.bind_error,14,UI.MUTED,true)

func _profile() -> void:
	UI.clear(screen_root)
	background("res://assets/ui/backgrounds/settings_profile.png",0.03)
	var margin = MarginContainer.new()
	screen_root.add_child(margin)
	UI.full(margin)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,38)
	var outer = UI.vbox(margin,18)
	var header = UI.hbox(outer,24)
	UI.button(header,"Назад",func(): _open("menu"),false,"right-arrow")
	UI.label(header,"Профиль",48)
	profile_view = ProfileScreen.new()
	profile_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(profile_view)
	profile_view.build(self)

func _settings() -> void:
	var outer = page("Настройки")
	var panel = UI.glass(outer,26,24)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var box = UI.scroll(panel)
	box.add_theme_constant_override("separation",12)
	var volume_row = _setting_row(box,"Общая громкость")
	var volume = HSlider.new()
	volume.name = "Volume"
	volume.min_value = 0
	volume.max_value = 1
	volume.step = .01
	volume.value = Profile.settings.volume
	volume.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume.custom_minimum_size = Vector2(200,42)
	volume_row.add_child(volume)
	var volume_value = UI.label(volume_row,str(roundi(volume.value*100))+"%",20)
	volume_value.custom_minimum_size.x = 62
	volume.value_changed.connect(func(value):
		Profile.settings.volume = value
		AudioServer.set_bus_volume_db(0,linear_to_db(maxf(value,0.001)))
		volume_value.text = str(roundi(value*100))+"%"
	)
	var sensitivity_row = _setting_row(box,"Чувствительность мыши")
	var sensitivity = HSlider.new()
	sensitivity.name = "Sensitivity"
	sensitivity.min_value = .25
	sensitivity.max_value = 2.5
	sensitivity.step = .05
	sensitivity.value = Profile.settings.sensitivity
	sensitivity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sensitivity.custom_minimum_size = Vector2(200,42)
	sensitivity_row.add_child(sensitivity)
	var sensitivity_value = UI.label(sensitivity_row,"%.2f" % sensitivity.value,20)
	sensitivity_value.custom_minimum_size.x = 62
	sensitivity.value_changed.connect(func(value):
		Profile.settings.sensitivity = value
		sensitivity_value.text = "%.2f" % value
	)
	var fullscreen_row = _setting_row(box,"Полноэкранный режим")
	var fullscreen = CheckButton.new()
	fullscreen.name = "Fullscreen"
	fullscreen.text = "Включён" if Profile.settings.fullscreen else "Выключен"
	fullscreen.button_pressed = Profile.settings.fullscreen
	fullscreen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fullscreen.custom_minimum_size.y = 42
	fullscreen_row.add_child(fullscreen)
	fullscreen.toggled.connect(func(value):
		Profile.settings.fullscreen = value
		fullscreen.text = "Включён" if value else "Выключен"
		Profile.apply_settings()
	)
	var resolution_row = _setting_row(box,"Разрешение окна")
	var resolution = OptionButton.new()
	resolution.name = "Resolution"
	for title in ["1280 × 800","1440 × 900","1920 × 1080"]: resolution.add_item(title)
	resolution.selected = int(Profile.settings.resolution)
	resolution.custom_minimum_size.y = 46
	resolution.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resolution_row.add_child(resolution)
	resolution.item_selected.connect(func(index):
		Profile.settings.resolution = index
		Profile.apply_settings()
	)
	var help = UI.hbox(UI.glass(box,18,16),20)
	UI.icon(help,"game-controller",40,UI.MUTED)
	UI.label(help,"В матче: удерживайте правую кнопку мыши для обзора.\nОтпустите её для выбора кнопок.\nE — открыть / закрыть свой кейс.   T — колесо эмоций.   Esc — меню.",18,UI.MUTED,true)
	var save = UI.button(box,"Сохранить настройки",func():
		if Profile.write_file("settings.json",Profile.settings): show_notice("Настройки сохранены.")
	,true)
	save.custom_minimum_size.y = 68
	save.custom_minimum_size.x = 380
	save.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

func _setting_row(parent: Node, title: String) -> HBoxContainer:
	var row = UI.hbox(UI.glass(parent,12,16),24)
	var caption = UI.label(row,title,22)
	caption.custom_minimum_size.x = 360
	return row

func _results() -> void:
	var outer = page("Кейсы открыты", "Матч завершён. Ковришки и финальный предмет сохранены в вашем профиле.",false)
	var panel = UI.panel(outer)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var box = UI.vbox(panel,12)
	var results = Net.public_state.get("revealed",[]).duplicate()
	results.sort_custom(func(a,b): return int(a.score) > int(b.score))
	var winners = []
	for result in results:
		if result.win:
			winners.append(Net.players.get(int(result.peer_id),{}).get("nickname","Участник"))
	UI.label(box,("Победитель: " if winners.size() == 1 else "Ничья: ") + ", ".join(winners),28,UI.GREEN,true)
	var match_event = Net.public_state.get("event",{})
	if not match_event.is_empty():
		UI.label(box,"Событие: " + match_event.name + " · " + match_event.description,16,Color("e6d090"),true)
	var list = UI.scroll(box)
	for result in results:
		var row = UI.hbox(UI.panel(list,Color("2b382b"),16),20)
		var p = Net.players.get(int(result.peer_id),{"nickname":"Участник вышел"})
		row.add_child(AvatarBadge.new(p,56))
		var art = VBoxContainer.new()
		art.custom_minimum_size.x = 140
		row.add_child(art)
		UI._add_card_preview(art,result.card)
		if art.get_child_count() > 0:
			art.get_child(0).custom_minimum_size = Vector2(140,175)
		var description = UI.vbox(row,4)
		description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UI.label(description,p.nickname+ ("  ·  Вы" if int(result.peer_id) == Net.my_id() else ""),20,UI.GREEN if result.win else UI.INK)
		UI.label(description,result.card.name,21,UI.INK,true)
		UI.label(description,"%s  ·  База %s  ·  %s" % [result.card.rarity,Content.number(result.card.base_value),result.card.property.get("name","Без свойства")],15,UI.MUTED,true)
		UI.label(description,"«"+result.card.description+"»",14,UI.MUTED,true)
		if not result.card.property.is_empty():
			UI.label(description,result.card.property.description,14,UI.MUTED,true)
		UI.label(description," / ".join(result.changes) if not result.changes.is_empty() else "Без изменений стоимости",14,Color("d1ceab"),true)
		var score = UI.vbox(row,2)
		UI.label(score,"+"+Content.number(result.score),30,UI.GREEN)
		UI.label(score,"Итоговая стоимость",13,UI.MUTED)
		UI.label(score,"Ковришки: "+Content.number(p.get("rating",0)),14,UI.MUTED)
	if not Profile.last_rewards.is_empty():
		UI.label(box,"Новая косметика: " + ", ".join(Profile.last_rewards),18,UI.GREEN,true)
	var bottom = UI.hbox(box,18)
	var returned_count = Net.public_state.get("returned",{}).size()
	UI.label(bottom,"Готовы вернуться в лобби: %d/%d   ·   Коллекция %d/%d" % [returned_count,Net.players.size(),Profile.data.collection.size(),Content.items.size()],17,UI.MUTED).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var return_button = UI.button(bottom,"В ЛОББИ",func(): Net.request("return"),true)
	return_button.disabled = Net.public_state.get("returned",{}).get(Net.my_id(),false)
	UI.button(bottom,"Выйти",func(): Net.leave())

func show_notice(message: String) -> void:
	if is_instance_valid(toast):
		toast.queue_free()
	toast = UI.panel(root,Color("233e29"),16)
	toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	toast.offset_left = -400
	toast.offset_right = 400
	toast.offset_top = 10
	UI.label(toast,message,18,UI.INK,true)
	toast_timer.start(5)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		if screen == "settings": _back_from_page()
		elif pause_open: close_pause()
		elif room: open_pause()
		elif screen in ["lobby","connecting"]: Net.leave()
		elif screen != "menu": _open("menu")
		get_viewport().set_input_as_handled()
	elif event.physical_keycode == KEY_T or event.keycode == KEY_T:
		if not pause_open: toggle_emotes()
		get_viewport().set_input_as_handled()

func toggle_emotes() -> void:
	if is_instance_valid(emote_wheel):
		close_emotes()
		return
	var profile_preview = screen == "profile" and is_instance_valid(profile_view) and profile_view.tab == "character" and is_instance_valid(profile_view.portrait)
	if not profile_preview and (not room or Net.state not in ["DISCUSSION","TURN"]): return
	if room:
		room.input_blocked = true
		room.camera_drag = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	emote_wheel = EmoteWheel.new()
	root.add_child(emote_wheel)
	if room: screen_root.hide()
	if profile_preview:
		emote_wheel.selected.connect(func(value): profile_view.portrait.avatar.set_pose(value,Time.get_ticks_msec()))
	else:
		emote_wheel.selected.connect(func(value): Net.request("gesture",{"pose":value}))
	emote_wheel.closed.connect(close_emotes)

func close_emotes() -> void:
	if is_instance_valid(emote_wheel):
		emote_wheel.queue_free()
		emote_wheel = null
	if room:
		room.input_blocked = pause_open or not hud_dialog.is_empty()
		screen_root.visible = screen == "settings" or not pause_open

func open_pause() -> void:
	if not room: return
	close_emotes()
	hud_dialog = ""
	for hud in screen_root.get_children():
		if hud.get_script() == HUDScreen and is_instance_valid(hud.active_modal):
			hud.active_modal.queue_free()
			hud.active_modal = null
	pause_open = true
	room.input_blocked = true
	room.camera_drag = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	screen_root.hide()
	_pause_menu()

func close_pause() -> void:
	pause_open = false
	if is_instance_valid(pause_overlay):
		pause_overlay.queue_free()
		pause_overlay = null
	if room: room.input_blocked = not hud_dialog.is_empty()
	if screen_root: screen_root.show()

func _pause_menu() -> void:
	if is_instance_valid(pause_overlay): return
	pause_overlay = Control.new()
	root.add_child(pause_overlay)
	UI.full(pause_overlay)
	var shade = ColorRect.new()
	shade.color = Color(0.01,0.02,0.02,0.62)
	pause_overlay.add_child(shade)
	UI.full(shade)
	var capture = BackBufferCopy.new()
	capture.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	pause_overlay.add_child(capture)
	var center = CenterContainer.new()
	pause_overlay.add_child(center)
	UI.full(center)
	var panel = UI.glass(center,28,24)
	panel.custom_minimum_size = Vector2(390,455)
	var box = UI.vbox(panel,20)
	UI.logo(box,310).custom_minimum_size.y = 110
	UI.button(box,"Продолжить",close_pause,true,"play-button").custom_minimum_size.y = 68
	UI.button(box,"Настройки",func():
		pause_overlay.queue_free()
		pause_overlay = null
		screen = "settings"
		screen_root.show()
		_settings()
	,false,"settings").custom_minimum_size.y = 68
	UI.button(box,"Выйти в меню",func():
		close_pause()
		Net.leave()
	,false,"logout").custom_minimum_size.y = 68
