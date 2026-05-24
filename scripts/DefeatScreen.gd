extends Control

const BATTLE_SCENE = "res://scenes/BattleScene.tscn"
const TUTORIAL_SCENE = "res://scenes/TutorialLevel.tscn"
const FARM_SCENE = "res://scenes/FarmLevel.tscn"
const MAIN_MENU_SCENE = "res://scenes/MainMenu.tscn"


func _ready() -> void:
	MusicManager.stop_music()
	_build_ui()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color(0.085, 0.055, 0.06)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(430, 0)
	box.add_theme_constant_override("separation", 18)
	center.add_child(box)

	var title := Label.new()
	title.text = "Perdiste la batalla"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 46)
	box.add_child(title)

	var retry_button := _make_button("Reintentar combate")
	retry_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(BATTLE_SCENE))
	box.add_child(retry_button)

	var return_scene := FARM_SCENE if GameState.current_location_id == "farm" else TUTORIAL_SCENE
	var return_text := "Volver a la granja" if GameState.current_location_id == "farm" else "Volver al tutorial"
	var return_button := _make_button(return_text)
	return_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(return_scene))
	box.add_child(return_button)

	var menu_button := _make_button("Menu principal")
	menu_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(MAIN_MENU_SCENE))
	box.add_child(menu_button)

	var quit_button := _make_button("Salir del juego")
	quit_button.pressed.connect(func() -> void: get_tree().quit())
	box.add_child(quit_button)


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(340, 54)
	button.add_theme_font_size_override("font_size", 21)
	return button
