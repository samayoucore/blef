extends VBoxContainer
const Carousel = preload("res://scripts/ui/carousel.gd")
const AccessoryPreview = preload("res://scripts/ui/accessory_preview.gd")
const CollectionTile = preload("res://scripts/ui/collection_tile.gd")
var app: Node
var draft: Dictionary
var portrait: Portrait
var body: VBoxContainer
var nickname: LineEdit
var tab = "character"
var tabs: HBoxContainer
var choices: Array[Button] = []
var grid: GridContainer
var grid_scroll: ScrollContainer

func build(owner_app: Node) -> void:
	app = owner_app
	draft = Profile.data.duplicate(true)
	draft.face_id = FacePresets.normalize(draft.get("face_id","normal"))
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",18)
	tabs = UI.hbox(UI.glass(self,5,18),6)
	body = UI.vbox(self,16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	Profile.changed.connect(_profile_changed)
	_tab("character")

func _tab(value: String) -> void:
	app.close_emotes()
	tab = value
	UI.clear(tabs)
	for entry in [["character","Кастомизация","shirt"],["collection","Коллекция","collection"],["stats","Статистика","bar-chart"]]:
		var target = entry[0]
		var button = UI.button(tabs,entry[1],func(): _tab(target),value == target,entry[2])
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_stretch_ratio = 1.0
	UI.clear(body)
	choices.clear()
	portrait = null
	nickname = null
	match value:
		"character": _character()
		"collection": _collection()
		"stats": _stats()

func _character() -> void:
	var columns = UI.hbox(body,24)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var left = UI.vbox(columns,8)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = .36
	portrait = Portrait.new()
	portrait.custom_minimum_size = Vector2(300,300)
	left.add_child(portrait)
	portrait.setup(draft)
	portrait.viewport.get_camera_3d().fov = 33
	var emote = UI.button(left,"Эмоции [T]",app.toggle_emotes,false,"happy-face")
	emote.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var panel = UI.glass(columns,22,22,.58)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = .64
	var box = UI.vbox(panel,14)
	var name_row = UI.hbox(box,18)
	UI.label(name_row,"Имя игрока",21)
	nickname = UI.line(name_row,draft.nickname)
	nickname.max_length = 20
	nickname.text_changed.connect(func(value): draft.nickname = value)
	var fields = UI.scroll(box)
	fields.add_theme_constant_override("separation",14)
	UI.label(fields,"Цвет",26)
	var colors = GridContainer.new()
	colors.columns = Content.COLORS.size()
	colors.add_theme_constant_override("h_separation",6)
	colors.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fields.add_child(colors)
	for i in Content.COLORS.size():
		var button = _choice(colors,"head_color_id",i,Content.COLOR_NAMES[i],Vector2(42,50))
		var swatch = Control.new()
		button.add_child(swatch)
		UI.full(swatch)
		swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		swatch.draw.connect(func():
			swatch.draw_circle(swatch.size*.5,20,Content.color(i),true,-1,true)
		)
	var faces = _carousel(fields,"Лицо")
	for id in FacePresets.IDS:
		var button = _choice(faces,"face_id",id,FacePresets.display_name(id),Vector2(72,72))
		button.set_meta("face_id",id)
		var badge = AvatarBadge.new(draft.merged({"face_id":id},true),56)
		button.add_child(badge)
		UI.full(badge)
	var accessories = _carousel(fields,"Аксессуары")
	var clear = _choice(accessories,"clear","","Без",Vector2(80,84))
	UI.label(clear,"Без",17,UI.MUTED).set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	for cosmetic in Content.cosmetics:
		var slot = "equipped_" + str(cosmetic.slot).to_lower()
		var unlocked = int(Profile.data.rating) >= int(cosmetic.unlock_points)
		var button = _choice(accessories,slot,cosmetic.id,cosmetic.name,Vector2(80,84))
		button.disabled = not unlocked
		button.set_meta("accessory_id",cosmetic.id)
		button.set_meta("unlock_points",cosmetic.unlock_points)
		var preview = AccessoryPreview.new()
		button.add_child(preview)
		UI.full(preview)
		preview.setup(cosmetic)
		if not unlocked:
			preview.modulate = Color(.4,.4,.4,.65)
			var lock = UI.icon(button,"padlock",28,Color.WHITE)
			lock.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
			lock.offset_left = -14
			lock.offset_top = -14
			lock.offset_right = 14
			lock.offset_bottom = 14
			button.tooltip_text = "Нужно %s ковришек,\nчтобы разблокировать" % Content.number(cosmetic.unlock_points)
	var footer = UI.hbox(box,16)
	UI.button(footer,"Сбросить",_reset).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UI.button(footer,"Сохранить",_save,true).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_update_selection()

func _carousel(parent: Node, title: String) -> HBoxContainer:
	UI.label(parent,title,26)
	var carousel = Carousel.new()
	parent.add_child(carousel)
	return carousel.items

func _choice(parent: Node, key: String, value: Variant, title: String, extent: Vector2) -> Button:
	var button = UI.button(parent,"",func():
		if key == "clear":
			for slot in ["equipped_head","equipped_eyes","equipped_face"]: draft[slot] = ""
		elif key.begins_with("equipped_"): _equip(key,str(value))
		else: draft[key] = value
		portrait.set_avatar(draft)
		_update_selection()
	)
	button.custom_minimum_size = extent
	button.tooltip_text = title
	button.set_meta("choice_key",key)
	button.set_meta("choice_value",value)
	choices.append(button)
	return button

func _update_selection() -> void:
	for button in choices:
		var key = str(button.get_meta("choice_key"))
		var active = draft.get(key) == button.get_meta("choice_value")
		if key == "clear": active = draft.equipped_head == "" and draft.equipped_eyes == "" and draft.equipped_face == ""
		var style = UI.style(Color(.18,.22,.19,.7),12,UI.GREEN if active else Color(.5,.6,.52,.3),6)
		style.set_border_width_all(3 if active else 1)
		button.add_theme_stylebox_override("normal",style)
		button.add_theme_stylebox_override("focus",UI.style(Color.TRANSPARENT,12,UI.GREEN,6))
		for child in button.get_children():
			if child is AvatarBadge:
				child.info.head_color_id = draft.head_color_id
				child.queue_redraw()

func _equip(slot: String, id: String) -> void:
	if id.is_empty(): return
	var cosmetic = Content.cosmetic(id,slot.trim_prefix("equipped_").to_upper())
	if not cosmetic.is_empty() and int(Profile.data.rating) >= int(cosmetic.unlock_points):
		for key in ["equipped_head","equipped_eyes","equipped_face"]: draft[key] = ""
		draft[slot] = id

func _reset() -> void:
	draft.nickname = Profile.data.nickname
	draft.head_color_id = 0
	draft.face_id = "normal"
	for key in ["equipped_head","equipped_eyes","equipped_face"]: draft[key] = ""
	nickname.text = draft.nickname
	portrait.set_avatar(draft)
	_update_selection()

func _save() -> void:
	if is_instance_valid(nickname): draft.nickname = nickname.text
	var name_value = str(draft.nickname).strip_edges()
	if name_value.is_empty():
		app.show_notice("Введите имя от 1 до 20 символов.")
		return
	Profile.data.nickname = name_value.left(20)
	for key in ["head_color_id","face_id","equipped_head","equipped_eyes","equipped_face"]: Profile.data[key] = draft[key]
	if Profile.save():
		if Net.peer: Net.request("appearance",Profile.public_data())
		app.show_notice("Профиль и внешность сохранены.")

func _collection() -> void:
	grid_scroll = ScrollContainer.new()
	grid_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	grid_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_scroll.follow_focus = true
	body.add_child(grid_scroll)
	grid = GridContainer.new()
	grid.add_theme_constant_override("h_separation",14)
	grid.add_theme_constant_override("v_separation",14)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_scroll.add_child(grid)
	for item in Content.items:
		var tile = CollectionTile.new()
		grid.add_child(tile)
		tile.setup(item,item.id in Profile.data.collection)
	grid_scroll.resized.connect(_resize_grid)
	_resize_grid.call_deferred()
	var progress = UI.hbox(UI.glass(body,14,18),24)
	UI.label(progress,"Собрано %d / %d" % [Profile.data.collection.size(),Content.items.size()],23)
	var bar = ProgressBar.new()
	bar.max_value = Content.items.size()
	bar.value = Profile.data.collection.size()
	bar.show_percentage = false
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.custom_minimum_size.y = 18
	progress.add_child(bar)

func _resize_grid() -> void:
	if not is_instance_valid(grid): return
	grid.columns = maxi(2,int((grid_scroll.size.x-14)/204))
	var width = floorf((grid_scroll.size.x-14-(grid.columns-1)*14)/grid.columns)
	for tile in grid.get_children(): tile.custom_minimum_size = Vector2(width,width*1.39)

func _stats() -> void:
	var center = CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(center)
	var row = UI.hbox(center,22)
	for entry in [["Ковришки",Profile.data.rating,"bar-chart"],["Сыграно матчей",Profile.data.matches_played,"game-controller"],["Побед",Profile.data.wins,"trophy"]]:
		var panel = UI.glass(row,32,22)
		panel.custom_minimum_size = Vector2(310,280)
		var box = UI.vbox(panel,22)
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		UI.icon(box,entry[2],62,UI.GREEN)
		UI.label(box,entry[0],23).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UI.label(box,Content.number(entry[1]),48).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _profile_changed() -> void:
	_tab(tab)
