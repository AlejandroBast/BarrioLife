extends Node

signal location_unlocked(location_id: String)
signal objective_completed(objective_id: String)
signal location_changed(location_id: String)
signal money_changed(new_amount: int)
signal farm_battle_changed(battle_id: String)

const FARM_SCENE = "res://scenes/FarmLevel.tscn"
const TOWN_SCENE = "res://scenes/TownLevel.tscn"
const NEIGHBORHOOD_SCENE = "res://scenes/NeighborhoodLevel.tscn"
const GENERIC_LOCATION_SCENE = "res://scenes/LocationScene.tscn"

var current_location_id: String = "farm"
var current_scene: String = "FarmScene"
var current_objective: String = ""
var currentObjective: String = ""
var progress: int = 0
var money: int = 0
var selected_farm_battle_id: String = ""
var pending_farm_story_event: String = ""

var unlocked_locations: Dictionary = {
	"farm": true,
}

var completed_objectives: Dictionary = {}

var mapLocations: Array[Dictionary] = [
	{
		"id": "farm",
		"name": "Granja",
		"description": "Lugar donde comienza la historia de Elian.",
		"unlocked": true,
		"unlockRequirement": "",
		"requiredObjective": "",
		"scene": "FarmScene",
		"scene_path": FARM_SCENE,
	},
	{
		"id": "town",
		"name": "Pueblo",
		"description": "Primer lugar fuera de la granja.",
		"unlocked": false,
		"unlockRequirement": "Completa el capitulo de la granja.",
		"requiredObjective": "farm_chapter_completed",
		"scene": "TownScene",
		"scene_path": TOWN_SCENE,
	},
	{
		"id": "neighborhood",
		"name": "Barrio",
		"description": "Zona donde Elian empieza a construir su identidad musical.",
		"unlocked": false,
		"unlockRequirement": "Completa la mision principal del pueblo.",
		"requiredObjective": "town_mission_completed",
		"scene": "NeighborhoodScene",
		"scene_path": NEIGHBORHOOD_SCENE,
	},
	{
		"id": "city",
		"name": "Ciudad",
		"description": "Lugar de nuevas oportunidades, presion y crecimiento musical.",
		"unlocked": false,
		"unlockRequirement": "Gana la primera batalla importante del barrio.",
		"requiredObjective": "first_battle_won",
		"scene": "CityScene",
		"scene_path": GENERIC_LOCATION_SCENE,
	},
	{
		"id": "studio",
		"name": "Estudio musical",
		"description": "Un espacio para grabar, mejorar y encontrar un sonido propio.",
		"unlocked": false,
		"unlockRequirement": "Llega a la ciudad.",
		"requiredObjective": "city_arrived",
		"scene": "MusicStudioScene",
		"scene_path": GENERIC_LOCATION_SCENE,
	},
	{
		"id": "urban_park",
		"name": "Parque urbano",
		"description": "Punto de encuentro para practicar y conectar con otros artistas.",
		"unlocked": false,
		"unlockRequirement": "Visita el estudio musical.",
		"requiredObjective": "studio_visited",
		"scene": "UrbanParkScene",
		"scene_path": GENERIC_LOCATION_SCENE,
	},
	{
		"id": "final_stadium",
		"name": "Estadio final",
		"description": "El escenario donde Elian puede demostrar todo su camino.",
		"unlocked": false,
		"unlockRequirement": "Completa todas las misiones principales.",
		"requiredObjective": "all_main_missions_completed",
		"scene": "FinalStadiumScene",
		"scene_path": GENERIC_LOCATION_SCENE,
	},
]

var locations: Array[Dictionary]:
	get:
		return mapLocations

var farm_battle_order: Array[String] = [
	"crop_child",
	"young_worker",
	"luis",
]

