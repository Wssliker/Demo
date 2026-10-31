extends Node
## Settings — ajustes globales persistentes (user://settings.cfg) y su
## aplicación en vivo (audio, brillo, vibración, subtítulos, idioma).
## Se registra como autoload "Settings".

const PATH := "user://settings.cfg"

# --- Estado -----------------------------------------------------------------
var language: String = "es"
var subtitles: bool = true
var vibration: bool = true
var master_volume: float = 0.8
var music_volume: float = 0.7
var sfx_volume: float = 0.8
var brightness: float = 1.0

# Video y accesibilidad. Se conservan entre sesiones (no son trucos de depuración).
var graphics_quality: int = 1 # 0: bajo, 1: medio, 2: alto
var volumetric_fog: bool = true
var screen_glow: bool = true
var reduce_flashes: bool = false
# 0: ventana con bordes, 1: ventana sin bordes, 2: pantalla completa exclusiva.
var display_mode: int = 0
var _windowed_size: Vector2i = Vector2i(1152, 648)

# --- Textos de menús (ES / EN) -----------------------------------------------
const LANG := {
	"es": {
		"ajustes": "AJUSTES", "volver": "VOLVER",
		"idioma": "Idioma", "subtitulos": "Subtítulos", "vibracion": "Vibración",
		"vol_master": "Volumen maestro", "vol_music": "Volumen música",
		"vol_sfx": "Volumen efectos", "brillo": "Brillo",
		"calidad_grafica": "Calidad gráfica", "niebla_vol": "Niebla volumétrica",
		"resplandor": "Resplandor", "destellos": "Reducir destellos",
		"modo_pantalla": "Modo de pantalla",
		"si": "Sí", "no": "No",
		"continuar": "CONTINUAR", "nueva": "NUEVA PARTIDA",
		"salir": "SALIR", "pausa": "EN PAUSA", "reanudar": "REANUDAR",
		"reiniciar": "REINICIAR COMBATE", "menu": "VOLVER AL MENÚ",
		"opciones": "AJUSTES",
	},
	"en": {
		"ajustes": "SETTINGS", "volver": "BACK",
		"idioma": "Language", "subtitulos": "Subtitles", "vibracion": "Vibration",
		"vol_master": "Master volume", "vol_music": "Music volume",
		"vol_sfx": "Effects volume", "brillo": "Brightness",
		"calidad_grafica": "Graphics quality", "niebla_vol": "Volumetric fog",
		"resplandor": "Glow", "destellos": "Reduce flashes",
		"modo_pantalla": "Display mode",
		"si": "Yes", "no": "No",
		"continuar": "CONTINUE", "nueva": "NEW GAME",
		"salir": "QUIT", "pausa": "PAUSED", "reanudar": "RESUME",
		"reiniciar": "RESTART FIGHT", "menu": "BACK TO MENU",
		"opciones": "SETTINGS",
	},
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	apply_display_mode()
	apply_audio()
	# Reaplica al final del frame: garantiza que los buses Music/SFX del
	# AudioManager ya existan, sin depender del orden de autoloads.
	call_deferred("apply_audio")
	call_deferred("apply_video")
	# Reaplica el brillo a cualquier WorldEnvironment que aparezca (arena, menús).
	get_tree().node_added.connect(_on_node_added)

func t(key: String) -> String:
	var table: Dictionary = LANG.get(language, LANG["es"])
	return table.get(key, key)


# --- Modo de pantalla -------------------------------------------------------
func apply_display_mode() -> void:
	# Estos tres modos son opciones del juego, independientes del panel F1.
	# Exclusivo permite que Windows utilice su ruta de pantalla completa.
	match display_mode:
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			# Restaurar dimensiones manejables y centrar en la pantalla actual.
			var display_rect: Rect2i = DisplayServer.screen_get_usable_rect()
			var target_size: Vector2i = Vector2i(
				mini(_windowed_size.x, display_rect.size.x),
				mini(_windowed_size.y, display_rect.size.y)
			)
			DisplayServer.window_set_size(target_size)
			DisplayServer.window_set_position(display_rect.position + (display_rect.size - target_size) / 2)
		1:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		2:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

# --- Audio ------------------------------------------------------------------
func _bus_index(bus_name: String) -> int:
	var i := AudioServer.get_bus_index(bus_name)
	return i if i >= 0 else 0

func set_volume(bus_name: String, value: float) -> void:
	var i := _bus_index(bus_name)
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(value, 0.0001)))
	AudioServer.set_bus_mute(i, value <= 0.001)

