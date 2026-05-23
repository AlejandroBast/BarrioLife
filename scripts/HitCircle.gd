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
	var fill_color := circle_color
	fill_color.a = 0.72
	var ring_color := circle_color.lightened(0.34)
	ring_color.a = 0.95

	draw_circle(center, BASE_RADIUS, fill_color)
	draw_arc(center, BASE_RADIUS, 0.0, TAU, 64, Color(0.12, 0.06, 0.03, 0.9), 4.0)
	draw_arc(center, approach_radius, 0.0, TAU, 72, ring_color, 5.0)

	var font := get_theme_default_font()
	var label_size := font.get_string_size(key_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 30)
	draw_string(font, center - Vector2(label_size.x * 0.5, -10.0), key_label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 30, Color.WHITE)
