extends Control

const FARM_SCENE = "res://scenes/FarmLevel.tscn"
const HIT_CIRCLE_SCENE = preload("res://scenes/HitCircle.tscn")
const MILK_DROP_SCRIPT = preload("res://scripts/MilkDrop.gd")
const UDDER_TEXTURE = "res://assets/sprites/cow_udder.png"
const FARM_BLUR_TEXTURE = "res://assets/sprites/farm_bg_01.png"
const BUCKET_EMPTY_TEXTURE = "res://assets/sprites/milk_bucket_empty.png"
const BUCKET_FULL_TEXTURE = "res://assets/sprites/milk_bucket_full.png"
const COW_MUSIC = "res://assets/audio/vaca-fondo.mp3"

const HIT_LIFETIME = 1.25
const TARGET_TIME = 0.82
const PERFECT_WINDOW = 0.16
const GOOD_WINDOW = 0.34
const MIN_WIN_ACCURACY = 65.0
const MIN_WIN_SCORE = 1000
const BUCKET_SIZE = Vector2(135.0, 135.0)
const BUCKET_SCREEN_MARGIN = Vector2(34.0, 58.0)
const MILK_DROP_COUNT = 9
const NOTES_PER_ROUND = 5
const HIT_LIFETIME_STEP = 0.09
const TARGET_TIME_STEP = 0.06
const PERFECT_WINDOW_STEP = 0.01
const GOOD_WINDOW_STEP = 0.025
const SUCCESS_SPAWN_DELAY = 0.48
const MISS_SPAWN_DELAY = 0.34
const SPAWN_DELAY_STEP = 0.045
const MIN_HIT_LIFETIME = 0.66
const MIN_TARGET_TIME = 0.42
const MIN_PERFECT_WINDOW = 0.09
const MIN_GOOD_WINDOW = 0.20
const MIN_SPAWN_DELAY = 0.13
const MAX_LIFE = 100
const MISS_DAMAGE = 20
const LOW_LIFE_THRESHOLD = 35
const PERFECT_MONEY_REWARD = 2
const GOOD_MONEY_REWARD = 1

const ZONES: Array[Dictionary] = [
	{"id": "J", "key": KEY_J, "position": Vector2(455, 415), "color": Color(1.0, 0.54, 0.34)},
	{"id": "K", "key": KEY_K, "position": Vector2(560, 520), "color": Color(1.0, 0.78, 0.35)},
	{"id": "L", "key": KEY_L, "position": Vector2(720, 520), "color": Color(0.58, 0.92, 0.48)},
	{"id": "I", "key": KEY_I, "position": Vector2(825, 415), "color": Color(0.45, 0.78, 1.0)},
]

const MILK_DROP_ORIGINS: Dictionary = {
	"J": Vector2(548, 474),
	"K": Vector2(588, 552),
	"L": Vector2(690, 552),
	"I": Vector2(748, 474),
}

var elapsed_time: float = 0.0
var score: int = 0
var hits: int = 0
var misses: int = 0
var game_finished: bool = false
var active_circle: HitCircle
var next_zone_index: int = -1
var spawn_delay: float = 0.0
var current_round: int = 1
var judged_notes: int = 0
var objective_ready: bool = false
var life: int = MAX_LIFE

var score_label: Label
var accuracy_label: Label
var stats_label: Label
var objective_status_label: Label
var round_label: Label
var time_label: Label
var time_bar: ProgressBar
var money_label: Label
var health_label: Label
var health_bar: ProgressBar
var feedback_label: Label
var milk_effect_layer: Node2D
var hit_layer: Control
var result_overlay: ColorRect
var result_panel: PanelContainer
var result_title_label: Label
var result_detail_label: Label
var bucket_display: Node2D
var bucket_empty_sprite: Sprite2D
var bucket_full_sprite: Sprite2D
var bucket_label: Label
var bucket_tween: Tween
var key_indicator_panels: Dictionary = {}
var key_indicator_labels: Dictionary = {}


