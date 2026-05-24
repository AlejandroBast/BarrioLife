extends Node

signal settings_changed
signal music_settings_changed
signal controls_changed
signal resolution_changed

const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
]

const ACTION_DEFINITIONS: Array[Dictionary] = [
	{"id": "move_left", "name": "Mover izquierda", "keys": [KEY_A, KEY_LEFT]},
	{"id": "move_right", "name": "Mover derecha", "keys": [KEY_D, KEY_RIGHT]},
	{"id": "interact", "name": "Interactuar", "keys": [KEY_E]},
	{"id": "open_map", "name": "Abrir mapa", "keys": [KEY_M]},
	{"id": "pause_game", "name": "Pausar", "keys": [KEY_ESCAPE]},
	{"id": "note_left", "name": "Nota izquierda", "keys": [KEY_A, KEY_LEFT]},
	{"id": "note_down", "name": "Nota abajo", "keys": [KEY_S, KEY_DOWN]},
	{"id": "note_up", "name": "Nota arriba", "keys": [KEY_W, KEY_UP]},
	{"id": "note_right", "name": "Nota derecha", "keys": [KEY_D, KEY_RIGHT]},
]

var music_volume: float = 0.55
var music_muted: bool = false
var resolution_index: int = 0
var action_keys: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	reset_controls(false)
	apply_resolution()


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	music_settings_changed.emit()
	settings_changed.emit()


func set_music_muted(value: bool) -> void:
	music_muted = value
	music_settings_changed.emit()
	settings_changed.emit()


func get_music_volume_db() -> float:
	if music_muted or music_volume <= 0.0:
		return -60.0

	return linear_to_db(music_volume)


func set_resolution_index(index: int) -> void:
	resolution_index = clampi(index, 0, RESOLUTIONS.size() - 1)
	apply_resolution()
	call_deferred("_apply_resolution_deferred", RESOLUTIONS[resolution_index])
	resolution_changed.emit()
	settings_changed.emit()


func apply_resolution() -> void:
	var size: Vector2i = RESOLUTIONS[resolution_index]
	_apply_resolution_deferred(size)


func _apply_resolution_deferred(size: Vector2i) -> void:
	var window := get_window()
	if window != null:
		window.mode = Window.MODE_WINDOWED
		window.size = size

	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(size)
	_center_window(size)


func get_resolution_label(index: int) -> String:
	var size: Vector2i = RESOLUTIONS[index]
	return "%d x %d" % [size.x, size.y]


func get_action_name(action_id: String) -> String:
	for definition in ACTION_DEFINITIONS:
		if String(definition["id"]) == action_id:
			return String(definition["name"])

	return action_id


func get_action_label(action_id: String) -> String:
	var keys: Array = action_keys.get(action_id, [])
	var labels: Array[String] = []

	for key in keys:
		labels.append(_key_to_text(int(key)))

	return " / ".join(labels) if not labels.is_empty() else "Sin tecla"


func rebind_primary_key(action_id: String, keycode: Key) -> void:
	if not action_keys.has(action_id):
		return

	var previous_keys: Array = action_keys[action_id]
	var new_keys: Array[int] = [int(keycode)]

	for index in range(1, previous_keys.size()):
		var alternate_key: int = int(previous_keys[index])
		if alternate_key != int(keycode):
			new_keys.append(alternate_key)

	action_keys[action_id] = new_keys
	_apply_action_to_input_map(action_id, new_keys)
	controls_changed.emit()
	settings_changed.emit()


func reset_controls(emit_signal: bool = true) -> void:
	action_keys.clear()

	for definition in ACTION_DEFINITIONS:
		var action_id := String(definition["id"])
		var keys: Array[int] = []
		for key in definition["keys"]:
			keys.append(int(key))

		action_keys[action_id] = keys
		_apply_action_to_input_map(action_id, keys)

	if emit_signal:
		controls_changed.emit()
		settings_changed.emit()


func _apply_action_to_input_map(action_id: String, keys: Array) -> void:
	if not InputMap.has_action(action_id):
		InputMap.add_action(action_id)

	InputMap.action_erase_events(action_id)

	for key in keys:
		var event := InputEventKey.new()
		event.keycode = int(key)
		InputMap.action_add_event(action_id, event)


func _key_to_text(keycode: int) -> String:
	if keycode == KEY_ESCAPE:
		return "ESC"

	var text := OS.get_keycode_string(keycode)
	return text if text != "" else str(int(keycode))


func _center_window(size: Vector2i) -> void:
	var screen_size := DisplayServer.screen_get_size()
	var target_position := Vector2i(
		maxi(0, int((screen_size.x - size.x) * 0.5)),
		maxi(0, int((screen_size.y - size.y) * 0.5))
	)
	DisplayServer.window_set_position(target_position)
	
