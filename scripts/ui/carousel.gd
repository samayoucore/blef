extends HBoxContainer
var track: ScrollContainer
var items: HBoxContainer
var previous: Button
var next: Button
var motion: Tween

func _init() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",10)

func _ready() -> void:
	previous = _arrow(true)
	track = ScrollContainer.new()
	track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	track.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	track.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	track.follow_focus = true
	add_child(track)
	items = UI.hbox(track,10)
	next = _arrow(false)
	track.get_h_scroll_bar().changed.connect(_update_arrows)
	track.get_h_scroll_bar().value_changed.connect(func(_v): _update_arrows())
	track.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			_scroll(-1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1)
			track.accept_event()
	)

func _arrow(left: bool) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(38,48)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.tooltip_text = "Предыдущие" if left else "Следующие"
	add_child(button)
	var glyph = UI.icon(button,"right-arrow",18)
	glyph.flip_h = left
	glyph.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	glyph.offset_left = -9
	glyph.offset_top = -9
	glyph.offset_right = 9
	glyph.offset_bottom = 9
	button.pressed.connect(func(): _scroll(-1 if left else 1))
	return button

func _scroll(direction: int) -> void:
	if motion: motion.kill()
	motion = create_tween()
	var bar = track.get_h_scroll_bar()
	var target = clampf(track.scroll_horizontal + direction * maxf(track.size.x*.75,100),0,bar.max_value-bar.page)
	motion.tween_property(track,"scroll_horizontal",int(target),.16)

func _update_arrows() -> void:
	if not next: return
	var bar = track.get_h_scroll_bar()
	previous.disabled = bar.value <= 0
	next.disabled = bar.value >= bar.max_value-bar.page-1
