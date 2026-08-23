extends Node

## Áudio central: música com fade + pool de SFX procedurais.
## Os efeitos vêm do SfxBank (síntese), então o jogo tem som mesmo sem assets.

const SfxBankScript := preload("res://scripts/utils/SfxBank.gd")

const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"
const MENU_MUSIC_PATH := "res://assets/audio/music/ira.mp3"

const SFX_POOL_SIZE := 20

var sfx_pool: Array[AudioStreamPlayer] = []
var music_player: AudioStreamPlayer
var music_tween: Tween
var last_played_at: Dictionary = {}
var _music_cache: Dictionary = {}
var _music_bus_idx: int = 0
var _sfx_bus_idx: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_buses()

	music_player = AudioStreamPlayer.new()
	music_player.bus = MUSIC_BUS
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(music_player)

	for i in range(SFX_POOL_SIZE):
		var sfx := AudioStreamPlayer.new()
		sfx.bus = SFX_BUS
		sfx.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(sfx)
		sfx_pool.append(sfx)

	_apply_volumes()
	EventBus.sfx_requested.connect(_on_sfx_requested)


## Cria os buses Music/SFX em runtime (o projeto não tem default_bus_layout).
func _ensure_buses() -> void:
	_music_bus_idx = AudioServer.get_bus_index(MUSIC_BUS)
	if _music_bus_idx == -1:
		AudioServer.add_bus()
		_music_bus_idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(_music_bus_idx, MUSIC_BUS)
		AudioServer.set_bus_send(_music_bus_idx, "Master")
	_sfx_bus_idx = AudioServer.get_bus_index(SFX_BUS)
	if _sfx_bus_idx == -1:
		AudioServer.add_bus()
		_sfx_bus_idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(_sfx_bus_idx, SFX_BUS)
		AudioServer.set_bus_send(_sfx_bus_idx, "Master")


func _clamp_volume(value: Variant) -> float:
	return clampf(float(value), 0.0, 1.0)


func _apply_volumes() -> void:
	var muted: bool = bool(SaveSystem.get_value("muted", false))
	var music: float = _clamp_volume(SaveSystem.get_value("music_volume", 0.5))
	var sfx: float = _clamp_volume(SaveSystem.get_value("sfx_volume", 0.8))
	AudioServer.set_bus_mute(_music_bus_idx, muted or music <= 0.001)
	AudioServer.set_bus_mute(_sfx_bus_idx, muted or sfx <= 0.001)
	AudioServer.set_bus_volume_db(_music_bus_idx, linear_to_db(maxf(music, 0.0001)))
	AudioServer.set_bus_volume_db(_sfx_bus_idx, linear_to_db(maxf(sfx, 0.0001)))


# --- SFX ---------------------------------------------------------------------

func _on_sfx_requested(key: String, volume: float) -> void:
	play(key, volume)


## Toca um efeito do banco procedural. `min_gap` evita metralhadora de sons.
func play(key: String, volume_scale: float = 1.0, min_gap: float = 0.035) -> void:
	if bool(SaveSystem.get_value("muted", false)):
		return
	var now: float = float(Time.get_ticks_msec()) / 1000.0
	var last: float = last_played_at.get(key, -10.0)
	if now - last < min_gap:
		return
	last_played_at[key] = now
	var stream: AudioStream = SfxBankScript.get_sound(key)
	play_stream(stream, volume_scale)


func play_stream(stream: AudioStream, volume_scale: float = 1.0) -> void:
	if stream == null:
		return
	var player: AudioStreamPlayer = _free_player()
	if player == null:
		return
	player.stream = stream
	player.volume_db = linear_to_db(clampf(volume_scale, 0.05, 2.0))
	player.pitch_scale = randf_range(0.94, 1.06)
	player.play()


func _free_player() -> AudioStreamPlayer:
	for p in sfx_pool:
		if not p.playing:
			return p
	return null


# --- Música ------------------------------------------------------------------

func play_music_track(path: String, fade_seconds: float = 0.8) -> void:
	var stream: AudioStream = _load_music(path)
	if stream == null:
		return
	play_music(stream, fade_seconds)


func play_menu_music() -> void:
	play_music_track(MENU_MUSIC_PATH)


func _load_music(path: String) -> AudioStream:
	if _music_cache.has(path):
		return _music_cache[path]
	var stream: AudioStream = null
	if ResourceLoader.exists(path):
		stream = load(path) as AudioStream
	if stream == null:
		stream = _load_mp3_from_disk(path)
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	if stream != null:
		_music_cache[path] = stream
	return stream


func _load_mp3_from_disk(path: String) -> AudioStreamMP3:
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var bytes := file.get_buffer(file.get_length())
	file.close()
	var stream := AudioStreamMP3.new()
	stream.data = bytes
	return stream


func play_music(stream: AudioStream, fade_seconds: float = 0.6) -> void:
	if music_player.stream == stream and music_player.playing:
		return
	music_player.stream = stream
	music_player.volume_db = -30.0
	music_player.play()
	_kill_music_tween()
	music_tween = create_tween()
	music_tween.tween_property(music_player, "volume_db", 0.0, fade_seconds)


func stop_music(fade_seconds: float = 0.4) -> void:
	if not music_player.playing:
		return
	_kill_music_tween()
	music_tween = create_tween()
	music_tween.tween_property(music_player, "volume_db", -40.0, fade_seconds)
	music_tween.tween_callback(music_player.stop)


## Abaixa a música por um instante (usado em boss/level-up)
func duck(seconds: float = 1.2, amount_db: float = -8.0) -> void:
	if not music_player.playing:
		return
	_kill_music_tween()
	music_tween = create_tween()
	music_tween.tween_property(music_player, "volume_db", amount_db, 0.18)
	music_tween.tween_interval(seconds)
	music_tween.tween_property(music_player, "volume_db", 0.0, 0.6)


func set_music_volume(volume: float) -> void:
	SaveSystem.set_value("music_volume", _clamp_volume(volume))
	_apply_volumes()


func set_sfx_volume(volume: float) -> void:
	SaveSystem.set_value("sfx_volume", _clamp_volume(volume))
	_apply_volumes()
	play("click", 0.8, 0.12)


func set_muted(muted: bool) -> void:
	SaveSystem.set_value("muted", muted)
	_apply_volumes()


func is_muted() -> bool:
	return bool(SaveSystem.get_value("muted", false))


func _kill_music_tween() -> void:
	if music_tween != null and music_tween.is_valid():
		music_tween.kill()
	music_tween = null
