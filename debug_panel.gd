extends CanvasLayer
## DebugPanel — panel de depuración para testear la demo.
## Abre/cierra con la acción `debug_menu` (F1). Ajusta parámetros en vivo de:
## JUGADOR, JEFE, MAPA y GENERAL. Cada parámetro tiene una viñeta al pasar el cursor.
## Se registra como autoload "Debug". No altera ninguna mecánica por sí mismo.

const BONE := Color(0.92, 0.90, 0.86)
const DIM := Color(0.05, 0.03, 0.07, 0.86)
const ACCENT := Color(0.85, 0.35, 0.42)
const PANEL := Color(0.09, 0.07, 0.12, 0.96)

## Viñetas: explican qué hace cada parámetro (clave = nombre de la variable).
const DESCRIPTIONS := {
	# --- Jugador ---
	"speed": "Velocidad de movimiento del jugador (unidades/seg).",
	"jump_velocity": "Impulso vertical al saltar.",
	"rotation_speed": "Rapidez con la que el modelo gira hacia donde te mueves.",
	"max_player_health": "Vida máxima del jugador. Pulsa 'Curar al máximo' para refrescar la barra.",
	"player_health": "Vida actual del jugador.",
	"max_jumps": "Número de saltos permitidos (1 = sin doble salto).",
	"coyote_time_duration": "Tiempo tras dejar el borde durante el que todavía puedes saltar.",
	"dash_speed": "Velocidad durante el dash/esquiva.",
	"dash_duration": "Duración del dash en segundos.",
	"dash_cooldown": "Tiempo de espera entre dashes.",
	"combo_reset_time": "Tiempo sin atacar tras el que se reinicia el combo.",
	"mouse_sensitivity": "Sensibilidad del ratón para girar la cámara.",
	"jump_buffer_time": "Margen: si pulsas salto justo antes de tocar el suelo, se registra.",
	"air_control": "Fracción de la velocidad que controlas en el aire (1 = control total).",
	"default_fov": "Campo de visión (FOV) por defecto de la cámara.",
	"locked_fov": "FOV cuando hay lock-on al jefe.",
	"camera_polish_enabled": "Activa el suavizado de cámara (Camera Polish).",
	"camera_turn_follow": "Rapidez de la cámara al seguir el giro horizontal.",
	"camera_pitch_follow": "Rapidez de la cámara al seguir la inclinación vertical.",
	"camera_fov_follow": "Rapidez del cambio de FOV.",
	"climb_fov": "FOV mientras trepas al coloso.",
	"awakening_fov": "FOV durante la cinemática de El Despertar.",
	"climb_look_height": "Altura del punto de mira mientras trepas.",
	"lock_look_height": "Altura del punto que mira la cámara en lock-on.",
	"teleport_snap_distance": "Distancia a la que la cámara se recoloca tras un teletransporte del jefe.",
	"climbing_target_weight": "Peso del encuadre hacia la superficie cuando trepas.",
	"climb_speed": "Velocidad al trepar al coloso.",
	"grip_max": "Resistencia de agarre máxima.",
	"grip_drain_idle": "Agarre que pierdes por segundo agarrado sin moverte.",
	"grip_drain_move": "Agarre extra que pierdes por segundo al trepar.",
	"grip_recover": "Agarre que recuperas por segundo en el suelo.",
	"climb_stab_damage": "Daño de la estocada pesada (clic derecho) sobre un ojo.",
	"climb_jab_damage": "Daño de la estocada ligera (clic izquierdo) sobre un ojo.",
	"climb_attack_range": "Alcance para enganchar un ojo al atacar trepando.",
	# --- Jefe ---
	"max_health": "Vida máxima del coloso (barra del HUD).",
	"fury_max": "Tope de la barra de FURIA del jefe.",
	"turn_speed": "Rapidez con la que el jefe gira hacia ti.",
	"approach_speed": "Velocidad a la que se acerca al jugador.",
	"approach_range": "Distancia a la que el jefe empieza a acercarse.",
	"anticipation_strength": "Intensidad del gesto previo antes de atacar (legibilidad).",
	"eye_hit_reaction_strength": "Sacudida del cuerpo al recibir una estocada en un ojo.",
	"enable_attack_anticipation": "Activa el gesto de anticipación antes de cada ataque.",
	"enable_attack_cue_light": "Activa la luz de aviso que precede a cada ataque.",
	"attack_cue_energy": "Brillo de la luz de aviso por ataque.",
	"attack_cue_range": "Alcance de la luz de aviso por ataque.",
	"attack_cue_motion_scale": "Escala del movimiento de aviso por ataque.",
	"enable_phase_feedback": "Activa el feedback visual en los cambios de fase.",
	"phase_light_energy": "Brillo de la luz de cambio de fase.",
	"phase_light_duration": "Duración de la luz de cambio de fase.",
	"eye_break_gesture_strength": "Intensidad del gesto del jefe al reventar un ojo.",
	"enable_boss_audio_cues": "Activa los sonidos de aviso del jefe.",
	"boss_cue_volume_db": "Volumen (dB) de los sonidos de aviso.",
	"boss_awakening_volume_db": "Volumen (dB) de El Despertar.",
	"enable_cinematic_awakening": "Activa la cinemática de El Despertar al entrar en fase 3.",
	"awakening_duration": "Duración de la cinemática de El Despertar.",
	"awakening_light_energy": "Brillo del halo carmesí de El Despertar.",
	"awakening_light_range": "Alcance del halo de El Despertar.",
	"phase2_combo_opening": "Ventana (s) para trepar tras un combo en fase 2.",
	"third_eye_combo_opening": "Ventana (s) para llegar al tercer ojo en fase 2.",
	"eye_break_opening": "Ventana (s) tras reventar el primer ojo.",
	"second_eye_break_opening": "Ventana (s) tras reventar el segundo ojo.",
	"teleport_warning": "Aviso (s) antes del teletransporte del jefe.",
	"climb_release_check": "Intervalo (s) con el que el jefe comprueba si sigues agarrado.",
	"phase1_pause": "Tiempo antes del siguiente combo en la fase 1.",
	"phase2_pause": "Tiempo antes del siguiente combo en la fase 2.",
	"phase3_pause": "Tiempo antes del siguiente combo en la fase 3.",
	"phase1_attack_speed": "Multiplicador de duración de ataques de la fase 1; menor valor significa ataques más rápidos.",
	"phase2_attack_speed": "Duración relativa de los ataques: cuanto menor el número, más rápidos son.",
	"phase2_enraged_speed": "Duración relativa tras el segundo ojo: cuanto menor el número, más rápidos son.",
	"phase3_attack_speed": "Duración relativa de los ataques: cuanto menor el número, más rápidos son.",
	"phase3_combo_breath": "Pausa adicional al terminar un combo de la fase 3.",
	"enable_phase_presence": "Enciende la luz ambiental que distingue las tres fases (solo presentación).",
	"phase1_presence": "Brillo azul tenue de la fase 1: indiferencia y solemnidad.",
	"phase2_presence": "Brillo violeta de la fase 2: resistencia y tensión.",
	"phase3_presence": "Brillo carmesí de la fase 3: agresividad y despertar.",
	"phase_presence_pulse_speed": "Velocidad del pulso luminoso ambiental; 0 deja brillo constante.",
	"phase_presence_range": "Alcance de la luz ambiental por fase (sin sombras).",
	"telegraph_visibility": "Intensidad de los indicadores en el suelo (Rain, Beam y Charge).",
	"telegraph_outline": "Fuerza del contorno de las zonas peligrosas.",
	"telegraph_pulse_speed": "Velocidad del pulso de los indicadores; 0 desactiva la pulsación.",
	"enable_colossus_anchor": "Permite resistir las sacudidas mientras trepas con E + Shift.",
	"anchor_cost_on_shake": "Agarre que gastas al resistir una sacudida.",
	"shake_grip_damage": "Agarre que pierdes si no resistes una sacudida.",
	"enable_climb_shakes": "Permite al jefe intentar desprenderte mientras trepas.",
	"climb_shake_after": "Tiempo de escalada antes de la primera sacudida.",
	"climb_shake_cooldown": "Tiempo mínimo entre sacudidas.",
	"climb_shake_warning": "Duración del aviso antes de una sacudida.",
}

