extends Node2D

const PAUSE_MENU_SCENE = preload("res://scenes/PauseMenu.tscn")

@onready var title_label: Label = $UI/Panel/Content/TitleLabel
@onready var description_label: Label = $UI/Panel/Content/DescriptionLabel
@onready var objective_label: Label = $UI/Panel/Content/ObjectiveLabel
@onready var complete_button: Button = $UI/Panel/Content/CompleteButton


func _ready() -> void:
	MusicManager.stop_music()
	complete_button.pressed.connect(_on_complete_pressed)
	_refresh_location()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.is_action_pressed("pause_game"):
		get_viewport().set_input_as_handled()
		_open_pause_menu()


func _refresh_location() -> void:
	var location := GameState.get_current_location()
	if location.is_empty():
		return

	title_label.text = String(location["name"])
	description_label.text = String(location["description"])
	objective_label.text = _get_objective_text(String(location["id"]))
	complete_button.visible = _get_completion_objective(String(location["id"])) != ""


func _on_complete_pressed() -> void:
	var objective_id := _get_completion_objective(GameState.current_location_id)
	if objective_id.is_empty():
		return

	GameState.complete_objective(objective_id)
	_refresh_location()


func _get_completion_objective(location_id: String) -> String:
	match location_id:
		"town":
			return "town_mission_completed"
		"neighborhood":
			return "first_battle_won"
		"urban_park":
			return "urban_park_visited"
		_:
			return ""


func _get_objective_text(location_id: String) -> String:
	match location_id:
		"town":
			return "Objetivo: completa la mision principal del pueblo para desbloquear el Barrio."
		"neighborhood":
			return "Objetivo: gana la primera batalla importante para desbloquear la Ciudad."
		"city":
			return "Llegaste a la ciudad. El Estudio musical queda desbloqueado."
		"studio":
			return "Visitaste el estudio. El Parque urbano queda desbloqueado."
		"urban_park":
			return "Objetivo: confirma tu progreso final para abrir el Estadio final."
		"final_stadium":
			return "Objetivo final disponible."
		_:
			return "Presiona M para abrir el mapa."


func _open_pause_menu() -> void:
	if get_tree().paused or has_node("PauseMenu"):
		return

	var pause_menu := PAUSE_MENU_SCENE.instantiate()
	add_child(pause_menu)