func _ready() -> void:
	objective_ready = GameState.is_objective_completed("farm_cow_milking_completed")
	MusicManager.play_music(COW_MUSIC, 0.75)
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


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed("pause_game"):
			get_viewport().set_input_as_handled()
			_return_to_farm()
			return

		if game_finished:
			return

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

	milk_effect_layer = Node2D.new()
	add_child(milk_effect_layer)

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
	hud.size = Vector2(410, 250)
	add_child(hud)

	var style := _make_panel_style(Color(0.055, 0.043, 0.034, 0.86), Color(1.0, 0.68, 0.28, 0.34), 1, 8)
	style.content_margin_left = 18
	style.content_margin_top = 14
	style.content_margin_right = 18
	style.content_margin_bottom = 14
	hud.add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	hud.add_child(box)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	box.add_child(header)

	var title_group := VBoxContainer.new()
	title_group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_group.add_theme_constant_override("separation", 0)
	header.add_child(title_group)

	var title := _make_ui_label("Ordeno", 25, Color(1.0, 0.92, 0.78))
	title.text = "Ordeno"
	title_group.add_child(title)

	round_label = _make_ui_label("Ronda 1 - ritmo suave", 14, Color(1.0, 0.73, 0.44, 0.86))
	title_group.add_child(round_label)

	time_label = _make_ui_label("00:00", 25, Color(1.0, 0.86, 0.55))
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_label.custom_minimum_size = Vector2(82, 34)
	header.add_child(time_label)

	time_bar = ProgressBar.new()
	time_bar.min_value = 0.0
	time_bar.max_value = 100.0
	time_bar.value = 100.0
	time_bar.show_percentage = false
	time_bar.custom_minimum_size = Vector2(0, 12)
	time_bar.add_theme_stylebox_override("background", _make_panel_style(Color(0.13, 0.085, 0.055, 0.92), Color(0, 0, 0, 0), 0, 6))
	time_bar.add_theme_stylebox_override("fill", _make_panel_style(Color(0.96, 0.56, 0.24, 0.96), Color(0, 0, 0, 0), 0, 6))
	box.add_child(time_bar)

	var health_box := VBoxContainer.new()
	health_box.add_theme_constant_override("separation", 4)
	box.add_child(health_box)

	health_label = _make_ui_label("Vida: 100%", 14, Color(1.0, 0.88, 0.66))
	health_box.add_child(health_label)

	health_bar = ProgressBar.new()
	health_bar.min_value = 0.0
	health_bar.max_value = MAX_LIFE
	health_bar.value = MAX_LIFE
	health_bar.show_percentage = false
	health_bar.custom_minimum_size = Vector2(0, 14)
	health_bar.add_theme_stylebox_override("background", _make_panel_style(Color(0.13, 0.055, 0.045, 0.92), Color(0, 0, 0, 0), 0, 7))
	health_bar.add_theme_stylebox_override("fill", _make_panel_style(Color(0.70, 1.0, 0.50, 0.96), Color(0, 0, 0, 0), 0, 7))
	health_box.add_child(health_bar)

	money_label = _make_ui_label("Dinero: $0", 15, Color(1.0, 0.86, 0.48))
	box.add_child(money_label)

	objective_status_label = _make_ui_label("Meta: 1000 pts y 65% precision. ESC vuelve a la granja.", 13, Color(1.0, 0.76, 0.48, 0.86))
	objective_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(objective_status_label)

	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 10)
	box.add_child(stats_row)

	score_label = _make_metric_tile(stats_row, "Puntaje", Color(1.0, 0.86, 0.50))
	accuracy_label = _make_metric_tile(stats_row, "Precision", Color(0.72, 1.0, 0.60))
	stats_label = _make_metric_tile(stats_row, "Aciertos", Color(0.55, 0.82, 1.0))

	feedback_label = Label.new()
	feedback_label.position = Vector2(450, 36)
	feedback_label.size = Vector2(380, 60)
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.add_theme_font_size_override("font_size", 46)
	feedback_label.add_theme_color_override("font_shadow_color", Color(0.08, 0.035, 0.02, 0.86))
	feedback_label.add_theme_constant_override("shadow_offset_x", 2)
	feedback_label.add_theme_constant_override("shadow_offset_y", 3)
	feedback_label.pivot_offset = feedback_label.size * 0.5
	add_child(feedback_label)

	_build_key_guide()


func _build_result_panel() -> void:
	result_overlay = ColorRect.new()
	result_overlay.visible = false
	result_overlay.color = Color(0.025, 0.018, 0.014, 0.66)
	result_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(result_overlay)

	result_panel = PanelContainer.new()
	result_panel.visible = false
	result_panel.position = Vector2(380, 164)
	result_panel.size = Vector2(520, 392)
	add_child(result_panel)

	var style := _make_panel_style(Color(0.062, 0.047, 0.038, 0.98), Color(1.0, 0.66, 0.28, 0.86), 2, 8)
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
	result_title_label.add_theme_font_size_override("font_size", 42)
	result_title_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.52))
	result_title_label.add_theme_color_override("font_shadow_color", Color(0.08, 0.035, 0.02, 0.9))
	result_title_label.add_theme_constant_override("shadow_offset_x", 2)
	result_title_label.add_theme_constant_override("shadow_offset_y", 3)
	box.add_child(result_title_label)

	result_detail_label = Label.new()
	result_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_detail_label.add_theme_font_size_override("font_size", 21)
	result_detail_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.80))
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
	button.custom_minimum_size = Vector2(300, 52)
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color(1.0, 0.92, 0.78))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _make_panel_style(Color(0.18, 0.11, 0.07, 0.96), Color(0.88, 0.51, 0.22, 0.75), 1, 8))
	button.add_theme_stylebox_override("hover", _make_panel_style(Color(0.30, 0.17, 0.09, 0.98), Color(1.0, 0.70, 0.34, 0.95), 2, 8))
	button.add_theme_stylebox_override("pressed", _make_panel_style(Color(0.12, 0.075, 0.052, 1.0), Color(1.0, 0.77, 0.40, 1.0), 2, 8))
	return button