const FRIENDLY_NAMES := {
	"speed": "Velocidad al caminar",
	"jump_velocity": "Fuerza del salto",
	"rotation_speed": "Velocidad de giro",
	"max_player_health": "Vida máxima",
	"player_health": "Vida actual",
	"max_jumps": "Cantidad de saltos",
	"coyote_time_duration": "Margen para saltar al caer",
	"dash_speed": "Velocidad de esquiva",
	"dash_duration": "Duración de esquiva",
	"dash_cooldown": "Espera entre esquivas",
	"combo_reset_time": "Tiempo para reiniciar combo",
	"mouse_sensitivity": "Sensibilidad de cámara",
	"jump_buffer_time": "Margen de salto anticipado",
	"air_control": "Control en el aire",
	"default_fov": "Amplitud de cámara normal",
	"locked_fov": "Amplitud con objetivo fijado",
	"camera_polish_enabled": "Suavizado de cámara",
	"camera_turn_follow": "Suavidad de giro de cámara",
	"camera_pitch_follow": "Suavidad vertical de cámara",
	"camera_fov_follow": "Suavidad del zoom",
	"climb_fov": "Amplitud de cámara al trepar",
	"awakening_fov": "Amplitud durante el despertar",
	"climb_look_height": "Altura de mirada al trepar",
	"lock_look_height": "Altura de mirada al jefe",
	"teleport_snap_distance": "Distancia para recolocar cámara",
	"climbing_target_weight": "Enfoque de cámara al trepar",
	"climb_speed": "Velocidad al trepar",
	"grip_max": "Agarre máximo",
	"grip_drain_idle": "Agarre gastado al sujetarse",
	"grip_drain_move": "Agarre gastado al moverse",
	"grip_recover": "Recuperación de agarre",
	"climb_stab_damage": "Daño de estocada fuerte",
	"climb_jab_damage": "Daño de estocada ligera",
	"climb_attack_range": "Alcance para golpear ojos",
	"enable_colossus_anchor": "Permitir anclaje",
	"anchor_cost_on_shake": "Coste al resistir sacudida",
	"shake_grip_damage": "Agarre perdido por sacudida",
	"max_health": "Vida máxima del jefe",
	"fury_max": "Furia máxima",
	"turn_speed": "Rapidez al girar",
	"approach_speed": "Velocidad al perseguir",
	"approach_range": "Distancia de persecución",
	"anticipation_strength": "Fuerza del gesto antes de atacar",
	"eye_hit_reaction_strength": "Reacción al golpear un ojo",
	"enable_attack_anticipation": "Mostrar gestos de ataque",
	"enable_attack_cue_light": "Mostrar luz de aviso",
	"attack_cue_energy": "Brillo del aviso de ataque",
	"attack_cue_range": "Alcance de la luz de aviso",
	"attack_cue_motion_scale": "Amplitud del gesto de aviso",
	"enable_phase_feedback": "Efectos al cambiar de fase",
	"phase_light_energy": "Brillo del cambio de fase",
	"phase_light_duration": "Duración del brillo de fase",
	"eye_break_gesture_strength": "Reacción al romper un ojo",
	"enable_boss_audio_cues": "Sonidos de aviso del jefe",
	"boss_cue_volume_db": "Volumen de avisos del jefe",
	"boss_awakening_volume_db": "Volumen del despertar",
	"enable_cinematic_awakening": "Mostrar despertar cinematográfico",
	"awakening_duration": "Duración del despertar",
	"awakening_light_energy": "Brillo rojo del despertar",
	"awakening_light_range": "Alcance del brillo del despertar",
	"telegraph_visibility": "Visibilidad de zonas peligrosas",
	"telegraph_outline": "Contorno de zonas peligrosas",
	"telegraph_pulse_speed": "Pulsación de zonas peligrosas",
	"enable_phase_presence": "Luces según fase",
	"phase1_presence": "Luz azul · fase 1",
	"phase2_presence": "Luz violeta · fase 2",
	"phase3_presence": "Luz roja · fase 3",
	"phase_presence_pulse_speed": "Ritmo de luces de fase",
	"phase_presence_range": "Alcance de luces de fase",
	"phase2_combo_opening": "Tiempo para trepar tras combo",
	"third_eye_combo_opening": "Tiempo para alcanzar tercer ojo",
	"eye_break_opening": "Descanso tras primer ojo",
	"second_eye_break_opening": "Descanso tras segundo ojo",
	"teleport_warning": "Aviso antes de teletransporte",
	"climb_release_check": "Frecuencia de revisión de agarre",
	"phase1_pause": "Pausa entre ataques · fase 1",
	"phase2_pause": "Pausa entre ataques · fase 2",
	"phase3_pause": "Pausa entre ataques · fase 3",
	"phase1_attack_speed": "Duración de ataques · fase 1",
	"phase2_attack_speed": "Duración de ataques · fase 2",
	"phase2_enraged_speed": "Duración tras segundo ojo",
	"phase3_attack_speed": "Duración de ataques · fase 3",
	"phase3_combo_breath": "Descanso extra · fase 3",
	"enable_climb_shakes": "Permitir sacudidas al trepar",
	"climb_shake_after": "Tiempo hasta primera sacudida",
	"climb_shake_cooldown": "Espera entre sacudidas",
	"climb_shake_warning": "Aviso previo a sacudida",
}