func apply_audio() -> void:
	set_volume("Master", master_volume)
	set_volume("Music", music_volume)
	set_volume("SFX", sfx_volume)

# --- Brillo -----------------------------------------------------------------
func set_brightness(value: float) -> void:
	brightness = clampf(value, 0.5, 1.5)
	apply_video()

func _apply_brightness(node: Node) -> void:
	if node is WorldEnvironment and node.environment:
		node.environment.adjustment_enabled = true
		node.environment.adjustment_brightness = brightness
	for c in node.get_children():
		_apply_brightness(c)

func _on_node_added(node: Node) -> void:
	if node is WorldEnvironment and node.environment:
		# Los recursos de entorno pueden estar compartidos con la escena del editor.
		# Duplicar evita contaminar la configuración original.
		if not node.has_meta("bgo_video_original"):
			node.environment = node.environment.duplicate(true)
			node.set_meta("bgo_video_original", {
				"volumetric": node.environment.volumetric_fog_enabled,
				"glow": node.environment.glow_enabled,
				"fog": node.environment.fog_enabled,
				"glow_intensity": node.environment.glow_intensity,
				"volumetric_density": node.environment.volumetric_fog_density
			})
		_apply_environment(node)

func apply_video() -> void:
	# Se aplica al menú y a la arena, también después de reiniciarla.
	_apply_video_tree(get_tree().root)

func _apply_video_tree(node: Node) -> void:
	if node is WorldEnvironment:
		_on_node_added(node)
	for child in node.get_children():
		_apply_video_tree(child)

func _apply_environment(world: WorldEnvironment) -> void:
	if not is_instance_valid(world) or world.environment == null:
		return
	var env: Environment = world.environment
	var original: Dictionary = world.get_meta("bgo_video_original", {})
	env.adjustment_enabled = true
	env.adjustment_brightness = brightness
	# Baja: quita niebla volumétrica. Media/alta: depende de la preferencia.
	env.volumetric_fog_enabled = bool(original.get("volumetric", false)) and volumetric_fog and graphics_quality > 0
	# Reducir destellos también desactiva bloom/resplandor para mayor legibilidad.
	env.glow_enabled = bool(original.get("glow", false)) and screen_glow and not reduce_flashes and graphics_quality > 0
	# La niebla estándar se mantiene: aporta profundidad sin la carga de la volumétrica.
	env.fog_enabled = bool(original.get("fog", false))
	# En medio se reduce la intensidad respecto de alto; en bajo se desactiva.
	var scale: float = 0.75 if graphics_quality == 1 else 1.0
	env.glow_intensity = float(original.get("glow_intensity", env.glow_intensity)) * scale
	env.volumetric_fog_density = float(original.get("volumetric_density", env.volumetric_fog_density)) * scale

# --- Vibración (escala de sacudida de cámara) --------------------------------
func shake_scale() -> float:
	return 1.0 if vibration else 0.0

# --- Persistencia -----------------------------------------------------------
func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("video", "brightness", brightness)
	cfg.set_value("video", "graphics_quality", graphics_quality)
	cfg.set_value("video", "display_mode", display_mode)
	cfg.set_value("video", "volumetric_fog", volumetric_fog)
	cfg.set_value("video", "screen_glow", screen_glow)
	cfg.set_value("accessibility", "reduce_flashes", reduce_flashes)
	cfg.set_value("game", "language", language)
	cfg.set_value("game", "subtitles", subtitles)
	cfg.set_value("game", "vibration", vibration)
	cfg.save(PATH)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	master_volume = cfg.get_value("audio", "master", master_volume)
	music_volume = cfg.get_value("audio", "music", music_volume)
	sfx_volume = cfg.get_value("audio", "sfx", sfx_volume)
	brightness = cfg.get_value("video", "brightness", brightness)
	graphics_quality = clampi(int(cfg.get_value("video", "graphics_quality", graphics_quality)), 0, 2)
	display_mode = clampi(int(cfg.get_value("video", "display_mode", display_mode)), 0, 2)
	volumetric_fog = bool(cfg.get_value("video", "volumetric_fog", volumetric_fog))
	screen_glow = bool(cfg.get_value("video", "screen_glow", screen_glow))
	reduce_flashes = bool(cfg.get_value("accessibility", "reduce_flashes", reduce_flashes))
	language = cfg.get_value("game", "language", language)
	subtitles = cfg.get_value("game", "subtitles", subtitles)
	vibration = cfg.get_value("game", "vibration", vibration)