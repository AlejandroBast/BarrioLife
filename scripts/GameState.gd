extends Node

signal location_unlocked(location_id: String)
signal objective_completed(objective_id: String)
signal location_changed(location_id: String)

const FARM_SCENE = "res://scenes/FarmLevel.tscn"
const GENERIC_LOCATION_SCENE = "res://scenes/LocationScene.tscn"

var current_location_id: String = "farm"
var current_scene: String = "FarmScene"
var progress: int = 0

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
		"unlockRequirement": "Completa el tutorial de la granja.",
		"requiredObjective": "farm_tutorial_completed",
		"scene": "TownScene",
		"scene_path": GENERIC_LOCATION_SCENE,
	},
	{
		"id": "neighborhood",
		"name": "Barrio",
		"description": "Zona donde Elian empieza a construir su identidad musical.",
		"unlocked": false,
		"unlockRequirement": "Completa la mision principal del pueblo.",
		"requiredObjective": "town_mission_completed",
		"scene": "NeighborhoodScene",
		"scene_path": GENERIC_LOCATION_SCENE,
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
		is_objective_completed("farm_tutorial_completed")
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
