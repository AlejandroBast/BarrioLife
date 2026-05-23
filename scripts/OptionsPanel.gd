class_name OptionsPanel
extends CanvasLayer

signal closed

var waiting_action: String = ""
var waiting_button: Button
var music_value_label: Label
var volume_slider: HSlider
var mute_check: CheckBox
var resolution_option: OptionButton
var control_buttons: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 130
	_build_ui()
	_refresh_values()

	SettingsManager.music_settings_changed.connect(_refresh_music_values)
	SettingsManager.controls_changed.connect(_refresh_control_values)
	SettingsManager.resolution_changed.connect(_refresh_resolution_values)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()

		if waiting_action != "":
			_finish_rebind(event.keycode)
			return

		if event.is_action_pressed("pause_game"):
			close_options()


func close_options() -> void:
	closed.emit()
	queue_free()


func _build_ui() -> void:
	var dimmer := ColorRect.new()
	dimmer.color = Color(0, 0, 0, 0.64)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dimmer)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 610)
	center.add_child(panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.075, 0.095, 0.98)
	style.border_color = Color(0.48, 0.30, 0.72, 0.9)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 24
	style.content_margin_top = 20
	style.content_margin_right = 24
	style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", style)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	panel.add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)

	var title := Label.new()
	title.text = "Opciones"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 34)
	header.add_child(title)

	var close_button := Button.new()
	close_button.text = "Cerrar"
	close_button.custom_minimum_size = Vector2(115, 42)
	close_button.pressed.connect(close_options)
	header.add_child(close_button)

	var tabs := TabContainer.new()
	tabs.custom_minimum_size = Vector2(700, 500)
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(tabs)

	tabs.add_child(_build_music_tab())
	tabs.add_child(_build_controls_tab())
	tabs.add_child(_build_resolution_tab())


func _build_music_tab() -> Control:
	var tab := VBoxContainer.new()
	tab.name = "Musica"
	tab.add_theme_constant_override("separation", 18)

	var title := Label.new()
	title.text = "Musica"
	title.add_theme_font_size_override("font_size", 26)
	tab.add_child(title)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	tab.add_child(row)

	var label := Label.new()
	label.text = "Volumen"
	label.custom_minimum_size = Vector2(120, 28)
	row.add_child(label)

	volume_slider = HSlider.new()
	volume_slider.min_value = 0
	volume_slider.max_value = 100
	volume_slider.step = 1
	volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume_slider.value_changed.connect(_on_volume_changed)
	row.add_child(volume_slider)

	music_value_label = Label.new()
	music_value_label.custom_minimum_size = Vector2(70, 28)
	row.add_child(music_value_label)

	mute_check = CheckBox.new()
	mute_check.text = "Silenciar musica"
	mute_check.toggled.connect(_on_mute_toggled)
	tab.add_child(mute_check)

	var hint := Label.new()
	hint.text = "Los cambios se aplican al instante a la musica del escenario."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.modulate = Color(0.78, 0.78, 0.84)
	tab.add_child(hint)

	return tab


func _build_controls_tab() -> Control:
	var tab := VBoxContainer.new()
	tab.name = "Controles"
	tab.add_theme_constant_override("separation", 10)

	var title := Label.new()
	title.text = "Controles"
	title.add_theme_font_size_override("font_size", 26)
	tab.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(690, 380)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab.add_child(scroll)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)

	for definition in SettingsManager.ACTION_DEFINITIONS:
		var action_id := String(definition["id"])
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		list.add_child(row)

		var label := Label.new()
		label.text = String(definition["name"])
		label.custom_minimum_size = Vector2(250, 36)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(label)

		var button := Button.new()
		button.custom_minimum_size = Vector2(220, 36)
		row.add_child(button)

		var captured_action_id := action_id
		var captured_button := button
		button.pressed.connect(func() -> void:
			_start_rebind(captured_action_id, captured_button)
		)

		control_buttons[action_id] = button

	var reset_button := Button.new()
	reset_button.text = "Restaurar controles"
	reset_button.custom_minimum_size = Vector2(220, 42)
	reset_button.pressed.connect(func() -> void:
		waiting_action = ""
		waiting_button = null
		SettingsManager.reset_controls()
	)
	tab.add_child(reset_button)

	return tab


func _build_resolution_tab() -> Control:
	var tab := VBoxContainer.new()
	tab.name = "Resolucion"
	tab.add_theme_constant_override("separation", 16)

	var title := Label.new()
	title.text = "Resolucion"
	title.add_theme_font_size_override("font_size", 26)
	tab.add_child(title)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	tab.add_child(row)

	var label := Label.new()
	label.text = "Tamano de ventana"
	label.custom_minimum_size = Vector2(190, 36)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)

	resolution_option = OptionButton.new()
	resolution_option.custom_minimum_size = Vector2(220, 40)
	for index in range(SettingsManager.RESOLUTIONS.size()):
		resolution_option.add_item(SettingsManager.get_resolution_label(index), index)
	resolution_option.item_selected.connect(_on_resolution_selected)
	row.add_child(resolution_option)

	var hint := Label.new()
	hint.text = "Incluye 1280 x 720, 1366 x 768, 1600 x 900 y 1920 x 1080."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.modulate = Color(0.78, 0.78, 0.84)
	tab.add_child(hint)

	return tab


func _refresh_values() -> void:
	_refresh_music_values()
	_refresh_control_values()
	_refresh_resolution_values()


func _refresh_music_values() -> void:
	if volume_slider != null:
		volume_slider.set_value_no_signal(SettingsManager.music_volume * 100.0)
	if mute_check != null:
		mute_check.set_pressed_no_signal(SettingsManager.music_muted)
	if music_value_label != null:
		music_value_label.text = "%d%%" % int(round(SettingsManager.music_volume * 100.0))


func _refresh_control_values() -> void:
	for action_id in control_buttons.keys():
		var button := control_buttons[action_id] as Button
		if button != null:
			button.text = SettingsManager.get_action_label(String(action_id))


func _refresh_resolution_values() -> void:
	if resolution_option != null:
		resolution_option.select(SettingsManager.resolution_index)


func _on_volume_changed(value: float) -> void:
	SettingsManager.set_music_volume(value / 100.0)


func _on_mute_toggled(enabled: bool) -> void:
	SettingsManager.set_music_muted(enabled)


func _on_resolution_selected(index: int) -> void:
	SettingsManager.set_resolution_index(index)


func _start_rebind(action_id: String, button: Button) -> void:
	waiting_action = action_id
	waiting_button = button
	button.text = "Presiona una tecla..."


func _finish_rebind(keycode: Key) -> void:
	SettingsManager.rebind_primary_key(waiting_action, keycode)
	waiting_action = ""
	waiting_button = null
	_refresh_control_values()
