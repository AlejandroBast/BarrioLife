extends Control

const FARM_SCENE = "res://scenes/FarmLevel.tscn"
const HIT_CIRCLE_SCENE = preload("res://scenes/HitCircle.tscn")
const UDDER_TEXTURE = "res://assets/sprites/cow_udder.png"

const GAME_DURATION = 25.0
const HIT_LIFETIME = 1.25
const TARGET_TIME = 0.82
const PERFECT_WINDOW = 0.16
const GOOD_WINDOW = 0.34
const MIN_WIN_ACCURACY = 65.0
const MIN_WIN_SCORE = 1000

const ZONES: Array[Dictionary] = [
	{"id": "J", "key": KEY_J, "position": Vector2(455, 415), "color": Color(1.0, 0.54, 0.34)},
	{"id": "K", "key": KEY_K, "position": Vector2(560, 520), "color": Color(1.0, 0.78, 0.35)},
	{"id": "L", "key": KEY_L, "position": Vector2(720, 520), "color": Color(0.58, 0.92, 0.48)},
	{"id": "I", "key": KEY_I, "position": Vector2(825, 415), "color": Color(0.45, 0.78, 1.0)},
]

var elapsed_time: float = 0.0
var score: int = 0
var hits: int = 0
var misses: int = 0
var game_finished: bool = false
var active_circle: HitCircle
var next_zone_index: int = -1

var score_label: Label
var accuracy_label: Label
var stats_label: Label
var time_label: Label
var feedback_label: Label
var hit_layer: Control
var result_panel: PanelContainer
var result_title_label: Label
var result_detail_label: Label


func _ready() -> void:
	_build_ui()
	_spawn_next_circle()
	_update_hud()


func _process(delta: float) -> void:
	if game_finished:
		return

	elapsed_time += delta

	if active_circle != null and is_instance_valid(active_circle) and active_circle.is_expired():
		_register_miss(active_circle)

	if active_circle == null or not is_instance_valid(active_circle):
		_spawn_next_circle()

	_update_hud()

	if elapsed_time >= GAME_DURATION:
		_finish_minigame()


func _unhandled_input(event: InputEvent) -> void:
	if game_finished:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		var zone_id := _zone_from_key(event.keycode)
		if zone_id != "":
			get_viewport().set_input_as_handled()
			_try_hit_zone(zone_id)


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color(0.16, 0.105, 0.075)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var warm_band := ColorRect.new()
	warm_band.color = Color(0.88, 0.52, 0.22, 0.12)
	warm_band.set_anchors_preset(Control.PRESET_FULL_RECT)
	warm_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(warm_band)

	var udder := TextureRect.new()
	udder.texture = load(UDDER_TEXTURE) as Texture2D
	udder.set_anchors_preset(Control.PRESET_FULL_RECT)
	udder.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	udder.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	udder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(udder)

	hit_layer = Control.new()
	hit_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	hit_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hit_layer)

	_build_hud()
	_build_result_panel()


func _build_hud() -> void:
	var hud := PanelContainer.new()
	hud.position = Vector2(24, 20)
	hud.size = Vector2(360, 150)
	add_child(hud)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.045, 0.04, 0.84)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 18
	style.content_margin_top = 12
	style.content_margin_right = 18
	style.content_margin_bottom = 12
	hud.add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	hud.add_child(box)

	var title := Label.new()
	title.text = "Ordeño"
	title.add_theme_font_size_override("font_size", 24)
	box.add_child(title)

	score_label = Label.new()
	score_label.add_theme_font_size_override("font_size", 18)
	box.add_child(score_label)

	accuracy_label = Label.new()
	accuracy_label.add_theme_font_size_override("font_size", 18)
	box.add_child(accuracy_label)

	stats_label = Label.new()
	stats_label.add_theme_font_size_override("font_size", 18)
	box.add_child(stats_label)

	time_label = Label.new()
	time_label.add_theme_font_size_override("font_size", 18)
	box.add_child(time_label)

	feedback_label = Label.new()
	feedback_label.position = Vector2(450, 44)
	feedback_label.size = Vector2(380, 60)
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.add_theme_font_size_override("font_size", 42)
	add_child(feedback_label)

	var help := Label.new()
	help.position = Vector2(820, 24)
	help.size = Vector2(420, 90)
	help.text = "Presiona J / K / L / I o haz clic en el circulo activo."
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.add_theme_font_size_override("font_size", 22)
	help.modulate = Color(1.0, 0.92, 0.78)
	add_child(help)


