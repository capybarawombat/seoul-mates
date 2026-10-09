extends Node2D

const State = preload("res://scripts/restaurant_state.gd")
const ROOM := Rect2(56, 72, 848, 504)
const SHELF := Rect2(80, 126, 115, 92)
const PREP := Rect2(288, 126, 112, 82)
const STOVE := Rect2(440, 126, 128, 82)
const PLATE := Rect2(620, 126, 110, 82)
const TABLE := Rect2(645, 354, 122, 82)
const DOOR := Rect2(434, 564, 92, 14)
const ITEM_NAMES := ["rice_cake", "fish_cake", "gochujang", "noodles", "broth", "scallion"]
const BG := Color("182735")
const CREAM := Color("fff2da")
const PEACH := Color("edaa96")
const MINT := Color("8fc7ae")
const DARK := Color("293743")
const GOLD := Color("f1c778")

var state: RestaurantState = State.new()
var player := Vector2(470, 460)
var facing := Vector2.DOWN
var moving := false
var walk_time := 0.0
var selected_item := 0
var panel_open := false
var mouse_down := false
var last_mouse := Vector2.ZERO
var last_stir_angle := 0.0
var drag_distance := 0.0
var toast_time := 0.0
var menu_open := true
var server_mode := false
var online := false
var positions: Dictionary = {}
var network_clock := 0.0
var network_status := "SOLO"
var last_sent_position := Vector2(470, 460)
var move_clock: Dictionary = {}
var debug_clock := 0.0
var player_colors: Dictionary = {}
var player_facings: Dictionary = {}
var player_walking: Dictionary = {}
var snapshot_seq := 0
var last_snapshot_seq := -1
var pending_spawn_sync := false
var sfx_player: AudioStreamPlayer
var sfx_muted := false
var sfx_volume := 0.7

func _ready() -> void:
	server_mode = OS.get_cmdline_user_args().has("--server")
	if not server_mode:
		var generator := AudioStreamGenerator.new()
		generator.mix_rate = 22050.0
		generator.buffer_length = 0.3
		sfx_player = AudioStreamPlayer.new()
		sfx_player.stream = generator
		add_child(sfx_player)
	var alternate_save := OS.get_environment("SEOUL_MATES_SAVE_PATH")
	if alternate_save != "": state.save_path = alternate_save
	state.load_game()
	if server_mode:
		var peer := WebSocketMultiplayerPeer.new()
		var result := peer.create_server(9090, "*")
		if result != OK:
			push_error("Cannot open WebSocket server: %d" % result)
			get_tree().quit(1)
			return
		multiplayer.multiplayer_peer = peer
		multiplayer.peer_connected.connect(_peer_joined)
		multiplayer.peer_disconnected.connect(_peer_left)
		positions["1"] = Vector2(470, 460)
		menu_open = false
		network_status = "SERVER 9090"
		print("SEOUL MATES server listening on 9090")
	queue_redraw()

func _process(delta: float) -> void:
	if not menu_open and not server_mode:
		var direction := Vector2.ZERO
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): direction.x -= 1
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): direction.x += 1
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): direction.y -= 1
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): direction.y += 1
		moving = direction.length_squared() > 0.0 and not panel_open
		if moving:
			direction = direction.normalized()
			facing = direction
			var next := player + direction * delta * 150.0
			if _can_walk(Vector2(next.x, player.y)): player.x = next.x
			if _can_walk(Vector2(player.x, next.y)): player.y = next.y
			walk_time += delta * 9.0
		if not online: state.tick(delta)
		if not online and state.phase == "OPEN" and state.customer_patience <= 0.0:
			state.customer_patience = 1.0
			state.message = "A guest waited too long. Keep cooking!"
		if online:
			network_clock += delta
			if network_clock >= 0.1 or player.distance_to(last_sent_position) > 8.0:
				network_clock = 0.0
				last_sent_position = player
				submit_position.rpc_id(1, player, facing, moving)
	if server_mode:
		state.tick(delta)
		network_clock += delta
		if network_clock >= 0.1:
			network_clock = 0.0
			_broadcast_snapshot()
	if OS.has_feature("web") and OS.has_feature("debug"):
		debug_clock += delta
		if debug_clock >= 0.1:
			debug_clock = 0.0
			_publish_debug_state()
	toast_time = maxf(0.0, toast_time - delta)
	queue_redraw()

