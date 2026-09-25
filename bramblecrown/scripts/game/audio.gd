extends Node
## Autoload `Sfx`: plays synthesized sound effects and the ambient bed from assets/audio.

const SOUNDS := ["card", "grow", "blight", "hit", "hurt", "ward", "step", "death", "click", "turn", "win", "lose", "summon", "burn"]

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _next := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for s in SOUNDS:
		var path := "res://assets/audio/%s.wav" % s
		if ResourceLoader.exists(path):
			_streams[s] = load(path)
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	add_child(_music)


func play(name_: String, pitch_jitter: float = 0.06, volume_db: float = 0.0) -> void:
	if not _streams.has(name_):
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _streams[name_]
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.volume_db = volume_db + linear_to_db(maxf(0.001, float(Game.settings.get("sfx", 0.8))))
	p.play()


func play_music(track: String) -> void:
	var path := "res://assets/audio/%s.ogg" % track
	if not ResourceLoader.exists(path):
		path = "res://assets/audio/%s.wav" % track
	if not ResourceLoader.exists(path):
		return
	var stream = load(path)
	if _music.stream == stream and _music.playing:
		return
	_music.stream = stream
	_music.volume_db = linear_to_db(maxf(0.001, float(Game.settings.get("music", 0.6)))) - 8.0
	_music.play()