const BALANCE_PHASE_FIELDS: Array = [
	["phase1_pause", "Pausa · Fase 1"],
	["phase2_pause", "Pausa · Fase 2"],
	["phase3_pause", "Pausa · Fase 3"],
	["phase1_attack_speed", "Duración de ataques · Fase 1"],
	["phase2_attack_speed", "Duración de ataques · Fase 2"],
	["phase2_enraged_speed", "Duración tras segundo ojo"],
	["phase3_attack_speed", "Duración de ataques · Fase 3"],
	["phase3_combo_breath", "Descanso · Fase 3"],
]

var _root: Control
var _rows: VBoxContainer
var _section: String = "player"
var _fps: Label
var _fps_enabled: bool = false
var _fps_root: Control
var _defaults: Dictionary = {}
var _test_status: String = ""
var _pause_on_open: bool = true
var _was_paused: bool = false
var _prev_mouse: Input.MouseMode = Input.MOUSE_MODE_CAPTURED
var _controls_layer: Control
var _controls_scroll: VBoxContainer
var _controls_prev_mouse: Input.MouseMode = Input.MOUSE_MODE_CAPTURED
var _controls_prev_paused: bool = false
var _controls_opened_from_debug: bool = false
var _individual_defaults: Dictionary = {}
var _saved_by_group: Dictionary = {"player": {}, "boss": {}, "environment": {}}
var _saved_brightness: Variant = null
var _scene_applied_id: int = 0
var _debug_invulnerable: bool = false
var _debug_passive: bool = false

func apply_saved_to(obj: Object, group_name: String) -> void:
	if not _saved_by_group.has(group_name):
		return
	for key in _saved_by_group[group_name]:
		var saved_value: Variant = _saved_by_group[group_name][key]
		if group_name == "boss" and key == "max_health" and obj.has_method("set_max_health_for_debug"):
			obj.set_max_health_for_debug(int(saved_value))
		else:
			obj.set(key, saved_value)
	if group_name == "player":
		obj.set("debug_invulnerable", _debug_invulnerable)
	elif group_name == "boss":
		# Al aparecer un jefe nuevo todavía no hay ataques activos.
		obj.set("debug_passive", _debug_passive)

func _set_invulnerable(enabled: bool) -> void:
	_debug_invulnerable = enabled
	var p := get_tree().get_first_node_in_group("player")
	if p: p.debug_invulnerable = enabled

func _set_passive(enabled: bool) -> void:
	_debug_passive = enabled
	var b := get_tree().get_first_node_in_group("boss")
	if b and b.has_method("set_debug_passive"):
		b.set_debug_passive(enabled)

func _set_object_param(obj: Object, group_name: String, key: String, value: Variant) -> void:
	if not _saved_by_group.has(group_name):
		_saved_by_group[group_name] = {}
	_saved_by_group[group_name][key] = value
	if is_instance_valid(obj):
		if group_name == "boss" and key == "max_health" and obj.has_method("set_max_health_for_debug"):
			obj.set_max_health_for_debug(int(value))
		else:
			obj.set(key, value)

