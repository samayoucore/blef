extends Node
var notes: Dictionary = {}
var previous_state = ""
var previous_owners: Dictionary = {}
var revealed_count = 0

func _ready() -> void:
	notes.click = tone(640,.07,.09)
	notes.ready = tone(820,.16,.10)
	notes.swap = tone(310,.22,.12)
	notes.open = tone(1040,.28,.10)
	Net.changed.connect(_on_change)

func tone(hz: float, seconds: float, amplitude: float) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var data = PackedByteArray()
	var count = int(22050*seconds)
	data.resize(count*2)
	for i in count:
		var t = float(i)/22050
		var envelope = sin(PI*float(i)/count)*exp(-t*12)
		var sample = int(sin(TAU*hz*t)*envelope*amplitude*32767)
		data.encode_s16(i*2,sample)
	stream.data = data
	return stream

func play(key: String = "click") -> void:
	if DisplayServer.get_name() == "headless": return
	var player = AudioStreamPlayer.new()
	add_child(player)
	player.stream = notes.get(key,notes.click)
	player.finished.connect(player.queue_free)
	player.play()

func _on_change() -> void:
	if Net.state != previous_state and Net.state in ["TURN","DISCUSSION_READY","RESULTS"]:
		play("ready")
	var current = Net.public_state.get("owners",{})
	if not previous_owners.is_empty() and current != previous_owners and not current.is_empty():
		play("swap")
	var count = Net.public_state.get("revealed",[]).size()
	if count > revealed_count: play("open")
	previous_owners = current.duplicate()
	revealed_count = count
	previous_state = Net.state
