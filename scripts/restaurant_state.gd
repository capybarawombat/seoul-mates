extends RefCounted
class_name RestaurantState

const RECIPES_PATH := "res://data/recipes.json"
const SAVE_PATH := "user://restaurant_v1.json"
const ALL_ITEMS := ["rice_cake", "fish_cake", "gochujang", "noodles", "broth", "scallion"]

var recipes: Dictionary = {}
var save_path: String = SAVE_PATH
var inventory: Dictionary = {}
var carried: String = ""
var carried_by: Dictionary = {}
var dish: Dictionary = {}
var session: Dictionary = {}
var money: int = 30
var day: int = 1
var served: int = 0
var target_orders: int = 3
var order: String = "tteokbokki"
var phase: String = "PREPARATION"
var message: String = "Gather ingredients at the shelf."
var customer_patience: float = 1.0
var action_count: int = 0
var station_owner: int = 0

func _init() -> void:
	var file := FileAccess.open(RECIPES_PATH, FileAccess.READ)
	if file != null:
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if parsed is Dictionary:
			recipes = parsed
	for item in ALL_ITEMS:
		inventory[item] = 3

func start_shift() -> void:
	if phase == "PREPARATION" or phase == "RESULTS":
		if phase == "RESULTS":
			day += 1
			served = 0
		phase = "OPEN"
		order = "tteokbokki" if served % 2 == 0 else "ramyeon"
		customer_patience = 1.0
		message = "Customer ordered %s." % recipes[order]["name"]

func held(player_id: int = 1) -> String:
	return str(carried_by.get(str(player_id), ""))

func gather(item: String, player_id: int = 1) -> bool:
	if not ALL_ITEMS.has(item) or held(player_id) != "" or int(inventory.get(item, 0)) <= 0:
		return false
	carried_by[str(player_id)] = item
	if player_id == 1: carried = item
	message = "Carrying %s. Bring it to prep or stove." % item.replace("_", " ")
	return true

func begin_cooking() -> bool:
	if not session.is_empty() or not dish.is_empty():
		return false
	if not recipes.has(order):
		return false
	session = {"recipe": order, "added": {}, "chopped": false, "chop_progress": 0.0, "heat": 0.0, "temperature": 0.0, "doneness": 0.0, "mixing": 0.0, "burn": 0.0, "stir_count": 0, "plating": 0.0, "finished": false}
	message = "Add recipe ingredients. Chop the garnish at prep."
	return true

func acquire_stove(player_id: int) -> bool:
	if station_owner == 0:
		station_owner = player_id
	return station_owner == player_id

func release_stove(player_id: int) -> void:
	if station_owner == player_id:
		station_owner = 0

func chop(amount: float, player_id: int = 1) -> bool:
	var item := held(player_id)
	if item == "" or session.is_empty():
		return false
	var recipe: Dictionary = recipes[session["recipe"]]
	if item != recipe["chop"]:
		return false
	session["chop_progress"] = minf(1.0, float(session["chop_progress"]) + clampf(amount, 0.0, 0.25))
	if float(session["chop_progress"]) >= 1.0:
		session["chopped"] = true
		message = "%s chopped. Add it at the stove." % item.replace("_", " ")
	return true

func add_carried(player_id: int = 1) -> bool:
	var item := held(player_id)
	if item == "" or session.is_empty():
		return false
	var recipe: Dictionary = recipes[session["recipe"]]
	var required: Dictionary = recipe["ingredients"]
	if not required.has(item):
		return false
	var added: Dictionary = session["added"]
	if int(added.get(item, 0)) >= int(required[item]):
		return false
	if item == recipe["chop"] and not bool(session["chopped"]):
		message = "Chop %s at the prep board first." % item.replace("_", " ")
		return false
	if int(inventory.get(item, 0)) <= 0:
		return false
	inventory[item] = int(inventory[item]) - 1
	added[item] = int(added.get(item, 0)) + 1
	message = "Added %s to the pot." % item.replace("_", " ")
	carried_by[str(player_id)] = ""
	if player_id == 1: carried = ""
	action_count += 1
	return true

func ingredients_complete() -> bool:
	if session.is_empty():
		return false
	var required: Dictionary = recipes[session["recipe"]]["ingredients"]
	for item in required:
		if int(session["added"].get(item, 0)) < int(required[item]):
			return false
	return true

func set_heat(value: float) -> void:
	if not session.is_empty():
		session["heat"] = clampf(value, 0.0, 1.0)

func stir(amount: float) -> void:
	if session.is_empty() or not ingredients_complete():
		return
	session["mixing"] = minf(1.0, float(session["mixing"]) + clampf(amount, 0.0, 0.08))
	session["stir_count"] = int(session["stir_count"]) + 1
	action_count += 1

