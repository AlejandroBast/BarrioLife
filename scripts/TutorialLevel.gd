extends Node2D

const BATTLE_SCENE = "res://scenes/BattleScene.tscn"
const PAUSE_MENU_SCENE = preload("res://scenes/PauseMenu.tscn")
const INTERACT_DISTANCE = 210.0

@onready var help_label: Label = $UI/HelpPanel/HelpLabel
@onready var interact_panel: PanelContainer = $UI/InteractPanel
@onready var interact_label: Label = $UI/InteractPanel/InteractLabel
@onready var player: CharacterBody2D = $Player
@onready var battle_trigger: Area2D = $BattleTrigger

var can_start_battle: bool = false
var changing_scene: bool = false
var left_revealed: bool = false
var right_revealed: bool = false
var pause_revealed: bool = false
var stage_revealed: bool = false


func _ready() -> void:
	MusicManager.stop_music()
	_update_tutorial_text()


func _process(_delta: float) -> void:
	can_start_battle = _is_player_near_battle_trigger()
	interact_panel.visible = can_start_battle
	_update_revealed_controls()
	_update_tutorial_text()

	if can_start_battle and Input.is_action_pressed("interact"):
		_start_battle()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.is_action_pressed("pause_game"):
		get_viewport().set_input_as_handled()
		_open_pause_menu()


func _on_battle_trigger_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		can_start_battle = true
		interact_panel.visible = true


func _on_battle_trigger_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		can_start_battle = false
		interact_panel.visible = false


func _is_player_near_battle_trigger() -> bool:
	if player == null or battle_trigger == null:
		return false

	return player.global_position.distance_to(battle_trigger.global_position) <= INTERACT_DISTANCE


func _update_revealed_controls() -> void:
	if player == null:
		return

	var player_x: float = player.global_position.x
	if Input.is_action_pressed("move_left") or player_x >= 180.0:
		left_revealed = true
	if Input.is_action_pressed("move_right") or player_x >= 360.0:
		right_revealed = true
	if player_x >= 760.0:
		pause_revealed = true
	if player_x >= 1160.0 or can_start_battle:
		stage_revealed = true


func _update_tutorial_text() -> void:
	var lines: Array[String] = ["Tutorial"]
	var move_right_label := SettingsManager.get_action_label("move_right")
	var move_left_label := SettingsManager.get_action_label("move_left")
	var pause_label := SettingsManager.get_action_label("pause_game")
	var interact_label_text := SettingsManager.get_action_label("interact")

	if not right_revealed:
		lines.append("%s: caminar hacia la derecha" % move_right_label)
	elif not left_revealed:
		lines.append("%s: caminar hacia la izquierda" % move_left_label)
	else:
		lines.append("%s: izquierda" % move_left_label)
		lines.append("%s: derecha" % move_right_label)

	if pause_revealed:
		lines.append("%s: pausar" % pause_label)
	if stage_revealed:
		lines.append("Llega al escenario de practica")
	if can_start_battle:
		lines.append("%s: hablar y empezar" % interact_label_text)

	help_label.text = _format_lines(lines)
	interact_label.text = "Escenario de practica\nPresiona %s para cantar\nEn combate, presiona la tecla que coincida con la nota." % interact_label_text


func _format_lines(lines: Array[String]) -> String:
	var result := ""
	for line_index in range(lines.size()):
		if line_index > 0:
			result += "\n"
		result += lines[line_index]
	return result


func _start_battle() -> void:
	if changing_scene:
		return

	changing_scene = true
	get_tree().change_scene_to_file(BATTLE_SCENE)


func _open_pause_menu() -> void:
	if get_tree().paused or has_node("PauseMenu"):
		return

	var pause_menu := PAUSE_MENU_SCENE.instantiate()
	add_child(pause_menu)
