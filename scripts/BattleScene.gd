extends Node2D

const VICTORY_SCENE = "res://scenes/VictoryScreen.tscn"
const DEFEAT_SCENE = "res://scenes/DefeatScreen.tscn"
const PAUSE_MENU_SCENE = preload("res://scenes/PauseMenu.tscn")

const NOTE_SPEED = 360.0
const HIT_Y = 560.0
const SPAWN_Y = -60.0
const HIT_WINDOW = 46.0
const MISS_Y = 630.0
const MAX_HEALTH = 100
const MISS_DAMAGE = 12
const HIT_SCORE = 100
const INTRO_DURATION = 3.0

const DIRECTIONS = ["left", "down", "up", "right"]
const DIR_COLORS = {
	"left": Color(0.95, 0.28, 0.24),
	"down": Color(0.26, 0.66, 1.0),
	"up": Color(0.42, 0.9, 0.42),
	"right": Color(1.0, 0.78, 0.23),
}
const COLUMN_X = {
	"left": 455.0,
	"down": 555.0,
	"up": 655.0,
	"right": 755.0,
}

# Patron simple y editable para prototipar la cancion.
var note_pattern: Array[Dictionary] = [
	{"time": 1.0, "dir": "left"},
	{"time": 1.5, "dir": "down"},
	{"time": 2.0, "dir": "up"},
	{"time": 2.5, "dir": "right"},
	{"time": 3.1, "dir": "left"},
	{"time": 3.6, "dir": "up"},
	{"time": 4.1, "dir": "down"},
	{"time": 4.6, "dir": "right"},
	{"time": 5.2, "dir": "down"},
	{"time": 5.7, "dir": "left"},
	{"time": 6.2, "dir": "right"},
	{"time": 6.7, "dir": "up"},
	{"time": 7.3, "dir": "left"},
	{"time": 7.8, "dir": "down"},
	{"time": 8.3, "dir": "up"},
	{"time": 8.8, "dir": "right"},
]

var active_notes: Array[Dictionary] = []
var elapsed_time: float = 0.0
var next_note_index: int = 0
var score: int = 0
var combo: int = 0
var health: int = MAX_HEALTH
var song_finished: bool = false
var battle_finished: bool = false
var intro_remaining: float = INTRO_DURATION

var score_label: Label
var combo_label: Label
var message_label: Label
var health_bar: ProgressBar
var note_layer: Node2D
var intro_panel: PanelContainer
var intro_label: Label


func _ready() -> void:
	MusicManager.stop_music()
	_build_battle()


func _process(delta: float) -> void:
	if battle_finished:
		return

	if intro_remaining > 0.0:
		_update_intro(delta)
		return

	elapsed_time += delta
	_spawn_due_notes()
	_update_notes(delta)

	if battle_finished:
		return

	_check_song_end()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed("pause_game"):
			get_viewport().set_input_as_handled()
			_open_pause_menu()
			return

		var direction: String = _direction_from_input(event)
		if direction != "":
			get_viewport().set_input_as_handled()
			_try_hit(direction)


func _build_battle() -> void:
	var background := ColorRect.new()
	background.color = Color(0.06, 0.055, 0.08)
	background.size = Vector2(1280, 720)
	add_child(background)

	var stage_floor := Polygon2D.new()
	stage_floor.color = Color(0.14, 0.125, 0.14)
	stage_floor.polygon = PackedVector2Array([
		Vector2(0, 620),
		Vector2(1280, 620),
		Vector2(1280, 720),
		Vector2(0, 720),
	])
	add_child(stage_floor)

	_add_performer(Vector2(180, 485), Color(0.82, 0.28, 0.20), "Tu")
	_add_performer(Vector2(1080, 485), Color(0.24, 0.48, 0.82), "Rival")
	_add_microphone(Vector2(270, 520))
	_add_microphone(Vector2(995, 520))

	note_layer = Node2D.new()
	note_layer.name = "Notes"
	add_child(note_layer)

	_build_columns()
	_build_ui()
	_build_intro_panel()


