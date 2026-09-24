class_name MatchRules
extends RefCounted
## Authoritative data lives only on the host. public_view() is an explicit allowlist.
var content: Node
var rng = RandomNumberGenerator.new()
var players: Array = []
var seats: Array = []
var order: Array = []
var cases: Dictionary = {}
var owners: Dictionary = {}
var blocked: Dictionary = {}
var intel: Dictionary = {}
var public_info: Dictionary = {}
var collections: Dictionary = {}
var ready: Dictionary = {}
var kept: Dictionary = {}
var peek_used: Dictionary = {}
var event: Dictionary = {}
var turn_index = 0
var round_number = 1
var total_rounds = 1
var information_applied = false
var notifications: Array = []
var phase = "DEAL"
var match_id = ""
var log_lines: Array = []
var results: Array = []
const CASE_OPEN_MS = 1900
const CASE_CLOSE_MS = 1320
const CASE_PHASES = ["DISCUSSION", "DISCUSSION_READY", "TURN"]
# Only case_lids is public. Access, history and deadlines stay on the host.
var case_lids: Dictionary = {}
var case_seen: Dictionary = {}
var case_access: Dictionary = {}
var case_first_open: Dictionary = {}
var case_deadlines: Dictionary = {}

func setup(roster: Array, catalog: Node, seed_value: int = -1) -> void:
	content = catalog
	if seed_value == -1:
		rng.randomize()
	else:
		rng.seed = seed_value
	match_id = Crypto.new().generate_random_bytes(16).hex_encode()
	for p in roster:
		players.append(int(p.peer_id))
		collections[int(p.peer_id)] = p.get("collection", []).duplicate()
		blocked[int(p.peer_id)] = []
		intel[int(p.peer_id)] = []
		ready[int(p.peer_id)] = false
	seats = shuffled(players)
	total_rounds = 1 if players.size() <= 3 else (2 if players.size() <= 5 else 3)
	var available = content.items.duplicate(true)
	for i in players.size():
		var p = players[i]
		var selected = draw_item(available)
		available.erase(selected)
		var prop = ""
		if rng.randf() < float(content.rules.property_chance):
			prop = content.properties[rng.randi_range(0,content.properties.size()-1)].id
		var case_id = "case_" + str(i)
		cases[case_id] = {"item_id":selected.id, "property_id":prop, "original_owner":p, "transfers":0}
		owners[p] = case_id
		case_lids[case_id] = {"state":"CLOSED", "seq":0}
		case_seen[case_id] = []
	if rng.randf() < float(content.rules.event_chance):
		event = content.events[rng.randi_range(0,content.events.size()-1)].duplicate(true)

func shuffled(array: Array) -> Array:
	var copy = array.duplicate()
	for i in range(copy.size()-1,0,-1):
		var j = rng.randi_range(0,i)
		var temp = copy[i]
		copy[i] = copy[j]
		copy[j] = temp
	return copy

func draw_item(available: Array) -> Dictionary:
	var groups = {}
	for it in available:
		if not groups.has(it.rarity):
			groups[it.rarity] = []
		groups[it.rarity].append(it)
	var total = 0.0
	for rarity in groups:
		total += float(content.rules.rarity_weights[rarity])
	var roll = rng.randf() * total
	var chosen = groups.keys()[0]
	for rarity in groups:
		roll -= float(content.rules.rarity_weights[rarity])
		if roll <= 0:
			chosen = rarity
			break
	var group = groups[chosen]
	return group[rng.randi_range(0,group.size()-1)]

func start_discussion() -> void:
	phase = "DISCUSSION"
	order.clear()
	turn_index = 0
	kept.clear()
	for p in players:
		ready[p] = false
		blocked[p] = []
	# Information properties and the match modifier are dealt once per match.
	if information_applied: return
	information_applied = true
	for p in players:
		var case_id = owners[p]
		var c = cases[case_id]
		var effect = content.property(c.property_id).get("effect", "")
		var others = players.duplicate()
		others.erase(p)
		if effect == "exposed":
			publish(case_id, "name", content.item(c.item_id).name)
		elif effect == "insider":
			var target = others[rng.randi_range(0,others.size()-1)]
			intel[p].append({"source":"Инсайд", "peer_id":target, "case_id":owners[target], "rarity":content.item(cases[owners[target]].item_id).rarity})
		elif effect == "leaked":
			var target = others[rng.randi_range(0,others.size()-1)]
			intel[target].append({"source":"Палево", "peer_id":p, "case_id":case_id, "card":card(case_id)})
	var event_effect = event.get("effect", "")
	if event_effect in ["public_name", "public_price"]:
		var eligible = []
		for case_id in cases:
			if content.property(cases[case_id].property_id).get("effect", "") != "quiet":
				eligible.append(case_id)
		if not eligible.is_empty():
			var case_id = eligible[rng.randi_range(0,eligible.size()-1)]
			var it = content.item(cases[case_id].item_id)
			publish(case_id, "name" if event_effect == "public_name" else "base_value", it.name if event_effect == "public_name" else it.base_value)
		else:
			log_lines.append("У события нет доступной публичной цели: все кейсы в тихом режиме.")

