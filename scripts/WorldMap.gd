extends CanvasLayer

const CARD_MIN_SIZE = Vector2(250, 175)

var is_open: bool = false
var card_grid: GridContainer
var title_label: Label
var status_label: Label
var background: ColorRect
var panel: PanelContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	close_map()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M:
		if not is_open and not _can_open_in_current_scene():
			return
		get_viewport().set_input_as_handled()
		toggle_map()


func open_map() -> void:
	is_open = true
	visible = true
	get_tree().paused = true
	_refresh_map()


func close_map() -> void:
	is_open = false
	visible = false
	if get_tree() != null:
		get_tree().paused = false


func toggle_map() -> void:
	if is_open:
		close_map()
	else:
		open_map()


func travel_to_location(location_id: String) -> void:
	close_map()
	GameState.travel_to_location(location_id)


func unlock_location(location_id: String) -> void:
	GameState.unlock_location(location_id)
	_refresh_map()


func complete_objective(objective_id: String) -> void:
	GameState.complete_objective(objective_id)
	_refresh_map()


# Wrappers con los nombres pedidos en el brief.
func openMap() -> void:
	open_map()


func closeMap() -> void:
	close_map()


func toggleMap() -> void:
	toggle_map()


func travelToLocation(location_id: String) -> void:
	travel_to_location(location_id)


func unlockLocation(location_id: String) -> void:
	unlock_location(location_id)


func completeObjective(objective_id: String) -> void:
	complete_objective(objective_id)


func _build_ui() -> void:
	background = ColorRect.new()
	background.color = Color(0.0, 0.0, 0.0, 0.68)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(1080, 620)
	center.add_child(panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.055, 0.055, 0.075, 0.96)
	panel_style.border_color = Color(0.55, 0.22, 0.82, 0.9)
	panel_style.set_border_width_all(2)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.content_margin_left = 24
	panel_style.content_margin_top = 22
	panel_style.content_margin_right = 24
	panel_style.content_margin_bottom = 22
	panel.add_theme_stylebox_override("panel", panel_style)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	panel.add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 18)
	root.add_child(header)

	var header_text := VBoxContainer.new()
	header_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_text)

	title_label = Label.new()
	title_label.text = "Mapa de BARRIOLIFE"
	title_label.add_theme_font_size_override("font_size", 34)
	header_text.add_child(title_label)

	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 17)
	header_text.add_child(status_label)

	var close_button := Button.new()
	close_button.text = "Cerrar (M)"
	close_button.custom_minimum_size = Vector2(130, 44)
	close_button.pressed.connect(close_map)
	header.add_child(close_button)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(1020, 500)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	card_grid = GridContainer.new()
	card_grid.columns = 3
	card_grid.add_theme_constant_override("h_separation", 14)
	card_grid.add_theme_constant_override("v_separation", 14)
	scroll.add_child(card_grid)


func _can_open_in_current_scene() -> bool:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return false

	return current_scene.name in ["FarmLevel", "LocationScene"]


func _refresh_map() -> void:
	for child in card_grid.get_children():
		child.queue_free()

	status_label.text = "Ubicacion actual: %s  |  Progreso: %d%%" % [
		String(GameState.get_current_location().get("name", "Desconocida")),
		GameState.progress,
	]

	for location in GameState.mapLocations:
		card_grid.add_child(_build_location_card(location))


func _build_location_card(location: Dictionary) -> Control:
	var location_id := String(location["id"])
	var is_unlocked := GameState.is_location_unlocked(location_id)

	var card := PanelContainer.new()
	card.custom_minimum_size = CARD_MIN_SIZE

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.095, 0.10, 0.13, 0.98) if is_unlocked else Color(0.08, 0.08, 0.085, 0.82)
	style.border_color = Color(0.68, 0.30, 0.90, 0.9) if is_unlocked else Color(0.24, 0.24, 0.26, 0.9)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 14
	style.content_margin_top = 12
	style.content_margin_right = 14
	style.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	card.add_child(box)

	var name_label := Label.new()
	name_label.text = "%s%s" % [String(location["name"]), "" if is_unlocked else "  [LOCK]"]
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.modulate = Color.WHITE if is_unlocked else Color(0.62, 0.62, 0.66)
	box.add_child(name_label)

	var state_label := Label.new()
	state_label.text = "Estado: desbloqueado" if is_unlocked else "Estado: bloqueado"
	state_label.modulate = Color(0.58, 0.95, 0.62) if is_unlocked else Color(0.78, 0.70, 0.70)
	box.add_child(state_label)

	var desc_label := Label.new()
	desc_label.text = String(location["description"])
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(220, 52)
	desc_label.modulate = Color.WHITE if is_unlocked else Color(0.63, 0.63, 0.67)
	box.add_child(desc_label)

	var requirement_label := Label.new()
	requirement_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	requirement_label.custom_minimum_size = Vector2(220, 42)
	if is_unlocked:
		requirement_label.text = "Listo para viajar."
	else:
		requirement_label.text = "Candado: %s" % String(location["unlockRequirement"])
		requirement_label.modulate = Color(0.92, 0.78, 0.45)
	box.add_child(requirement_label)

	if is_unlocked:
		var travel_button := Button.new()
		travel_button.text = "Viajar"
		travel_button.custom_minimum_size = Vector2(120, 38)
		travel_button.pressed.connect(func() -> void: travel_to_location(location_id))
		box.add_child(travel_button)

	return card
