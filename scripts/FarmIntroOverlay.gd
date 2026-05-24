class_name FarmIntroOverlay
extends CanvasLayer

signal intro_finished

const SAMPLE_RATE = 22050.0
const INTRO_LINES: Array[String] = [
	"Hay personas que nacen soñando con ser alguien...",
	"Y otras que nacen creyendo que nunca podrán salir del lugar donde crecieron.",
	"Elian era uno de ellos.",
	"9 años.",
	"Una granja.",
	"Y una vida que parecía ya estar escrita.",
]
const MOTHER_DIALOGUE = "Elian... vaya a ordeñar las vacas antes de que salga el sol."

var black_rect: ColorRect
var narration_label: Label
var dialogue_panel: PanelContainer
var speaker_label: Label
var dialogue_label: Label
var ambient_player: AudioStreamPlayer
var ambient_playback: AudioStreamGeneratorPlayback
var sample_cursor: float = 0.0
var wind_state: float = 0.0
var cricket_timer: float = 0.18
var cricket_age: float = 0.0
var cricket_duration: float = 0.0
var cricket_frequency: float = 4200.0
var cow_timer: float = 2.6
var cow_age: float = 0.0
var cow_duration: float = 0.0
var cow_frequency: float = 86.0
var wood_timer: float = 1.4
var wood_age: float = 0.0
var wood_duration: float = 0.0
var wood_frequency: float = 210.0


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_start_ambient()
	call_deferred("_play_intro")


func _process(_delta: float) -> void:
	_fill_ambient_buffer()


func _build_ui() -> void:
	black_rect = ColorRect.new()
	black_rect.color = Color.BLACK
	black_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(black_rect)

	narration_label = Label.new()
	narration_label.set_anchors_preset(Control.PRESET_CENTER)
	narration_label.offset_left = -430.0
	narration_label.offset_top = -80.0
	narration_label.offset_right = 430.0
	narration_label.offset_bottom = 80.0
	narration_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	narration_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	narration_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	narration_label.add_theme_font_size_override("font_size", 32)
	narration_label.add_theme_color_override("font_color", Color(0.92, 0.88, 0.78))
	narration_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.86))
	narration_label.add_theme_constant_override("shadow_offset_x", 2)
	narration_label.add_theme_constant_override("shadow_offset_y", 3)
	narration_label.modulate.a = 0.0
	add_child(narration_label)

	dialogue_panel = PanelContainer.new()
	dialogue_panel.visible = false
	dialogue_panel.modulate.a = 0.0
	dialogue_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	dialogue_panel.offset_left = -430.0
	dialogue_panel.offset_top = -170.0
	dialogue_panel.offset_right = 430.0
	dialogue_panel.offset_bottom = -44.0
	dialogue_panel.add_theme_stylebox_override("panel", _make_panel_style())
	add_child(dialogue_panel)

	var dialogue_box := VBoxContainer.new()
	dialogue_box.add_theme_constant_override("separation", 8)
	dialogue_panel.add_child(dialogue_box)

	speaker_label = Label.new()
	speaker_label.text = "Madre"
	speaker_label.add_theme_font_size_override("font_size", 18)
	speaker_label.add_theme_color_override("font_color", Color(1.0, 0.74, 0.42))
	dialogue_box.add_child(speaker_label)

	dialogue_label = Label.new()
	dialogue_label.text = MOTHER_DIALOGUE
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.add_theme_font_size_override("font_size", 25)
	dialogue_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.80))
	dialogue_box.add_child(dialogue_label)


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.042, 0.032, 0.92)
	style.border_color = Color(0.85, 0.48, 0.20, 0.62)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 22
	style.content_margin_top = 16
	style.content_margin_right = 22
	style.content_margin_bottom = 16
	return style


func _play_intro() -> void:
	await get_tree().create_timer(0.7).timeout

	for line in INTRO_LINES:
		await _show_narration_line(line)

	await _fade_black_to_game()
	await _show_mother_dialogue()
	_stop_ambient()
	intro_finished.emit()
	queue_free()


func _show_narration_line(text: String) -> void:
	narration_label.text = text
	narration_label.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(narration_label, "modulate:a", 1.0, 1.05)
	tween.tween_interval(_get_line_hold_time(text))
	tween.tween_property(narration_label, "modulate:a", 0.0, 0.9)
	await tween.finished


func _get_line_hold_time(text: String) -> float:
	if text.length() <= 12:
		return 1.0
	return 1.45