func publish(case_id: String, key: String, value) -> void:
	if not public_info.has(case_id):
		public_info[case_id] = {}
	public_info[case_id][key] = value

func card(case_id: String) -> Dictionary:
	var c = cases[case_id]
	var result = content.item(c.item_id).duplicate(true)
	result.case_id = case_id
	result.property = content.property(c.property_id).duplicate(true)
	result.transfers = c.transfers
	return result

func mark_ready(peer: int, value: bool) -> bool:
	if phase != "DISCUSSION" or not ready.has(peer):
		return false
	ready[peer] = value
	if not false in ready.values():
		phase = "DISCUSSION_READY"
	return true

func begin_turns() -> void:
	if phase != "DISCUSSION_READY":
		return
	order = shuffled(players)
	if event.get("effect", "") == "shuffle":
		log_lines.append("Очередь перемешана событием «Ежедневный отчёт о спаме».")
	phase = "TURN"

func turn_revision() -> int:
	# A delayed request from round 1 cannot become a valid move in round 2.
	return (round_number - 1) * players.size() + turn_index

func active_peer() -> int:
	return int(order[turn_index]) if phase == "TURN" and turn_index < order.size() else 0

func legal_targets(peer: int) -> Array:
	var targets = []
	for other in players:
		if other != peer and not other in blocked.get(peer, []):
			targets.append(other)
	return targets

func forced(peer: int) -> bool:
	return event.get("effect", "") == "forced" or content.property(cases[owners[peer]].property_id).get("effect", "") == "forced"

func act(peer: int, action: String, target: int = 0) -> String:
	if phase != "TURN" or active_peer() != peer:
		return "Сейчас ход другого игрока."
	if action == "keep":
		if forced(peer):
			return "Нужно обменяться: действует обязательный обмен."
		kept[peer] = owners[peer]
	elif action == "swap":
		if not target in legal_targets(peer):
			return "Эта цель недоступна: действует адресная защита."
		var first = owners[peer]
		owners[peer] = owners[target]
		owners[target] = first
		cases[first].transfers += 1
		cases[owners[peer]].transfers += 1
		reset_case(first)
		reset_case(owners[peer])
		if not peer in blocked[target]:
			blocked[target].append(peer)
	else:
		return "Неизвестное действие."
	advance()
	return ""

func skip_deadlock() -> bool:
	var p = active_peer()
	if p != 0 and forced(p) and legal_targets(p).is_empty():
		log_lines.append("У игрока на ходу нет разрешённых целей. Ход пропущен без бонуса за «Оставить».")
		advance()
		return true
	return false

func advance() -> void:
	turn_index += 1
	if turn_index >= order.size():
		for case_id in cases: reset_case(case_id)
		if round_number < total_rounds:
			round_number += 1
			start_discussion()
		else:
			phase = "REVEAL"
			results = calculate()

func reset_case(case_id: String) -> void:
	case_lids[case_id] = {"state":"CLOSED", "seq":int(case_lids[case_id].seq)+1}
	case_access.erase(case_id)
	case_first_open.erase(case_id)
	case_deadlines.erase(case_id)

func interact_case(peer: int, case_id: String, sequence: int, now: int = -1) -> String:
	if phase not in CASE_PHASES or owners.get(peer, "") != case_id or not case_lids.has(case_id):
		return "Можно открыть только свой текущий кейс во время раунда."
	var lid = case_lids[case_id]
	if int(lid.seq) != sequence or lid.state not in ["CLOSED", "OPEN"]:
		return "Дождитесь завершения движения крышки."
	if now < 0: now = Time.get_ticks_msec()
	lid.seq += 1
	if lid.state == "CLOSED":
		lid.state = "OPENING"
		case_access[case_id] = peer
		case_first_open[case_id] = not peer in case_seen[case_id]
		case_deadlines[case_id] = now + CASE_OPEN_MS
	else:
		lid.state = "CLOSING"
		case_access.erase(case_id)
		case_deadlines[case_id] = now + CASE_CLOSE_MS
	return ""

func open_public_case(case_id: String) -> void:
	if phase != "REVEAL" or not case_lids.has(case_id): return
	case_lids[case_id] = {"state":"OPENING", "seq":int(case_lids[case_id].seq)+1}
	case_deadlines[case_id] = Time.get_ticks_msec() + CASE_OPEN_MS

