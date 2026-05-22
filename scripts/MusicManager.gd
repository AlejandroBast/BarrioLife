extends Node

const DEFAULT_FADE_TIME = 1.4
const DEFAULT_VOLUME_DB = -10.0
const SILENCE_DB = -60.0

var current_track_path: String = ""
var active_player_index: int = 0
var player_a: AudioStreamPlayer
var player_b: AudioStreamPlayer
var fade_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	player_a = _create_player()
	player_b = _create_player()
	add_child(player_a)
	add_child(player_b)


func play_music(track_path: String, fade_time: float = DEFAULT_FADE_TIME, volume_db: float = DEFAULT_VOLUME_DB) -> void:
	if track_path == "":
		stop_music(fade_time)
		return

	var active_player := _get_active_player()
	if current_track_path == track_path and active_player.playing:
		_fade_player(active_player, volume_db, fade_time)
		return

	var stream := load(track_path) as AudioStream
	if stream == null:
		push_warning("No se pudo cargar la musica: %s" % track_path)
		return

	_try_enable_loop(stream)

	var next_player := _get_inactive_player()
	next_player.stop()
	next_player.stream = stream
	next_player.volume_db = SILENCE_DB
	next_player.play()

	if fade_tween != null:
		fade_tween.kill()

	fade_tween = create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(next_player, "volume_db", volume_db, fade_time)

	if active_player.playing:
		fade_tween.tween_property(active_player, "volume_db", SILENCE_DB, fade_time)
		fade_tween.chain().tween_callback(Callable(active_player, "stop"))

	current_track_path = track_path
	active_player_index = 1 - active_player_index


func stop_music(fade_time: float = DEFAULT_FADE_TIME) -> void:
	current_track_path = ""

	if fade_tween != null:
		fade_tween.kill()

	fade_tween = create_tween()
	fade_tween.set_parallel(true)

	for player in [player_a, player_b]:
		if player.playing:
			fade_tween.tween_property(player, "volume_db", SILENCE_DB, fade_time)

	fade_tween.chain().tween_callback(Callable(self, "_stop_all_players"))


func _create_player() -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = "Master"
	player.volume_db = SILENCE_DB
	return player


func _get_active_player() -> AudioStreamPlayer:
	return player_a if active_player_index == 0 else player_b


func _get_inactive_player() -> AudioStreamPlayer:
	return player_b if active_player_index == 0 else player_a


func _fade_player(player: AudioStreamPlayer, volume_db: float, fade_time: float) -> void:
	if fade_tween != null:
		fade_tween.kill()

	fade_tween = create_tween()
	fade_tween.tween_property(player, "volume_db", volume_db, fade_time)


func _stop_all_players() -> void:
	player_a.stop()
	player_b.stop()


func _try_enable_loop(stream: AudioStream) -> void:
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