func _make_panel_style(bg_color: Color, border_color: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	style.content_margin_left = 12
	style.content_margin_top = 8
	style.content_margin_right = 12
	style.content_margin_bottom = 8
	return style


func _make_ui_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _make_metric_tile(parent: Container, title: String, color: Color) -> Label:
	var tile := PanelContainer.new()
	tile.custom_minimum_size = Vector2(118, 64)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.add_theme_stylebox_override("panel", _make_panel_style(Color(0.11, 0.075, 0.052, 0.78), Color(color.r, color.g, color.b, 0.32), 1, 8))
	parent.add_child(tile)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	tile.add_child(box)

	var title_label := _make_ui_label(title, 13, Color(1.0, 0.80, 0.58, 0.78))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title_label)

	var value_label := _make_ui_label("0", 22, color)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(value_label)
	return value_label


func _build_key_guide() -> void:
	var guide := PanelContainer.new()
	guide.position = Vector2(816, 20)
	guide.size = Vector2(440, 132)
	guide.add_theme_stylebox_override("panel", _make_panel_style(Color(0.055, 0.043, 0.034, 0.78), Color(1.0, 0.68, 0.28, 0.26), 1, 8))
	add_child(guide)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	guide.add_child(box)

	var title := _make_ui_label("Presiona la tecla que coincida", 20, Color(1.0, 0.92, 0.78))
	box.add_child(title)

	var keys_row := HBoxContainer.new()
	keys_row.add_theme_constant_override("separation", 10)
	box.add_child(keys_row)

	key_indicator_panels.clear()
	key_indicator_labels.clear()

	for zone_data in ZONES:
		var zone_id := String(zone_data["id"])
		var zone_color: Color = zone_data["color"]
		var key_panel := PanelContainer.new()
		key_panel.custom_minimum_size = Vector2(72, 52)
		key_panel.add_theme_stylebox_override("panel", _make_key_style(zone_color, false))
		keys_row.add_child(key_panel)

		var key_label := _make_ui_label(zone_id, 28, Color(1.0, 0.94, 0.84))
		key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		key_panel.add_child(key_label)

		key_indicator_panels[zone_id] = key_panel
		key_indicator_labels[zone_id] = key_label

	var note := _make_ui_label("Tambien puedes hacer clic en el circulo activo.", 14, Color(1.0, 0.74, 0.48, 0.82))
	box.add_child(note)


func _make_key_style(color: Color, active: bool) -> StyleBoxFlat:
	var bg_color := Color(0.13, 0.08, 0.055, 0.86)
	var border_color := Color(color.r, color.g, color.b, 0.54)
	var border_width := 1

	if active:
		bg_color = Color(color.r * 0.42, color.g * 0.28, color.b * 0.20, 0.98)
		border_color = Color(color.r, color.g, color.b, 1.0)
		border_width = 2

	var style := _make_panel_style(bg_color, border_color, border_width, 8)
	style.content_margin_left = 0
	style.content_margin_top = 7
	style.content_margin_right = 0
	style.content_margin_bottom = 7
	return style


func _set_active_key_indicator(active_zone_id: String) -> void:
	for zone_data in ZONES:
		var zone_id := String(zone_data["id"])
		var zone_color: Color = zone_data["color"]
		var panel: PanelContainer = key_indicator_panels.get(zone_id) as PanelContainer
		var label: Label = key_indicator_labels.get(zone_id) as Label
		var active := zone_id == active_zone_id

		if panel != null:
			panel.add_theme_stylebox_override("panel", _make_key_style(zone_color, active))

		if label != null:
			if active:
				label.add_theme_color_override("font_color", Color.WHITE)
			else:
				label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.84))


