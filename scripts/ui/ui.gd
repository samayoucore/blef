class_name UI
extends RefCounted
const INK = Color("edf3e8")
const MUTED = Color("a5b6a7")
const GREEN = Color("61f268")
const DARK = Color("202624")
const CARD_PREVIEW_SHADER = preload("res://scripts/ui/card_preview.gdshader")
const ICON_TINT_SHADER = preload("res://scripts/ui/icon_tint.gdshader")

static func style(color: Color, radius: int = 16, border: Color = Color.TRANSPARENT, padding: int = 18) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	s.border_color = border
	s.set_border_width_all(1 if border.a > 0 else 0)
	s.content_margin_left = padding
	s.content_margin_right = padding
	s.content_margin_top = padding
	s.content_margin_bottom = padding
	return s

static func theme() -> Theme:
	var t = Theme.new()
	t.default_font_size = 19
	t.set_color("font_color","Label",INK)
	t.set_color("font_color","Button",INK)
	t.set_color("font_hover_color","Button",Color.WHITE)
	t.set_color("font_disabled_color","Button",Color("657568"))
	t.set_color("font_focus_color","Button",GREEN)
	t.set_stylebox("normal","Button",style(Color(0.23,0.25,0.24,0.65),12,Color(0.65,0.70,0.66,0.3),14))
	t.set_stylebox("hover","Button",style(Color("3b5040"),12,GREEN,14))
	t.set_stylebox("pressed","Button",style(Color("294c30"),12,GREEN,14))
	t.set_stylebox("disabled","Button",style(Color("29312b"),12,Color("39433b"),14))
	t.set_stylebox("focus","Button",style(Color(0,0,0,0),12,GREEN,14))
	t.set_stylebox("normal","LineEdit",style(Color(0.08,0.10,0.09,0.7),10,Color("536057"),13))
	t.set_stylebox("focus","LineEdit",style(Color("16291d"),10,GREEN,13))
	t.set_color("font_color","LineEdit",INK)
	t.set_color("font_placeholder_color","LineEdit",MUTED)
	t.set_color("caret_color","LineEdit",GREEN)
	t.set_stylebox("panel","PanelContainer",style(DARK))
	t.set_constant("separation","VBoxContainer",12)
	t.set_constant("separation","HBoxContainer",12)
	t.set_stylebox("panel","PopupMenu",style(DARK,12,Color("637b60")))
	t.set_color("font_color","PopupMenu",INK)
	t.set_stylebox("panel","TooltipPanel",style(Color("202823"),12,Color("657268"),16))
	t.set_color("font_color","TooltipLabel",INK)
	t.set_font_size("font_size","TooltipLabel",18)
	for state in ["normal","hover","pressed","disabled","focus"]:
		t.set_stylebox(state,"OptionButton",t.get_stylebox(state,"Button"))
	t.set_color("font_color","OptionButton",INK)
	t.set_stylebox("slider","HSlider",style(Color("747e75"),5,Color.TRANSPARENT,4))
	t.set_stylebox("grabber_area","HSlider",style(GREEN,5,Color.TRANSPARENT,4))
	t.set_stylebox("grabber_area_highlight","HSlider",style(GREEN,5,Color.TRANSPARENT,4))
	t.set_stylebox("background","ProgressBar",style(Color("111a14"),8,Color.TRANSPARENT,6))
	t.set_stylebox("fill","ProgressBar",style(GREEN,8,Color.TRANSPARENT,6))
	return t

static func label(parent: Node, text: String, size: int = 19, color: Color = INK, wrap: bool = false) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size",size)
	l.add_theme_color_override("font_color",color)
	if size >= 26:
		var bold = SystemFont.new()
		bold.font_names = PackedStringArray(["Arial","Noto Sans"])
		bold.font_weight = 700
		l.add_theme_font_override("font",bold)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(l)
	return l

static func vbox(parent: Node, gap: int = 12) -> VBoxContainer:
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation",gap)
	parent.add_child(box)
	return box

static func hbox(parent: Node, gap: int = 12) -> HBoxContainer:
	var box = HBoxContainer.new()
	box.add_theme_constant_override("separation",gap)
	parent.add_child(box)
	return box

