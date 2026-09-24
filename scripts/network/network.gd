extends Node
signal changed
signal notice(message: String)
signal state_changed(state: String)
signal delta_received(delta: Dictionary)
signal gestures_received(roster: Dictionary)
const PROTOCOL = 4
const REVEAL_VIEW_SECONDS = 10.0
const GAME_PORT = 42042
const RuleScript = preload("res://scripts/game/match_rules.gd")
const DiscoveryScript = preload("res://scripts/network/discovery.gd")
var discovery: LANDiscovery
var peer: ENetMultiplayerPeer
var is_host = false
var state = "MAIN_MENU"
var lobby_name = ""
var lobby_id = ""
var max_players = 8
var players: Dictionary = {}
var public_state: Dictionary = {}
var private_state: Dictionary = {}
var rules: MatchRules
var loaded: Dictionary = {}
var returned: Dictionary = {}
var generation = 0
var revealed: Array = []
var rejected_count = 0
var _last_request: Dictionary = {}
var _pending_peers: Dictionary = {}
var _connect_elapsed = 0.0

func _ready() -> void:
	# Clients talk only to the host; no peer relay is needed for this game.
	multiplayer.server_relay = false
	discovery = DiscoveryScript.new()
	add_child(discovery)
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	multiplayer.connected_to_server.connect(_connected)
	multiplayer.connection_failed.connect(func(): leave("Не удалось подключиться. Проверьте IP и доступ к локальной сети."))
	multiplayer.server_disconnected.connect(func(): leave("Хост закрыл лобби или соединение потеряно."))

func my_id() -> int:
	return multiplayer.get_unique_id() if peer else 1

func local_state(value: String) -> void:
	if peer:
		return
	_set_state(value)

func _set_state(value: String) -> void:
	if state != value:
		state = value
		state_changed.emit(value)

func create_lobby(title: String, maximum: int) -> String:
	leave()
	lobby_name = title.strip_edges().left(24)
	if lobby_name.is_empty():
		return "Введите название лобби."
	max_players = clampi(maximum,3,8)
	lobby_id = Crypto.new().generate_random_bytes(12).hex_encode()
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(GAME_PORT, max_players-1)
	if err != OK:
		peer = null
		return "Не удалось создать лобби. Возможно, порт 42042 занят другой игрой."
	multiplayer.multiplayer_peer = peer
	is_host = true
	var p = sanitize_profile(Profile.join_data())
	p.peer_id = 1
	p.ready = false
	p.gesture = "idle"
	players[1] = p
	_set_state("LOBBY")
	discovery.host(advertisement())
	_broadcast()
	return ""

func advertisement() -> Dictionary:
	return {"id":lobby_id,"name":lobby_name,"host":players.get(1,{}).get("nickname","Игрок"),"count":players.size(),"max":max_players,"version":PROTOCOL,"port":GAME_PORT,"address":local_addresses()}

func local_addresses() -> String:
	var addresses = []
	for address in IP.get_local_addresses():
		if address.count(".") == 3 and not address.begins_with("127.") and not address.begins_with("169.254."):
			addresses.append(address)
	return ", ".join(addresses) if not addresses.is_empty() else "127.0.0.1"

func join_lobby(ip: String, port: int = GAME_PORT) -> String:
	leave()
	if not ip.strip_edges().is_valid_ip_address():
		return "Введите корректный IP-адрес, например 192.168.1.10."
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(ip.strip_edges(), port)
	if err != OK:
		peer = null
		return "Не удалось открыть сетевое соединение."
	multiplayer.multiplayer_peer = peer
	_connect_elapsed = 0
	_set_state("CONNECTING")
	changed.emit()
	return ""

func leave(message: String = "") -> void:
	generation += 1
	is_host = false
	discovery.stop()
	if peer:
		peer.close()
	peer = null
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	players.clear()
	public_state.clear()
	private_state.clear()
	loaded.clear()
	returned.clear()
	_pending_peers.clear()
	_last_request.clear()
	revealed.clear()
	rules = null
	_set_state("MAIN_MENU")
	changed.emit()
	if not message.is_empty():
		notice.emit(message)

