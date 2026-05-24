class_name HitCircle
extends Control

signal hit_requested(circle: HitCircle)

const BASE_RADIUS = 34.0
const APPROACH_START_RADIUS = 94.0

var zone_id: String = ""
var key_label: String = ""
var circle_color: Color = Color(1.0, 0.82, 0.34)
var lifetime: float = 1.25
var target_time: float = 0.82
var age: float = 0.0
var judged: bool = false


func setup(new_zone_id: String, new_key_label: String, new_color: Color, new_lifetime: float, new_target_time: float) -> void:
	zone_id = new_zone_id
	key_label = new_key_label
	circle_color = new_color
	lifetime = new_lifetime
	target_time = new_target_time


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(160, 160)
	size = Vector2(160, 160)


func _process(delta: float) -> void:
	if judged:
		return

	age += delta
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if judged:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		hit_requested.emit(self)


func get_timing_error() -> float:
	return abs(age - target_time)


func is_expired() -> bool:
	return age > lifetime


func finish_judged() -> void:
	judged = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.18)
	tween.tween_callback(queue_free)


func _draw() -> void:
	var center := size * 0.5
	var target_progress := clampf(age / target_time, 0.0, 1.0)
	var approach_radius := lerpf(APPROACH_START_RADIUS, BASE_RADIUS, target_progress)
	var pulse := 1.0 + sin(age * 18.0) * 0.035
	var fill_color := circle_color
	fill_color.a = 0.82
	var ring_color := circle_color.lightened(0.34)
	ring_color.a = 0.95
	var shadow_color := Color(0.06, 0.025, 0.014, 0.52)
	var dark_ring := Color(0.12, 0.055, 0.025, 0.9)
	var highlight := Color.WHITE
	highlight.a = 0.22

	draw_circle(center + Vector2(4, 7), BASE_RADIUS * 1.10, shadow_color)
	draw_circle(center, BASE_RADIUS * pulse, fill_color)
	draw_circle(center - Vector2(7, 9), BASE_RADIUS * 0.42, highlight)
	draw_arc(center, BASE_RADIUS, 0.0, TAU, 72, dark_ring, 5.0)
	draw_arc(center, BASE_RADIUS + 4.0, -PI * 0.5, -PI * 0.5 + TAU * target_progress, 72, ring_color, 4.0)
	draw_arc(center, approach_radius, 0.0, TAU, 96, ring_color, 5.0)

	var font := get_theme_default_font()
	var label_size := font.get_string_size(key_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 30)
	draw_string(font, center - Vector2(label_size.x * 0.5 - 2.0, -12.0), key_label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 30, Color(0.08, 0.035, 0.02, 0.8))
	draw_string(font, center - Vector2(label_size.x * 0.5, -10.0), key_label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 30, Color.WHITE)