static func panel(parent: Node, color: Color = DARK, padding: int = 24) -> PanelContainer:
	var p = PanelContainer.new()
	p.add_theme_stylebox_override("panel",style(color,20,Color("3e5141"),padding))
	parent.add_child(p)
	return p

static func glass(parent: Node, padding: int = 24, radius: int = 22, opacity: float = .76) -> PanelContainer:
	var p = preload("res://scripts/ui/glass_panel.gd").new()
	p.padding = padding
	p.corner_radius = radius
	p.background_opacity = opacity
	parent.add_child(p)
	return p

static func background_image(parent: Node, path: String, shade: float = 0.0) -> TextureRect:
	var image = TextureRect.new()
	image.texture = load(path) as Texture2D
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(image)
	if shade > 0.0:
		var veil = ColorRect.new()
		veil.color = Color(0.01,0.03,0.02,shade)
		veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
		veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		parent.add_child(veil)
	return image

static func logo(parent: Node, width: int = 340) -> TextureRect:
	var image = TextureRect.new()
	image.name = "GameLogo"
	var source = load("res://assets/ui/logo.png") as Texture2D
	var atlas = AtlasTexture.new()
	atlas.atlas = source
	atlas.region = Rect2(290,50,1600,655)
	image.texture = atlas
	image.custom_minimum_size = Vector2(width, width * 0.36)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(image)
	return image

static func button(parent: Node, title: String, callback: Callable, primary: bool = false, icon_name: String = "") -> Button:
	var b = preload("res://scripts/ui/menu_button.gd").new()
	parent.add_child(b)
	b.configure(title,icon_name,primary)
	b.pressed.connect(func(): Sound.play())
	b.pressed.connect(callback)
	return b

static func spacer(parent: Node, stretch: bool = true, height: float = 0) -> Control:
	var s = Control.new()
	s.custom_minimum_size.y = height
	if stretch:
		s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(s)
	return s

static func line(parent: Node, text: String, placeholder: String = "") -> LineEdit:
	var input = LineEdit.new()
	input.text = text
	input.placeholder_text = placeholder
	input.custom_minimum_size.y = 52
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(input)
	return input

static func scroll(parent: Node) -> VBoxContainer:
	var sc = ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(sc)
	var box = vbox(sc)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return box

static func clear(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

static func full(control: Control) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

static func icon(parent: Node, name: String, size: int = 28, tint: Color = Color.WHITE, tooltip: String = "") -> TextureRect:
	var texture_path = "res://assets/ui/icons/%s.png" % name
	if not ResourceLoader.exists(texture_path):
		return null
	var image = TextureRect.new()
	image.name = "Icon_%s" % name
	image.texture = load(texture_path) as Texture2D
	image.custom_minimum_size = Vector2(size, size)
	image.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	image.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not tooltip.is_empty():
		image.tooltip_text = tooltip
	var material = ShaderMaterial.new()
	material.shader = ICON_TINT_SHADER
	material.set_shader_parameter("tint", tint)
	image.material = material
	parent.add_child(image)
	return image

static func card(parent: Node, data: Dictionary, show_property: bool = true, size: int = 22) -> void:
	_add_card_preview(parent, data)
	label(parent,str(data.get("rarity","" )).to_upper(),13,Color(Content.RARITY_COLORS.get(data.get("rarity",""),"#b9c6bc")))
	label(parent,str(data.get("name","???")),size,INK,true)
	label(parent,"«%s»" % str(data.get("description","")),16,MUTED,true)
	label(parent,"Базовая стоимость  ·  " + Content.number(data.get("base_value",0)),17,GREEN)
	if show_property:
		var prop = data.get("property",{})
		if prop.is_empty():
			label(parent,"Без случайного свойства",14,MUTED)
		else:
			label(parent,prop.name,17,Color("d7ca96"),true)
			label(parent,prop.description,14,MUTED,true)

static func _add_card_preview(parent: Node, data: Dictionary) -> void:
	var path = str(data.get("card_texture_path", ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	var texture = load(path) as Texture2D
	if texture == null:
		return
	var preview = TextureRect.new()
	preview.name = "CardPreview"
	preview.texture = texture
	preview.custom_minimum_size = Vector2(168, 210)
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var material = ShaderMaterial.new()
	material.shader = CARD_PREVIEW_SHADER
	preview.material = material
	parent.add_child(preview)
