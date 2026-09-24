extends Node
signal changed
signal graphics_changed
signal save_failed(message: String)
var data: Dictionary = {}
var settings: Dictionary = {"volume":0.6, "fullscreen":false, "resolution":0, "sensitivity":1.0, "graphics":1}
var directory = "user://"
var last_rewards: Array = []

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--profile="):
			var suffix = arg.trim_prefix("--profile=").validate_filename()
			directory = "user://tests/" + suffix + "/"
	DirAccess.make_dir_recursive_absolute(directory)
	data = fresh()
	var loaded = load_file("profile.json")
	if loaded.is_empty():
		loaded = load_file("profile.backup.json")
	data.merge(loaded, true)
	settings.merge(load_file("settings.json"), true)
	data.nickname = str(data.nickname).strip_edges().left(20)
	if data.nickname.is_empty():
		data.nickname = "Игрок"
	validate_appearance()
	data.unlocked_cosmetics = data.unlocked_cosmetics.filter(func(id): return not Content.lookup(Content.cosmetics,id).is_empty())
	unlock()
	save()
	apply_settings()

func fresh() -> Dictionary:
	var bytes = Crypto.new().generate_random_bytes(16)
	bytes[6] = (bytes[6] & 15) | 64
	bytes[8] = (bytes[8] & 63) | 128
	var id = bytes.hex_encode()
	return {"player_id":"%s-%s-%s-%s-%s" % [id.substr(0,8),id.substr(8,4),id.substr(12,4),id.substr(16,4),id.substr(20,12)], "nickname":"Игрок", "rating":0, "matches_played":0, "wins":0, "collection":[], "item_receive_counts":{}, "head_color_id":0, "face_id":"normal", "unlocked_cosmetics":[], "equipped_head":"", "equipped_eyes":"", "equipped_face":"", "statistics":{"best_score":0, "best_item":"", "worst":-1, "average":0.0}, "applied_matches":[]}

func load_file(file: String) -> Dictionary:
	if not FileAccess.file_exists(directory + file):
		return {}
	var parser = JSON.new()
	if parser.parse(FileAccess.get_file_as_string(directory + file)) != OK:
		return {}
	return parser.data if parser.data is Dictionary else {}

func write_file(file: String, value: Dictionary) -> bool:
	var temp = directory + file + ".tmp"
	var handle = FileAccess.open(temp, FileAccess.WRITE)
	if handle == null:
		save_failed.emit("Не удалось сохранить профиль. Проверьте доступ к папке данных.")
		return false
	handle.store_string(JSON.stringify(value, "\t"))
	handle.flush()
	handle.close()
	var target = directory + file
	if FileAccess.file_exists(target) and file == "profile.json":
		DirAccess.copy_absolute(target, directory + "profile.backup.json")
	var err = DirAccess.rename_absolute(temp, target)
	if err != OK:
		save_failed.emit("Ошибка сохранения данных. Код: " + str(err))
	return err == OK

func save() -> bool:
	data.face_id = FacePresets.normalize(data.get("face_id","normal"))
	validate_appearance()
	return write_file("profile.json", data)

func validate_appearance() -> void:
	for slot in ["head","eyes","face"]:
		var key = "equipped_"+slot
		var cosmetic = Content.cosmetic(str(data.get(key,"")),slot.to_upper())
		if cosmetic.is_empty() or int(cosmetic.unlock_points) > int(data.rating): data[key] = ""

func unlock() -> void:
	for cosmetic in Content.cosmetics:
		if data.rating >= cosmetic.unlock_points and not cosmetic.id in data.unlocked_cosmetics:
			data.unlocked_cosmetics.append(cosmetic.id)
			last_rewards.append(cosmetic.name)

func apply_delta(delta: Dictionary) -> bool:
	if str(delta.get("match_id", "")).is_empty() or delta.match_id in data.applied_matches:
		return false
	if Content.item(str(delta.get("item_id", ""))).is_empty() or int(delta.get("score", -1)) < 0:
		return false
	last_rewards.clear()
	data.applied_matches.append(delta.match_id)
	data.rating += int(delta.score)
	data.matches_played += 1
	data.wins += int(bool(delta.win))
	var item_id = str(delta.item_id)
	if not item_id in data.collection:
		data.collection.append(item_id)
	data.item_receive_counts[item_id] = int(data.item_receive_counts.get(item_id, 0)) + 1
	var stats = data.statistics
	if delta.score >= stats.best_score:
		stats.best_score = delta.score
		stats.best_item = item_id
	if stats.worst < 0 or delta.score < stats.worst:
		stats.worst = delta.score
	stats.average = float(data.rating) / data.matches_played
	unlock()
	var saved = save()
	changed.emit()
	return saved

func public_data() -> Dictionary:
	var result = {}
	for key in ["player_id", "nickname", "rating", "head_color_id", "face_id", "equipped_head", "equipped_eyes", "equipped_face"]:
		result[key] = data[key]
	result.face_id = FacePresets.normalize(result.face_id)
	return result

func join_data() -> Dictionary:
	var result = public_data()
	result.collection = data.collection.duplicate()
	return result

func apply_settings() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(clampf(float(settings.volume), 0.001, 1.0)))
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if settings.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	if not settings.fullscreen:
		var resolutions = [Vector2i(1280,800), Vector2i(1440,900), Vector2i(1920,1080)]
		DisplayServer.window_set_size(resolutions[clampi(int(settings.resolution),0,2)])
