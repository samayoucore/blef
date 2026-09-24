extends PanelContainer
var card: Dictionary
var unlocked = false
var art: TextureRect
var details: PanelContainer
var animation: Tween

func setup(data: Dictionary, owned: bool) -> void:
	card = data
	unlocked = owned
	name = "Card_"+str(card.id)
	custom_minimum_size = Vector2(190,270)
	add_theme_stylebox_override("panel",UI.style(Color.TRANSPARENT,16,Color.TRANSPARENT,0))
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	art = TextureRect.new()
	art.texture = load(card.card_texture_path if unlocked else "res://assets/cards/back/locked_card.png")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if unlocked:
		var material = ShaderMaterial.new()
		material.shader = UI.CARD_PREVIEW_SHADER
		art.material = material
	add_child(art)
	details = PanelContainer.new()
	var rarity_color = Color(Content.RARITY_COLORS.get(card.rarity,"#b9c6bc")) if unlocked else UI.GREEN
	details.add_theme_stylebox_override("panel",UI.style(Color("17221c"),16,rarity_color,14))
	details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(details)
	var box = UI.vbox(details,8)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if unlocked:
		UI.label(box,card.name,20,UI.INK,true)
		UI.label(box,card.description,16,UI.MUTED,true)
		UI.spacer(box)
		UI.label(box,card.rarity,17,rarity_color,true)
		UI.label(box,"Стоимость: "+Content.number(card.base_value),17,UI.INK,true)
	else:
		UI.label(box,"Карточка не открыта",20,UI.INK,true)
		UI.label(box,"Завершите матч с этим предметом в своём кейсе, чтобы добавить его в коллекцию.",17,UI.MUTED,true)
	_set_mouse_ignored(details)
	details.modulate.a = 0
	mouse_entered.connect(func(): show_info(true))
	mouse_exited.connect(func(): show_info(false))
	focus_entered.connect(func(): show_info(true))
	focus_exited.connect(func(): show_info(false))

func _set_mouse_ignored(node: Node) -> void:
	if node is Control: node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children(): _set_mouse_ignored(child)

func show_info(value: bool) -> void:
	if animation: animation.kill()
	animation = create_tween().set_parallel()
	animation.tween_property(details,"modulate:a",1.0 if value else 0.0,.15)
	animation.tween_property(art,"modulate:a",0.0 if value else 1.0,.15)