var farm_battles: Dictionary = {
	"crop_child": {
		"id": "crop_child",
		"name": "NINO DEL CULTIVO",
		"subtitle": "Tutorial de improvisacion",
		"description": "Un nino campesino confiado pero amigable.",
		"cost": 90,
		"required_objective": "farm_cow_milking_completed",
		"complete_objective": "farm_battle_crop_child_won",
		"post_event": "after_battle_1",
		"portrait_path": "res://assets/sprites/rivals/crop_child.png",
		"theme_color": Color(0.78, 0.52, 0.26),
		"note_speed": 300.0,
		"hit_window": 62.0,
		"miss_damage": 8,
		"hit_score": 100,
		"target_score": 700,
		"intro_duration": 3.0,
		"pattern": [
			{"time": 1.0, "dir": "left"},
			{"time": 1.8, "dir": "down"},
			{"time": 2.6, "dir": "up"},
			{"time": 3.4, "dir": "right"},
			{"time": 4.3, "dir": "left"},
			{"time": 5.1, "dir": "right"},
			{"time": 6.0, "dir": "down"},
			{"time": 6.8, "dir": "up"},
			{"time": 7.7, "dir": "left"},
			{"time": 8.5, "dir": "down"},
		],
	},
	"young_worker": {
		"id": "young_worker",
		"name": "TRABAJADOR JOVEN",
		"subtitle": "Desafio de la cuadrilla",
		"description": "Un adolescente mas fuerte, serio y acostumbrado al trabajo duro.",
		"cost": 220,
		"required_objective": "farm_battle_crop_child_won",
		"complete_objective": "farm_battle_young_worker_won",
		"post_event": "after_battle_2",
		"portrait_path": "res://assets/sprites/rivals/young_worker.png",
		"theme_color": Color(0.78, 0.18, 0.12),
		"note_speed": 390.0,
		"hit_window": 46.0,
		"miss_damage": 12,
		"hit_score": 115,
		"target_score": 1300,
		"intro_duration": 2.4,
		"pattern": [
			{"time": 0.8, "dir": "left"},
			{"time": 1.35, "dir": "down"},
			{"time": 1.9, "dir": "left"},
			{"time": 2.45, "dir": "up"},
			{"time": 3.0, "dir": "right"},
			{"time": 3.45, "dir": "down"},
			{"time": 3.9, "dir": "up"},
			{"time": 4.35, "dir": "right"},
			{"time": 4.9, "dir": "left"},
			{"time": 5.35, "dir": "left"},
			{"time": 5.8, "dir": "down"},
			{"time": 6.25, "dir": "up"},
			{"time": 6.75, "dir": "right"},
			{"time": 7.2, "dir": "down"},
			{"time": 7.65, "dir": "right"},
			{"time": 8.1, "dir": "up"},
		],
	},
	"luis": {
		"id": "luis",
		"name": "LUIS",
		"subtitle": "La prueba real",
		"description": "El mejor improvisador de la granja. Relajado, seguro y peligroso.",
		"cost": 450,
		"required_objective": "farm_battle_young_worker_won",
		"complete_objective": "farm_battle_luis_won",
		"post_event": "farm_final",
		"portrait_path": "res://assets/sprites/rivals/luis.png",
		"theme_color": Color(0.18, 0.20, 0.24),
		"note_speed": 470.0,
		"hit_window": 36.0,
		"miss_damage": 16,
		"hit_score": 125,
		"target_score": 2100,
		"intro_duration": 2.0,
		"pattern": [
			{"time": 0.7, "dir": "left"},
			{"time": 1.1, "dir": "down"},
			{"time": 1.5, "dir": "up"},
			{"time": 1.9, "dir": "right"},
			{"time": 2.3, "dir": "left"},
			{"time": 2.65, "dir": "up"},
			{"time": 3.0, "dir": "down"},
			{"time": 3.35, "dir": "right"},
			{"time": 3.75, "dir": "right"},
			{"time": 4.1, "dir": "up"},
			{"time": 4.45, "dir": "left"},
			{"time": 4.8, "dir": "down"},
			{"time": 5.15, "dir": "left"},
			{"time": 5.5, "dir": "right"},
			{"time": 5.85, "dir": "up"},
			{"time": 6.2, "dir": "down"},
			{"time": 6.55, "dir": "left"},
			{"time": 6.9, "dir": "up"},
			{"time": 7.25, "dir": "right"},
			{"time": 7.6, "dir": "down"},
			{"time": 7.95, "dir": "up"},
			{"time": 8.3, "dir": "left"},
		],
	},
}

