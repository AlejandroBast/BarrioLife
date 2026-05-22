extends Control

const TUTORIAL_SCENE = "res://scenes/TutorialLevel.tscn"

var controls_panel: PanelContainer


func _ready() -> void:
	MusicManager.stop_music()
	_build_ui()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color(0.055, 0.059, 0.075)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var root := CenterContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var menu := VBoxContainer.new()
	menu.custom_minimum_size = Vector2(430, 0)
	menu.add_theme_constant_override("separation", 18)
	root.add_child(menu)

	var title := Label.new()
	title.text = "BARRIOLIFE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	menu.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Una demo 2D de barrio, ritmo y ganas de cantar"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	menu.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(1, 24)
	menu.add_child(spacer)

	var play_button := _make_button("Jugar")
	play_button.pressed.connect(_on_play_pressed)
	menu.add_child(play_button)

	var tutorial_button := _make_button("Tutorial")
	tutorial_button.pressed.connect(_on_tutorial_pressed)
	menu.add_child(tutorial_button)

	var controls_button := _make_button("Controles")
	controls_button.pressed.connect(_on_controls_pressed)
	menu.add_child(controls_button)

	var quit_button := _make_button("Salir")
	quit_button.pressed.connect(_on_quit_pressed)
	menu.add_child(quit_button)

	controls_panel = _make_controls_panel()
	controls_panel.visible = false
	add_child(controls_panel)


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(320, 54)
	button.add_theme_font_size_override("font_size", 22)
	return button


func _make_controls_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -260
	panel.offset_top = -160
	panel.offset_right = 260
	panel.offset_bottom = 160

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.105, 0.13, 0.96)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 28
	style.content_margin_top = 24
	style.content_margin_right = 28
	style.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", style)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	panel.add_child(content)

	var title := Label.new()
	title.text = "Controles"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	content.add_child(title)

	var body := Label.new()
	body.text = "A / D: moverte\nE: interactuar\nESC: pausar\nBatalla: A/S/W/D o flechas"
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size", 20)
	content.add_child(body)

	var close_button := _make_button("Cerrar")
	close_button.pressed.connect(func() -> void: controls_panel.visible = false)
	content.add_child(close_button)

	return panel


func _on_play_pressed() -> void:
	GameState.travel_to_location("farm")


func _on_tutorial_pressed() -> void:
	get_tree().change_scene_to_file(TUTORIAL_SCENE)


func _on_controls_pressed() -> void:
	controls_panel.visible = true


func _on_quit_pressed() -> void:
	get_tree().quit()
