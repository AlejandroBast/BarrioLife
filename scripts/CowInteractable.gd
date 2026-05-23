class_name CowInteractable
extends Area2D

signal interaction_requested

const BREATH_SPEED = 1.8
const BREATH_SCALE_X = 0.012
const BREATH_SCALE_Y = 0.018

@onready var cow_sprite: Sprite2D = $CowSprite

var player_near: bool = false
var base_scale: Vector2
var breath_time: float = 0.0


func _ready() -> void:
	base_scale = cow_sprite.scale
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	_apply_breath(delta)

	if player_near and Input.is_action_just_pressed("interact"):
		interaction_requested.emit()


func is_player_near() -> bool:
	return player_near


func _apply_breath(delta: float) -> void:
	breath_time += delta * BREATH_SPEED
	var breath := (sin(breath_time) + 1.0) * 0.5
	cow_sprite.scale = Vector2(
		base_scale.x * (1.0 + BREATH_SCALE_X * breath),
		base_scale.y * (1.0 + BREATH_SCALE_Y * breath)
	)


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_near = true


func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_near = false
