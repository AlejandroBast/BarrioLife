extends Node2D

const PAUSE_MENU_SCENE = preload("res://scenes/PauseMenu.tscn")
const FARM_INTRO_SCRIPT = preload("res://scripts/FarmIntroOverlay.gd")
const FARM_STORY_SCRIPT = preload("res://scripts/FarmStoryOverlay.gd")
const MILKING_MINIGAME_SCENE = "res://scenes/MilkingMinigame.tscn"
const BATTLE_SCENE = "res://scenes/BattleScene.tscn"
const FLOOR_TOP_Y = 620.0
const FLOOR_HEIGHT = 72.0
const BACKGROUND_TARGET_HEIGHT = 720.0
const BACKGROUND_BLEND_WIDTH = 320.0
const FARM_MUSIC = "res://assets/audio/granja-fondo.mp3"
const BATTLE_MARKER_Y = FLOOR_TOP_Y - 88.0
const BATTLE_INTERACT_DISTANCE = 155.0
const BATTLE_MARKER_SPACING = 430.0
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
@onready var cow_interactable: CowInteractable = $CowInteractable
@onready var objective_trigger: Area2D = $FarmObjectiveTrigger
@onready var objective_panel: PanelContainer = $UI/ObjectivePanel
@onready var objective_label: Label = $UI/ObjectivePanel/ObjectiveLabel
@onready var interact_panel: PanelContainer = $UI/InteractPanel
@onready var interact_label: Label = $UI/InteractPanel/InteractLabel

var level_width: float = 1280.0
var can_complete_objective: bool = false
var objective_completed: bool = false
var intro_active: bool = false
var story_active: bool = false
var currentObjective: String = ""
var battle_marker_layer: Node2D
var battle_markers: Dictionary = {}
var current_near_battle_id: String = ""


func _ready() -> void:
	GameState.set_current_location("farm")
	cow_interactable.interaction_requested.connect(_on_cow_milking_requested)
	if not GameState.money_changed.is_connected(_on_money_changed):
		GameState.money_changed.connect(_on_money_changed)
	level_width = _build_backgrounds()
	_configure_level_bounds()
	_build_battle_challenges()
	if GameState.is_objective_completed("farm_intro_completed"):
		_begin_farm_gameplay()
	else:
		_start_farm_intro()


func _process(_delta: float) -> void:
	if intro_active or story_active:
		interact_panel.visible = false
		return

	can_complete_objective = _is_player_near_objective()
	var can_milk_cow: bool = cow_interactable != null and cow_interactable.is_player_near()
	var cow_completed: bool = GameState.is_objective_completed("farm_cow_milking_completed")
	current_near_battle_id = _get_near_battle_id()

	if can_milk_cow:
		interact_panel.visible = true
		interact_label.text = "Presiona %s para ordeñar" % SettingsManager.get_action_label("interact")
	elif current_near_battle_id != "":
		interact_panel.visible = true
		interact_label.text = _get_battle_interact_text(current_near_battle_id)
	elif can_complete_objective and not objective_completed:
		interact_panel.visible = true
		if cow_completed:
			interact_label.text = "Presiona %s para completar el objetivo de la granja" % SettingsManager.get_action_label("interact")
		else:
			interact_label.text = "Primero ayuda con la vaca para completar la rutina de la granja"
	else:
		interact_panel.visible = false

	if Input.is_action_just_pressed("interact"):
		if can_milk_cow:
			_on_cow_milking_requested()
		elif current_near_battle_id != "":
			_try_start_farm_battle(current_near_battle_id)
		elif can_complete_objective and not objective_completed:
			_complete_farm_objective()


func _unhandled_input(event: InputEvent) -> void:
	if intro_active or story_active:
		get_viewport().set_input_as_handled()
		return

	if event is InputEventKey and event.pressed and not event.echo and event.is_action_pressed("pause_game"):
		get_viewport().set_input_as_handled()
		_open_pause_menu()