func _can_walk(pos: Vector2) -> bool:
	if pos.x < ROOM.position.x + 17 or pos.x > ROOM.end.x - 17 or pos.y < ROOM.position.y + 39 or pos.y > ROOM.end.y - 14:
		return false
	var body := Rect2(pos.x - 10, pos.y - 11, 20, 19)
	for obstacle in [SHELF, PREP, STOVE, PLATE, TABLE, Rect2(205, 360, 100, 78), Rect2(335, 355, 83, 78)]:
		if body.intersects(obstacle.grow(3)):
			return false
	return true

func _nearest_station(pos: Vector2 = Vector2.INF) -> String:
	if pos == Vector2.INF: pos = player
	var stations := {"shelf": SHELF, "prep": PREP, "stove": STOVE, "plate": PLATE, "table": TABLE}
	var best := ""
	var best_dist := 87.0
	for key in stations:
		var rect: Rect2 = stations[key]
		var dist := pos.distance_to(_closest(rect, pos))
		if dist < best_dist:
			best = key
			best_dist = dist
	return best

func _interact() -> void:
	_play_sfx(_nearest_station())
	if online:
		if _nearest_station() == "stove" and not state.session.is_empty(): panel_open = true
		request_action.rpc_id(1, "interact", selected_item, 0.0)
		return
	_perform_interact(1, player, selected_item)

func _perform_interact(player_id: int, pos: Vector2, item_index: int) -> void:
	var station := _nearest_station(pos)
	match station:
		"shelf":
			var item: String = ITEM_NAMES[clampi(item_index, 0, 5)]
			if not state.gather(item, player_id):
				state.message = "Hands full or shelf empty. Select another ingredient."
		"prep":
			if not state.chop(0.25, player_id):
				state.message = "Carry the recipe's garnish here to chop it."
		"stove":
			if state.session.is_empty(): state.begin_cooking()
			state.acquire_stove(player_id)
			if state.held(player_id) != "": state.add_carried(player_id)
			if not server_mode and (not online or player_id == multiplayer.get_unique_id()):
				panel_open = not state.session.is_empty()
		"plate":
			if not state.plate(0.35):
				state.message = "Finish cooking at the stove before plating."
		"table":
			if not state.serve():
				state.message = "Bring the customer's matching dish to this table."
		_:
			state.message = "Step closer to a station and press E."
	toast_time = 3.0
	if server_mode: _broadcast_snapshot()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ENTER:
		if menu_open:
			menu_open = false
		elif online:
			request_action.rpc_id(1, "start", 0, 0.0)
		else:
			state.start_shift()
		return
	if event.keycode == KEY_ESCAPE:
		panel_open = false
		return
	if event.keycode == KEY_E or event.keycode == KEY_SPACE:
		if not menu_open:
			_interact()
		return
	if event.keycode >= KEY_1 and event.keycode <= KEY_6:
		selected_item = event.keycode - KEY_1
	if event.keycode == KEY_F5:
		if not online: state.save_game()
		state.message = "Restaurant saved."
	if event.keycode == KEY_M:
		sfx_muted = not sfx_muted
	if event.keycode == KEY_BRACKETLEFT:
		sfx_volume = maxf(0.0, sfx_volume - 0.1)
	if event.keycode == KEY_BRACKETRIGHT:
		sfx_volume = minf(1.0, sfx_volume + 0.1)
	if event.keycode == KEY_N:
		_connect_server()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var p: Vector2 = event.position
		if event.button_index == MOUSE_BUTTON_LEFT:
			mouse_down = event.pressed
			if event.pressed:
				last_mouse = p
				if menu_open and Rect2(344, 380, 272, 55).has_point(p):
					menu_open = false
					return
				if Rect2(71, 595, 810, 38).has_point(p):
					selected_item = clampi(int((p.x - 72.0) / 135.0), 0, 5)
					return
				if panel_open:
					if Rect2(270, 458, 420, 34).has_point(p):
						_play_sfx("dial")
						_set_heat(clampf((p.x - 270.0) / 420.0, 0.0, 1.0))
					if Rect2(712, 138, 42, 37).has_point(p): panel_open = false
					if p.distance_to(Vector2(480, 333)) < 100.0: _play_sfx("stir")
					last_stir_angle = (p - Vector2(480, 333)).angle()
				else:
					if SHELF.grow(12).has_point(p) and player.distance_to(_closest(SHELF, player)) < 95: _interact()
					if PREP.grow(12).has_point(p) and player.distance_to(_closest(PREP, player)) < 95: _chop(0.25)
					if PLATE.grow(12).has_point(p) and player.distance_to(_closest(PLATE, player)) < 95: _interact()
	if event is InputEventMouseMotion and mouse_down:
		var p: Vector2 = event.position
		if panel_open:
			if Rect2(270, 458, 420, 34).has_point(p):
				_set_heat(clampf((p.x - 270.0) / 420.0, 0.0, 1.0))
			var offset := p - Vector2(480, 333)
			if offset.length() > 45.0 and offset.length() < 125.0:
				var change := absf(wrapf(offset.angle() - last_stir_angle, -PI, PI))
				if change < 1.1: _stir(change / TAU * 0.13)
				last_stir_angle = offset.angle()
		elif PREP.grow(18).has_point(p) and player.distance_to(_closest(PREP, player)) < 95:
			drag_distance += p.distance_to(last_mouse)
			if drag_distance > 24.0:
				_chop(0.15)
				drag_distance = 0.0
		last_mouse = p

