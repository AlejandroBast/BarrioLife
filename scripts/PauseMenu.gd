extends CanvasLayer

const MAIN_MENU_SCENE = "res://scenes/MainMenu.tscn"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	get_tree().paused = true
	_build_ui()


func _build_ui() -> void:
	var dimmer := ColorRect.new()
	dimmer.color = Color(0, 0, 0, 0.58)
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dimmer)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(360, 260)
	center.add_child(panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.085, 0.105, 0.98)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 28
	style.content_margin_top = 26
	style.content_margin_right = 28
	style.content_margin_bottom = 26
	panel.add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)

	var title := Label.new()
	title.text = "Pausa"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	box.add_child(title)

	var resume_button := _make_button("Continuar")
	resume_button.pressed.connect(_on_resume_pressed)
	box.add_child(resume_button)

	var menu_button := _make_button("Menu principal")
	menu_button.pressed.connect(_on_menu_pressed)
	box.add_child(menu_button)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_on_resume_pressed()


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(260, 52)
	button.add_theme_font_size_override("font_size", 20)
	return button


func _on_resume_pressed() -> void:
	get_tree().paused = false
	queue_free()


func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
