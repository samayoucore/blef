class_name LANDiscovery
extends Node
signal changed
const HOST_PORT = 42043
const BEACON_PORT = 42044
const MAGIC = "BLEF_LAN_V1"
var socket: PacketPeerUDP
var hosting = false
var searching = false
var advertised: Dictionary = {}
var found: Dictionary = {}
var elapsed = 0.0
var bind_error = ""

func host(info: Dictionary) -> void:
	stop()
	hosting = true
	advertised = info
	socket = PacketPeerUDP.new()
	var err = socket.bind(HOST_PORT)
	if err != OK:
		bind_error = "Не удалось открыть порт поиска лобби. Закройте другой экземпляр хоста и создайте лобби снова."
		socket.bind(0)
	socket.set_broadcast_enabled(true)
	elapsed = 1.0

func search() -> void:
	stop()
	searching = true
	socket = PacketPeerUDP.new()
	if socket.bind(BEACON_PORT) != OK:
		socket.bind(0)
	socket.set_broadcast_enabled(true)
	elapsed = 1.0
	changed.emit()

func stop() -> void:
	if socket:
		socket.close()
	socket = null
	hosting = false
	searching = false
	found.clear()
	bind_error = ""

func send(address: String, port: int, message: Dictionary) -> void:
	if not socket:
		return
	socket.set_dest_address(address, port)
	socket.put_packet(JSON.stringify(message).to_utf8_buffer())

func _process(delta: float) -> void:
	if not socket:
		return
	elapsed += delta
	if elapsed >= 1.0:
		elapsed = 0.0
		if hosting and not advertised.is_empty():
			var packet = advertised.duplicate()
			packet.magic = MAGIC
			send("255.255.255.255", BEACON_PORT, packet)
		elif searching:
			var query = {"magic":MAGIC, "query":true}
			send("255.255.255.255", HOST_PORT, query)
			send("127.0.0.1", HOST_PORT, query)
			for key in found.keys():
				if Time.get_ticks_msec() - int(found[key].seen) > 3500:
					found.erase(key)
					changed.emit()
	var budget = 64
	while socket.get_available_packet_count() > 0 and budget > 0:
		budget -= 1
		var bytes = socket.get_packet()
		var ip = socket.get_packet_ip()
		var port = socket.get_packet_port()
		if bytes.size() > 2048:
			continue
		var parser = JSON.new()
		if parser.parse(bytes.get_string_from_utf8()) != OK:
			continue
		var parsed = parser.data
		if not parsed is Dictionary or parsed.get("magic", "") != MAGIC:
			continue
		if hosting and parsed.get("query",false) and not advertised.is_empty():
			var packet = advertised.duplicate()
			packet.magic = MAGIC
			send(ip,port,packet)
		elif searching and not parsed.get("query",false):
			if not parsed.has_all(["name","host","count","max","version","port"]):
				continue
			if int(parsed.port) < 1 or int(parsed.port) > 65535:
				continue
			parsed.ip = ip
			parsed.seen = Time.get_ticks_msec()
			var key = str(parsed.get("id",ip + ":" + str(int(parsed.port))))
			if ip == "127.0.0.1" and found.has(key) and found[key].ip != "127.0.0.1":
				parsed.ip = found[key].ip
			found[key] = parsed
			changed.emit()