func _set_heat(value: float) -> void:
	if online: request_action.rpc_id(1, "heat", 0, value)
	else: state.set_heat(value)

func _stir(value: float) -> void:
	if online: request_action.rpc_id(1, "stir", 0, value)
	else: state.stir(value)

func _chop(value: float) -> void:
	if online: request_action.rpc_id(1, "chop", 0, value)
	else: state.chop(value)

func _play_sfx(kind: String) -> void:
	if server_mode or sfx_muted or sfx_volume <= 0.0 or sfx_player == null:
		return
	if not sfx_player.playing:
		sfx_player.play()
	var playback := sfx_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	var frequency := 390.0
	match kind:
		"prep": frequency = 280.0
		"stove", "stir": frequency = 330.0
		"plate": frequency = 590.0
		"table": frequency = 740.0
		"dial": frequency = 440.0
	var sample_count := mini(playback.get_frames_available(), 2500)
	var frames := PackedVector2Array()
	frames.resize(sample_count)
	for i in range(sample_count):
		var progress := float(i) / float(maxi(sample_count, 1))
		var envelope := (1.0 - progress) * (1.0 - progress)
		var tone := sin(TAU * frequency * float(i) / 22050.0) * envelope * 0.14 * sfx_volume
		frames[i] = Vector2(tone, tone)
	playback.push_buffer(frames)

func _connect_server() -> void:
	if online or server_mode: return
	var url := "ws://127.0.0.1:9090"
	if OS.has_feature("web"):
		var configured: Variant = JavaScriptBridge.eval("window.SEOUL_MATES_SERVER_URL || ''")
		if str(configured) != "": url = str(configured)
		elif JavaScriptBridge.eval("location.protocol") == "https:":
			network_status = "SET WSS SERVER URL IN WEB PAGE"
			return
	var peer := WebSocketMultiplayerPeer.new()
	var result := peer.create_client(url)
	if result != OK:
		network_status = "CONNECT FAILED %d" % result
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_server_connected, CONNECT_ONE_SHOT)
	multiplayer.connection_failed.connect(_server_failed, CONNECT_ONE_SHOT)
	multiplayer.server_disconnected.connect(_server_disconnected, CONNECT_ONE_SHOT)
	network_status = "CONNECTING"

func _server_connected() -> void:
	online = true
	network_status = "ROOM SEOUL · CONNECTED"
	menu_open = false
	pending_spawn_sync = true
	last_snapshot_seq = -1

func _server_failed() -> void:
	online = false
	network_status = "SERVER UNAVAILABLE"
	multiplayer.multiplayer_peer = null

