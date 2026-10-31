extends Node
## AudioManager — genera todo el audio del juego de forma procedural (sin assets).
## Ofrece SFX (swing, hit, heavy strike, dash, parry, stagger, roar...) y dos
## pistas musicales (tensión de fase 1 y épica de fase 2).
## Se registra como autoload "Audio".

const SR := 22050            # Frecuencia de muestreo (suficiente y ligera).
const SFX_POOL := 8          # Reproducciones simultáneas de efectos.
const MUSIC_LOOP_SECONDS := 8.0

var _sfx: Dictionary = {}    # name -> AudioStreamWAV
var _music_tracks: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_index: int = 0
var _music_player: AudioStreamPlayer
var _current_music: String = ""
var _music_tween: Tween = null
const MUSIC_NORMAL_DB: float = -8.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_streams()
	_ensure_buses()

	for i in SFX_POOL:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_players.append(p)

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	_music_player.volume_db = -8.0
	add_child(_music_player)

## Crea los buses Music/SFX para que los sliders de ajustes sean independientes.
func _ensure_buses() -> void:
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)

# ---------------------------------------------------------------------------
# API pública
# ---------------------------------------------------------------------------

func play_sfx(sfx_name: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not _sfx.has(sfx_name):
		return
	var p := _sfx_players[_sfx_index]
	_sfx_index = (_sfx_index + 1) % _sfx_players.size()
	p.stream = _sfx[sfx_name]
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()

func _cancel_music_tween() -> void:
	if _music_tween != null and _music_tween.is_running():
		_music_tween.kill()
	_music_tween = null

func play_music(track: String) -> void:
	if not _music_tracks.has(track):
		return
	# Las tres fases comparten esta misma pista: no volver a empezar al cambiar de fase.
	var target_stream: AudioStream = _music_tracks[track] as AudioStream
	if _music_player.playing and _music_player.stream == target_stream:
		_current_music = track
		return
	if track == _current_music and _music_player.playing:
		return
	_current_music = track
	_cancel_music_tween()
	if _music_player.playing:
		_music_tween = create_tween()
		_music_tween.tween_property(_music_player, "volume_db", -40.0, 0.35)
		_music_tween.tween_callback(func() -> void:
			_music_player.stream = _music_tracks[track]
			_music_player.volume_db = -40.0
			_music_player.play()
		)
		_music_tween.tween_property(_music_player, "volume_db", MUSIC_NORMAL_DB, 0.65)
	else:
		_music_player.stream = _music_tracks[track]
		_music_player.volume_db = -40.0
		_music_player.play()
		_music_tween = create_tween()
		_music_tween.tween_property(_music_player, "volume_db", MUSIC_NORMAL_DB, 1.1)

func stop_music() -> void:
	_current_music = ""
	_cancel_music_tween()
	if not _music_player.playing:
		return
	_music_tween = create_tween()
	_music_tween.tween_property(_music_player, "volume_db", -40.0, 0.55)
	_music_tween.tween_callback(_music_player.stop)

# ---------------------------------------------------------------------------
# Construcción de los streams
# ---------------------------------------------------------------------------

func _build_streams() -> void:
	# Audio Pass V1: recursos originales pre-generados (no cargar WAV al vuelo).
	for cue_name in [
		"cue_rain", "cue_beam", "cue_eyes", "cue_charge", "cue_sweep",
		"cue_darkmark", "cue_melee", "boss_teleport", "eye_pierce",
		"eye_shatter", "colossus_pain", "awakening_charge",
		"awakening_stone", "awakening_release"
	]:
		var resource_path: String = "res://audio/boss/%s.wav" % cue_name
		if ResourceLoader.exists(resource_path):
			_sfx[cue_name] = load(resource_path)
		else:
			push_warning("Audio Pass V1: falta recurso " + resource_path)
	_sfx["swing"] = _gen_sfx("swing")
	_sfx["hit"] = _gen_sfx("hit")
	_sfx["heavy_hit"] = _gen_sfx("heavy_hit")
	_sfx["heavy_swing"] = _gen_sfx("heavy_swing")
	_sfx["dash"] = _gen_sfx("dash")
	_sfx["parry"] = _gen_sfx("parry")
	_sfx["stagger"] = _gen_sfx("stagger")
	_sfx["roar"] = _gen_sfx("roar")
	_sfx["weak_break"] = _gen_sfx("weak_break")
	_sfx["rain_impact"] = _gen_sfx("rain_impact")
	_sfx["beam_charge"] = _gen_sfx("beam_charge")
	_sfx["beam_fire"] = _gen_sfx("beam_fire")
	_sfx["hurt"] = _gen_sfx("hurt")
	_sfx["ui"] = _gen_sfx("ui")

	# Pista original del menú principal: OGG de reproducción continua.
	var menu_stream: AudioStreamOggVorbis = load("res://audio/music/menu_principal.ogg") as AudioStreamOggVorbis
	if menu_stream != null:
		menu_stream.loop = true
		_music_tracks["menu"] = menu_stream
	else:
		push_warning("Falta audio/music/menu_principal.ogg")

	# Tema del primer jefe: una sola composición durante las tres fases.
	var combat_stream: AudioStreamOggVorbis = load("res://audio/music/umbral_primer_jefe.ogg") as AudioStreamOggVorbis
	if combat_stream != null:
		combat_stream.loop = true
		_music_tracks["tension"] = combat_stream
		_music_tracks["epic"] = combat_stream
	else:
		push_warning("Falta audio/music/umbral_primer_jefe.ogg; usando música temporal")
		_music_tracks["tension"] = _gen_music("tension")
		_music_tracks["epic"] = _gen_music("epic")

func _make(samples: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(round(clampf(samples[i], -1.0, 1.0) * 32767.0)))
	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = SR
	st.stereo = false
	st.data = bytes
	if loop:
		st.loop_mode = AudioStreamWAV.LOOP_FORWARD
		st.loop_begin = 0
		st.loop_end = samples.size()
	return st

func _env(t: float, attack: float, decay: float) -> float:
	if t <= 0.0:
		return 0.0
	if t < attack:
		return t / maxf(attack, 0.0001)
	return exp(-(t - attack) / maxf(decay, 0.0001))

func _gen_sfx(kind: String) -> AudioStreamWAV:
	var durations := {
		"swing": 0.22, "hit": 0.14, "heavy_hit": 0.34, "heavy_swing": 0.34,
		"dash": 0.28, "parry": 0.5, "stagger": 0.8, "roar": 1.5,
		"weak_break": 0.6, "rain_impact": 0.3, "beam_charge": 1.0,
		"beam_fire": 0.6, "hurt": 0.25, "ui": 0.09,
	}
	var dur: float = durations.get(kind, 0.2)
	var n := int(SR * dur)
	var out := PackedFloat32Array()
	out.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(hash(kind))
	var lp := 0.0
	for i in n:
		var t := float(i) / SR
		var nz := rng.randf_range(-1.0, 1.0)
		var s := 0.0
		match kind:
			"swing":
				lp += (nz - lp) * (0.15 + 0.5 * sin(PI * t / dur))
				s = lp * _env(t, 0.01, 0.06) * 0.8
			"heavy_swing":
				lp += (nz - lp) * (0.1 + 0.35 * sin(PI * t / dur))
				s = lp * _env(t, 0.02, 0.12) * 0.85 + sin(TAU * 120 * t) * _env(t, 0.02, 0.15) * 0.2
			"hit":
				lp += (nz - lp) * 0.6
				s = lp * _env(t, 0.001, 0.03) * 0.5 + sin(TAU * 180 * t) * _env(t, 0.001, 0.045) * 0.6
			"heavy_hit":
				lp += (nz - lp) * 0.25
				s = lp * _env(t, 0.001, 0.09) * 0.6 + sin(TAU * 70 * t) * _env(t, 0.001, 0.14) * 0.9 \
					+ sin(TAU * 140 * t) * _env(t, 0.001, 0.1) * 0.3
			"dash":
				lp += (nz - lp) * 0.4
				s = lp * _env(t, 0.02, 0.16) * 0.7
			"parry":
				s = sin(TAU * 1200 * t) * exp(-t * 6.0) * 0.5 \
					+ sin(TAU * 1800 * t) * exp(-t * 8.0) * 0.35 \
					+ nz * exp(-t * 20.0) * 0.2
			"stagger":
				lp += (nz - lp) * 0.2
				s = sin(TAU * 55 * t) * exp(-t * 3.5) * 0.9 \
					+ sin(TAU * 110 * t) * exp(-t * 5.0) * 0.3 + lp * 0.3 * exp(-t * 4.0)
			"roar":
				var mod := 1.0 + 0.03 * sin(TAU * 5.0 * t)
				var base := 55.0 * mod
				s = _saw(base, t) * 0.45 + _saw(base * 1.5, t) * 0.28 \
					+ _saw(base * 0.5, t) * 0.4
				lp += (nz - lp) * 0.3
				s = (s + lp * 0.3) * _env(t, 0.18, 0.9)
			"weak_break":
				lp += (nz - lp) * 0.7
				s = lp * _env(t, 0.001, 0.06) * 0.6 \
					+ sin(TAU * (900.0 - 500.0 * t) * t) * exp(-t * 5.0) * 0.4
			"rain_impact":
				lp += (nz - lp) * 0.3
				s = sin(TAU * 90 * t) * exp(-t * 10.0) * 0.8 + lp * 0.3 * exp(-t * 9.0)
			"beam_charge":
				lp += (nz - lp) * 0.4
				s = (sin(TAU * (150.0 + 700.0 * t / dur) * t) * 0.5 + lp * 0.25) * _env(t, 0.1, 0.35)
			"beam_fire":
				lp += (nz - lp) * 0.5
				s = (sin(TAU * 210 * t) * 0.45 + sin(TAU * 320 * t) * 0.25 + lp * 0.4) * _env(t, 0.005, 0.4)
			"hurt":
				lp += (nz - lp) * 0.4
				s = sin(TAU * (320.0 - 180.0 * t) * t) * exp(-t * 8.0) * 0.5 + lp * 0.2 * exp(-t * 10.0)
			"ui":
				s = sin(TAU * 800 * t) * exp(-t * 30.0) * 0.6
		out[i] = s
	return _make(out)

func _saw(f: float, t: float) -> float:
	return 2.0 * (f * t - floor(0.5 + f * t))

func _gen_music(kind: String) -> AudioStreamWAV:
	var n := int(SR * MUSIC_LOOP_SECONDS)
	var out := PackedFloat32Array()
	out.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(hash(kind))
	# Acorde menor (La menor): A2, C3, E3, A3.
	var chord := [110.0, 130.81, 164.81, 220.0]
	var is_epic := kind == "epic"
	for i in n:
		var t := float(i) / SR
		var s := 0.0
		# Drone / pad: suma de la fundamental y casi-armónicos con trémolo lento.
		for j in chord.size():
			var f: float = chord[j]
			var trem := 0.65 + 0.35 * sin(TAU * (0.15 + 0.05 * j) * t)
			s += sin(TAU * f * t) * 0.16 * trem
			s += sin(TAU * f * 1.005 * t) * 0.06 * trem
		if is_epic:
			# Pulso rítmico cada 0.5 s + "kick" grave + octava brillante.
			var pulse := fmod(t, 0.5)
			var kick := sin(TAU * 50.0 * t) * exp(-pulse * 22.0) * 0.9
			var pulse_env := exp(-pulse * 6.0)
			s += kick
			s += sin(TAU * 330.0 * t) * 0.08 * pulse_env
			s += rng.randf_range(-1.0, 1.0) * 0.03 * exp(-pulse * 30.0)
		else:
			# Pulso lento y tenso cada 2 s.
			var pulse2 := fmod(t, 2.0)
			s += sin(TAU * 55.0 * t) * exp(-pulse2 * 6.0) * 0.5
			s += rng.randf_range(-1.0, 1.0) * 0.015
		s *= 0.6
		out[i] = s
	# Micro-fade en los extremos para evitar chasquidos al repetir.
	var fade := int(SR * 0.015)
	for i in fade:
		var k := float(i) / fade
		out[i] *= k
		out[n - 1 - i] *= k
	return _make(out, true)