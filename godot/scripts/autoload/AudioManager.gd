extends Node

const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"

var sfx_pool: Array[AudioStreamPlayer] = []
var music_player: AudioStreamPlayer
var last_played_at: Dictionary = {}


func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	music_player.volume_db = linear_to_db(_clamp_volume(SaveSystem.get_value("music_volume", 0.5)))
	add_child(music_player)

	for i in range(8):
		var sfx := AudioStreamPlayer.new()
		sfx.bus = "Master"
		add_child(sfx)
		sfx_pool.append(sfx)


func _clamp_volume(value: Variant) -> float:
	return clampf(float(value), 0.0, 1.0)


func play_sfx(stream: AudioStream, key: String = "", min_gap: float = 0.04, volume_scale: float = 1.0) -> void:
	if stream == null:
		return
	if SaveSystem.get_value("muted", false):
		return
	if key != "":
		var now := Time.get_ticks_msec() / 1000.0
		var last: float = last_played_at.get(key, -10.0)
		if now - last < min_gap:
			return
		last_played_at[key] = now

	for sfx in sfx_pool:
		if not sfx.playing:
			var volume := _clamp_volume(SaveSystem.get_value("sfx_volume", 0.8)) * volume_scale
			sfx.volume_db = linear_to_db(max(volume, 0.0001))
			sfx.stream = stream
			sfx.play()
			return


func play_music(stream: AudioStream, fade_seconds: float = 0.6) -> void:
	if music_player.stream == stream and music_player.playing:
		return
	music_player.stream = stream
	var target_db := linear_to_db(max(_clamp_volume(SaveSystem.get_value("music_volume", 0.5)), 0.0001))
	if SaveSystem.get_value("muted", false):
		target_db = -80.0
	music_player.volume_db = -40.0
	music_player.play()
	var tween := create_tween()
	tween.tween_property(music_player, "volume_db", target_db, fade_seconds)


func set_music_volume(volume: float) -> void:
	SaveSystem.set_value("music_volume", _clamp_volume(volume))
	if SaveSystem.get_value("muted", false):
		music_player.volume_db = -80.0
	else:
		music_player.volume_db = linear_to_db(max(_clamp_volume(volume), 0.0001))


func set_sfx_volume(volume: float) -> void:
	SaveSystem.set_value("sfx_volume", _clamp_volume(volume))


func set_muted(muted: bool) -> void:
	SaveSystem.set_value("muted", muted)
	if muted:
		music_player.volume_db = -80.0
	else:
		music_player.volume_db = linear_to_db(max(_clamp_volume(SaveSystem.get_value("music_volume", 0.5)), 0.0001))