func _spawn_next_circle() -> void:
	if game_finished:
		return

	next_zone_index = (next_zone_index + randi_range(1, ZONES.size() - 1)) % ZONES.size()
	var zone := ZONES[next_zone_index]
	var zone_id := String(zone["id"])
	var zone_position: Vector2 = zone["position"]
	var zone_color: Color = zone["color"]
	var circle := HIT_CIRCLE_SCENE.instantiate() as HitCircle
	circle.setup(zone_id, zone_id, zone_color, _get_hit_lifetime(), _get_target_time())
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

	if timing_error <= _get_perfect_window():
		score += 150 + (current_round - 1) * 12
		GameState.add_money(PERFECT_MONEY_REWARD)
		hits += 1
		_show_feedback("Perfect", Color(1.0, 0.88, 0.35))
		_spawn_milk_drops(circle.zone_id, true)
		_fill_bucket()
		circle.finish_judged()
	elif timing_error <= _get_good_window():
		score += 90 + (current_round - 1) * 8
		GameState.add_money(GOOD_MONEY_REWARD)
		hits += 1
		_show_feedback("Good", Color(0.62, 1.0, 0.48))
		_spawn_milk_drops(circle.zone_id, false)
		_fill_bucket()
		circle.finish_judged()
	else:
		_register_miss(circle)
		return

	_advance_round_progress()
	_check_objective_progress()
	active_circle = null
	spawn_delay = _get_spawn_delay(SUCCESS_SPAWN_DELAY)
	_update_hud()


func _register_miss(circle: HitCircle) -> void:
	misses += 1
	_apply_life_damage(MISS_DAMAGE)
	_show_feedback("Miss", Color(1.0, 0.30, 0.30))
	_shake_empty_bucket()
	if circle != null and is_instance_valid(circle):
		circle.finish_judged()
	if circle == active_circle:
		active_circle = null
	_advance_round_progress()
	spawn_delay = _get_spawn_delay(MISS_SPAWN_DELAY)
	_update_hud()

	if life <= 0:
		_finish_minigame()


func _finish_minigame() -> void:
	if game_finished:
		return

	game_finished = true
	if active_circle != null and is_instance_valid(active_circle):
		active_circle.finish_judged()
		active_circle = null

	var accuracy := _get_accuracy()
	var won := objective_ready or (accuracy >= MIN_WIN_ACCURACY and score >= MIN_WIN_SCORE)
	var result_text := _get_result_text(accuracy, won)

	if won:
		GameState.complete_objective("farm_cow_milking_completed")

	result_title_label.text = result_text
	result_detail_label.text = "Puntaje: %d\nPrecision: %d%%\nAciertos: %d  Fallos: %d\nRonda alcanzada: %d\nVida final: %d%%" % [
		score,
		int(round(accuracy)),
		hits,
		misses,
		current_round,
		life,
	]
	result_overlay.visible = true
	result_panel.visible = true
	bucket_display.visible = false
	bucket_label.visible = false
	_set_active_key_indicator("")
	_update_hud()


func _return_to_farm() -> void:
	get_tree().change_scene_to_file(FARM_SCENE)


func _get_result_text(accuracy: float, won: bool) -> String:
	if not won:
		return "Sin energia"
	if life <= 0 and objective_ready:
		return "Objetivo completado"
	if accuracy >= 90.0:
		return "Excelente"
	if accuracy >= 75.0:
		return "Bien"
	return "Regular"