func _set_environment_param(key: String, value: float) -> void:
	_saved_by_group["environment"][key] = value
	var env := _env()
	if env: env.set(key, value)

func _set_brightness(value: float) -> void:
	_saved_brightness = value
	var settings := get_node_or_null("/root/Settings")
	if settings: settings.set_brightness(value)

func _apply_environment_saved() -> void:
	var env := _env()
	if env:
		for key in _saved_by_group["environment"]:
			env.set(key, _saved_by_group["environment"][key])
	if _saved_brightness != null:
		var settings := get_node_or_null("/root/Settings")
		if settings: settings.set_brightness(_saved_brightness)


const CONTROL_ACTIONS := [
	["MOVIMIENTO", "ui_up", "Avanzar"],
	["MOVIMIENTO", "ui_down", "Retroceder"],
	["MOVIMIENTO", "ui_left", "Izquierda"],
	["MOVIMIENTO", "ui_right", "Derecha"],
	["MOVIMIENTO", "ui_accept", "Saltar / doble salto"],
	["MOVIMIENTO", "dash", "Esquivar / dash"],
	["COMBATE", "attack_light", "Ataque ligero"],
	["COMBATE", "attack_heavy", "Ataque fuerte"],
	["COMBATE", "lock_on", "Fijar objetivo"],
	["ESCALADA", "grab", "Agarrarse / trepar"],
	["INTERFAZ", "pausar", "Pausar"],
	["INTERFAZ", "debug_menu", "Depuración (desarrollo)"],
]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100  # por encima del HUD
	_build_ui()
	_build_controls_ui()
	set_process(true)
	_root.visible = false
	_fps_root = Control.new()
	_fps_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fps_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fps_root)
	_fps.reparent(_fps_root)
	_fps.visible = _fps_enabled

func _process(_delta: float) -> void:
	# Autoload persiste entre recargas de escena; los nodos de ambiente no.
	var current := get_tree().current_scene
	if current and current.get_instance_id() != _scene_applied_id:
		_scene_applied_id = current.get_instance_id()
		_apply_environment_saved()
	if _fps and _fps_enabled:
		_fps.text = "FPS %d   |   time_scale %.2f" % [Engine.get_frames_per_second(), Engine.time_scale]

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_F2 or event.physical_keycode == KEY_F2):
		_toggle_controls()
		get_viewport().set_input_as_handled()
		return
	if _controls_layer != null and _controls_layer.visible:
		if event.is_action_pressed("ui_cancel"):
			_close_controls()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("debug_menu"):
		_toggle()
		get_viewport().set_input_as_handled()

func _toggle() -> void:
	if _root.visible:
		_close()
	else:
		_open()

func _open() -> void:
	_was_paused = get_tree().paused
	_prev_mouse = Input.mouse_mode
	_root.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if _pause_on_open:
		get_tree().paused = true
	if _defaults.is_empty() or (not _defaults.has("player") and get_tree().get_first_node_in_group("player")):
		_capture_defaults()
	_populate()

func _close() -> void:
	_root.visible = false
	get_tree().paused = _was_paused
	Input.mouse_mode = _prev_mouse

# ---------------------------------------------------------------------------
# Construcción de la interfaz
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = DIM
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dim)

	var panel := PanelContainer.new()
	panel.anchor_top = 0.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 0.0
	panel.offset_right = 640.0
	panel.offset_top = 0.0
	panel.offset_bottom = 0.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = PANEL
	sb.border_color = ACCENT
	sb.border_width_right = 2
	panel.add_theme_stylebox_override("panel", sb)
	_root.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "[F1]  PANEL DE DEPURACIÓN"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", ACCENT)
	vbox.add_child(title)

	var controls_button := Button.new()
	controls_button.text = "CONTROLES  [F2]"
	controls_button.tooltip_text = "Consulta todos los controles del juego sin salir de la partida."
	controls_button.pressed.connect(_toggle_controls)
	vbox.add_child(controls_button)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	vbox.add_child(tabs)
	for sec in [["player", "JUGADOR"], ["boss", "JEFE"], ["map", "MAPA"], ["general", "GENERAL"], ["tests", "PRUEBAS"]]:
		var b := Button.new()
		b.text = sec[1]
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(108, 30)
		b.set_meta("section", sec[0])
		b.pressed.connect(func(): _set_section(b.get_meta("section")))
		tabs.add_child(b)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	_rows = VBoxContainer.new()
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override("separation", 6)
	scroll.add_child(_rows)

	# Etiqueta de FPS (esquina superior derecha).
	_fps = Label.new()
	_fps.anchor_left = 1.0
	_fps.anchor_right = 1.0
	_fps.offset_left = -320.0
	_fps.offset_right = -12.0
	_fps.offset_top = 8.0
	_fps.offset_bottom = 30.0
	_fps.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_fps.add_theme_font_size_override("font_size", 16)
	_fps.add_theme_color_override("font_color", BONE)
	_fps.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fps.visible = false
	_root.add_child(_fps)

func _set_section(section_id: String) -> void:
	_section = section_id
	for c in _root.find_children("*", "Button", true, false):
		if c.has_meta("section"):
			c.button_pressed = (c.get_meta("section") == section_id)
	_populate()

func _populate() -> void:
	if _rows == null:
		return
	for c in _rows.get_children():
		_rows.remove_child(c)
		c.queue_free()
	match _section:
		"player": _build_player()
		"boss": _build_boss()
		"map": _build_map()
		"general": _build_general()
		"tests": _build_tests()

# ---------------------------------------------------------------------------
# Secciones
# ---------------------------------------------------------------------------

