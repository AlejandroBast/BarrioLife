extends Control

const FARM_SCENE = "res://scenes/FarmLevel.tscn"
const HIT_CIRCLE_SCENE = preload("res://scenes/HitCircle.tscn")
const UDDER_TEXTURE = "res://assets/sprites/cow_udder.png"
const FARM_BLUR_TEXTURE = "res://assets/sprites/farm_bg_01.png"
const BUCKET_EMPTY_TEXTURE = "res://assets/sprites/milk_bucket_empty.png"
const BUCKET_FULL_TEXTURE = "res://assets/sprites/milk_bucket_full.png"

const GAME_DURATION = 25.0
const HIT_LIFETIME = 1.25
const TARGET_TIME = 0.82
const PERFECT_WINDOW = 0.16
const GOOD_WINDOW = 0.34
const MIN_WIN_ACCURACY = 65.0
const MIN_WIN_SCORE = 1000
const BUCKET_SIZE = Vector2(135.0, 135.0)
const BUCKET_SCREEN_MARGIN = Vector2(34.0, 58.0)

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
var spawn_delay: float = 0.0

var score_label: Label
var accuracy_label: Label
var stats_label: Label
var time_label: Label
var feedback_label: Label
var hit_layer: Control
var result_panel: PanelContainer
var result_title_label: Label
var result_detail_label: Label
var bucket_display: Node2D
var bucket_empty_sprite: Sprite2D
var bucket_full_sprite: Sprite2D
var bucket_label: Label
var bucket_tween: Tween


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
		if spawn_delay > 0.0:
			spawn_delay = maxf(0.0, spawn_delay - delta)
		else:
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
	_build_blurred_background()

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

	_build_bucket_display()
	_build_hud()
	_build_result_panel()


func _build_blurred_background() -> void:
	var background := TextureRect.new()
	background.texture = load(FARM_BLUR_TEXTURE) as Texture2D
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.material = _create_blur_material()
	add_child(background)

	var warm_overlay := ColorRect.new()
	warm_overlay.color = Color(0.35, 0.18, 0.08, 0.42)
	warm_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	warm_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(warm_overlay)

	var vignette := ColorRect.new()
	vignette.color = Color(0.08, 0.045, 0.03, 0.28)
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.material = _create_vignette_material()
	add_child(vignette)


func _create_blur_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float blur_amount = 4.0;
uniform vec4 warm_tint = vec4(0.24, 0.13, 0.06, 1.0);

void fragment() {
	vec2 pixel = TEXTURE_PIXEL_SIZE * blur_amount;
	vec4 color = texture(TEXTURE, UV) * 0.20;
	color += texture(TEXTURE, UV + vec2(pixel.x, 0.0)) * 0.13;
	color += texture(TEXTURE, UV - vec2(pixel.x, 0.0)) * 0.13;
	color += texture(TEXTURE, UV + vec2(0.0, pixel.y)) * 0.13;
	color += texture(TEXTURE, UV - vec2(0.0, pixel.y)) * 0.13;
	color += texture(TEXTURE, UV + vec2(pixel.x, pixel.y)) * 0.07;
	color += texture(TEXTURE, UV + vec2(-pixel.x, pixel.y)) * 0.07;
	color += texture(TEXTURE, UV + vec2(pixel.x, -pixel.y)) * 0.07;
	color += texture(TEXTURE, UV + vec2(-pixel.x, -pixel.y)) * 0.07;
	COLOR = mix(color, warm_tint, 0.28);
}
"""

	var material := ShaderMaterial.new()
	material.shader = shader
	return material


func _create_vignette_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

void fragment() {
	vec2 centered_uv = UV - vec2(0.5);
	float distance_from_center = length(centered_uv);
	float alpha = smoothstep(0.22, 0.74, distance_from_center) * 0.72;
	COLOR = vec4(0.04, 0.022, 0.015, alpha);
}
"""

	var material := ShaderMaterial.new()
	material.shader = shader
	return material


func _build_bucket_display() -> void:
	bucket_display = Node2D.new()
	bucket_display.visible = false
	bucket_display.position = _get_bucket_position()
	add_child(bucket_display)

	bucket_empty_sprite = _make_bucket_sprite(BUCKET_EMPTY_TEXTURE)
	bucket_empty_sprite.modulate = Color(0.7, 0.7, 0.7, 0.9)
	bucket_display.add_child(bucket_empty_sprite)

	bucket_full_sprite = _make_bucket_sprite(BUCKET_FULL_TEXTURE)
	bucket_full_sprite.material = _create_bucket_fill_material()
	bucket_display.add_child(bucket_full_sprite)

	bucket_label = Label.new()
	bucket_label.visible = false
	bucket_label.position = _get_bucket_label_position()
	bucket_label.size = Vector2(BUCKET_SIZE.x + 70.0, 32.0)
	bucket_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bucket_label.add_theme_font_size_override("font_size", 18)
	bucket_label.modulate = Color(1.0, 0.92, 0.78)
	add_child(bucket_label)


