extends Node

const COLORS = ["#ffd34f", "#65d96b", "#71d4f2", "#437dff", "#ed565c", "#ff9948", "#f36bb6", "#a767ef", "#e8e8df", "#555b61"]
const COLOR_NAMES = ["Жёлтый", "Зелёный", "Голубой", "Синий", "Красный", "Оранжевый", "Розовый", "Фиолетовый", "Белый", "Графит"]
const RARITY_COLORS = {"Обычный":"#b9c6bc", "Редкий":"#80c7ff", "Эпический":"#ce9aff", "Легендарный":"#f7d273"}
var items: Array = []
var properties: Array = []
var events: Array = []
var cosmetics: Array = []
var rules: Dictionary = {}
var card_textures: Dictionary = {}

func _ready() -> void:
	items = read_json("res://data/items/catalog.json")
	card_textures = read_json("res://data/items/card_textures.json")
	for entry in items:
		entry.card_texture_path = str(card_textures.get(str(entry.id),""))
	properties = read_json("res://data/items/properties.json")
	events = read_json("res://data/events/events.json")
	cosmetics = read_json("res://data/cosmetics/catalog.json")
	rules = read_json("res://data/items/rules.json")
	assert(items.size() == 42 and properties.size() == 13 and events.size() == 5)

func read_json(path: String):
	return JSON.parse_string(FileAccess.get_file_as_string(path))

func item(id: String) -> Dictionary:
	return lookup(items, id)

func cosmetic(id: String, slot: String = "") -> Dictionary:
	var entry = lookup(cosmetics,id)
	if entry.is_empty() or (not slot.is_empty() and entry.slot != slot): return {}
	var path = str(entry.get("scene_path",""))
	if not path.is_empty() and not ResourceLoader.exists(path,"PackedScene"): return {}
	if not path.is_empty():
		for dependency in ResourceLoader.get_dependencies(path):
			var resource_path = str(dependency).split("::")[-1]
			if not ResourceLoader.exists(resource_path): return {}
	return entry

func property(id: String) -> Dictionary:
	return lookup(properties, id)

func lookup(list: Array, id: String) -> Dictionary:
	for entry in list:
		if str(entry.id) == id:
			return entry
	return {}

func color(id: int) -> Color:
	return Color(COLORS[clampi(id, 0, COLORS.size()-1)])

func number(value) -> String:
	var digits = str(int(value))
	var result = ""
	for i in digits.length():
		if i > 0 and (digits.length()-i) % 3 == 0:
			result += " "
		result += digits[i]
	return result
