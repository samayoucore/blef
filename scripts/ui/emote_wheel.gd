class_name EmoteWheel
extends Control
signal selected(pose: String)
signal closed
const ICONS = ["hello","like","point","shrug","sign","rock"]
var hovered = -1
var selected_caption: Label
var buttons: Array[Button] = []
var radius = 290.0
var center_box: VBoxContainer
var hint: Label
var cancel: Button

func _ready() -> void:
	UI.full(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	center_box = UI.vbox(self,12)
	center_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.icon(center_box,"happy-face",54,UI.GREEN)
	selected_caption = UI.label(center_box,"Выберите жест",20)
	selected_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for i in Emotes.IDS.size():
		var button = Button.new()
		button.name = "Gesture_" + Emotes.IDS[i]
		button.tooltip_text = Emotes.CAPTIONS[i]
		button.custom_minimum_size = Vector2(146,118)
		button.size = button.custom_minimum_size
		for state in ["normal","hover","pressed","focus"]:
			button.add_theme_stylebox_override(state,StyleBoxEmpty.new())
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		add_child(button)
		var box = UI.vbox(button,8)
		UI.full(box)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		UI.icon(box,ICONS[i],58)
		var caption = UI.label(box,Emotes.LABELS[i],17)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.pressed.connect(func(): choose(i))
		button.mouse_entered.connect(func(): _hover(i))
		button.focus_entered.connect(func(): _hover(i))
		buttons.append(button)
	hint = UI.label(self,"Мышь или 1–6 — выбрать жест",17,UI.MUTED)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cancel = UI.button(self,"Отмена · Esc",func(): closed.emit())
	cancel.custom_minimum_size = Vector2(200,50)
	resized.connect(_layout)
	_layout()
	modulate.a = 0
	create_tween().tween_property(self,"modulate:a",1.0,.15)

func _layout() -> void:
	radius = minf(300.0,size.y*.34)
	center_box.position = size*.5 - Vector2(128,62)
	center_box.size = Vector2(256,124)
	for i in buttons.size():
		var angle = -PI*.5+i*TAU/6.0
		buttons[i].position = size*.5+Vector2(cos(angle),sin(angle))*radius*.69-buttons[i].size*.5
	hint.position = Vector2(size.x*.5-260,size.y*.5+radius+20)
	hint.size.x = 520
	cancel.position = Vector2(size.x*.5-100,size.y*.5+radius+54)
	queue_redraw()

func _hover(index: int) -> void:
	hovered = index
	selected_caption.text = Emotes.LABELS[index]
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color(.015,.025,.020,.76))
	var center = size*.5
	draw_circle(center+Vector2(0,8),radius+8,Color(0,0,0,.26),true,-1,true)
	for i in 6:
		var start = -PI*.5 + i*TAU/6.0 - PI/6.0
		var points = PackedVector2Array()
		for step in 25:
			var angle = start + PI/3.0*step/24.0
			points.append(center+Vector2(cos(angle),sin(angle))*radius)
		for step in range(24,-1,-1):
			var angle = start + PI/3.0*step/24.0
			points.append(center+Vector2(cos(angle),sin(angle))*radius*.39)
		draw_colored_polygon(points,Color(.14,.30,.15,.96) if i == hovered else Color(.12,.15,.13,.94))
		draw_line(center+Vector2(cos(start),sin(start))*radius*.39,center+Vector2(cos(start),sin(start))*radius,Color(.6,.7,.62,.30),1.2,true)
	draw_circle(center,radius*.39,Color("19251d"),true,-1,true)
	draw_arc(center,radius*.39,0,TAU,96,Color(.5,.8,.5,.6),2,true)
	draw_arc(center,radius,0,TAU,128,UI.GREEN,3,true)
	if hovered >= 0:
		var angle = -PI*.5 + hovered*TAU/6.0
		draw_arc(center,radius,angle-PI/6.0,angle+PI/6.0,32,Color("b4ff9b"),5,true)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var relative = event.position-size*.5
		if relative.length() > radius*.39 and relative.length() < radius:
			_hover(posmod(int(floor((relative.angle()+PI*.5+PI/6.0)/(TAU/6.0))),6))
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var distance = (event.position-size*.5).length()
		if hovered >= 0 and distance > radius*.39 and distance < radius: choose(hovered)

func choose(index: int) -> void:
	if index in range(6): selected.emit(Emotes.IDS[index])
	closed.emit()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode in [KEY_T,KEY_ESCAPE] or event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			closed.emit()
		elif event.keycode >= KEY_1 and event.keycode <= KEY_6:
			get_viewport().set_input_as_handled()
			choose(event.keycode-KEY_1)