func _build_player() -> void:
	var p := get_tree().get_first_node_in_group("player")
	if p == null:
		_note("No hay jugador en la escena actual.")
		return
	_header("ESTADO")
	_add_switch("Inmortal", "El jugador no recibe daño (útil para testear el jefe).",
		func(): return _debug_invulnerable,
		func(v): _set_invulnerable(v), false)
	_add_action("Curar al máximo", "Rellena la vida del jugador y refresca la barra del HUD.", func(): _heal_player(p))
	_add_action("Reponer agarre", "Rellena la resistencia de agarre.", func(): p.set("grip", p.get("grip_max")))
	_header("PARÁMETROS EXPORTADOS")
	_obj_rows(p, "jugador")

func _build_boss() -> void:
	var b := get_tree().get_first_node_in_group("boss")
	if b == null:
		_note("No hay jefe en la escena actual.")
		return
	_header("ESTADO")
	_add_switch("Pasivo (no ataca)", "Interrumpe los ataques actuales y evita nuevos combos.",
		func(): return _debug_passive,
		func(v): _set_passive(v), false)
	_add_action("Romper un ojo", "Reventar el siguiente ojo intacto (avanza el puzzle de fases).", func(): _break_eye())
	_add_action("Resetear vida del jefe", "Devuelve la vida del jefe al máximo.", func():
		b.set("current_health", b.get("max_health"))
		if b.has_method("_update_health_ui"): b._update_health_ui())
	_header("FASES")
	_add_action("Entrar en Fase 2", "Fuerza la transición a 'El Puzzle' (1 ojo).", func():
		if b.has_method("enter_phase_two"): b.enter_phase_two())
	_add_action("Entrar en Fase 3", "Fuerza la transición a 'Te Mira' (despierta).", func():
		if b.has_method("enter_phase_three"): b.enter_phase_three())
	_add_action("Matar al jefe", "Elimina al jefe (dispara la pantalla de victoria).", func():
		if b.has_method("die"): b.die())
	_header("BALANCE POR FASES")
	for entry in BALANCE_PHASE_FIELDS:
		var key: String = entry[0]
		var display_name: String = entry[1]
		if not _has_property(b, key):
			continue
		var prop_info: Dictionary = _find_property(b, key)
		var value: float = float(b.get(key))
		var bounds: Vector2 = _range_for(value, prop_info)
		var step: float = 0.05 if key.ends_with("speed") else 0.1
		_add_number(display_name, _desc(key, "jefe"),
			func(): return b.get(key),
			func(v): _set_object_param(b, "boss", key, v),
			bounds.x, bounds.y, step, _export_default(b, key), "jefe:" + key)
	_header("OTROS PARÁMETROS EXPORTADOS")
	_obj_rows(b, "jefe")

func _build_map() -> void:
	_header("AMBIENTE (WorldEnvironment)")
	var env := _env()
	if env == null:
		_note("No hay WorldEnvironment en la escena actual.")
	else:
		_add_number("Luz ambiental", "Energía de la luz ambiental. Bájala para más contraste.",
			func(): return env.ambient_light_energy, func(v): _set_environment_param("ambient_light_energy", v), 0.0, 2.0, 0.01, _env_default("ambient_light_energy"))
		_add_number("Bloom (glow)", "Intensidad del resplandor. Súbela para un look más onírico.",
			func(): return env.glow_intensity, func(v): _set_environment_param("glow_intensity", v), 0.0, 3.0, 0.01, _env_default("glow_intensity"))
		_add_number("Niebla", "Densidad de la niebla de distancia.",
			func(): return env.fog_density, func(v): _set_environment_param("fog_density", v), 0.0, 0.2, 0.001, _env_default("fog_density"))
		_add_number("Niebla volumétrica", "Densidad de la niebla volumétrica (rayos de luz).",
			func(): return env.volumetric_fog_density, func(v): _set_environment_param("volumetric_fog_density", v), 0.0, 0.05, 0.0005, _env_default("volumetric_fog_density"))
		_add_number("Fondo", "Energía del cielo/fondo. Súbela para un cielo más brillante.",
			func(): return env.background_energy_multiplier, func(v): _set_environment_param("background_energy_multiplier", v), 0.0, 3.0, 0.01, _env_default("background_energy_multiplier"))
		var s := get_node_or_null("/root/Settings")
		if s:
			_add_number("Brillo (Ajustes)", "Brillo global guardado en Ajustes (ajustment_brightness).",
				func(): return s.get("brightness"), func(v): _set_brightness(v), 0.5, 1.5, 0.01)

func _build_general() -> void:
	_note("Ajustes activos durante esta sesión, incluso al reiniciar la arena. Los parámetros restauran su valor original con ↺.")
	_header("SIMULACIÓN")
	_add_number("Velocidad de tiempo", "Escala temporal del juego (0.1 = cámara lenta).",
		func(): return Engine.time_scale, func(v): Engine.time_scale = v, 0.05, 2.0, 0.05, 1.0)
	_add_switch("Mostrar FPS", "Muestra FPS y time_scale en la esquina.",
		func(): return _fps_enabled, func(v): _fps_enabled = v; _fps.visible = v)
	_add_switch("Pausar al abrir", "Congela el juego mientras el panel está abierto.",
		func(): return _pause_on_open,
		func(v):
			_pause_on_open = v
			get_tree().paused = v if _root.visible else get_tree().paused)
	_add_action("Restaurar tiempo x1", "Devuelve Engine.time_scale a 1.0.", func(): Engine.time_scale = 1.0; _populate())
	_add_action("Restaurar parámetros", "Restablece valores exportados del jugador, jefe y ambiente capturados al iniciar.", func(): _restore_defaults(); _populate())
	_header("ATAJOS")
	_add_action("Curar al jugador", "Rellena la vida del jugador.", func():
		var p := get_tree().get_first_node_in_group("player")
		if p: _heal_player(p))
	_add_action("Reiniciar escena", "Recarga la escena actual (útil tras romper algo).", func():
		get_tree().paused = false
		get_tree().reload_current_scene())
	_add_action("Ver todos los controles [F2]", "Muestra la ayuda con las teclas configuradas.", _toggle_controls)
	_add_action("Cerrar panel", "Cierra este panel ([F1]).", func(): _close())

