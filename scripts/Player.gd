extends CharacterBody2D

const SPEED = 200.0
const GRAVITY = 1200.0
const FRAME_WIDTH = 256
const FRAME_HEIGHT = 682
const FRAME_COUNT = 7
const WALK_FIRST_FRAME = 1
const WALK_FPS = 12.0
const BREATH_SPEED = 2.4
const BREATH_SCALE_X = 0.010
const BREATH_SCALE_Y = 0.018
const BREATH_LIFT = 2.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var base_sprite_position: Vector2
var base_sprite_scale: Vector2
var breath_time: float = 0.0


func _ready() -> void:
	base_sprite_position = animated_sprite.position
	base_sprite_scale = animated_sprite.scale
	_setup_sprite_frames()
	_play_idle()


func _physics_process(delta: float) -> void:
	var direction := _get_move_direction()

	velocity.x = direction * SPEED
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0

	if direction != 0.0:
		_reset_breath_pose()
		animated_sprite.flip_h = direction < 0.0
		if animated_sprite.animation != "walk":
			animated_sprite.play("walk")
	else:
		_play_idle()
		_apply_idle_breath(delta)

	move_and_slide()


func _get_move_direction() -> float:
	var direction := 0.0
	if Input.is_action_pressed("move_left"):
		direction -= 1.0
	if Input.is_action_pressed("move_right"):
		direction += 1.0
	return direction


func _setup_sprite_frames() -> void:
	var texture := load("res://assets/sprites/player_walk.png") as Texture2D
	if texture == null:
		push_error("No se pudo cargar res://assets/sprites/player_walk.png")
		return

	# Frame 0 es idle. Los frames 1..6 son la caminata.
	var sprite_frames := SpriteFrames.new()
	sprite_frames.add_animation("idle")
	sprite_frames.set_animation_loop("idle", true)
	sprite_frames.set_animation_speed("idle", 1.0)
	sprite_frames.add_frame("idle", _make_frame(texture, 0))

	sprite_frames.add_animation("walk")
	sprite_frames.set_animation_loop("walk", true)
	sprite_frames.set_animation_speed("walk", WALK_FPS)

	for frame_index in range(WALK_FIRST_FRAME, FRAME_COUNT):
		sprite_frames.add_frame("walk", _make_frame(texture, frame_index))

	animated_sprite.sprite_frames = sprite_frames


func _make_frame(texture: Texture2D, frame_index: int) -> Texture2D:
	var atlas_texture := AtlasTexture.new()
	atlas_texture.atlas = texture
	atlas_texture.region = Rect2(frame_index * FRAME_WIDTH, 0, FRAME_WIDTH, FRAME_HEIGHT)
	return atlas_texture


func _play_idle() -> void:
	if animated_sprite.sprite_frames == null:
		return

	if animated_sprite.animation != "idle":
		animated_sprite.play("idle")
	animated_sprite.frame = 0
	animated_sprite.pause()


func _apply_idle_breath(delta: float) -> void:
	breath_time += delta * BREATH_SPEED
	var breath := (sin(breath_time) + 1.0) * 0.5
	animated_sprite.scale = Vector2(
		base_sprite_scale.x * (1.0 + BREATH_SCALE_X * breath),
		base_sprite_scale.y * (1.0 + BREATH_SCALE_Y * breath)
	)
	animated_sprite.position = base_sprite_position + Vector2(0.0, -BREATH_LIFT * breath)


func _reset_breath_pose() -> void:
	animated_sprite.scale = base_sprite_scale
	animated_sprite.position = base_sprite_position