func _server_disconnected() -> void:
	online = false
	network_status = "DISCONNECTED · N RETRY"
	multiplayer.multiplayer_peer = null

func _peer_joined(id: int) -> void:
	if positions.size() >= 5:
		multiplayer.multiplayer_peer.disconnect_peer(id)
		return
	positions[str(id)] = Vector2(475 + id % 3 * 24, 470)
	var color_index := 0
	while player_colors.values().has(color_index):
		color_index += 1
	player_colors[str(id)] = color_index
	player_facings[str(id)] = Vector2.DOWN
	player_walking[str(id)] = false
	move_clock[str(id)] = Time.get_ticks_msec()
	print("Player %d joined room SEOUL" % id)
	_broadcast_snapshot()

func _peer_left(id: int) -> void:
	positions.erase(str(id))
	player_colors.erase(str(id))
	player_facings.erase(str(id))
	player_walking.erase(str(id))
	move_clock.erase(str(id))
	state.carried_by.erase(str(id))
	state.release_stove(id)
	print("Player %d left room SEOUL" % id)
	state.save_game()
	_broadcast_snapshot()

@rpc("any_peer", "call_remote", "unreliable")
func submit_position(pos: Vector2, look: Vector2, walking_now: bool) -> void:
	if not server_mode: return
	var id := multiplayer.get_remote_sender_id()
	if not positions.has(str(id)) or not _can_walk(pos): return
	var old: Vector2 = positions[str(id)]
	var now := Time.get_ticks_msec()
	var elapsed := clampf(float(now - int(move_clock.get(str(id), now))) / 1000.0, 0.0, 0.3)
	if old.distance_to(pos) > 150.0 * elapsed + 12.0: return
	var parts := maxi(1, ceili(old.distance_to(pos) / 8.0))
	for step in range(1, parts + 1):
		if not _can_walk(old.lerp(pos, float(step) / float(parts))): return
	positions[str(id)] = pos
	player_facings[str(id)] = look.normalized() if look.length_squared() > 0.01 else Vector2.DOWN
	player_walking[str(id)] = walking_now
	move_clock[str(id)] = now

@rpc("any_peer", "call_remote", "reliable")
func request_action(action: String, item_index: int, value: float) -> void:
	if not server_mode: return
	var id := multiplayer.get_remote_sender_id()
	if not positions.has(str(id)) or action.length() > 16: return
	var pos: Vector2 = positions[str(id)]
	match action:
		"interact": _perform_interact(id, pos, item_index)
		"start": state.start_shift()
		"chop":
			if _nearest_station(pos) == "prep": state.chop(clampf(value, 0.0, 0.25), id)
		"heat":
			if _nearest_station(pos) == "stove" and state.station_owner == id: state.set_heat(clampf(value, 0.0, 1.0))
		"stir":
			if _nearest_station(pos) == "stove" and state.station_owner == id: state.stir(clampf(value, 0.0, 0.08))
	if action == "interact" or action == "start": state.save_game()
	_broadcast_snapshot()

func _broadcast_snapshot() -> void:
	if server_mode and multiplayer.multiplayer_peer != null:
		snapshot_seq += 1
		receive_snapshot.rpc(snapshot_seq, state.snapshot(), positions, player_colors, player_facings, player_walking)

@rpc("authority", "call_remote", "unreliable")
func receive_snapshot(seq: int, data: Dictionary, player_positions: Dictionary, colors: Dictionary, facings: Dictionary, walking_flags: Dictionary) -> void:
	if server_mode: return
	if seq <= last_snapshot_seq: return
	last_snapshot_seq = seq
	state.apply_snapshot(data)
	positions = player_positions
	player_colors = colors
	player_facings = facings
	player_walking = walking_flags
	if pending_spawn_sync and positions.has(str(multiplayer.get_unique_id())):
		player = positions[str(multiplayer.get_unique_id())]
		last_sent_position = player
		pending_spawn_sync = false
	if panel_open and state.session.is_empty(): panel_open = false

