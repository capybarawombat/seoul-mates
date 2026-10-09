extends SceneTree

var game: Node2D
var role := "A"
var expected_money := -1
var expected_rice := -1

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0: role = args[0]
	if args.size() > 1: expected_money = int(args[1])
	if args.size() > 2: expected_rice = int(args[2])
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child.call_deferred(game)
	_run.call_deferred()

func _run() -> void:
	await create_timer(0.3).timeout
	game.menu_open = false
	game._connect_server()
	var limit := 0
	while not game.online and limit < 50:
		await create_timer(0.1).timeout
		limit += 1
	if not game.online:
		push_error("client %s failed to connect" % role)
		quit(1)
		return
	print("CLIENT %s CONNECTED %d" % [role, game.multiplayer.get_unique_id()])
	await create_timer(1.0).timeout
	if role == "A": await _run_a()
	elif role == "B": await _run_b()
	elif role == "C": await _run_rejoin()
	else: await _run_restart()

func _move(target: Vector2) -> void:
	var count := 0
	while game.player.distance_to(target) > 1.0 and count < 100:
		game.player = game.player.move_toward(target, 15.0)
		await create_timer(0.11).timeout
		count += 1
	assert(count < 100)
	await create_timer(0.35).timeout

func _to_shelf() -> void:
	await _move(Vector2(470, 300))
	await _move(Vector2(220, 300))
	await _move(Vector2(220, 235))

func _to_stove() -> void:
	await _move(Vector2(220, 300))
	await _move(Vector2(580, 300))
	await _move(Vector2(580, 235))

func _run_a() -> void:
	game.request_action.rpc_id(1, "start", 0, 0.0)
	await _to_shelf()
	game.selected_item = 0
	game._interact()
	await create_timer(0.4).timeout
	assert(game.state.held(game.multiplayer.get_unique_id()) == "rice_cake")
	await _to_stove()
	game._interact()
	await create_timer(0.5).timeout
	assert(int(game.state.session["added"].get("rice_cake", 0)) == 1)
	print("CLIENT A ADDED RICE CAKE")
	await _to_shelf()
	game.selected_item = 2
	game._interact()
	await _to_stove()
	game._interact()
	await create_timer(0.5).timeout
	assert(int(game.state.session["added"].get("gochujang", 0)) == 1)
	var limit := 0
	while int(game.state.session["added"].get("fish_cake", 0)) < 1 and limit < 200:
		await create_timer(0.1).timeout
		limit += 1
	assert(limit < 200)
	print("CLIENT A SEES B FISH CAKE")
	game._set_heat(0.72)
	for i in range(100):
		game._stir(0.07)
		await create_timer(0.08).timeout
	limit = 0
	while float(game.state.session["doneness"]) < 0.72 and limit < 240:
		await create_timer(0.1).timeout
		limit += 1
	assert(limit < 240)
	game.panel_open = false
	await _move(Vector2(580, 300))
	await _move(Vector2(755, 300))
	await _move(Vector2(755, 235))
	for i in range(3):
		game._interact()
		await create_timer(0.25).timeout
	assert(not game.state.dish.is_empty())
	await _move(Vector2(785, 300))
	await _move(Vector2(785, 440))
	game._interact()
	await create_timer(0.6).timeout
	assert(game.state.served == 1)
	var paid_once: int = game.state.money
	game._interact()
	await create_timer(0.5).timeout
	assert(game.state.money == paid_once and game.state.served == 1)
	print("CLIENT A SERVED; BALANCE %d" % game.state.money)
	quit()

func _run_b() -> void:
	await create_timer(1.0).timeout
	await _to_shelf()
	game.selected_item = 1
	game._interact()
	await create_timer(0.4).timeout
	assert(game.state.held(game.multiplayer.get_unique_id()) == "fish_cake")
	await _move(Vector2(220, 300))
	await _move(Vector2(410, 300))
	await _move(Vector2(410, 230))
	var session_wait := 0
	while game.state.session.is_empty() and session_wait < 100:
		await create_timer(0.1).timeout
		session_wait += 1
	assert(session_wait < 100)
	for i in range(4):
		game._interact()
		await create_timer(0.25).timeout
	assert(bool(game.state.session["chopped"]))
	await _move(Vector2(410, 300))
	await _move(Vector2(580, 300))
	await _move(Vector2(580, 235))
	game._interact()
	await create_timer(0.5).timeout
	assert(int(game.state.session["added"].get("fish_cake", 0)) == 1)
	print("CLIENT B ADDED FISH CAKE")
	var limit := 0
	while game.state.served < 1 and limit < 360:
		await create_timer(0.1).timeout
		limit += 1
	assert(limit < 360)
	print("CLIENT B SEES PAYMENT; BALANCE %d" % game.state.money)
	quit()

func _run_rejoin() -> void:
	assert(game.state.served == 1)
	assert(game.state.order == "ramyeon")
	assert(int(game.state.inventory["rice_cake"]) == 2)
	print("REJOINED CLIENT SEES SERVED %d; BALANCE %d" % [game.state.served, game.state.money])
	quit()

func _run_restart() -> void:
	assert(expected_money >= 0 and expected_rice >= 0)
	assert(game.state.money == expected_money)
	assert(int(game.state.inventory["rice_cake"]) == expected_rice)
	assert(game.state.served == 0)
	print("RESTARTED SERVER RESTORED BALANCE %d; RICE CAKE %d" % [game.state.money, game.state.inventory["rice_cake"]])
	quit()