func sanitize_profile(raw: Dictionary) -> Dictionary:
	var result = {"player_id":str(raw.get("player_id","")).left(64), "nickname":str(raw.get("nickname","Игрок")).strip_edges().replace("\n"," ").left(20), "rating":clampi(int(raw.get("rating",0)),0,2000000000), "head_color_id":clampi(int(raw.get("head_color_id",0)),0,9), "face_id":FacePresets.normalize(raw.get("face_id","normal")), "collection":[]}
	if result.nickname.is_empty():
		result.nickname = "Игрок"
	for slot in ["head","eyes","face"]:
		var id = str(raw.get("equipped_"+slot,""))
		var cosmetic = Content.cosmetic(id,slot.to_upper())
		result["equipped_"+slot] = id if cosmetic.get("slot","") == slot.to_upper() and int(cosmetic.get("unlock_points",0)) <= result.rating else ""
	if raw.get("collection",[]) is Array:
		for id in raw.get("collection",[]).slice(0,41):
			if not Content.item(str(id)).is_empty() and not str(id) in result.collection:
				result.collection.append(str(id))
	return result

func _peer_connected(id: int) -> void:
	if is_host:
		_pending_peers[id] = Time.get_ticks_msec()

func _connected() -> void:
	register_player.rpc_id(1, PROTOCOL, Profile.join_data())

@rpc("any_peer", "call_remote", "reliable")
func register_player(version: int, profile: Dictionary) -> void:
	if not is_host:
		return
	var sender = multiplayer.get_remote_sender_id()
	if players.has(sender):
		return
	if version != PROTOCOL or not state in ["LOBBY","LOBBY_READY"] or players.size() >= max_players or var_to_bytes(profile).size() > 8192:
		_reject_join(sender, "Лобби недоступно: матч начался, мест нет или версия игры отличается.")
		return
	var p = sanitize_profile(profile)
	for existing in players.values():
		if existing.player_id == p.player_id:
			_reject_join(sender, "Этот профиль уже находится в лобби. Для второго окна используйте отдельный тестовый профиль.")
			return
	p.peer_id = sender
	p.ready = false
	p.gesture = "idle"
	players[sender] = p
	_pending_peers.erase(sender)
	_set_state("LOBBY")
	_broadcast()

func _reject_join(id: int, message: String) -> void:
	join_rejected.rpc_id(id,message)
	var stamp = generation
	await get_tree().create_timer(0.4).timeout
	if peer and is_host and generation == stamp and id in multiplayer.get_peers():
		peer.disconnect_peer(id)

@rpc("authority", "call_remote", "reliable")
func join_rejected(message: String) -> void:
	leave(message)

func _peer_disconnected(id: int) -> void:
	if not is_host:
		return
	_pending_peers.erase(id)
	if not players.has(id):
		return
	var nickname = players[id].nickname
	players.erase(id)
	if not state in ["LOBBY","LOBBY_READY","RESULTS"]:
		generation += 1
		rules = null
		revealed.clear()
		for p in players.values():
			p.ready = false
		_set_state("LOBBY")
		_send_notice_all(nickname + " отключился. Матч отменён без начисления очков.")
		discovery.host(advertisement())
	elif state != "RESULTS":
		_update_lobby_ready()
	_broadcast()
	if state == "RESULTS":
		_check_return()

func request(action: String, payload: Dictionary = {}) -> void:
	var token = public_state.get("match_id", "")
	var turn = int(public_state.get("turn_revision",-1))
	if is_host:
		_handle(1,action,payload,token,turn)
	elif peer and state != "CONNECTING":
		request_action.rpc_id(1,action,payload,token,turn)

@rpc("any_peer", "call_remote", "reliable")
func request_action(action: String, payload: Dictionary, token: String, turn: int) -> void:
	if is_host:
		_handle(multiplayer.get_remote_sender_id(),action,payload,token,turn)

