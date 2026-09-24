class_name FacePresets
extends RefCounted
## One ordered catalogue for the world, profile, badges and wire IDs.
const IDS = ["normal", "wink", "serious", "joyful", "doubt", "surprised", "angry", "happy", "bored", "confident"]
const PRESETS = {
	"normal": {"display_name":"Обычный", "texture":preload("res://assets/character/faces/face_normal.png")},
	"wink": {"display_name":"Подмигивает", "texture":preload("res://assets/character/faces/face_wink.png")},
	"serious": {"display_name":"Серьёзный", "texture":preload("res://assets/character/faces/face_serious.png")},
	"joyful": {"display_name":"Радостный", "texture":preload("res://assets/character/faces/face_joyful.png")},
	"doubt": {"display_name":"Сомневается", "texture":preload("res://assets/character/faces/face_doubt.png")},
	"surprised": {"display_name":"Удивлённый", "texture":preload("res://assets/character/faces/face_surprised.png")},
	"angry": {"display_name":"Злой", "texture":preload("res://assets/character/faces/face_angry.png")},
	"happy": {"display_name":"Счастливый", "texture":preload("res://assets/character/faces/face_happy.png")},
	"bored": {"display_name":"Скучающий", "texture":preload("res://assets/character/faces/face_bored.png")},
	"confident": {"display_name":"Уверенный", "texture":preload("res://assets/character/faces/face_confident.png")},
}
# The numeric ordering used by versions <= 0.4. JSON numbers load as floats.
const LEGACY_IDS = ["normal", "joyful", "wink", "serious", "doubt", "angry", "confident", "bored", "surprised", "normal", "happy", "confident"]

static func normalize(value: Variant) -> String:
	if value is String and PRESETS.has(value): return value
	if value is int or value is float:
		if is_finite(float(value)) and float(value) == floor(float(value)) and value >= 0 and value < LEGACY_IDS.size():
			return LEGACY_IDS[int(value)]
	return "normal"

static func texture(value: Variant) -> Texture2D:
	return PRESETS[normalize(value)].texture

static func display_name(value: Variant) -> String:
	return PRESETS[normalize(value)].display_name