var farm_story_events: Dictionary = {
	"after_battle_1": {
		"lines": [
			"Por primera vez... Elian sintio que era bueno en algo.",
			"Se escuchaba gente improvisando a lo lejos.",
		],
	},
	"after_battle_2": {
		"lines": [
			"La granja empezaba a sentirse mas pequena...",
			"Y el mundo... mas grande.",
		],
	},
	"farm_final": {
		"lines": [
			"Esa noche... algo cambio.",
			"Luis: Ven. Quiero mostrarte algo.",
			"Elian salio escondido de su casa y cruzo la granja en silencio.",
			"Solo se escuchaban grillos, pasos sobre tierra y viento.",
			"A lo lejos, el rap salia de una ventana iluminada.",
			"Andres: Alguna vez has escuchado a alguien decir todo lo que siente?",
			"Andres subio el volumen de la grabadora.",
			"Y asi comenzo todo.",
			"FIN DEL CAPITULO 1 - LA GRANJA",
		],
	},
}


func _ready() -> void:
	_refresh_unlocks()


func is_location_unlocked(location_id: String) -> bool:
	return bool(unlocked_locations.get(location_id, false))


func is_objective_completed(objective_id: String) -> bool:
	if objective_id.is_empty():
		return true
	return bool(completed_objectives.get(objective_id, false))


func get_location(location_id: String) -> Dictionary:
	for location in mapLocations:
		if String(location["id"]) == location_id:
			return location
	return {}


func get_current_location() -> Dictionary:
	return get_location(current_location_id)


func unlock_location(location_id: String) -> void:
	if is_location_unlocked(location_id):
		return

	unlocked_locations[location_id] = true
	_set_location_unlocked_in_data(location_id, true)
	location_unlocked.emit(location_id)


func complete_objective(objective_id: String) -> void:
	if objective_id.is_empty() or is_objective_completed(objective_id):
		return

	completed_objectives[objective_id] = true
	objective_completed.emit(objective_id)
	_refresh_unlocks()


func travel_to_location(location_id: String) -> void:
	if not is_location_unlocked(location_id):
		return

	var location := get_location(location_id)
	if location.is_empty():
		return

	current_location_id = location_id
	current_scene = String(location["scene"])
	location_changed.emit(location_id)
	_apply_arrival_objectives(location_id)

	var scene_path := String(location["scene_path"])
	if get_tree() != null:
		get_tree().change_scene_to_file(scene_path)


func set_current_scene(scene_name: String) -> void:
	current_scene = scene_name


func set_current_location(location_id: String) -> void:
	var location := get_location(location_id)
	if location.is_empty():
		return

	current_location_id = location_id
	current_scene = String(location["scene"])
	_apply_arrival_objectives(location_id)
	location_changed.emit(location_id)


func set_current_objective(objective_text: String) -> void:
	current_objective = objective_text
	currentObjective = objective_text


func add_money(amount: int) -> void:
	if amount <= 0:
		return

	money += amount
	money_changed.emit(money)


func spend_money(amount: int) -> bool:
	if amount <= 0:
		return true

	if money < amount:
		return false

	money -= amount
	money_changed.emit(money)
	return true


func get_money() -> int:
	return money


func get_farm_battle(battle_id: String) -> Dictionary:
	if not farm_battles.has(battle_id):
		return {}

	return farm_battles[battle_id] as Dictionary


func get_selected_farm_battle() -> Dictionary:
	return get_farm_battle(selected_farm_battle_id)