func _handle(sender: int, action: String, payload: Dictionary, token: String, turn: int) -> void:
	if not is_host or not players.has(sender) or var_to_bytes(payload).size() > 2048:
		return
	var request_key = str(sender)+":"+action
	var now = Time.get_ticks_msec()
	if now - int(_last_request.get(request_key,-1000)) < 70:
		return
	_last_request[request_key] = now
	var error = ""
	match action:
		"appearance":
			# Only appearance IDs/color/face change. Rating, identity, readiness,
			# collection and match progression stay under the host's control.
			var candidate = players[sender].duplicate(true)
			for key in ["head_color_id","face_id","equipped_head","equipped_eyes","equipped_face"]:
				if payload.has(key): candidate[key] = payload[key]
			var clean = sanitize_profile(candidate)
			for key in ["head_color_id","face_id","equipped_head","equipped_eyes","equipped_face"]:
				players[sender][key] = clean[key]
		"lobby_ready":
			if state in ["LOBBY","LOBBY_READY"]:
				players[sender].ready = bool(payload.get("value",false))
				_update_lobby_ready()
			else:
				error = "Готовность лобби сейчас недоступна."
		"start":
			if sender == 1 and state == "LOBBY_READY":
				_start_match()
				return
			else:
				error = "Начать матч может хост, когда готовы все участники (минимум трое)."
		"loaded":
			if state == "LOAD_SCENE" and rules and token == rules.match_id:
				loaded[sender] = true
				if loaded.size() == players.size():
					_finish_loading()
		"discussion_ready":
			if rules and token == rules.match_id and state == "DISCUSSION" and turn == rules.turn_revision():
				rules.mark_ready(sender,bool(payload.get("value",false)))
				players[sender].gesture = "ready" if bool(payload.get("value",false)) else "idle"
				players[sender].gesture_seq = int(players[sender].get("gesture_seq",0))+1
				if rules.phase == "DISCUSSION_READY":
					_start_turns()
					return
			else:
				error = "Обсуждение уже завершено."
		"keep", "swap":
			if rules and state == "TURN" and token == rules.match_id and turn == rules.turn_revision():
				error = rules.act(sender,action,int(payload.get("target",0)))
				if error.is_empty():
					var target = int(payload.get("target",0))
					var message = players[sender].nickname + (" оставил себе кейс" if action == "keep" else " поменялся с " + players[target].nickname)
					rules.log_lines.append(message)
					rules.notifications.append({"id":rules.notifications.size()+1,"kind":action,"message":message})
					while rules.skip_deadlock():
						pass
					if rules.phase == "REVEAL":
						_reveal()
						return
					if rules.phase == "DISCUSSION":
						_set_state("DISCUSSION")
						for p in players.values():
							p.gesture = "idle"
							p.gesture_seq = int(p.get("gesture_seq",0))+1
			else:
				error = "Этот ход уже завершён."
		"peek":
			if rules and token == rules.match_id and state == "DISCUSSION":
				error = rules.peek(sender,int(payload.get("target",0)))
			else:
				error = "Подсмотр сейчас недоступен."
		"case_interact":
			if rules and token == rules.match_id and state in MatchRules.CASE_PHASES:
				error = rules.interact_case(sender,str(payload.get("case_id","")),int(payload.get("seq",-1)))
			else:
				error = "Сейчас нельзя открывать личный кейс."
		"gesture":
			var pose = str(payload.get("pose","idle"))
			if rules and token == rules.match_id and state in ["DISCUSSION","TURN"] and pose in Emotes.IDS:
				players[sender].gesture = pose
				players[sender].gesture_seq = int(players[sender].get("gesture_seq",0))+1
		"return":
			if state == "RESULTS" and rules and token == rules.match_id:
				returned[sender] = true
				_check_return()
		_:
			error = "Неизвестный запрос."
	if not error.is_empty():
		rejected_count += 1
		_tell(sender,error)
	_broadcast()

func _update_lobby_ready() -> void:
	var all_ready = players.size() >= 3
	for p in players.values():
		all_ready = all_ready and p.ready
	_set_state("LOBBY_READY" if all_ready else "LOBBY")

func _start_match() -> void:
	generation += 1
	rules = RuleScript.new()
	rules.setup(players.values(),Content)
	loaded.clear()
	returned.clear()
	revealed.clear()
	discovery.stop()
	_set_state("LOAD_SCENE")
	_broadcast()

func _finish_loading() -> void:
	var stamp = generation
	_set_state("SEATING")
	_broadcast()
	await get_tree().create_timer(0.45).timeout
	if stamp != generation or not is_host:
		return
	_set_state("DEAL")
	_broadcast()
	await get_tree().create_timer(0.65).timeout
	if stamp != generation or not is_host:
		return
	rules.start_discussion()
	_set_state("DISCUSSION")
	_broadcast()

func _start_turns() -> void:
	var stamp = generation
	_set_state("DISCUSSION_READY")
	_broadcast()
	await get_tree().create_timer(0.6).timeout
	if stamp != generation or not is_host:
		return
	rules.begin_turns()
	_set_state("TURN")
	_broadcast()