func tick(delta: float) -> void:
	if phase == "OPEN":
		customer_patience = maxf(0.0, customer_patience - delta / 210.0)
	if session.is_empty() or not ingredients_complete():
		return
	var heat: float = session["heat"]
	var temp: float = session["temperature"]
	session["temperature"] = move_toward(temp, heat, delta * 0.18)
	var recipe: Dictionary = recipes[session["recipe"]]
	var ideal: Array = recipe["ideal_temperature"]
	if float(session["temperature"]) >= float(ideal[0]):
		session["doneness"] = minf(1.3, float(session["doneness"]) + delta * 0.055 * (float(session["temperature"]) / float(ideal[0])))
	if float(session["temperature"]) > float(ideal[1]) and float(session["mixing"]) < 0.55:
		session["burn"] = minf(1.0, float(session["burn"]) + delta * 0.055)
	if float(session["doneness"]) > 1.0:
		session["burn"] = minf(1.0, float(session["burn"]) + delta * 0.03)

func plate(amount: float) -> bool:
	if session.is_empty() or not ingredients_complete():
		return false
	if float(session["doneness"]) < 0.40:
		message = "Keep cooking before plating."
		return false
	session["plating"] = minf(1.0, float(session["plating"]) + clampf(amount, 0.0, 0.35))
	if float(session["plating"]) < 1.0:
		return true
	var recipe: Dictionary = recipes[session["recipe"]]
	var quality: float = 100.0
	quality -= absf(float(session["doneness"]) - float(recipe["target_doneness"])) * 56.0
	quality -= maxf(0.0, float(recipe["target_mixing"]) - float(session["mixing"])) * 28.0
	quality -= float(session["burn"]) * 48.0
	quality = clampf(quality, 0.0, 100.0)
	dish = {"recipe": session["recipe"], "quality": roundi(quality)}
	session.clear()
	station_owner = 0
	message = "%s plated · %d quality. Serve at the table!" % [recipe["name"], dish["quality"]]
	action_count += 1
	return true

func serve() -> bool:
	if phase != "OPEN" or dish.is_empty() or dish["recipe"] != order:
		return false
	var price: int = recipes[order]["price"]
	var earned: int = roundi(float(price) * (0.5 + float(dish["quality"]) / 200.0) * (0.65 + customer_patience * 0.35))
	money += earned
	served += 1
	dish.clear()
	action_count += 1
	if served >= target_orders:
		phase = "RESULTS"
		message = "Shift complete! Earned meals: %d. Press Enter for next day." % served
	else:
		order = "tteokbokki" if served % 2 == 0 else "ramyeon"
		customer_patience = 1.0
		message = "+%d coins! Next order: %s." % [earned, recipes[order]["name"]]
	return true

func restock(item: String) -> bool:
	if not ALL_ITEMS.has(item) or money < 3:
		return false
	money -= 3
	inventory[item] = int(inventory[item]) + 1
	message = "Bought one %s for 3 coins." % item.replace("_", " ")
	return true

func save_game() -> bool:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"version": 1, "money": money, "day": day, "inventory": inventory}))
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(save_path):
		return false
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return false
	var data: Variant = JSON.parse_string(file.get_as_text())
	if not data is Dictionary or int(data.get("version", 0)) != 1:
		return false
	var saved_items: Variant = data.get("inventory", {})
	if not saved_items is Dictionary:
		return false
	for item in ALL_ITEMS:
		if int(saved_items.get(item, -1)) < 0:
			return false
	money = maxi(0, int(data.get("money", 30)))
	day = maxi(1, int(data.get("day", 1)))
	for item in ALL_ITEMS:
		inventory[item] = int(saved_items[item])
	return true

func snapshot() -> Dictionary:
	return {"version": 1, "money": money, "day": day, "served": served, "order": order, "phase": phase, "message": message, "inventory": inventory.duplicate(true), "carried_by": carried_by.duplicate(true), "dish": dish.duplicate(true), "session": session.duplicate(true), "customer_patience": customer_patience, "action_count": action_count, "station_owner": station_owner}

func apply_snapshot(data: Dictionary) -> bool:
	if int(data.get("version", 0)) != 1:
		return false
	money = int(data.get("money", money))
	day = int(data.get("day", day))
	served = int(data.get("served", served))
	order = str(data.get("order", order))
	phase = str(data.get("phase", phase))
	message = str(data.get("message", message))
	inventory = data.get("inventory", inventory).duplicate(true)
	carried_by = data.get("carried_by", carried_by).duplicate(true)
	dish = data.get("dish", dish).duplicate(true)
	session = data.get("session", session).duplicate(true)
	customer_patience = float(data.get("customer_patience", customer_patience))
	action_count = int(data.get("action_count", action_count))
	station_owner = int(data.get("station_owner", station_owner))
	carried = held(1)
	return true