func _show_feedback(text: String, color: Color) -> void:
	feedback_label.text = text
	feedback_label.modulate = color
	feedback_label.scale = Vector2(0.82, 0.82)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(feedback_label, "modulate:a", 1.0, 0.01)
	tween.tween_property(feedback_label, "scale", Vector2(1.0, 1.0), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain()
	tween.tween_interval(0.35)
	tween.tween_property(feedback_label, "modulate:a", 0.0, 0.22)


func _spawn_milk_drops(zone_id: String, is_perfect: bool) -> void:
	if milk_effect_layer == null:
		return

	var origin := MILK_DROP_ORIGINS.get(zone_id, Vector2.ZERO) as Vector2
	if origin == Vector2.ZERO:
		return

	var drop_count := MILK_DROP_COUNT
	if not is_perfect:
		drop_count = maxi(5, MILK_DROP_COUNT - 2)

	for _index in range(drop_count):
		var drop := MILK_DROP_SCRIPT.new() as MilkDrop
		var side_drift := randf_range(-52.0, 52.0)
		var speed_y := randf_range(126.0, 210.0)
		var start_offset := Vector2(randf_range(-8.0, 8.0), randf_range(-3.0, 7.0))
		var drop_radius := randf_range(6.4, 10.4)
		var drop_lifetime := randf_range(0.46, 0.72)

		drop.setup(origin + start_offset, Vector2(side_drift, speed_y), drop_radius, drop_lifetime)
		milk_effect_layer.add_child(drop)


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
	_set_active_key_indicator(zone_id)
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


func _apply_life_damage(amount: int) -> void:
	life = maxi(0, life - amount)


func _advance_round_progress() -> void:
	judged_notes += 1
	current_round = 1 + int(floor(float(judged_notes) / float(NOTES_PER_ROUND)))


func _check_objective_progress() -> void:
	if objective_ready:
		return

	if score >= MIN_WIN_SCORE and _get_accuracy() >= MIN_WIN_ACCURACY:
		objective_ready = true
		GameState.complete_objective("farm_cow_milking_completed")
		_show_feedback("Objetivo listo", Color(1.0, 0.86, 0.42))


func _get_hit_lifetime() -> float:
	return maxf(MIN_HIT_LIFETIME, HIT_LIFETIME - float(current_round - 1) * HIT_LIFETIME_STEP)


func _get_target_time() -> float:
	return maxf(MIN_TARGET_TIME, TARGET_TIME - float(current_round - 1) * TARGET_TIME_STEP)


func _get_perfect_window() -> float:
	return maxf(MIN_PERFECT_WINDOW, PERFECT_WINDOW - float(current_round - 1) * PERFECT_WINDOW_STEP)


func _get_good_window() -> float:
	return maxf(MIN_GOOD_WINDOW, GOOD_WINDOW - float(current_round - 1) * GOOD_WINDOW_STEP)


func _get_spawn_delay(base_delay: float) -> float:
	return maxf(MIN_SPAWN_DELAY, base_delay - float(current_round - 1) * SPAWN_DELAY_STEP)


func _get_round_speed_label() -> String:
	if current_round >= 12:
		return "ritmo extremo"
	if current_round >= 8:
		return "ritmo intenso"
	if current_round >= 4:
		return "ritmo rapido"
	if current_round >= 2:
		return "ritmo vivo"
	return "ritmo suave"


func _update_hud() -> void:
	var accuracy := _get_accuracy()
	score_label.text = "%d" % score
	accuracy_label.text = "%d%%" % int(round(accuracy))
	stats_label.text = "%d/%d" % [hits, misses]
	round_label.text = "Ronda %d - %s" % [current_round, _get_round_speed_label()]
	time_label.text = _format_elapsed_time(elapsed_time)
	time_bar.value = float(judged_notes % NOTES_PER_ROUND) / float(NOTES_PER_ROUND) * 100.0
	accuracy_label.add_theme_color_override("font_color", _get_accuracy_color(accuracy))
	health_label.text = "Vida: %d%%" % life
	health_label.add_theme_color_override("font_color", _get_life_color())
	health_bar.value = life
	health_bar.add_theme_stylebox_override("fill", _make_panel_style(_get_life_color(), Color(0, 0, 0, 0), 0, 7))
	if money_label != null:
		money_label.text = "Dinero ganado: $%d" % GameState.get_money()

	if objective_ready:
		objective_status_label.text = "Objetivo completado. Puedes seguir o presionar ESC para volver."
		objective_status_label.add_theme_color_override("font_color", Color(0.70, 1.0, 0.58))
	else:
		objective_status_label.text = "Meta: %d pts y %d%% precision. ESC vuelve a la granja." % [MIN_WIN_SCORE, int(MIN_WIN_ACCURACY)]
		objective_status_label.add_theme_color_override("font_color", Color(1.0, 0.76, 0.48, 0.86))


func _format_elapsed_time(total_seconds: float) -> String:
	var seconds := int(floor(total_seconds))
	var minutes := int(seconds / 60)
	var remaining_seconds := seconds % 60
	return "%02d:%02d" % [minutes, remaining_seconds]


func _get_accuracy() -> float:
	var judged := hits + misses
	if judged <= 0:
		return 100.0

	return float(hits) / float(judged) * 100.0


func _get_accuracy_color(accuracy: float) -> Color:
	if accuracy >= 80.0:
		return Color(0.72, 1.0, 0.60)
	if accuracy >= 60.0:
		return Color(1.0, 0.82, 0.38)
	return Color(1.0, 0.42, 0.36)


func _get_life_color() -> Color:
	if life <= LOW_LIFE_THRESHOLD:
		return Color(1.0, 0.30, 0.26, 0.96)
	if life <= 65:
		return Color(1.0, 0.78, 0.28, 0.96)
	return Color(0.70, 1.0, 0.50, 0.96)


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