func _reveal() -> void:
	var stamp = generation
	_set_state("REVEAL")
	_broadcast()
	for result in rules.results:
		await get_tree().create_timer(2.0).timeout
		if stamp != generation or not is_host:
			return
		revealed.append(result)
		rules.open_public_case(result.case_id)
		_broadcast()
	# Wait for the last FRONT to finish appearing, then leave every card on
	# display above its closed case before opening the results screen.
	await get_tree().create_timer(2.0).timeout
	if stamp != generation or not is_host: return
	rules.close_public_cases()
	_broadcast()
	await get_tree().create_timer(REVEAL_VIEW_SECONDS).timeout
	if stamp != generation or not is_host:
		return
	_set_state("RESULTS")
	for result in rules.results:
		var id = int(result.peer_id)
		var delta = {"match_id":rules.match_id,"score":result.score,"item_id":result.card.id,"win":result.win}
		delta.statistics_delta = {"matches_played":1,"wins":int(result.win),"result":result.score}
		delta.unlocked_cosmetics = []
		for cosmetic in Content.cosmetics:
			if players[id].rating < cosmetic.unlock_points and players[id].rating + int(result.score) >= cosmetic.unlock_points:
				delta.unlocked_cosmetics.append(cosmetic.id)
		players[id].rating += int(result.score)
		if not result.card.id in players[id].collection:
			players[id].collection.append(result.card.id)
		if id == 1:
			_accept_delta(delta)
		elif _can_send(id):
			receive_delta.rpc_id(id,delta)
	_broadcast()

func _check_return() -> void:
	for id in players:
		if not returned.get(id,false):
			return
	_return_lobby()

func _return_lobby() -> void:
	var stamp = generation
	_set_state("RETURN_TO_LOBBY")
	_broadcast()
	await get_tree().create_timer(0.25).timeout
	if stamp != generation or not is_host:
		return
	rules = null
	revealed.clear()
	returned.clear()
	for p in players.values():
		p.ready = false
		p.gesture = "idle"
	_set_state("LOBBY")
	discovery.host(advertisement())
	_broadcast()

func _broadcast() -> void:
	if not is_host:
		return
	var roster = {}
	for id in players:
		roster[id] = players[id].duplicate(true)
		roster[id].erase("collection")
	var snapshot = {"state":state,"lobby_name":lobby_name,"max_players":max_players,"players":roster,"returned":returned.duplicate()}
	if rules:
		snapshot.merge(rules.public_view(),true)
		snapshot.revealed = revealed.duplicate(true)
	if state in ["LOBBY","LOBBY_READY"]:
		discovery.advertised = advertisement()
	for id in players:
		var personal = rules.private_view(id) if rules and not state in ["LOAD_SCENE","SEATING"] else {}
		if id == 1:
			_accept_snapshot(snapshot,personal)
		elif _can_send(id):
			receive_snapshot.rpc_id(id,snapshot,personal)

func _can_send(id: int) -> bool:
	if not peer or not id in multiplayer.get_peers():
		return false
	var remote = peer.get_peer(id)
	return remote != null and remote.get_state() == ENetPacketPeer.STATE_CONNECTED and remote.get_channels() > 0

@rpc("authority", "call_remote", "reliable")
func receive_snapshot(snapshot: Dictionary, personal: Dictionary) -> void:
	_accept_snapshot(snapshot,personal)

func _accept_snapshot(snapshot: Dictionary, personal: Dictionary) -> void:
	public_state = snapshot.duplicate(true)
	private_state = personal.duplicate(true)
	lobby_name = snapshot.lobby_name
	max_players = int(snapshot.max_players)
	if not is_host:
		players = snapshot.players.duplicate(true)
	# Deliver every logical pose before deferred HUD refreshes can coalesce
	# snapshots. All peers, including the host, use the same presentation path.
	gestures_received.emit(snapshot.players)
	_set_state(snapshot.state)
	changed.emit()

@rpc("authority", "call_remote", "reliable")
func receive_delta(delta: Dictionary) -> void:
	_accept_delta(delta)

func _accept_delta(delta: Dictionary) -> void:
	Profile.apply_delta(delta)
	delta_received.emit(delta)

@rpc("authority", "call_remote", "reliable")
func receive_notice(message: String) -> void:
	notice.emit(message)

func _tell(id: int, message: String) -> void:
	if id == 1:
		notice.emit(message)
	elif _can_send(id):
		receive_notice.rpc_id(id,message)

func _send_notice_all(message: String) -> void:
	for id in players:
		_tell(id,message)

func _process(delta: float) -> void:
	if is_host and rules and rules.finish_case_transitions():
		_broadcast()
	if state == "CONNECTING":
		_connect_elapsed += delta
		if _connect_elapsed > 10:
			leave("Хост не ответил за 10 секунд. Проверьте IP, порт и брандмауэр.")
	if is_host and peer:
		for id in _pending_peers.keys():
			if Time.get_ticks_msec() - int(_pending_peers[id]) > 8000:
				peer.disconnect_peer(id)
				_pending_peers.erase(id)