# ---------------------------------------------------------------------------
# Fábrica de filas y utilidades
# ---------------------------------------------------------------------------

func _header(text: String) -> void:
	var l := Label.new()
	l.text = "— " + text + " —"
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", ACCENT)
	_rows.add_child(l)

func _note(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", BONE)
	_rows.add_child(l)

func _row(text: String, tip: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.tooltip_text = tip
	var l := Label.new()
	l.text = text
	l.custom_minimum_size = Vector2(210, 0)
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", BONE)
	l.tooltip_text = tip
	row.add_child(l)
	_rows.add_child(row)
	return row

func _default_for(id: String, getter: Callable, explicit_default: Variant = null) -> Variant:
	if explicit_default != null:
		return explicit_default
	if not _individual_defaults.has(id):
		_individual_defaults[id] = getter.call()
	return _individual_defaults[id]

func _add_number(text: String, tip: String, getter: Callable, setter: Callable, minv: float, maxv: float, step: float, explicit_default: Variant = null, default_id: String = "") -> void:
	var row := _row(text, tip)
	var id := default_id if not default_id.is_empty() else _section + ":" + text
	var base: float = float(_default_for(id, getter, explicit_default))
	var slider := HSlider.new()
	slider.min_value = minf(minv, base)
	slider.max_value = maxf(maxv, base)
	slider.step = step
	slider.value = clampf(float(getter.call()), slider.min_value, slider.max_value)
	slider.custom_minimum_size = Vector2(138, 22)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.tooltip_text = tip
	var val := Label.new()
	val.text = _fmt(slider.value)
	val.custom_minimum_size = Vector2(58, 0)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	slider.value_changed.connect(func(nv: float):
		setter.call(nv)
		val.text = _fmt(nv))
	row.add_child(slider)
	row.add_child(val)
	var reset := Button.new()
	reset.text = "↺"
	reset.custom_minimum_size = Vector2(30, 26)
	reset.tooltip_text = "Restablecer solo '%s' a %s" % [text, _fmt(base)]
	reset.pressed.connect(func():
		setter.call(base)
		slider.set_value_no_signal(base)
		val.text = _fmt(base))
	row.add_child(reset)

func _add_switch(text: String, tip: String, getter: Callable, setter: Callable, explicit_default: Variant = null, default_id: String = "") -> void:
	var row := _row(text, tip)
	var id := default_id if not default_id.is_empty() else _section + ":" + text
	var base: bool = bool(_default_for(id, getter, explicit_default))
	var cb := CheckButton.new()
	cb.button_pressed = bool(getter.call())
	cb.tooltip_text = tip
	cb.toggled.connect(func(on: bool): setter.call(on))
	row.add_child(cb)
	var reset := Button.new()
	reset.text = "↺"
	reset.custom_minimum_size = Vector2(30, 26)
	reset.tooltip_text = "Restablecer solo '%s' a %s" % [text, "activado" if base else "desactivado"]
	reset.pressed.connect(func():
		setter.call(base)
		cb.set_pressed_no_signal(base))
	row.add_child(reset)

func _add_action(text: String, tip: String, cb: Callable) -> void:
	var row := _row(text, tip)
	var b := Button.new()
	b.text = "Ejecutar"
	b.tooltip_text = tip
	b.pressed.connect(cb)
	row.add_child(b)

## Crea filas para cada @export numérico/booleano del objeto, con su viñeta.
func _find_property(obj: Object, key: String) -> Dictionary:
	for prop in obj.get_property_list():
		if String(prop.get("name", "")) == key:
			return prop
	return {}

func _has_property(obj: Object, key: String) -> bool:
	return not _find_property(obj, key).is_empty()

func _obj_rows(obj: Object, context: String) -> void:
	var context_group := "player" if context == "jugador" else "boss"
	var count := 0
	for prop in obj.get_property_list():
		var usage: int = prop.usage
		if (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) == 0:
			continue
		if (usage & PROPERTY_USAGE_EDITOR) == 0:
			continue
		var key: String = prop.name
		if context_group == "boss" and _is_balance_field(key):
			continue
		if key.begins_with("_") or key == "script":
			continue
		var tip: String = _desc(key, context)
		match int(prop.type):
			TYPE_FLOAT:
				var r := _range_for(float(obj.get(key)), prop)
				_add_number(_friendly_name(key), tip,
					func(): return obj.get(key),
					func(v): _set_object_param(obj, context_group, key, v),
					r.x, r.y, _step_for(r), _export_default(obj, key), context + ":" + key)
				count += 1
			TYPE_INT:
				var r2 := _range_for(float(obj.get(key)), prop)
				_add_number(_friendly_name(key), tip,
					func(): return obj.get(key),
					func(v): _set_object_param(obj, context_group, key, int(round(v))),
					r2.x, r2.y, 1.0, _export_default(obj, key), context + ":" + key)
				count += 1
			TYPE_BOOL:
				_add_switch(_friendly_name(key), tip,
					func(): return obj.get(key),
					func(v): _set_object_param(obj, context_group, key, v), _export_default(obj, key), context + ":" + key)
				count += 1
	if count == 0:
		_note("Sin parámetros exportados para este nodo.")

func _is_balance_field(key: String) -> bool:
	for entry in BALANCE_PHASE_FIELDS:
		if entry[0] == key:
			return true
	return false

func _friendly_name(key: String) -> String:
	if FRIENDLY_NAMES.has(key):
		return String(FRIENDLY_NAMES[key])
	# Las variables nuevas también reciben un título legible.
	return key.replace("_", " ").capitalize()

func _desc(key: String, context: String) -> String:
	if DESCRIPTIONS.has(key):
		return DESCRIPTIONS[key]
	return "Parámetro '%s' del %s (sin descripción específica)." % [key, context]

## Rango del slider: usa el hint del export si existe; si no, lo deriva del valor.
func _range_for(value: float, prop: Dictionary) -> Vector2:
	if int(prop.hint) == PROPERTY_HINT_RANGE:
		var parts := String(prop.hint_string).split(",")
		if parts.size() >= 2:
			return Vector2(float(parts[0]), float(parts[1]))
	if value > 0.0 and value <= 1.0:
		return Vector2(0.0, 1.0)
	if value < 0.0:
		return Vector2(value * 3.0, 0.0)
	return Vector2(0.0, maxf(1.0, value * 3.0))

func _step_for(r: Vector2) -> float:
	var span := maxf(r.y - r.x, 0.001)
	var s := span / 200.0
	return maxf(s, 0.0005)

func _fmt(v: float) -> String:
	if absf(v) >= 100.0:
		return str(int(round(v)))
	if v == round(v):
		return "%d" % int(v)
	if absf(v) < 0.1:
		return "%.4f" % v
	return "%.2f" % v

func _env() -> Environment:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	var we := scene.find_child("WorldEnvironment", true, false) as WorldEnvironment
	return we.environment if we != null else null

func _heal_player(p: Node) -> void:
	p.set("player_health", p.get("max_player_health"))
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("update_health"):
		hud.update_health(int(p.get("player_health")))

func _break_eye() -> void:
	for wp in get_tree().get_nodes_in_group("weak_point"):
		if wp.get("is_broken") != true and wp.has_method("break_eye"):
			wp.break_eye()
			return
	_note("No quedan ojos intactos.")
# ---------------------------------------------------------------------------
# PRUEBAS — escenarios rápidos; nunca fuerza la fase sobre un bucle existente.
# ---------------------------------------------------------------------------
func _build_tests() -> void:
	_header("PRUEBAS DE COMBATE")
	_note("Usa las acciones para preparar situaciones; F1 cierra el panel.")
	_add_action("Restaurar agarre y vida", "Para repetir pruebas de escalada sin reiniciar.", func():
		var p := get_tree().get_first_node_in_group("player")
		if p:
			_heal_player(p)
			p.set("grip", p.get("grip_max")))
	_add_action("Romper siguiente ojo", "Destruye visualmente el próximo ojo intacto y avanza el puzzle.", func(): _break_eye())
	_add_action("Preparar tercer ojo", "Rompe los primeros dos ojos en orden; deja intacto el tercero para practicar la escalada.", func(): _prepare_third_eye())
	_add_action("Probar El Despertar", "Rompe los ojos restantes y activa la transición normal a fase 3.", func(): _break_all_eyes())
	_add_action("Probar pantalla de victoria", "Dispara la muerte normal del jefe.", func():
		var b := get_tree().get_first_node_in_group("boss")
		if b and b.has_method("die"):
			b.die())
	_header("HERRAMIENTAS")
	_add_action("Restablecer tiempo x1", "Recupera velocidad de simulación normal.", func(): Engine.time_scale = 1.0; _populate())
	_add_action("Reiniciar prueba", "Reinicia la escena y restablece el tiempo.", func():
		Engine.time_scale = 1.0
		get_tree().paused = false
		_close_for_reload()
		get_tree().reload_current_scene())
	_note("Las pruebas de ojos invocan la lógica real de ruptura del jefe.")

func _close_for_reload() -> void:
	_root.visible = false
	Input.mouse_mode = _prev_mouse

func _eyes_ordered() -> Array:
	var eyes: Array = get_tree().get_nodes_in_group("boss_eye")
	eyes.sort_custom(func(a, b): return int(a.get("eye_index")) < int(b.get("eye_index")))
	return eyes

func _prepare_third_eye() -> void:
	for eye in _eyes_ordered():
		if int(eye.get("eye_index")) >= 2:
			break
		if not bool(eye.get("is_broken")) and eye.has_method("break_eye"):
			eye.break_eye()

func _break_all_eyes() -> void:
	for eye in _eyes_ordered():
		if is_instance_valid(eye) and not bool(eye.get("is_broken")) and eye.has_method("break_eye"):
			eye.break_eye()

func _capture_defaults() -> void:
	_defaults.clear()
	for group_name in ["player", "boss"]:
		var obj := get_tree().get_first_node_in_group(group_name)
		if obj:
			var values: Dictionary = {}
			for prop in obj.get_property_list():
				if (int(prop.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE) and (int(prop.usage) & PROPERTY_USAGE_EDITOR):
					if int(prop.type) in [TYPE_INT, TYPE_FLOAT, TYPE_BOOL]:
						values[String(prop.name)] = obj.get(prop.name)
			_defaults[group_name] = values
	var env := _env()
	if env:
		_defaults["environment"] = {
			"ambient_light_energy": env.ambient_light_energy,
			"glow_intensity": env.glow_intensity,
			"fog_density": env.fog_density,
			"volumetric_fog_density": env.volumetric_fog_density,
			"background_energy_multiplier": env.background_energy_multiplier}

func _restore_defaults() -> void:
	Engine.time_scale = 1.0
	_saved_by_group = {"player": {}, "boss": {}, "environment": {}}
	_saved_brightness = null
	_set_invulnerable(false)
	_set_passive(false)
	for group_name in ["player", "boss"]:
		var obj := get_tree().get_first_node_in_group(group_name)
		if obj and _defaults.has(group_name):
			for key in _defaults[group_name]:
				if group_name == "boss" and key == "max_health" and obj.has_method("set_max_health_for_debug"):
					obj.set_max_health_for_debug(int(_defaults[group_name][key]))
				else:
					obj.set(key, _defaults[group_name][key])
	var env := _env()
	if env and _defaults.has("environment"):
		for key in _defaults["environment"]:
			env.set(key, _defaults["environment"][key])
	# La interfaz se refresca después desde el botón que llama a esta función.

# ---------------------------------------------------------------------------
# GUÍA DE CONTROLES — overlay independiente de la depuración, accesible con F2.
# Lee las asignaciones del InputMap; no contiene teclas supuestas.
# ---------------------------------------------------------------------------
func _export_default(obj: Object, key: String) -> Variant:
	var group_name := "player" if obj.is_in_group("player") else "boss"
	if _defaults.has(group_name) and _defaults[group_name].has(key):
		return _defaults[group_name][key]
	return null

func _build_controls_ui() -> void:
	_controls_layer = Control.new()
	_controls_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	_controls_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_controls_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_controls_layer)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.025, 0.025, 0.055, 0.94)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_controls_layer.add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_controls_layer.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(540, 490)
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = ACCENT
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	margin.add_child(v)
	var header := HBoxContainer.new()
	v.add_child(header)
	var title := Label.new()
	title.text = "CONTROLES  ·  EL QUE SOSTIENE"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", ACCENT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := Button.new()
	close.text = "Cerrar  [F2]"
	close.pressed.connect(_close_controls)
	header.add_child(close)
	var note := Label.new()
	note.text = "Teclado y ratón · Esc o F2 para cerrar"
	note.add_theme_color_override("font_color", BONE)
	v.add_child(note)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(480, 370)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_controls_scroll = VBoxContainer.new()
	_controls_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_controls_scroll.add_theme_constant_override("separation", 5)
	scroll.add_child(_controls_scroll)
	_controls_layer.visible = false

func _binding_text(action: String) -> String:
	# Un único control principal de teclado/ratón, sin mandos ni alternativas.
	if not InputMap.has_action(action):
		return "—"
	for e in InputMap.action_get_events(action):
		if e is InputEventKey:
			var code: Key = e.physical_keycode if e.physical_keycode != KEY_NONE else e.keycode
			if code != KEY_NONE:
				var key_name := OS.get_keycode_string(code)
				match code:
					KEY_SHIFT: return "SHIFT"
					KEY_SPACE: return "ESPACIO"
					KEY_ESCAPE: return "ESC"
				return key_name.to_upper()
	for e in InputMap.action_get_events(action):
		if e is InputEventMouseButton:
			match e.button_index:
				MOUSE_BUTTON_LEFT: return "CLIC IZQUIERDO"
				MOUSE_BUTTON_RIGHT: return "CLIC DERECHO"
				MOUSE_BUTTON_MIDDLE: return "CLIC CENTRAL"
	return "—"

func _refresh_controls() -> void:
	for child in _controls_scroll.get_children():
		child.queue_free()
	var last_section := ""
	var rows := [
		["MOVIMIENTO", "Moverse", "W A S D"],
		["MOVIMIENTO", "Cámara", "RATÓN"],
	]
	for entry in CONTROL_ACTIONS:
		if entry[1] in ["ui_up", "ui_down", "ui_left", "ui_right"]:
			continue
		rows.append([entry[0], entry[2], "ESPACIO" if entry[1] == "ui_accept" else _binding_text(entry[1])])
	rows.append(["INTERFAZ", "Ver controles", "F2"])
	for entry in rows:
		if entry[0] != last_section:
			last_section = entry[0]
			var header := Label.new()
			header.text = "  " + last_section
			header.add_theme_font_size_override("font_size", 13)
			header.add_theme_color_override("font_color", ACCENT)
			_controls_scroll.add_child(header)
		var line := HBoxContainer.new()
		line.custom_minimum_size.y = 28
		_controls_scroll.add_child(line)
		var title := Label.new()
		title.text = entry[1]
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title.add_theme_color_override("font_color", BONE)
		line.add_child(title)
		var binding := Label.new()
		binding.text = entry[2]
		binding.add_theme_color_override("font_color", Color("f0a6a9"))
		binding.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		line.add_child(binding)

func show_controls() -> void:
	# API pública para abrir la guía desde el menú principal.
	if _controls_layer != null and not _controls_layer.visible:
		_toggle_controls()

func _toggle_controls() -> void:
	if _controls_layer.visible:
		_close_controls()
		return
	_controls_opened_from_debug = _root.visible
	_controls_prev_paused = get_tree().paused
	_controls_prev_mouse = Input.mouse_mode
	_refresh_controls()
	_controls_layer.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true

func _close_controls() -> void:
	_controls_layer.visible = false
	get_tree().paused = _controls_prev_paused
	Input.mouse_mode = _controls_prev_mouse

func _env_default(key: String) -> Variant:
	if _defaults.has("environment") and _defaults["environment"].has(key):
		return _defaults["environment"][key]
	return null
