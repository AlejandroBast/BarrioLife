class_name MilkDrop
extends Node2D

var velocity: Vector2 = Vector2.ZERO
var gravity: float = 680.0
var lifetime: float = 0.56
var radius: float = 8.0
var age: float = 0.0


func setup(start_position: Vector2, start_velocity: Vector2, drop_radius: float = 8.0, drop_lifetime: float = 0.56) -> void:
	position = start_position
	velocity = start_velocity
	radius = drop_radius
	lifetime = drop_lifetime
	age = 0.0
	scale = Vector2(0.86, 0.86)


func _process(delta: float) -> void:
	age += delta
	velocity.y += gravity * delta
	position += velocity * delta

	var progress := clampf(age / lifetime, 0.0, 1.0)
	scale = Vector2.ONE * lerpf(0.86, 1.30, minf(progress * 2.0, 1.0))

	var current_modulate := modulate
	current_modulate.a = 1.0 - progress
	modulate = current_modulate

	queue_redraw()

	if age >= lifetime:
		queue_free()


func _draw() -> void:
	var milk_color := Color(0.96, 0.99, 1.0, 0.95)
	var shine_color := Color(1.0, 1.0, 1.0, 0.74)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.72, 1.36))
	draw_circle(Vector2.ZERO, radius, milk_color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(Vector2(-radius * 0.22, -radius * 0.34), radius * 0.26, shine_color)
