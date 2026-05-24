extends Control

const TUTORIAL_SCENE = "res://scenes/TutorialLevel.tscn"
const MENU_BACKGROUND_TEXTURE = "res://assets/sprites/ui/main_menu_bg.png"
const MENU_TITLE_TEXTURE = "res://assets/sprites/ui/main_menu_title.png"
const BUTTON_PLANK_TEXTURE = "res://assets/sprites/ui/button_plank.png"
const FALLBACK_BACKGROUND_TEXTURE = "res://assets/sprites/neighborhood_bg_01.png"

var controls_panel: PanelContainer
var controls_body_label: Label
var options_panel: OptionsPanel


func _ready() -> void:
	MusicManager.stop_music()
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()


func _build_ui() -> void:
	_add_background()

	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 72)
	root.add_theme_constant_override("margin_top", 38)
	root.add_theme_constant_override("margin_right", 72)
	root.add_theme_constant_override("margin_bottom", 46)
	add_child(root)

	var screen_layout := HBoxContainer.new()
	screen_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	screen_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	screen_layout.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(screen_layout)

	var menu_anchor := CenterContainer.new()
	menu_anchor.custom_minimum_size = Vector2(470, 0)
	menu_anchor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	screen_layout.add_child(menu_anchor)

	var menu := VBoxContainer.new()
	menu.custom_minimum_size = Vector2(430, 0)
	menu.add_theme_constant_override("separation", 14)
	menu_anchor.add_child(menu)

	var title_texture := _load_texture(MENU_TITLE_TEXTURE)
	if title_texture != null:
		var title_image := TextureRect.new()
		title_image.texture = title_texture
		title_image.custom_minimum_size = Vector2(430, 230)
		title_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		title_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		title_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		menu.add_child(title_image)
	else:
		var title := Label.new()
		title.text = "BARRIOLIFE"
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 64)
		title.add_theme_color_override("font_color", Color(0.74, 0.97, 0.95))
		title.add_theme_color_override("font_shadow_color", Color(0.02, 0.01, 0.025, 0.9))
		title.add_theme_constant_override("shadow_offset_x", 4)
		title.add_theme_constant_override("shadow_offset_y", 5)
		menu.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Una historia de granja, barrio y voz propia"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(1.0, 0.91, 0.67))
	subtitle.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.7))
	subtitle.add_theme_constant_override("shadow_offset_x", 2)
	subtitle.add_theme_constant_override("shadow_offset_y", 2)
	menu.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(1, 12)
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

	var options_button := _make_button("Opciones")
	options_button.pressed.connect(_on_options_pressed)
	menu.add_child(options_button)

	var quit_button := _make_button("Salir")
	quit_button.pressed.connect(_on_quit_pressed)
	menu.add_child(quit_button)

	controls_panel = _make_controls_panel()
	controls_panel.visible = false
	add_child(controls_panel)


func _add_background() -> void:
	var texture := _load_texture(MENU_BACKGROUND_TEXTURE)
	if texture == null:
		texture = _load_texture(FALLBACK_BACKGROUND_TEXTURE)

	if texture != null:
		var background := TextureRect.new()
		background.texture = texture
		background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		background.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(background)
	else:
		var background_color := ColorRect.new()
		background_color.color = Color(0.045, 0.047, 0.065)
		background_color.mouse_filter = Control.MOUSE_FILTER_IGNORE
		background_color.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(background_color)

	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.015, 0.03, 0.28)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(340, 62)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 23)
	button.add_theme_color_override("font_color", Color(1.0, 0.92, 0.72))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.98, 0.84))
	button.add_theme_color_override("font_pressed_color", Color(0.96, 0.78, 0.46))
	button.add_theme_color_override("font_shadow_color", Color(0.09, 0.035, 0.005, 0.9))
	button.add_theme_constant_override("shadow_offset_x", 2)
	button.add_theme_constant_override("shadow_offset_y", 3)

	var plank_texture := _load_texture(BUTTON_PLANK_TEXTURE)
	if plank_texture != null:
		var plank_style := _make_plank_style(plank_texture)
		button.add_theme_stylebox_override("normal", plank_style)
		button.add_theme_stylebox_override("hover", plank_style)
		button.add_theme_stylebox_override("pressed", plank_style)
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	else:
		button.add_theme_stylebox_override("normal", _make_flat_button_style(Color(0.42, 0.22, 0.09, 0.94)))
		button.add_theme_stylebox_override("hover", _make_flat_button_style(Color(0.55, 0.29, 0.12, 0.98)))
		button.add_theme_stylebox_override("pressed", _make_flat_button_style(Color(0.30, 0.15, 0.06, 0.98)))
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	return button


func _make_plank_style(texture: Texture2D) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.content_margin_left = 38
	style.content_margin_top = 14
	style.content_margin_right = 38
	style.content_margin_bottom = 14
	return style


func _make_flat_button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.11, 0.055, 0.02, 1.0)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 30
	style.content_margin_top = 14
	style.content_margin_right = 30
	style.content_margin_bottom = 14
	return style


func _make_controls_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -260
	panel.offset_top = -160
	panel.offset_right = 260
	panel.offset_bottom = 160

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.055, 0.04, 0.94)
	style.border_color = Color(0.78, 0.48, 0.20, 0.85)
	style.set_border_width_all(2)
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
	title.add_theme_color_override("font_color", Color(1.0, 0.90, 0.68))
	content.add_child(title)

	controls_body_label = Label.new()
	controls_body_label.text = _get_controls_text()
	controls_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_body_label.add_theme_font_size_override("font_size", 20)
	controls_body_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.84))
	content.add_child(controls_body_label)

	var close_button := _make_button("Cerrar")
	close_button.pressed.connect(func() -> void: controls_panel.visible = false)
	content.add_child(close_button)

	return panel


func _on_play_pressed() -> void:
	GameState.travel_to_location("farm")


func _on_tutorial_pressed() -> void:
	get_tree().change_scene_to_file(TUTORIAL_SCENE)


func _on_controls_pressed() -> void:
	controls_body_label.text = _get_controls_text()
	controls_panel.visible = true


func _get_controls_text() -> String:
	return "%s / %s: moverte\n%s: interactuar\n%s: pausar\nBatalla: %s / %s / %s / %s" % [
		SettingsManager.get_action_label("move_left"),
		SettingsManager.get_action_label("move_right"),
		SettingsManager.get_action_label("interact"),
		SettingsManager.get_action_label("pause_game"),
		SettingsManager.get_action_label("note_left"),
		SettingsManager.get_action_label("note_down"),
		SettingsManager.get_action_label("note_up"),
		SettingsManager.get_action_label("note_right"),
	]


func _on_options_pressed() -> void:
	if options_panel != null and is_instance_valid(options_panel):
		return

	options_panel = OptionsPanel.new()
	options_panel.closed.connect(func() -> void:
		options_panel = null
	)
	add_child(options_panel)


func _on_quit_pressed() -> void:
	get_tree().quit()


func _load_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