func _fade_black_to_game() -> void:
	narration_label.modulate.a = 0.0
	await get_tree().create_timer(0.35).timeout
	var tween := create_tween()
	tween.tween_property(black_rect, "color:a", 0.0, 2.2)
	await tween.finished


func _show_mother_dialogue() -> void:
	dialogue_panel.visible = true
	var tween := create_tween()
	tween.tween_property(dialogue_panel, "modulate:a", 1.0, 0.5)
	tween.tween_interval(3.0)
	tween.tween_property(dialogue_panel, "modulate:a", 0.0, 0.55)
	await tween.finished


func _start_ambient() -> void:
	ambient_player = AudioStreamPlayer.new()
	ambient_player.bus = "Master"
	ambient_player.volume_db = -18.0

	var stream := AudioStreamGenerator.new()
	stream.mix_rate = int(SAMPLE_RATE)
	stream.buffer_length = 0.7
	ambient_player.stream = stream
	add_child(ambient_player)
	ambient_player.play()
	ambient_playback = ambient_player.get_stream_playback() as AudioStreamGeneratorPlayback


func _stop_ambient() -> void:
	if ambient_player == null:
		return

	var tween := create_tween()
	tween.tween_property(ambient_player, "volume_db", -60.0, 0.8)
	tween.tween_callback(ambient_player.queue_free)


func _fill_ambient_buffer() -> void:
	if ambient_playback == null:
		return

	var frames := ambient_playback.get_frames_available()
	for _frame_index in range(frames):
		var sample := _next_ambient_sample()
		ambient_playback.push_frame(Vector2(sample, sample))


func _next_ambient_sample() -> float:
	var delta := 1.0 / SAMPLE_RATE
	sample_cursor += delta

	var wind := _next_wind_sample()
	var crickets := _next_cricket_sample(delta)
	var cows := _next_cow_sample(delta)
	var wood := _next_wood_creak_sample(delta)
	return clampf(wind + crickets + cows + wood, -0.55, 0.55)


func _next_wind_sample() -> float:
	wind_state = lerpf(wind_state, randf_range(-0.10, 0.10), 0.006)
	return wind_state * 0.42


func _next_cricket_sample(delta: float) -> float:
	if cricket_duration <= 0.0:
		cricket_timer -= delta
		if cricket_timer <= 0.0:
			cricket_age = 0.0
			cricket_duration = randf_range(0.045, 0.09)
			cricket_frequency = randf_range(3600.0, 5200.0)
			cricket_timer = randf_range(0.16, 0.52)
		return 0.0

	cricket_age += delta
	var envelope := 1.0 - clampf(cricket_age / cricket_duration, 0.0, 1.0)
	var sample := sin(TAU * cricket_frequency * sample_cursor) * envelope * 0.13
	if cricket_age >= cricket_duration:
		cricket_duration = 0.0
	return sample


func _next_cow_sample(delta: float) -> float:
	if cow_duration <= 0.0:
		cow_timer -= delta
		if cow_timer <= 0.0:
			cow_age = 0.0
			cow_duration = randf_range(1.1, 1.9)
			cow_frequency = randf_range(72.0, 96.0)
			cow_timer = randf_range(4.2, 7.2)
		return 0.0

	cow_age += delta
	var progress := clampf(cow_age / cow_duration, 0.0, 1.0)
	var attack := smoothstep(0.0, 0.18, progress)
	var release := 1.0 - smoothstep(0.62, 1.0, progress)
	var envelope := attack * release
	var low := sin(TAU * cow_frequency * sample_cursor)
	var harmonic := sin(TAU * cow_frequency * 0.5 * sample_cursor) * 0.45
	if cow_age >= cow_duration:
		cow_duration = 0.0
	return (low + harmonic) * envelope * 0.12


func _next_wood_creak_sample(delta: float) -> float:
	if wood_duration <= 0.0:
		wood_timer -= delta
		if wood_timer <= 0.0:
			wood_age = 0.0
			wood_duration = randf_range(0.18, 0.36)
			wood_frequency = randf_range(140.0, 260.0)
			wood_timer = randf_range(2.8, 5.4)
		return 0.0

	wood_age += delta
	var progress := clampf(wood_age / wood_duration, 0.0, 1.0)
	var envelope := sin(progress * PI) * 0.24
	var wobble := sin(TAU * 3.0 * sample_cursor) * 18.0
	var sample := sin(TAU * (wood_frequency + wobble) * sample_cursor) * envelope
	if wood_age >= wood_duration:
		wood_duration = 0.0
	return sample