func close_public_cases() -> void:
	if phase != "REVEAL": return
	for case_id in cases:
		case_lids[case_id] = {"state":"CLOSING", "seq":int(case_lids[case_id].seq)+1}
		case_deadlines[case_id] = Time.get_ticks_msec() + CASE_CLOSE_MS

func finish_case_transitions(now: int = -1) -> bool:
	if now < 0: now = Time.get_ticks_msec()
	var changed = false
	for case_id in case_deadlines.keys():
		if now < int(case_deadlines[case_id]): continue
		if case_lids[case_id].state == "OPENING" and case_access.has(case_id):
			var viewer = int(case_access[case_id])
			if owners.get(viewer,"") == case_id and not viewer in case_seen[case_id]:
				case_seen[case_id].append(viewer)
		case_lids[case_id].state = "OPEN" if case_lids[case_id].state == "OPENING" else "CLOSED"
		case_deadlines.erase(case_id)
		changed = true
	return changed

func peek(peer: int, target: int) -> String:
	if phase != "DISCUSSION" or not peer in players or not target in players or target == peer:
		return "Подсмотр доступен только во время обсуждения и только для чужого кейса."
	var case_id = owners[peer]
	if content.property(cases[case_id].property_id).get("effect", "") != "peek" or peek_used.get(case_id,false):
		return "Подсмотр недоступен или уже использован."
	peek_used[case_id] = true
	intel[peer].append({"source":"Мильпупс", "peer_id":target, "case_id":owners[target], "card":card(owners[target])})
	return ""

func calculate() -> Array:
	var all_ids = []
	for c in cases.values():
		all_ids.append(c.item_id)
	var output = []
	for p in players:
		var case_id = owners[p]
		var c = cases[case_id]
		var it = content.item(c.item_id)
		var value = int(it.base_value)
		var changes = []
		var combo_names = []
		for combo in content.rules.combos:
			var present = true
			for id in combo.items:
				present = present and id in all_ids
			if present and combo.values.has(c.item_id):
				value = int(combo.values[c.item_id])
				combo_names.append(combo.name)
				changes.append("%s: %d → %d" % [combo.name,int(it.base_value),value])
		var prop = content.property(c.property_id)
		var bonus = 0
		var amount = int(prop.get("amount",0))
		match prop.get("effect", ""):
			"kept":
				if kept.get(p, "") == case_id:
					bonus = amount
			"transfer":
				bonus = amount * int(c.transfers)
				if int(prop.get("cap",-1)) >= 0:
					bonus = mini(bonus,int(prop.cap))
			"new":
				if not c.item_id in collections[p]:
					bonus = amount
			"original":
				if c.original_owner == p:
					bonus = amount
			"moved":
				if c.transfers > 0:
					bonus = amount
		if bonus != 0:
			changes.append("%s: %+d" % [prop.name,bonus])
		value = maxi(0,value + bonus)
		if event.get("effect", "") == "multiply" and value > 0:
			value = int(round(value * float(event.factor)))
			changes.append("%s: ×%s" % [event.name,str(event.factor)])
		output.append({"peer_id":p, "case_id":case_id, "card":card(case_id), "score":value, "changes":changes, "combos":combo_names, "event":event, "win":false})
	var highest = 0
	for r in output:
		highest = maxi(highest,int(r.score))
	for r in output:
		r.win = int(r.score) == highest
	return output

func public_view() -> Dictionary:
	return {"match_id":match_id, "phase":phase, "seats":seats.duplicate(), "order":order.duplicate() if phase in ["TURN","REVEAL"] else [], "owners":owners.duplicate(), "case_lids":case_lids.duplicate(true), "blocked":blocked.duplicate(true), "ready":ready.duplicate(), "turn_index":turn_index, "turn_revision":turn_revision(), "round_number":round_number, "total_rounds":total_rounds, "active_peer":active_peer(), "event":event.duplicate(true), "public_info":public_info.duplicate(true), "log":log_lines.duplicate(), "notifications":notifications.duplicate(true)}

func private_view(peer: int) -> Dictionary:
	if not owners.has(peer):
		return {}
	var case_id = owners[peer]
	var result = {"intel":intel[peer].duplicate(true), "can_peek":phase == "DISCUSSION" and content.property(cases[case_id].property_id).get("effect", "") == "peek" and not peek_used.get(case_id,false), "forced":forced(peer), "targets":legal_targets(peer)}
	if phase in CASE_PHASES and case_access.get(case_id,0) == peer and case_lids[case_id].state in ["OPENING","OPEN"]:
		result.own = card(case_id)
		result.first_open = bool(case_first_open.get(case_id,true))
	return result