func _publish_debug_state() -> void:
	var peers: Dictionary = {}
	for id in positions:
		var pos: Vector2 = positions[id]
		peers[str(id)] = [pos.x, pos.y]
	var data := {
		"online": online,
		"peer_id": multiplayer.get_unique_id(),
		"position": [player.x, player.y],
		"peers": peers,
		"colors": player_colors,
		"carried": state.held(multiplayer.get_unique_id() if online else 1),
		"inventory": state.inventory,
		"session": state.session,
		"dish": state.dish,
		"phase": state.phase,
		"customer_stage": state.customer_stage,
		"served": state.served,
		"money": state.money,
		"order": state.order,
		"panel_open": panel_open,
		"message": state.message
	}
	JavaScriptBridge.eval("window.__SEOUL_TEST_STATE = " + JSON.stringify(data))

func _draw() -> void:
	draw_rect(Rect2(0, 0, 960, 640), BG)
	_draw_room()
	_draw_station(SHELF, "INGREDIENTS", Color("7599a1"), 0)
	_draw_station(PREP, "PREP BOARD", Color("dda57b"), 1)
	_draw_station(STOVE, "STOVE", Color("9d7d8e"), 2)
	_draw_station(PLATE, "PLATING", Color("8fbdb1"), 3)
	_draw_table(TABLE, true)
	_draw_table(Rect2(205, 360, 100, 78), false)
	_draw_table(Rect2(335, 355, 83, 78), false)
	var actors: Array[Dictionary] = []
	if state.phase == "OPEN" and state.customer_stage != "absent":
		actors.append({"kind": "customer", "y": state.customer_position.y})
	if online:
		for id in positions:
			if int(id) != multiplayer.get_unique_id():
				actors.append({"kind": "teammate", "y": positions[id].y, "id": int(id), "pos": positions[id]})
	actors.append({"kind": "player", "y": player.y})
	actors.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["y"]) < float(b["y"]))
	for actor in actors:
		match actor["kind"]:
			"customer": _draw_customer()
			"teammate": _draw_teammate(actor["pos"], actor["id"])
			"player": _draw_player()
	_draw_hud()
	if panel_open and not state.session.is_empty(): _draw_cooking_panel()
	if menu_open: _draw_menu()

func _draw_room() -> void:
	draw_rect(ROOM, Color("c79679"))
	draw_rect(Rect2(ROOM.position.x + 9, ROOM.position.y + 28, ROOM.size.x - 18, ROOM.size.y - 39), Color("ebcaa2"))
	for y in range(ROOM.position.y + 30, ROOM.end.y - 8, 32):
		for x in range(ROOM.position.x + 10, ROOM.end.x - 50, 32):
			var offset := 0 if int(y / 32) % 2 == 0 else 16
			draw_rect(Rect2(x + offset, y, 30, 30), Color("e4bc93") if (int(x / 32) + int(y / 32)) % 2 == 0 else Color("f1d4ac"))
	draw_rect(Rect2(56, 72, 848, 50), Color("764e57"))
	draw_rect(Rect2(56, 114, 848, 12), Color("ac6f63"))
	for x in [132, 350, 506, 695, 821]:
		draw_rect(Rect2(x, 86, 55, 22), Color("f9dfac"))
		draw_rect(Rect2(x + 5, 91, 45, 12), Color("f1ba72"))
	draw_rect(DOOR, Color("4d716c"))
	draw_rect(Rect2(436, 548, 88, 16), Color("9bbcb1"))
	_label(Vector2(370, 67), "SEOUL MATES  •  LATE NIGHT KITCHEN", 19, CREAM)
	for i in range(10):
		var light_x := 84 + i * 88
		draw_circle(Vector2(light_x, 70), 3, GOLD)
		draw_circle(Vector2(light_x, 75), 2, Color("f6dfb2"))
	for pos in [Vector2(120, 318), Vector2(843, 493)]:
		draw_rect(Rect2(pos.x - 10, pos.y + 8, 20, 17), Color("9e645c"))
		draw_rect(Rect2(pos.x - 8, pos.y + 10, 16, 10), Color("c88369"))
		for offset in [Vector2(-11, 3), Vector2(0, -7), Vector2(10, 1)]:
			draw_circle(pos + offset, 9, Color("719c78"))
			draw_circle(pos + offset + Vector2(-3, -3), 3, Color("9bc398"))

