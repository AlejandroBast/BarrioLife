class_name GroundShadow
extends Node2D

@export var radius: float = 48.0
@export var squash: float = 0.20
@export var shadow_color: Color = Color(0.02, 0.014, 0.01, 0.36)


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, squash))

	for layer in range(5, 0, -1):
		var layer_progress := float(layer) / 5.0
		var color := shadow_color
		color.a *= 0.16 + (1.0 - layer_progress) * 0.22
		draw_circle(Vector2.ZERO, radius * (0.58 + layer_progress * 0.42), color)
