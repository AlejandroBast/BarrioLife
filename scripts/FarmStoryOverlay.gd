class_name FarmStoryOverlay
extends CanvasLayer

signal story_finished

var lines: Array[String] = []
var hold_time: float = 1.55
var fade_time: float = 0.85
var final_black_hold: float = 0.25

var black_rect: ColorRect
var story_label: Label


func setup(story_lines: Array, line_hold_time: float = 1.55) -> void:
	lines.clear()
	for line in story_lines:
		lines.append(String(line))
	hold_time = line_hold_time


func _ready() -> void:
	layer = 55
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	call_deferred("_play_story")


func _build_ui() -> void:
	black_rect = ColorRect.new()
	black_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	black_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(black_rect)

	story_label = Label.new()
	story_label.set_anchors_preset(Control.PRESET_CENTER)
	story_label.offset_left = -430.0
	story_label.offset_top = -90.0
	story_label.offset_right = 430.0
	story_label.offset_bottom = 90.0
	story_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	story_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story_label.add_theme_font_size_override("font_size", 31)
	story_label.add_theme_color_override("font_color", Color(0.94, 0.90, 0.80))
	story_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	story_label.add_theme_constant_override("shadow_offset_x", 2)
	story_label.add_theme_constant_override("shadow_offset_y", 3)
	story_label.modulate.a = 0.0
	add_child(story_label)


func _play_story() -> void:
	var fade_in := create_tween()
	fade_in.tween_property(black_rect, "color:a", 1.0, 0.95)
	await fade_in.finished

	for line in lines:
		await _show_line(line)

	await get_tree().create_timer(final_black_hold).timeout
	var fade_out := create_tween()
	fade_out.tween_property(black_rect, "color:a", 0.0, 1.15)
	await fade_out.finished

	story_finished.emit()
	queue_free()


func _show_line(text: String) -> void:
	story_label.text = text
	story_label.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(story_label, "modulate:a", 1.0, fade_time)
	tween.tween_interval(_get_hold_time(text))
	tween.tween_property(story_label, "modulate:a", 0.0, fade_time)
	await tween.finished


func _get_hold_time(text: String) -> float:
	return maxf(hold_time, minf(3.2, 0.06 * float(text.length())))