func _draw_station(rect: Rect2, title: String, color: Color, kind: int) -> void:
	draw_rect(Rect2(rect.position + Vector2(0, 7), rect.size), Color("735b61"))
	draw_rect(rect, DARK)
	draw_rect(Rect2(rect.position + Vector2(5, 5), rect.size - Vector2(10, 14)), color)
	match kind:
		0:
			for i in range(3):
				draw_rect(Rect2(rect.position + Vector2(14 + i * 30, 19), Vector2(24, 30)), [Color("e9d1a4"), Color("e7a185"), Color("ca684f")][i])
				draw_rect(Rect2(rect.position + Vector2(14 + i * 30, 43), Vector2(24, 6)), Color("f8e8ca"))
		1:
			draw_rect(Rect2(rect.position + Vector2(18, 21), Vector2(74, 42)), Color("f4d8aa"))
			for i in range(4): draw_line(rect.position + Vector2(25 + i * 18, 29), rect.position + Vector2(39 + i * 18, 55), Color("b7786a"), 3)
			if not state.session.is_empty() and float(state.session["chop_progress"]) > 0.0:
				draw_rect(Rect2(rect.position + Vector2(20, 67), Vector2(70 * float(state.session["chop_progress"]), 4)), MINT)
		2:
			draw_circle(rect.position + Vector2(64, 40), 30, Color("424b56"))
			draw_circle(rect.position + Vector2(64, 40), 23, Color("d77c59"))
			for i in range(4): draw_circle(rect.position + Vector2(48 + i * 10, 39 + (i % 2) * 9), 4, CREAM)
			if not state.session.is_empty() and float(state.session["temperature"]) > 0.35:
				for i in range(3):
					var lift := sin(float(Time.get_ticks_msec()) / 330.0 + float(i)) * 3.0
					draw_line(rect.position + Vector2(44 + i * 20, 8 + lift), rect.position + Vector2(48 + i * 20, -8 + lift), Color("f7e5c8", 0.75), 3)
		3:
			draw_circle(rect.position + Vector2(55, 41), 32, Color("e9e8d7"))
			draw_circle(rect.position + Vector2(55, 41), 23, Color("cf8a6f"))
			if not state.dish.is_empty():
				for offset in [Vector2(-10, -7), Vector2(4, -11), Vector2(-2, 8), Vector2(12, 4)]:
					draw_rect(Rect2(rect.position + Vector2(55, 41) + offset, Vector2(7, 5)), CREAM)
	_label(rect.position + Vector2(8, -9), title, 13, CREAM)

func _draw_table(rect: Rect2, occupied: bool) -> void:
	for x in [rect.position.x + 8, rect.end.x - 22]:
		draw_rect(Rect2(x, rect.position.y - 18, 15, 18), Color("b57866"))
		draw_rect(Rect2(x, rect.end.y, 15, 18), Color("b57866"))
	draw_rect(Rect2(rect.position + Vector2(0, 5), rect.size), Color("7b5357"))
	draw_rect(rect, Color("b77968"))
	draw_rect(rect.grow(-7), Color("deb090"))
	draw_circle(rect.get_center(), 18, Color("f5e1c6"))
	if occupied and state.customer_stage == "seated":
		draw_circle(rect.get_center(), 9, Color("dc745b"))

func _draw_customer() -> void:
	if state.phase != "OPEN" or state.customer_stage == "absent": return
	var pos: Vector2 = state.customer_position
	_ellipse(Rect2(pos.x - 17, pos.y + 13, 34, 7), Color("8e6c68"))
	draw_rect(Rect2(pos.x - 12, pos.y - 6, 24, 28), Color("9ebaa5"))
	draw_circle(pos + Vector2(0, -15), 13, Color("e5b59b"))
	draw_rect(Rect2(pos.x - 12, pos.y - 27, 24, 9), Color("554c5b"))
	if state.customer_stage == "seated":
		_label(pos + Vector2(-40, -44), state.recipes[state.order]["name"], 13, CREAM)
		draw_rect(Rect2(pos.x - 22, pos.y - 36, 44, 4), Color("534c58"))
		draw_rect(Rect2(pos.x - 22, pos.y - 36, 44 * state.customer_patience, 4), MINT)