func set_selected_farm_battle(battle_id: String) -> void:
	if not farm_battles.has(battle_id):
		selected_farm_battle_id = ""
		return

	selected_farm_battle_id = battle_id
	farm_battle_changed.emit(battle_id)


func is_farm_battle_completed(battle_id: String) -> bool:
	var battle := get_farm_battle(battle_id)
	if battle.is_empty():
		return false

	return is_objective_completed(String(battle.get("complete_objective", "")))


func is_farm_battle_unlocked(battle_id: String) -> bool:
	var battle := get_farm_battle(battle_id)
	if battle.is_empty():
		return false

	return is_objective_completed(String(battle.get("required_objective", "")))


func get_next_available_farm_battle() -> Dictionary:
	for battle_id in farm_battle_order:
		if is_farm_battle_unlocked(battle_id) and not is_farm_battle_completed(battle_id):
			return get_farm_battle(battle_id)

	return {}


func complete_farm_battle(battle_id: String) -> void:
	var battle := get_farm_battle(battle_id)
	if battle.is_empty():
		return

	complete_objective(String(battle.get("complete_objective", "")))
	pending_farm_story_event = String(battle.get("post_event", ""))

	if battle_id == "luis":
		complete_objective("farm_chapter_completed")


func get_farm_story_lines(event_id: String) -> Array:
	var event_data := farm_story_events.get(event_id, {}) as Dictionary
	return event_data.get("lines", []) as Array


func consume_pending_farm_story_event() -> String:
	var event_id := pending_farm_story_event
	pending_farm_story_event = ""
	return event_id


func _refresh_unlocks() -> void:
	for location in mapLocations:
		var location_id := String(location["id"])
		var required_objective := String(location.get("requiredObjective", ""))
		var should_unlock := bool(location.get("unlocked", false)) or is_objective_completed(required_objective)
		if should_unlock:
			unlocked_locations[location_id] = true
			_set_location_unlocked_in_data(location_id, true)
		else:
			_set_location_unlocked_in_data(location_id, false)
	_update_progress()


func _set_location_unlocked_in_data(location_id: String, is_unlocked: bool) -> void:
	for index in range(mapLocations.size()):
		if String(mapLocations[index]["id"]) == location_id:
			mapLocations[index]["unlocked"] = is_unlocked
			return


func _apply_arrival_objectives(location_id: String) -> void:
	match location_id:
		"city":
			complete_objective("city_arrived")
		"studio":
			complete_objective("studio_visited")
		"urban_park":
			complete_objective("urban_park_visited")


func _update_progress() -> void:
	var unlocked_count := 0
	for location in mapLocations:
		if is_location_unlocked(String(location["id"])):
			unlocked_count += 1

	progress = int(round(float(unlocked_count) / float(mapLocations.size()) * 100.0))

	if (
		is_objective_completed("farm_chapter_completed")
		and is_objective_completed("town_mission_completed")
		and is_objective_completed("first_battle_won")
		and is_objective_completed("city_arrived")
		and is_objective_completed("studio_visited")
		and is_objective_completed("urban_park_visited")
	):
		if not is_objective_completed("all_main_missions_completed"):
			completed_objectives["all_main_missions_completed"] = true
			_set_location_unlocked_in_data("final_stadium", true)
			unlocked_locations["final_stadium"] = true
			progress = 100


# Wrappers con los nombres pedidos en el brief.
func unlockLocation(location_id: String) -> void:
	unlock_location(location_id)


func completeObjective(objective_id: String) -> void:
	complete_objective(objective_id)


func travelToLocation(location_id: String) -> void:
	travel_to_location(location_id)


func setCurrentScene(scene_name: String) -> void:
	set_current_scene(scene_name)


func setCurrentObjective(objective_text: String) -> void:
	set_current_objective(objective_text)


func addMoney(amount: int) -> void:
	add_money(amount)


func spendMoney(amount: int) -> bool:
	return spend_money(amount)
