extends Node2D

const PAUSE_MENU_SCENE = preload("res://scenes/PauseMenu.tscn")
const FLOOR_TOP_Y = 620.0
const FLOOR_HEIGHT = 72.0
const BACKGROUND_TARGET_HEIGHT = 720.0
const BACKGROUND_BLEND_WIDTH = 320.0
const FARM_MUSIC = "res://assets/audio/granja-fondo.mp3"
const BACKGROUND_PATHS: Array[String] = [
	"res://assets/sprites/farm_bg_01.png",
	"res://assets/sprites/farm_bg_02.png",
	"res://assets/sprites/farm_bg_03.png",
]

@onready var background_segments: Node2D = $BackgroundSegments
@onready var player: CharacterBody2D = $Player
@onready var floor_body: StaticBody2D = $Floor
@onready var floor_collision: CollisionShape2D = $Floor/FloorCollision
@onready var left_wall: StaticBody2D = $LeftWall
@onready var right_wall: StaticBody2D = $RightWall
@onready var objective_trigger: Area2D = $FarmObjectiveTrigger
@onready var objective_label: Label = $UI/ObjectivePanel/ObjectiveLabel
@onready var interact_panel: PanelContainer = $UI/InteractPanel
@onready var interact_label: Label = $UI/InteractPanel/InteractLabel

var level_width: float = 1280.0
var can_complete_objective: bool = false
var objective_completed: bool = false


func _ready() -> void:
	GameState.set_current_location("farm")
	MusicManager.play_music(FARM_MUSIC)
	level_width = _build_backgrounds()
	_configure_level_bounds()
	_refresh_ui()


func _process(_delta: float) -> void:
	can_complete_objective = _is_player_near_objective()
	interact_panel.visible = can_complete_objective and not objective_completed

	if can_complete_objective and not objective_completed and Input.is_action_pressed("interact"):
		_complete_farm_objective()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.is_action_pressed("pause_game"):
		get_viewport().set_input_as_handled()
		_open_pause_menu()


func _build_backgrounds() -> float:
	var next_x := 0.0

	for index in BACKGROUND_PATHS.size():
		var path: String = BACKGROUND_PATHS[index]
		if not FileAccess.file_exists(path):
			continue

		var texture := load(path) as Texture2D
		if texture == null:
			continue

		var scale_factor: float = BACKGROUND_TARGET_HEIGHT / float(texture.get_height())
		var segment_width: float = float(texture.get_width()) * scale_factor
		var has_previous: bool = index > 0
		var has_next: bool = index < BACKGROUND_PATHS.size() - 1
		var blend_ratio: float = BACKGROUND_BLEND_WIDTH / segment_width

		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.centered = true
		sprite.scale = Vector2(scale_factor, scale_factor)
		sprite.position = Vector2(next_x + segment_width * 0.5, BACKGROUND_TARGET_HEIGHT * 0.5)
		sprite.material = _create_background_blend_material(has_previous, has_next, blend_ratio)
		background_segments.add_child(sprite)

		next_x += segment_width
		if has_next:
			next_x -= BACKGROUND_BLEND_WIDTH

	return maxf(next_x, 1280.0)


func _create_background_blend_material(fade_left: bool, fade_right: bool, fade_width_ratio: float) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform bool fade_left = false;
uniform bool fade_right = false;
uniform float fade_width = 0.1;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	float edge_alpha = 1.0;

	if (fade_left) {
		edge_alpha *= smoothstep(0.0, fade_width, UV.x);
	}

	if (fade_right) {
		edge_alpha *= 1.0 - smoothstep(1.0 - fade_width, 1.0, UV.x);
	}

	COLOR = vec4(color.rgb, color.a * edge_alpha);
}
"""

	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("fade_left", fade_left)
	material.set_shader_parameter("fade_right", fade_right)
	material.set_shader_parameter("fade_width", clampf(fade_width_ratio, 0.02, 0.35))
	return material


func _configure_level_bounds() -> void:
	player.position = Vector2(120.0, FLOOR_TOP_Y)
	floor_body.position = Vector2(level_width * 0.5, FLOOR_TOP_Y + FLOOR_HEIGHT * 0.5)
	left_wall.position = Vector2(-16.0, 360.0)
	right_wall.position = Vector2(level_width + 16.0, 360.0)
	objective_trigger.position = Vector2(level_width - 220.0, FLOOR_TOP_Y - 95.0)

	var floor_shape := RectangleShape2D.new()
	floor_shape.size = Vector2(level_width, FLOOR_HEIGHT)
	floor_collision.shape = floor_shape

	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera != null:
		camera.limit_left = 0
		camera.limit_right = int(level_width)
		camera.limit_top = 0
		camera.limit_bottom = 720


func _refresh_ui() -> void:
	objective_completed = GameState.is_objective_completed("farm_tutorial_completed")
	if objective_completed:
		objective_label.text = "Granja: objetivo completado\nPueblo desbloqueado. Presiona M para abrir el mapa."
	else:
		objective_label.text = "Granja\nExplora el camino y llega al final.\nPresiona M para abrir el mapa."

	interact_label.text = "Presiona E para completar el objetivo de la granja"


func _is_player_near_objective() -> bool:
	if player == null or objective_trigger == null:
		return false

	return player.global_position.distance_to(objective_trigger.global_position) <= 210.0


func _complete_farm_objective() -> void:
	objective_completed = true
	GameState.complete_objective("farm_tutorial_completed")
	interact_panel.visible = false
	_refresh_ui()


func _on_farm_objective_trigger_body_entered(body: Node2D) -> void:
	if body == player:
		can_complete_objective = true


func _on_farm_objective_trigger_body_exited(body: Node2D) -> void:
	if body == player:
		can_complete_objective = false


func _open_pause_menu() -> void:
	if get_tree().paused or has_node("PauseMenu"):
		return

	var pause_menu := PAUSE_MENU_SCENE.instantiate()
	add_child(pause_menu)
