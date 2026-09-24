extends Button
var caption: Label
var glyph: TextureRect
var primary = false
var transition: Tween
var was_disabled = false

func configure(title: String, icon_name: String, accented: bool) -> void:
	text = title
	primary = accented
	custom_minimum_size.y = 62
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if primary:
		for state in ["normal","hover","pressed"]:
			var color = UI.GREEN if state == "normal" else (Color("83ff79") if state == "hover" else Color("39c94a"))
			add_theme_stylebox_override(state,UI.style(color,12,Color(0.7,1,0.65,0.65),16))
	if not icon_name.is_empty():
		custom_minimum_size.x = get_theme_font("font").get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,22).x + (90 if not title.is_empty() else 72)
		for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_disabled_color","font_hover_pressed_color"]:
			add_theme_color_override(state,Color.TRANSPARENT)
		var margin = MarginContainer.new()
		UI.full(margin)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_theme_constant_override("margin_left",22)
		margin.add_theme_constant_override("margin_right",22)
		add_child(margin)
		var row = UI.hbox(margin,18)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		glyph = UI.icon(row,icon_name,28)
		if title == "Назад": glyph.flip_h = true
		if not title.is_empty():
			caption = UI.label(row,title,22)
			caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
			caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_update_content()
	elif primary:
		for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
			add_theme_color_override(state,Color("112b17"))
	mouse_entered.connect(_animate.bind(true))
	mouse_exited.connect(_animate.bind(false))

func _process(_delta: float) -> void:
	if glyph and disabled != was_disabled: _update_content()

func _update_content() -> void:
	was_disabled = disabled
	var color = Color("747e77") if disabled else (Color("112b17") if primary else UI.INK)
	if caption: caption.add_theme_color_override("font_color",color)
	if glyph: glyph.material.set_shader_parameter("tint",color)

func _animate(over: bool) -> void:
	if transition: transition.kill()
	transition = create_tween()
	transition.tween_property(self,"self_modulate",Color(1.10,1.10,1.10) if over and not disabled else Color.WHITE,0.12)

func _make_custom_tooltip(for_text: String) -> Object:
	var panel = GlassPanel.new()
	panel.padding = 16
	panel.corner_radius = 14
	panel.background_opacity = .88
	panel.theme = UI.theme()
	var label = UI.label(panel,for_text,18,UI.INK,true)
	label.custom_minimum_size.x = 275
	return panel
