extends Node2D

const BREATH_SPEED = 2.0
const BREATH_SCALE_X = 0.008
const BREATH_SCALE_Y = 0.016
const BREATH_LIFT = 3.0

@onready var body: Node2D = $Body
@onready var sprite: Sprite2D = $Body/Sprite2D
@onready var missing_image_label: Label = $MissingImageLabel

var base_body_position: Vector2
var base_body_scale: Vector2
var breath_time: float = 0.0


func _ready() -> void:
	_load_real_sprite()
	base_body_position = body.position
	base_body_scale = body.scale


func _process(delta: float) -> void:
	breath_time += delta * BREATH_SPEED
	var breath := (sin(breath_time) + 1.0) * 0.5
	body.scale = Vector2(
		base_body_scale.x * (1.0 + BREATH_SCALE_X * breath),
		base_body_scale.y * (1.0 + BREATH_SCALE_Y * breath)
	)
	body.position = base_body_position + Vector2(0.0, -BREATH_LIFT * breath)


func _load_real_sprite() -> void:
	if not FileAccess.file_exists("res://assets/sprites/battle_npc.png"):
		sprite.visible = false
		missing_image_label.visible = true
		return

	var texture := load("res://assets/sprites/battle_npc.png") as Texture2D
	if texture == null:
		sprite.visible = false
		missing_image_label.visible = true
		return

	sprite.texture = texture
	sprite.visible = true
	missing_image_label.visible = false