func _make_bucket_sprite(texture_path: String) -> Sprite2D:
	var sprite := Sprite2D.new()
	var texture := load(texture_path) as Texture2D
	sprite.texture = texture
	sprite.centered = false

	if texture != null:
		var texture_size := texture.get_size()
		var scale_factor: float = minf(BUCKET_SIZE.x / texture_size.x, BUCKET_SIZE.y / texture_size.y)
		sprite.scale = Vector2.ONE * scale_factor
	else:
		push_error("No se pudo cargar la textura de cubeta: %s" % texture_path)

	return sprite


func _create_bucket_fill_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float fill_progress = 0.0;

void fragment() {
	vec4 color = texture(TEXTURE, UV) * COLOR;
	if (UV.y < 1.0 - fill_progress) {
		color.a = 0.0;
	}
	COLOR = color;
}
"""

	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("fill_progress", 0.0)
	return material


func _get_bucket_position() -> Vector2:
	var viewport_size := get_viewport_rect().size
	var position := Vector2(
		viewport_size.x - BUCKET_SIZE.x - BUCKET_SCREEN_MARGIN.x,
		viewport_size.y - BUCKET_SIZE.y - BUCKET_SCREEN_MARGIN.y
	)

	position.x = clampf(position.x, 24.0, viewport_size.x - BUCKET_SIZE.x - 24.0)
	position.y = clampf(position.y, 220.0, viewport_size.y - BUCKET_SIZE.y - 24.0)
	return position


func _get_bucket_label_position() -> Vector2:
	return _get_bucket_position() + Vector2(-35.0, BUCKET_SIZE.y - 2.0)


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
	title.text = "Ordeno"
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
	_show_empty_bucket(zone_id)


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
		_fill_bucket()
		circle.finish_judged()
	elif timing_error <= GOOD_WINDOW:
		score += 90
		hits += 1
		_show_feedback("Good", Color(0.62, 1.0, 0.48))
		_fill_bucket()
		circle.finish_judged()
	else:
		_register_miss(circle)
		return

	active_circle = null
	spawn_delay = 0.48
	_update_hud()


func _register_miss(circle: HitCircle) -> void:
	misses += 1
	_show_feedback("Miss", Color(1.0, 0.30, 0.30))
	_shake_empty_bucket()
	if circle != null and is_instance_valid(circle):
		circle.finish_judged()
	if circle == active_circle:
		active_circle = null
	spawn_delay = 0.34
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
	bucket_display.visible = false
	bucket_label.visible = false
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


func _show_empty_bucket(zone_id: String) -> void:
	if bucket_tween != null:
		bucket_tween.kill()

	bucket_display.visible = true
	bucket_display.modulate = Color(1, 1, 1, 1)
	bucket_display.position = _get_bucket_position()
	bucket_display.scale = Vector2(0.84, 0.84)
	bucket_label.visible = true
	bucket_label.position = _get_bucket_label_position()
	bucket_label.text = "Cubeta %s" % zone_id
	_set_bucket_fill_progress(0.0)

	bucket_tween = create_tween()
	bucket_tween.set_parallel(true)
	bucket_tween.tween_property(bucket_display, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	bucket_tween.tween_property(bucket_empty_sprite, "modulate", Color(0.72, 0.72, 0.72, 0.92), 0.18)


func _fill_bucket() -> void:
	if bucket_tween != null:
		bucket_tween.kill()

	bucket_tween = create_tween()
	bucket_tween.set_parallel(true)
	bucket_tween.tween_method(Callable(self, "_set_bucket_fill_progress"), 0.0, 1.0, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	bucket_tween.tween_property(bucket_display, "scale", Vector2(1.08, 1.08), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	bucket_tween.chain().tween_property(bucket_display, "scale", Vector2.ONE, 0.14)


func _shake_empty_bucket() -> void:
	if bucket_tween != null:
		bucket_tween.kill()

	_set_bucket_fill_progress(0.0)
	var base_position := _get_bucket_position()
	bucket_tween = create_tween()
	bucket_tween.tween_property(bucket_display, "position:x", base_position.x - 10.0, 0.04)
	bucket_tween.tween_property(bucket_display, "position:x", base_position.x + 10.0, 0.06)
	bucket_tween.tween_property(bucket_display, "position:x", base_position.x, 0.05)
	bucket_tween.tween_property(bucket_empty_sprite, "modulate", Color(0.95, 0.48, 0.42, 1.0), 0.08)
	bucket_tween.tween_property(bucket_empty_sprite, "modulate", Color(0.72, 0.72, 0.72, 0.92), 0.16)


func _set_bucket_fill_progress(progress: float) -> void:
	if bucket_full_sprite == null:
		return

	var fill_material := bucket_full_sprite.material as ShaderMaterial
	if fill_material != null:
		fill_material.set_shader_parameter("fill_progress", clampf(progress, 0.0, 1.0))


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