func _start_farm_intro() -> void:
	intro_active = true
	currentObjective = "Despertar"
	objective_panel.visible = false
	interact_panel.visible = false
	_set_player_control_enabled(false)

	var intro_overlay := FARM_INTRO_SCRIPT.new() as FarmIntroOverlay
	intro_overlay.intro_finished.connect(_on_farm_intro_finished)
	add_child(intro_overlay)


func _on_farm_intro_finished() -> void:
	GameState.complete_objective("farm_intro_completed")
	_begin_farm_gameplay()


func _begin_farm_gameplay() -> void:
	intro_active = false
	currentObjective = "Ordeñar las vacas"
	GameState.set_current_objective(currentObjective)
	objective_panel.visible = true
	_set_player_control_enabled(true)
	MusicManager.play_music(FARM_MUSIC)
	_refresh_ui()
	_apply_current_farm_objective_text()
	_refresh_battle_challenges()
	_play_pending_farm_story_event()


func _set_player_control_enabled(is_enabled: bool) -> void:
	if player == null:
		return

	if player.has_method("set_input_locked"):
		player.call("set_input_locked", not is_enabled)
	else:
		player.set_physics_process(is_enabled)


func _apply_current_farm_objective_text() -> void:
	if GameState.is_objective_completed("farm_chapter_completed"):
		currentObjective = "Capitulo 1 completado"
		GameState.set_current_objective(currentObjective)
		objective_label.text = "Granja\nCapitulo 1 completado. Pueblo desbloqueado.\nDinero: $%d  |  Presiona M para abrir el mapa." % GameState.get_money()
		return

	var next_battle := GameState.get_next_available_farm_battle()
	if not next_battle.is_empty():
		currentObjective = "Prepararse para %s" % String(next_battle["name"])
		GameState.set_current_objective(currentObjective)
		objective_label.text = "Granja\nSiguiente batalla: %s\nCosto: $%d  |  Dinero: $%d\nTrabaja con la vaca si necesitas ahorrar." % [
			String(next_battle["name"]),
			int(next_battle["cost"]),
			GameState.get_money(),
		]
		return

	if objective_completed:
		currentObjective = "Granja completada"
		GameState.set_current_objective(currentObjective)
		objective_label.text = "Granja: objetivo completado\nPueblo desbloqueado. Presiona M para abrir el mapa."
	elif GameState.is_objective_completed("farm_cow_milking_completed"):
		currentObjective = "Cerrar el tutorial de la granja"
		GameState.set_current_objective(currentObjective)
		objective_label.text = "Granja\nOrdeño completado. Ve al final del camino para cerrar el tutorial.\nPresiona M para abrir el mapa."
	else:
		currentObjective = "Ordeñar las vacas"
		GameState.set_current_objective(currentObjective)
		objective_label.text = "Granja\nObjetivo: ordeñar las vacas antes de que salga el sol.\nPresiona M para abrir el mapa."


func _build_battle_challenges() -> void:
	battle_marker_layer = Node2D.new()
	battle_marker_layer.name = "BattleChallenges"
	battle_marker_layer.z_index = 4
	add_child(battle_marker_layer)

	var start_x := minf(1280.0, level_width - 1280.0)
	start_x = maxf(1120.0, start_x)
	for index in range(GameState.farm_battle_order.size()):
		var battle_id: String = GameState.farm_battle_order[index]
		var battle := GameState.get_farm_battle(battle_id)
		if battle.is_empty():
			continue

		var marker := _create_battle_marker(battle)
		marker.position = Vector2(start_x + float(index) * BATTLE_MARKER_SPACING, BATTLE_MARKER_Y)
		battle_marker_layer.add_child(marker)
		battle_markers[battle_id] = marker

	_refresh_battle_challenges()