func _draw_player() -> void:
	var bounce := sin(walk_time) * 2.0 if moving else 0.0
	var carried_item := state.held(multiplayer.get_unique_id() if online else 1)
	var color_index := int(player_colors.get(str(multiplayer.get_unique_id()), 0)) if online else 0
	_draw_avatar(player + Vector2(0, bounce), color_index, facing, "", carried_item)

func _draw_teammate(pos: Vector2, id: int) -> void:
	var color_index := int(player_colors.get(str(id), 1))
	var look: Vector2 = player_facings.get(str(id), Vector2.DOWN)
	var bob := sin(float(Time.get_ticks_msec()) / 115.0 + float(id % 9)) * 2.0 if bool(player_walking.get(str(id), false)) else 0.0
	_draw_avatar(pos + Vector2(0, bob), color_index, look, "P%d" % (color_index + 1), state.held(id))

func _draw_avatar(p: Vector2, color_index: int, look: Vector2, tag: String, item: String) -> void:
	var outfits := [Color("e27f7a"), MINT, Color("d7ab73"), Color("a5a7d3")]
	var outfit: Color = outfits[clampi(color_index, 0, outfits.size() - 1)]
	var hair := Color("453e4b")
	_ellipse(Rect2(p.x - 16, p.y + 16, 32, 8), Color("9b796e"))
	draw_rect(Rect2(p.x - 12, p.y + 3, 10, 17), Color("566178"))
	draw_rect(Rect2(p.x + 3, p.y + 3, 10, 17), Color("566178"))
	draw_rect(Rect2(p.x - 14, p.y - 17, 28, 27), outfit)
	draw_rect(Rect2(p.x - 8, p.y - 14, 16, 18), CREAM)
	draw_rect(Rect2(p.x - 18, p.y - 12, 5, 15), Color("e6b08f"))
	draw_rect(Rect2(p.x + 13, p.y - 12, 5, 15), Color("e6b08f"))
	draw_circle(p + Vector2(0, -23), 13, Color("e6b08f"))
	draw_rect(Rect2(p.x - 14, p.y - 37, 28, 9), hair)
	if look.y < -0.5:
		draw_rect(Rect2(p.x - 14, p.y - 31, 28, 15), hair)
	elif look.x > 0.5:
		draw_rect(Rect2(p.x + 5, p.y - 23, 3, 3), DARK)
	elif look.x < -0.5:
		draw_rect(Rect2(p.x - 8, p.y - 23, 3, 3), DARK)
	else:
		draw_rect(Rect2(p.x - 6, p.y - 23, 3, 3), DARK)
		draw_rect(Rect2(p.x + 4, p.y - 23, 3, 3), DARK)
	if tag != "": _label(p + Vector2(-10, -40), tag, 12, CREAM)
	if item != "":
		draw_circle(p + Vector2(20, -9), 8, GOLD)
		_label(p + Vector2(10, -49), item.replace("_", " "), 12, CREAM)

func _draw_hud() -> void:
	draw_rect(Rect2(56, 6, 848, 40), Color("354856"))
	_label(Vector2(71, 33), "DAY %d   %s" % [state.day, state.phase], 17, CREAM)
	_label(Vector2(280, 33), "COINS  %d" % state.money, 17, GOLD)
	_label(Vector2(445, 33), "SERVED  %d / %d" % [state.served, state.target_orders], 17, MINT)
	var connection_label := "ROOM SEOUL" if online else "N JOIN ROOM" if network_status == "SOLO" else network_status
	_label(Vector2(670, 33), "%s  ·  SFX %d%%" % [connection_label, 0 if sfx_muted else roundi(sfx_volume * 100.0)], 12, CREAM)
	draw_rect(Rect2(56, 580, 848, 54), Color("354856"))
	for i in range(6):
		var x := 72 + i * 136
		if i == selected_item: draw_rect(Rect2(x - 4, 590, 133, 37), GOLD)
		draw_rect(Rect2(x, 593, 125, 31), DARK)
		_label(Vector2(x + 4, 613), "%d %s:%d" % [i + 1, ITEM_NAMES[i].replace("_", " "), state.inventory[ITEM_NAMES[i]]], 12, CREAM)
	draw_rect(Rect2(56, 528, 848, 39), Color("3e565a"))
	_label(Vector2(69, 553), state.message, 16, CREAM)
	var near := _nearest_station()
	if near != "" and not panel_open:
		_label(Vector2(66, 512), "E  INTERACT: %s" % near.to_upper(), 14, GOLD)
	if state.phase == "PREPARATION" or state.phase == "RESULTS":
		_label(Vector2(550, 512), "ENTER  START SHIFT", 15, GOLD)