func _build_result_panel() -> void:
	result_panel = PanelContainer.new()
	result_panel.visible = false
	result_panel.position = Vector2(390, 180)
	result_panel.size = Vector2(500, 360)
	add_child(result_panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.065, 0.052, 0.045, 0.96)
	style.border_color = Color(0.95, 0.62, 0.28, 0.9)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 28
	style.content_margin_top = 24
	style.content_margin_right = 28
	style.content_margin_bottom = 24
	result_panel.add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	result_panel.add_child(box)

	result_title_label = Label.new()
	result_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_title_label.add_theme_font_size_override("font_size", 38)
	box.add_child(result_title_label)

	result_detail_label = Label.new()
	result_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_detail_label.add_theme_font_size_override("font_size", 20)
	box.add_child(result_detail_label)

	var retry_button := _make_button("Reintentar")
	retry_button.pressed.connect(func() -> void: get_tree().reload_current_scene())
	box.add_child(retry_button)

	var farm_button := _make_button("Volver a la granja")
	farm_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(FARM_SCENE))
	box.add_child(farm_button)


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(260, 48)
	button.add_theme_font_size_override("font_size", 20)
	return button


func _spawn_next_circle() -> void:
	if game_finished:
		return

	next_zone_index = (next_zone_index + randi_range(1, ZONES.size() - 1)) % ZONES.size()
	var zone := ZONES[next_zone_index]
	var zone_id := String(zone["id"])
	var zone_position: Vector2 = zone["position"]
	var zone_color: Color = zone["color"]
	var circle := HIT_CIRCLE_SCENE.instantiate() as HitCircle
	circle.setup(zone_id, zone_id, zone_color, HIT_LIFETIME, TARGET_TIME)
	circle.position = zone_position - Vector2(80, 80)
	circle.hit_requested.connect(_try_hit_circle)
	hit_layer.add_child(circle)
	active_circle = circle


func _try_hit_circle(circle: HitCircle) -> void:
	if game_finished or circle == null or not is_instance_valid(circle):
		return

	_judge_circle(circle)


func _try_hit_zone(zone_id: String) -> void:
	if active_circle == null or not is_instance_valid(active_circle):
		return

	if active_circle.zone_id != zone_id:
		_register_miss(active_circle)
		return

	_judge_circle(active_circle)


func _judge_circle(circle: HitCircle) -> void:
	var timing_error := circle.get_timing_error()

	if timing_error <= PERFECT_WINDOW:
		score += 150
		hits += 1
		_show_feedback("Perfect", Color(1.0, 0.88, 0.35))
		circle.finish_judged()
	elif timing_error <= GOOD_WINDOW:
		score += 90
		hits += 1
		_show_feedback("Good", Color(0.62, 1.0, 0.48))
		circle.finish_judged()
	else:
		_register_miss(circle)
		return

	active_circle = null
	_update_hud()


func _register_miss(circle: HitCircle) -> void:
	misses += 1
	_show_feedback("Miss", Color(1.0, 0.30, 0.30))
	if circle != null and is_instance_valid(circle):
		circle.finish_judged()
	if circle == active_circle:
		active_circle = null
	_update_hud()


func _finish_minigame() -> void:
	if game_finished:
		return

	game_finished = true
	if active_circle != null and is_instance_valid(active_circle):
		active_circle.finish_judged()
		active_circle = null

	var accuracy := _get_accuracy()
	var won := accuracy >= MIN_WIN_ACCURACY and score >= MIN_WIN_SCORE
	var result_text := _get_result_text(accuracy, won)

	if won:
		GameState.complete_objective("farm_cow_milking_completed")

	result_title_label.text = result_text
	result_detail_label.text = "Puntaje: %d\nPrecision: %d%%\nAciertos: %d  Fallos: %d" % [
		score,
		int(round(accuracy)),
		hits,
		misses,
	]
	result_panel.visible = true
	_update_hud()


func _get_result_text(accuracy: float, won: bool) -> String:
	if not won:
		return "Fallaste"
	if accuracy >= 90.0:
		return "Excelente"
	if accuracy >= 75.0:
		return "Bien"
	return "Regular"


func _show_feedback(text: String, color: Color) -> void:
	feedback_label.text = text
	feedback_label.modulate = color
	var tween := create_tween()
	tween.tween_property(feedback_label, "modulate:a", 1.0, 0.01)
	tween.tween_interval(0.35)
	tween.tween_property(feedback_label, "modulate:a", 0.0, 0.22)


func _update_hud() -> void:
	score_label.text = "Puntaje: %d" % score
	accuracy_label.text = "Precision: %d%%" % int(round(_get_accuracy()))
	stats_label.text = "Aciertos: %d  Fallos: %d" % [hits, misses]
	time_label.text = "Tiempo: %ds" % maxi(0, int(ceil(GAME_DURATION - elapsed_time)))


func _get_accuracy() -> float:
	var judged := hits + misses
	if judged <= 0:
		return 100.0

	return float(hits) / float(judged) * 100.0


func _zone_from_key(keycode: Key) -> String:
	match keycode:
		KEY_J:
			return "J"
		KEY_K:
			return "K"
		KEY_L:
			return "L"
		KEY_I:
			return "I"
		_:
			return ""
