extends Control

const TUTORIAL_SCENE = "res://scenes/TutorialLevel.tscn"
const MAIN_MENU_SCENE = "res://scenes/MainMenu.tscn"


func _ready() -> void:
	if GameState.current_location_id == "neighborhood":
		GameState.complete_objective("first_battle_won")
	_build_ui()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color(0.055, 0.08, 0.06)
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
	title.text = "Ganaste la batalla"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 46)
	box.add_child(title)

	var tutorial_button := _make_button("Volver al tutorial")
	tutorial_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(TUTORIAL_SCENE))
	box.add_child(tutorial_button)

	var menu_button := _make_button("Menu principal")
	menu_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(MAIN_MENU_SCENE))
	box.add_child(menu_button)


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(340, 54)
	button.add_theme_font_size_override("font_size", 21)
	return button