func _add_performer(spawn_position: Vector2, color: Color, label_text: String) -> void:
	var body := Polygon2D.new()
	body.position = spawn_position
	body.color = color
	body.polygon = PackedVector2Array([
		Vector2(-34, -110),
		Vector2(34, -110),
		Vector2(48, 40),
		Vector2(-48, 40),
	])
	add_child(body)

	var head := Polygon2D.new()
	head.position = spawn_position + Vector2(0, -145)
	head.color = Color(0.93, 0.74, 0.58)
	head.polygon = PackedVector2Array([
		Vector2(-34, -34),
		Vector2(34, -34),
		Vector2(40, 18),
		Vector2(16, 42),
		Vector2(-18, 42),
		Vector2(-40, 18),
	])
	add_child(head)

	var name_label := Label.new()
	name_label.text = label_text
	name_label.position = spawn_position + Vector2(-42, 52)
	name_label.add_theme_font_size_override("font_size", 22)
	add_child(name_label)


func _add_microphone(spawn_position: Vector2) -> void:
	var mic := Line2D.new()
	mic.position = spawn_position
	mic.points = PackedVector2Array([
		Vector2(0, -90),
		Vector2(0, 20),
		Vector2(-24, 40),
		Vector2(24, 40),
	])
	mic.width = 5.0
	mic.default_color = Color(0.88, 0.84, 0.74)
	add_child(mic)


func _build_columns() -> void:
	for direction in DIRECTIONS:
		var x_position: float = float(COLUMN_X[direction])

		var lane := ColorRect.new()
		lane.position = Vector2(x_position - 38.0, 80.0)
		lane.size = Vector2(76.0, 540.0)
		lane.color = Color(1, 1, 1, 0.045)
		add_child(lane)

		var hit_zone := ColorRect.new()
		var hit_color: Color = Color(DIR_COLORS[direction])
		hit_color.a = 0.62
		hit_zone.position = Vector2(x_position - 34.0, HIT_Y - 34.0)
		hit_zone.size = Vector2(68.0, 68.0)
		hit_zone.color = hit_color
		add_child(hit_zone)

		var key_label := Label.new()
		key_label.text = _get_note_key_label(direction)
		key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key_label.position = Vector2(x_position - 45.0, HIT_Y + 45.0)
		key_label.size = Vector2(90.0, 28.0)
		key_label.add_theme_font_size_override("font_size", 18)
		add_child(key_label)


func _build_ui() -> void:
	score_label = Label.new()
	score_label.position = Vector2(32, 26)
	score_label.add_theme_font_size_override("font_size", 26)
	add_child(score_label)

	combo_label = Label.new()
	combo_label.position = Vector2(32, 62)
	combo_label.add_theme_font_size_override("font_size", 22)
	add_child(combo_label)

	health_bar = ProgressBar.new()
	health_bar.position = Vector2(32, 104)
	health_bar.size = Vector2(300, 28)
	health_bar.max_value = MAX_HEALTH
	health_bar.value = health
	add_child(health_bar)

	message_label = Label.new()
	message_label.text = ""
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.position = Vector2(500, 28)
	message_label.size = Vector2(280, 52)
	message_label.add_theme_font_size_override("font_size", 34)
	add_child(message_label)

	_update_ui()


func _build_intro_panel() -> void:
	intro_panel = PanelContainer.new()
	intro_panel.position = Vector2(390, 215)
	intro_panel.size = Vector2(500, 170)
	add_child(intro_panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.055, 0.075, 0.92)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 24
	style.content_margin_top = 18
	style.content_margin_right = 24
	style.content_margin_bottom = 18
	intro_panel.add_theme_stylebox_override("panel", style)

	intro_label = Label.new()
	intro_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	intro_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro_label.add_theme_font_size_override("font_size", 24)
	intro_panel.add_child(intro_label)
	_update_intro_text()


func _update_intro(delta: float) -> void:
	intro_remaining = maxf(0.0, intro_remaining - delta)
	_update_intro_text()

	if intro_remaining <= 0.0:
		intro_panel.visible = false


func _update_intro_text() -> void:
	var seconds_left: int = int(ceil(intro_remaining))
	intro_label.text = "Modo practica\nPresiona la tecla que coincida para cantar.\n%s / %s / %s / %s.\nEmpieza en %d..." % [
		SettingsManager.get_action_label("note_left"),
		SettingsManager.get_action_label("note_down"),
		SettingsManager.get_action_label("note_up"),
		SettingsManager.get_action_label("note_right"),
		maxi(1, seconds_left),
	]