func _create_battle_marker(battle: Dictionary) -> Node2D:
	var root := Node2D.new()
	root.name = "Battle_%s" % String(battle["id"])

	var glow := Polygon2D.new()
	glow.name = "Glow"
	glow.color = Color(1.0, 0.64, 0.22, 0.30)
	glow.polygon = PackedVector2Array([
		Vector2(-78, 106),
		Vector2(-42, 78),
		Vector2(42, 78),
		Vector2(78, 106),
		Vector2(42, 128),
		Vector2(-42, 128),
	])
	root.add_child(glow)

	var portrait_path := String(battle.get("portrait_path", ""))
	if portrait_path != "" and FileAccess.file_exists(portrait_path):
		_add_battle_marker_portrait(root, portrait_path)
	else:
		_add_battle_marker_placeholder(root, battle)

	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.position = Vector2(-118, 126)
	name_label.size = Vector2(236, 26)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	root.add_child(name_label)

	var cost_label := Label.new()
	cost_label.name = "CostLabel"
	cost_label.position = Vector2(-118, 152)
	cost_label.size = Vector2(236, 24)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.add_theme_font_size_override("font_size", 15)
	root.add_child(cost_label)

	return root


func _add_battle_marker_portrait(root: Node2D, portrait_path: String) -> void:
	var sprite := Sprite2D.new()
	sprite.name = "Portrait"
	sprite.texture = load(portrait_path) as Texture2D
	sprite.centered = true
	sprite.position = Vector2(0, -2)
	root.add_child(sprite)

	if sprite.texture == null:
		return

	var texture_size := sprite.texture.get_size()
	var scale_factor := minf(185.0 / texture_size.x, 245.0 / texture_size.y)
	sprite.scale = Vector2.ONE * scale_factor


func _add_battle_marker_placeholder(root: Node2D, battle: Dictionary) -> void:
	var body := Polygon2D.new()
	body.name = "Body"
	body.position = Vector2(0, 26)
	var body_color: Color = battle.get("theme_color", Color(0.6, 0.4, 0.25)) as Color
	body.color = body_color
	body.polygon = PackedVector2Array([
		Vector2(-28, -72),
		Vector2(28, -72),
		Vector2(38, 42),
		Vector2(-38, 42),
	])
	root.add_child(body)

	var head := Polygon2D.new()
	head.name = "Head"
	head.position = Vector2(0, -66)
	head.color = Color(0.95, 0.74, 0.55)
	head.polygon = PackedVector2Array([
		Vector2(-30, -28),
		Vector2(30, -28),
		Vector2(34, 12),
		Vector2(16, 34),
		Vector2(-16, 34),
		Vector2(-34, 12),
	])
	root.add_child(head)


func _refresh_battle_challenges() -> void:
	for battle_id in battle_markers.keys():
		var battle := GameState.get_farm_battle(String(battle_id))
		var marker := battle_markers[battle_id] as Node2D
		if battle.is_empty() or marker == null:
			continue

		var is_unlocked := GameState.is_farm_battle_unlocked(String(battle_id))
		var is_completed := GameState.is_farm_battle_completed(String(battle_id))
		var can_afford := GameState.get_money() >= int(battle["cost"])
		var alpha := 1.0 if is_unlocked and not is_completed else 0.45
		marker.modulate = Color(1, 1, 1, alpha)
		marker.visible = is_unlocked or is_completed

		var glow := marker.get_node_or_null("Glow") as Polygon2D
		if glow != null:
			glow.visible = is_unlocked and not is_completed
			glow.color = Color(0.55, 1.0, 0.42, 0.34) if can_afford else Color(1.0, 0.64, 0.22, 0.28)

		var name_label := marker.get_node_or_null("NameLabel") as Label
		if name_label != null:
			name_label.text = String(battle["name"]) if not is_completed else "%s - ganado" % String(battle["name"])

		var cost_label := marker.get_node_or_null("CostLabel") as Label
		if cost_label != null:
			if is_completed:
				cost_label.text = "Reto superado"
			elif is_unlocked:
				cost_label.text = "Costo: $%d" % int(battle["cost"])
			else:
				cost_label.text = "Bloqueado"