func _draw_cooking_panel() -> void:
	draw_rect(Rect2(188, 111, 584, 410), Color("263b47"))
	draw_rect(Rect2(201, 124, 558, 385), Color("f4ddba"))
	_label(Vector2(226, 159), "COOKING  •  %s" % state.recipes[state.session["recipe"]]["name"], 21, DARK)
	_label(Vector2(718, 162), "X", 21, DARK)
	var added: Dictionary = state.session["added"]
	var required: Dictionary = state.recipes[state.session["recipe"]]["ingredients"]
	var ingredient_text := ""
	for item in required:
		ingredient_text += "%s %d/%d   " % [item.replace("_", " "), int(added.get(item, 0)), int(required[item])]
	_label(Vector2(224, 194), ingredient_text, 14, DARK)
	draw_circle(Vector2(480, 336), 91, Color("4c5660"))
	draw_circle(Vector2(480, 336), 79, Color("d57756"))
	draw_circle(Vector2(480, 336), 69, Color("e9945e"))
	for i in range(10):
		var angle := float(i) * TAU / 10.0 + walk_time * 0.05
		var spot := Vector2(480, 336) + Vector2(cos(angle), sin(angle)) * (29 + i % 3 * 11)
		draw_circle(spot, 8 if i % 2 == 0 else 5, CREAM if i % 2 == 0 else Color("8cae82"))
	_label(Vector2(224, 219), "DRAG IN CIRCLES TO STIR", 14, DARK)
	_label(Vector2(224, 239), "TEMP %d%%   COOK %d%%   MIX %d%%" % [int(float(state.session["temperature"]) * 100), int(float(state.session["doneness"]) * 100), int(float(state.session["mixing"]) * 100)], 15, DARK)
	draw_rect(Rect2(270, 458, 420, 22), Color("6f7680"))
	draw_rect(Rect2(270, 458, 420 * float(state.session["heat"]), 22), Color("df785e"))
	draw_circle(Vector2(270 + 420 * float(state.session["heat"]), 469), 15, GOLD)
	_label(Vector2(272, 449), "HEAT  •  DRAG SLIDER TO SET FLAME", 14, DARK)
	_label(Vector2(257, 501), "Gather at shelf • chop at prep • add at stove • plate at counter", 13, DARK)

func _draw_menu() -> void:
	draw_rect(Rect2(220, 160, 520, 320), Color("334953"))
	draw_rect(Rect2(232, 172, 496, 296), Color("f5ddb9"))
	_label(Vector2(288, 226), "SEOUL MATES", 38, Color("834e53"))
	_label(Vector2(315, 265), "A COZY KOREAN KITCHEN", 18, DARK)
	_label(Vector2(274, 308), "Walk: WASD / arrows   •   Interact: E / Space", 16, DARK)
	_label(Vector2(274, 337), "Choose shelf item: 1–6   •   Start shift: Enter", 16, DARK)
	_label(Vector2(296, 359), "N joins room SEOUL on local server", 13, DARK)
	draw_rect(Rect2(344, 380, 272, 55), Color("a25858"))
	_label(Vector2(413, 416), "ENTER KITCHEN", 20, CREAM)

func _label(pos: Vector2, value: String, size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _ellipse(rect: Rect2, color: Color) -> void:
	draw_set_transform(rect.get_center(), 0.0, Vector2(rect.size.x / rect.size.y, 1.0))
	draw_circle(Vector2.ZERO, rect.size.y / 2.0, color)
	draw_set_transform(Vector2.ZERO)

func _closest(rect: Rect2, point: Vector2) -> Vector2:
	return Vector2(clampf(point.x, rect.position.x, rect.end.x), clampf(point.y, rect.position.y, rect.end.y))