func _spawn_due_notes() -> void:
	while next_note_index < note_pattern.size() and elapsed_time >= float(note_pattern[next_note_index]["time"]):
		_spawn_note(String(note_pattern[next_note_index]["dir"]))
		next_note_index += 1


func _spawn_note(direction: String) -> void:
	var note := ColorRect.new()
	note.name = "Note_%s" % direction
	note.position = Vector2(float(COLUMN_X[direction]) - 28.0, SPAWN_Y)
	note.size = Vector2(56.0, 56.0)
	note.color = Color(DIR_COLORS[direction])
	note_layer.add_child(note)

	active_notes.append({
		"dir": direction,
		"node": note,
	})


func _update_notes(delta: float) -> void:
	for index in range(active_notes.size() - 1, -1, -1):
		var note_data: Dictionary = active_notes[index]
		var note: ColorRect = note_data["node"] as ColorRect
		note.position.y += NOTE_SPEED * delta

		if note.position.y > MISS_Y:
			active_notes.remove_at(index)
			note.queue_free()
			_register_miss()


func _try_hit(direction: String) -> void:
	var best_index: int = -1
	var best_distance: float = INF

	for index in range(active_notes.size()):
		var note_data: Dictionary = active_notes[index]
		if String(note_data["dir"]) != direction:
			continue

		var note: ColorRect = note_data["node"] as ColorRect
		var note_center_y: float = note.position.y + note.size.y * 0.5
		var distance: float = abs(note_center_y - HIT_Y)
		if distance < best_distance:
			best_distance = distance
			best_index = index

	if best_index != -1 and best_distance <= HIT_WINDOW:
		var best_note_data: Dictionary = active_notes[best_index]
		var hit_note: ColorRect = best_note_data["node"] as ColorRect
		active_notes.remove_at(best_index)
		hit_note.queue_free()
		_register_hit()
	else:
		_register_miss()


func _register_hit() -> void:
	score += HIT_SCORE
	combo += 1
	message_label.text = "Good"
	_update_ui()


func _register_miss() -> void:
	if battle_finished:
		return

	combo = 0
	health = maxi(0, health - MISS_DAMAGE)
	message_label.text = "Miss"
	_update_ui()

	if health <= 0:
		_finish_battle(DEFEAT_SCENE)


func _update_ui() -> void:
	score_label.text = "Puntaje: %d" % score
	combo_label.text = "Combo: %d" % combo
	health_bar.value = health


func _check_song_end() -> void:
	if song_finished or battle_finished:
		return

	if next_note_index >= note_pattern.size() and active_notes.is_empty():
		song_finished = true
		if score >= 900 and health > 0:
			_finish_battle(VICTORY_SCENE)
		else:
			_finish_battle(DEFEAT_SCENE)


func _finish_battle(scene_path: String) -> void:
	if battle_finished:
		return

	battle_finished = true
	set_process(false)
	set_process_unhandled_input(false)

	if not is_inside_tree():
		return

	var scene_tree := get_tree()
	if scene_tree == null:
		return

	scene_tree.call_deferred("change_scene_to_file", scene_path)


func _direction_from_input(event: InputEvent) -> String:
	if event.is_action_pressed("note_left"):
		return "left"
	if event.is_action_pressed("note_down"):
		return "down"
	if event.is_action_pressed("note_up"):
		return "up"
	if event.is_action_pressed("note_right"):
		return "right"

	return ""


func _get_note_key_label(direction: String) -> String:
	match direction:
		"left":
			return SettingsManager.get_action_label("note_left")
		"down":
			return SettingsManager.get_action_label("note_down")
		"up":
			return SettingsManager.get_action_label("note_up")
		"right":
			return SettingsManager.get_action_label("note_right")
		_:
			return ""


func _open_pause_menu() -> void:
	if get_tree().paused or has_node("PauseMenu"):
		return

	var pause_menu: Node = PAUSE_MENU_SCENE.instantiate()
	add_child(pause_menu)