func _get_near_battle_id() -> String:
	if player == null:
		return ""

	for battle_id in battle_markers.keys():
		var marker := battle_markers[battle_id] as Node2D
		if marker == null or not marker.visible:
			continue

		if player.global_position.distance_to(marker.global_position + Vector2(0, 70)) <= BATTLE_INTERACT_DISTANCE:
			return String(battle_id)

	return ""


func _get_battle_interact_text(battle_id: String) -> String:
	var battle := GameState.get_farm_battle(battle_id)
	if battle.is_empty():
		return ""

	if GameState.is_farm_battle_completed(battle_id):
		return "Ya ganaste este reto"

	if not GameState.is_farm_battle_unlocked(battle_id):
		return "Todavia no esta desbloqueado"

	var cost := int(battle["cost"])
	if GameState.get_money() < cost:
		return "%s cuesta $%d. Tienes $%d." % [String(battle["name"]), cost, GameState.get_money()]

	return "Presiona %s para retar a %s ($%d)" % [
		SettingsManager.get_action_label("interact"),
		String(battle["name"]),
		cost,
	]


func _try_start_farm_battle(battle_id: String) -> void:
	var battle := GameState.get_farm_battle(battle_id)
	if battle.is_empty():
		return

	if GameState.is_farm_battle_completed(battle_id):
		interact_label.text = "Ese reto ya fue superado"
		return

	if not GameState.is_farm_battle_unlocked(battle_id):
		interact_label.text = "Completa el reto anterior primero"
		return

	var cost := int(battle["cost"])
	if GameState.get_money() < cost:
		interact_label.text = "Necesitas $%d para este reto. Tienes $%d." % [cost, GameState.get_money()]
		return

	if not GameState.spend_money(cost):
		return

	GameState.set_selected_farm_battle(battle_id)
	get_tree().change_scene_to_file(BATTLE_SCENE)


func _play_pending_farm_story_event() -> void:
	var event_id := GameState.consume_pending_farm_story_event()
	if event_id == "":
		return

	var lines := GameState.get_farm_story_lines(event_id)
	if lines.is_empty():
		return

	story_active = true
	interact_panel.visible = false
	_set_player_control_enabled(false)
	MusicManager.stop_music(0.8)

	var story_overlay := FARM_STORY_SCRIPT.new() as FarmStoryOverlay
	story_overlay.setup(lines, 1.6)
	story_overlay.story_finished.connect(_on_farm_story_finished)
	add_child(story_overlay)


func _on_farm_story_finished() -> void:
	story_active = false
	_set_player_control_enabled(true)
	MusicManager.play_music(FARM_MUSIC)
	_refresh_battle_challenges()
	_apply_current_farm_objective_text()


func _on_money_changed(_new_amount: int) -> void:
	_refresh_battle_challenges()
	_apply_current_farm_objective_text()


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
	cow_interactable.position = Vector2(760.0, FLOOR_TOP_Y - 2.0)
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
	elif GameState.is_objective_completed("farm_cow_milking_completed"):
		objective_label.text = "Granja\nOrdeño completado. Ve al final del camino para cerrar el tutorial.\nPresiona M para abrir el mapa."
	else:
		objective_label.text = "Granja\nAcercate a la vaca y aprende a ordeñar.\nPresiona M para abrir el mapa."

	interact_label.text = "Presiona %s para interactuar" % SettingsManager.get_action_label("interact")


func _is_player_near_objective() -> bool:
	if player == null or objective_trigger == null:
		return false

	return player.global_position.distance_to(objective_trigger.global_position) <= 210.0


func _complete_farm_objective() -> void:
	if not GameState.is_objective_completed("farm_cow_milking_completed"):
		interact_label.text = "Primero ayuda con la vaca antes de completar el tutorial"
		return

	objective_completed = true
	GameState.complete_objective("farm_tutorial_completed")
	interact_panel.visible = false
	_refresh_ui()
	_apply_current_farm_objective_text()


func _on_cow_milking_requested() -> void:
	get_tree().change_scene_to_file(MILKING_MINIGAME_SCENE)


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
