extends CharacterBody3D
enum State {IDLE, CHARGING, RECOVER, STAGGERED, PHASE_CHANGE, EXHAUSTED, DEAD}

@export_group("Identidad")
@export var boss_name: String = "El Que Sostiene"

@export_group("Salud del coloso")
@export_range(200, 2000, 25) var max_health: int = 800
@export_group("Vida por tramos — Ojos")
@export var use_eye_health_gates: bool = true
# Cada ojo protege un cuarto de la barra del jefe. No modificar durante el combate.

@export_group("Ataques por fase")
@export var attacks_p1: Array[AttackData]   # 0 ojos: te ignora (Barrido, Marca, Lluvia)
@export var attacks_p2: Array[AttackData]   # 1 ojo: el puzzle (proyectiles, rayo, dash x3)
@export var attacks_p3: Array[AttackData]   # 3 ojos: te mira (todo, rapidísimo)
@export var fury_max: float = 100.0

@export_group("Movimiento")
@export var turn_speed: float = 3.0
@export var approach_speed: float = 3.4
@export var approach_range: float = 7.0

@export_group("Boss Polish V1 — lectura de ataques")
@export var anticipation_strength: float = 0.16
@export var eye_hit_reaction_strength: float = 0.10
@export var enable_attack_anticipation: bool = true

var _anticipation_tween: Tween
var _eye_reaction_tween: Tween

@export_group("Boss Polish V5 — señales de ataque")
@export var enable_attack_cue_light: bool = true
@export_range(0.0, 2.0, 0.05) var attack_cue_energy: float = 0.75
@export_range(2.0, 16.0, 0.5) var attack_cue_range: float = 9.0
@export_range(0.1, 2.0, 0.05) var attack_cue_motion_scale: float = 1.0

var _attack_cue_light: OmniLight3D
var _attack_cue_tween: Tween

@export_group("Boss Polish V2 — transiciones")
@export var enable_phase_feedback: bool = true
@export_range(0.0, 2.0, 0.05) var phase_light_energy: float = 0.9
@export_range(0.1, 2.0, 0.05) var phase_light_duration: float = 0.85
@export_range(0.0, 1.0, 0.01) var eye_break_gesture_strength: float = 0.28

var _phase_light: OmniLight3D
var _phase_light_tween: Tween
var _phase_gesture_tweens: Array[Tween] = []

@export_group("Audio Pass V1 — Identidad sonora")
@export var enable_boss_audio_cues: bool = true
@export_range(-24.0, 3.0, 0.5) var boss_cue_volume_db: float = -7.0
@export_range(-24.0, 3.0, 0.5) var boss_awakening_volume_db: float = -3.0

@export_group("Boss Polish V6 — El Despertar")
@export var enable_cinematic_awakening: bool = true
@export_range(1.5, 6.0, 0.1) var awakening_duration: float = 3.0
@export_range(0.0, 2.0, 0.05) var awakening_light_energy: float = 1.25
@export_range(6.0, 25.0, 0.5) var awakening_light_range: float = 16.0

var _awakening_light: OmniLight3D
var _awakening_light_tween: Tween
var _awakening_body_tween: Tween
var _awakening_running: bool = false

@export_group("Legibilidad V1 — señales de peligro")
@export_range(0.25, 2.0, 0.05) var telegraph_visibility: float = 1.0
@export_range(0.0, 2.0, 0.05) var telegraph_outline: float = 1.0
@export_range(0.0, 20.0, 0.5) var telegraph_pulse_speed: float = 8.0

# Personalidad V1: presencia ambiental discreta para diferenciar estados emocionales.
# No altera daño, colisiones, IA, ventanas de escalada ni tiempos de ataque.
@export_group("Personalidad V1 — presencia por fase")
@export var enable_phase_presence: bool = true
@export_range(0.0, 2.0, 0.05) var phase1_presence: float = 0.18
@export_range(0.0, 2.0, 0.05) var phase2_presence: float = 0.45
@export_range(0.0, 2.0, 0.05) var phase3_presence: float = 0.8
@export_range(0.0, 10.0, 0.1) var phase_presence_pulse_speed: float = 1.3
@export_range(2.0, 18.0, 0.5) var phase_presence_range: float = 8.0

var _presence_light: OmniLight3D = null
var _presence_clock: float = 0.0

var current_health: int
var current_state: State = State.IDLE
var phase: int = 1
var attack_loop_running: bool = false
var debug_passive: bool = false # Depuración: desactiva el ciclo ofensivo
var is_dead: bool = false
var _first_attack: bool = true
var is_onboarding: bool = false
var fury: float = 0.0
var external_control: bool = false
@export_group("Ventanas de escalada — Fase 2")
@export_range(0.5, 10.0, 0.25) var phase2_combo_opening: float = 3.5
@export_range(0.5, 12.0, 0.25) var third_eye_combo_opening: float = 6.0
@export_range(0.5, 10.0, 0.25) var eye_break_opening: float = 4.0
@export_range(0.5, 15.0, 0.25) var second_eye_break_opening: float = 8.0
@export_range(0.2, 2.0, 0.05) var teleport_warning: float = 0.6
@export_range(0.1, 2.0, 0.05) var climb_release_check: float = 0.25

# Balance V1: parámetros ajustables sin modificar daños ni ventanas de escalada.
@export_group("Balance V1 — Ritmo del combate")
@export_range(0.5, 5.0, 0.1) var phase1_pause: float = 2.2
@export_range(0.2, 4.0, 0.1) var phase2_pause: float = 1.3
@export_range(0.2, 4.0, 0.1) var phase3_pause: float = 0.8
@export_range(0.3, 1.5, 0.05) var phase1_attack_speed: float = 1.0
@export_range(0.3, 1.5, 0.05) var phase2_attack_speed: float = 0.85
@export_range(0.3, 1.5, 0.05) var phase2_enraged_speed: float = 0.68
@export_range(0.3, 1.5, 0.05) var phase3_attack_speed: float = 0.5
@export_range(0.0, 4.0, 0.1) var phase3_combo_breath: float = 1.0

# Versiona las corrutinas: un bucle anterior no puede recuperar el control.

# Escalada V2: oportunidad y riesgo, sin cambiar ataques ni ventanas.
@export_group("Escalada V2 — Sacudida del coloso")
@export var enable_climb_shakes: bool = true
@export_range(2.0, 15.0, 0.5) var climb_shake_after: float = 5.0
@export_range(5.0, 30.0, 0.5) var climb_shake_cooldown: float = 14.0
@export_range(0.5, 2.5, 0.1) var climb_shake_warning: float = 1.3
var _climb_hold_time: float = 0.0
var _climb_shake_cooldown_left: float = 0.0
var _climb_shaking: bool = false

var _attack_epoch: int = 0
var _last_combo: Array = []
var eyes_broken: int = 0            # Ojos reventados (0-3): dirige las fases
const MAX_EYES: int = 3

const EYE_EMISSION := Color(1.0, 0.95, 0.58)
const TELEGRAPH: PackedScene = preload("res://telegraph_decal.tscn")
# FASE 1 (te ignora) -> FASE 2 (el puzzle) -> FASE 3 (te mira).
const COMBOS := {
	1: [["Sweep"], ["DarkMark"], ["Rain"], ["Sweep", "DarkMark"], ["Melee", "Sweep"]],
	2: [["Eyes"], ["Rain"], ["Beam"], ["Charge"], ["Eyes", "Beam"], ["Charge", "DarkMark"]],
	3: [["Charge"], ["Beam"], ["Eyes", "Eyes"], ["Rain", "Sweep"], ["Charge", "Beam"], ["DarkMark", "Eyes"]],
}

@onready var body_pivot: Node3D = $BodyPivot
@onready var body_mesh: MeshInstance3D = $BodyPivot/MeshInstance3D
@onready var orbit_eyes: Node3D = $BodyPivot/OrbitEyes
@onready var climb_zone: Area3D = $BodyPivot/ClimbZone
# Alias usado por algunos ataques/telemetría.
@onready var mesh: MeshInstance3D = body_mesh
# Partes del cuerpo que gesticulan con los ataques (antes eran estáticas).
@onready var _head: Node3D = body_pivot.get_node_or_null("Head")
@onready var _hump: Node3D = body_pivot.get_node_or_null("Hump")
@onready var _arm_l: Node3D = body_pivot.get_node_or_null("Arm_L")
@onready var _arm_r: Node3D = body_pivot.get_node_or_null("Arm_R")

var _base_head := Transform3D()
var _base_hump := Transform3D()
var _base_arm_l := Transform3D()
var _base_arm_r := Transform3D()

var _base_pivot_scale: Vector3 = Vector3.ONE
var _base_pivot_position: Vector3 = Vector3.ZERO
var _base_pivot_rotation: Vector3 = Vector3.ZERO
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _play_boss_audio(sound_name: String, volume_db: float = -6.0) -> void:
	if enable_boss_audio_cues:
		Audio.play_sfx(sound_name, volume_db)

func _ready() -> void:
	add_to_group("boss")
	get_node("/root/Debug").apply_saved_to(self, "boss")
	current_health = max_health
	_base_pivot_scale = body_pivot.scale
	_base_pivot_position = body_pivot.position
	_base_pivot_rotation = body_pivot.rotation
	var hud := _hud()
	if hud and hud.has_method("setup_boss_hud"):
		hud.setup_boss_hud(boss_name, max_health)
	if hud and hud.has_method("update_eyes_broken"):
		hud.update_eyes_broken(0)
	_update_health_ui()
	if orbit_eyes:
		orbit_eyes.visible = false
	# El coloso es escalable desde el primer momento: esto es un puzzle, no un combate.
	if climb_zone:
		climb_zone.monitoring = true
	_set_eyes_visible(true)
	_kneel()
	_capture_part_bases()
	_create_attack_cue_light()
	_create_phase_presence_light()
	_start_idle_anim()
	Audio.play_music("tension")
	_boss_intro()

func _create_phase_presence_light() -> void:
	if is_instance_valid(_presence_light):
		return
	_presence_light = OmniLight3D.new()
	_presence_light.name = "PhasePresenceLightV1"
	_presence_light.position = Vector3(0.0, 3.0, 0.0)
	_presence_light.shadow_enabled = false
	_presence_light.light_energy = 0.0
	_presence_light.omni_range = phase_presence_range
	body_pivot.add_child(_presence_light)

func _process(delta: float) -> void:
	if not is_instance_valid(_presence_light):
		return
	_presence_clock += delta
	_presence_light.omni_range = phase_presence_range
	if is_dead or not enable_phase_presence:
		_presence_light.light_energy = move_toward(_presence_light.light_energy, 0.0, delta * 2.0)
		return
	var target_energy: float = phase1_presence
	match phase:
		1:
			_presence_light.light_color = Color(0.40, 0.48, 0.85)
			target_energy = phase1_presence
		2:
			_presence_light.light_color = Color(0.72, 0.24, 0.72)
			target_energy = phase2_presence
		3:
			_presence_light.light_color = Color(0.95, 0.18, 0.26)
			target_energy = phase3_presence
	# El pulso acompaña la fase sin competir con los indicadores de ataque.
	var pulse: float = 0.90 + 0.10 * sin(_presence_clock * phase_presence_pulse_speed)
	if current_state == State.CHARGING or current_state == State.PHASE_CHANGE:
		pulse *= 0.5
	_presence_light.light_energy = lerpf(_presence_light.light_energy, target_energy * pulse, clampf(delta * 3.0, 0.0, 1.0))

func _set_eyes_visible(show_node: bool) -> void:
	# Los 3 ojos de la espalda están siempre ahí; se revientan trepando.
	for wp in get_tree().get_nodes_in_group("weak_point"):
		wp.visible = show_node
		if wp is CollisionObject3D:
			wp.collision_layer = 1 if show_node else 0

func _boss_intro() -> void:
	var hud := _hud()
	if hud and hud.has_method("boss_intro"):
		hud.boss_intro(boss_name)
	Audio.play_sfx("roar", -2.0)
	await get_tree().create_timer(2.5, false).timeout
	if not is_dead:
		choose_attack()

func _kneel() -> void:
	# La entidad está arrodillada: el cuerpo se inclina hacia delante, pesado.
	var t := create_tween().set_parallel(true)
	t.set_trans(Tween.TRANS_SINE)
	t.tween_property(body_pivot, "rotation:x", _base_pivot_rotation.x + deg_to_rad(-13.0), 1.2)
	t.tween_property(body_pivot, "position:y", _base_pivot_position.y - 0.8, 1.2)

func _interrupted() -> bool:
	# El bucle de ataque se corta si el coloso reacciona (p. ej. ojo reventado).
	return debug_passive or current_state == State.STAGGERED or current_state == State.PHASE_CHANGE or current_state == State.EXHAUSTED

func _hud() -> Node:
	var hud := get_tree().get_first_node_in_group("hud")
	if not hud:
		hud = get_tree().get_first_node_in_group("HUD")
	return hud

func _speed_mult() -> float:
	# Cada ojo reventado acelera al coloso.
	match phase:
		1: return phase1_attack_speed
		2: return phase2_attack_speed if eyes_broken <= 1 else phase2_enraged_speed
		3: return phase3_attack_speed
		_: return 1.0

func _data_by_id(attack_id: String) -> AttackData:
	for pool in [attacks_p1, attacks_p2, attacks_p3]:
		for a in pool:
			if a and a.id == attack_id:
				return a
	return null

func _pick_combo() -> Array:
	var combos: Array = COMBOS.get(phase, [])
	if combos.is_empty():
		return []
	# Onboarding: el primer combo de la pelea es un melee lento y previsible.
	if _first_attack:
		_first_attack = false
		is_onboarding = true
		return ["Melee"]
	# Selecciona solo alternativas diferentes cuando estén disponibles.
	# Un segundo pick_random podía devolver exactamente el mismo combo.
	var alternatives: Array = []
	for option in combos:
		if option != _last_combo:
			alternatives.append(option)
	var pool: Array = alternatives if not alternatives.is_empty() else combos
	var selected: Array = pool.pick_random()
	_last_combo = selected.duplicate()
	return selected

func _cancel_attack_sequence() -> void:
	_attack_epoch += 1
	attack_loop_running = false
	_clear_attack_anticipation()
	_clear_telegraph()

func _show_exhaustion() -> void:
	# Con dos ojos destruidos, la recuperación es más dolorosa y visible.
	# Solo afecta a gestos, nunca a la duración de la ventana.
	var pain_scale: float = 1.4 if eyes_broken >= 2 else 1.0
	_gesture(_head, _base_head, Vector3(24.0 * pain_scale, 0, 0), Vector3(0, -0.40 * pain_scale, 0), 0.25, 0.65)
	_gesture(_arm_l, _base_arm_l, Vector3(12.0 * pain_scale, 0, -10.0), Vector3(0, -0.20 * pain_scale, 0), 0.25, 0.65)

func _rest_phase_two(duration: float, epoch: int) -> void:
	current_state = State.EXHAUSTED
	_show_exhaustion()
	await get_tree().create_timer(duration, false).timeout
	# No teletransportar al jugador si todavía está agarrado.
	while not is_dead and _attack_epoch == epoch and phase == 2 and _player_is_climbing():
		await get_tree().create_timer(climb_release_check, false).timeout
	if not is_dead and _attack_epoch == epoch and phase == 2:
		current_state = State.IDLE

func _second_eye_recovery() -> void:
	_cancel_attack_sequence()
	var epoch: int = _attack_epoch
	await _rest_phase_two(second_eye_break_opening, epoch)
	if not is_dead and _attack_epoch == epoch and phase == 2:
		choose_attack()

func set_debug_passive(enabled: bool) -> void:
	if debug_passive == enabled:
		return
	debug_passive = enabled
	if enabled:
		# Invalidar secuencias pendientes e impedir movimiento residual.
		_cancel_attack_sequence()
		external_control = false
		velocity = Vector3.ZERO
		current_state = State.IDLE
		_climb_shaking = false
		_climb_hold_time = 0.0
		var climbing_player: Node = get_tree().get_first_node_in_group("player")
		if is_instance_valid(climbing_player) and climbing_player.has_method("cancel_colossus_shake_warning"):
			climbing_player.cancel_colossus_shake_warning()
	else:
		_resume_after_debug_passive()

func _resume_after_debug_passive() -> void:
	# Mantiene la recuperación de ojos/cambio de fase si todavía continúa.
	# Si el descanso fue interrumpido por el modo pasivo, libera ese estado.
	if current_state == State.EXHAUSTED:
		current_state = State.IDLE
	while not debug_passive and not is_dead and _interrupted():
		await get_tree().create_timer(0.20, false).timeout
	if not debug_passive and not is_dead and not attack_loop_running:
		choose_attack()

func choose_attack() -> void:
	if attack_loop_running or is_dead or _interrupted():
		return
	attack_loop_running = true
	var epoch: int = _attack_epoch
	while not is_dead and _attack_epoch == epoch and not _interrupted():
		current_state = State.IDLE
		var pre_combo_pause: float = phase1_pause
		if phase == 2:
			pre_combo_pause = phase2_pause
		elif phase == 3:
			pre_combo_pause = phase3_pause
		await get_tree().create_timer(pre_combo_pause, false).timeout
		if is_dead or _attack_epoch != epoch or _interrupted():
			break
		if phase == 2 and not _player_is_climbing():
			await _puzzle_teleport()
			if is_dead or _attack_epoch != epoch or _interrupted():
				break
		var combo: Array = _pick_combo()
		if combo.is_empty():
			break
		for i in combo.size():
			if is_dead or _attack_epoch != epoch or _interrupted():
				break
			var data: AttackData = _data_by_id(combo[i])
			if data == null:
				continue
			current_state = State.CHARGING
			telegraph(data)
			var charge: float = maxf(0.0, data.charge_time) * _speed_mult()
			if is_onboarding:
				charge = maxf(charge, 1.4)
				is_onboarding = false
			_anticipate_attack(data.id, charge)
			await get_tree().create_timer(charge, false).timeout
			if is_dead or _attack_epoch != epoch or _interrupted():
				_clear_attack_anticipation()
				break
			_clear_attack_anticipation()
			var attack_node: Node = get_node_or_null("Attacks/" + data.id)
			if attack_node and attack_node.has_method("fire"):
				play_anim(data.id)
				attack_node.fire()
			else:
				push_warning("Falta el ataque 'Attacks/%s'." % data.id)
			current_state = State.RECOVER
			var rec: float = maxf(0.0, data.recover_time) * _speed_mult()
			if i < combo.size() - 1:
				rec = minf(rec, 0.35)
			await get_tree().create_timer(rec, false).timeout
			_clear_telegraph()
		if is_dead or _attack_epoch != epoch or _interrupted():
			break
		# La segunda mitad de fase 2 necesita mas tiempo para llegar al tercer ojo.
		if phase == 2:
			var climb_opening: float = third_eye_combo_opening if eyes_broken >= 2 else phase2_combo_opening
			await _rest_phase_two(climb_opening, epoch)
			if is_dead or _attack_epoch != epoch or _interrupted():
				break
		elif phase == 3 and phase3_combo_breath > 0.0:
			# Una pausa breve entre combos, nunca dentro de un ataque.
			current_state = State.RECOVER
			await get_tree().create_timer(phase3_combo_breath, false).timeout
			if is_dead or _attack_epoch != epoch or _interrupted():
				break
	if _attack_epoch == epoch:
		attack_loop_running = false

# Señales de V5: un gesto distinto por ataque y un pulso de color.
# NO cambia el daño, el tiempo de carga ni el patrón de la habilidad.
func _create_attack_cue_light() -> void:
	if _attack_cue_light != null and is_instance_valid(_attack_cue_light):
		return
	_attack_cue_light = OmniLight3D.new()
	_attack_cue_light.name = "AttackCueLightV5"
	_attack_cue_light.position = Vector3(0.0, 3.0, -0.3)
	_attack_cue_light.omni_range = attack_cue_range
	_attack_cue_light.shadow_enabled = false
	_attack_cue_light.light_energy = 0.0
	body_pivot.add_child(_attack_cue_light)

func _cue_color(attack_id: String) -> Color:
	match attack_id:
		"Sweep", "Melee", "Stomp": return Color(0.96, 0.31, 0.18)
		"DarkMark": return Color(0.76, 0.20, 0.92)
		"Rain": return Color(0.32, 0.48, 1.0)
		"Beam": return Color(1.0, 0.27, 0.48)
		"Eyes": return Color(0.90, 0.48, 1.0)
		"Charge": return Color(1.0, 0.50, 0.18)
		_: return Color(0.65, 0.35, 0.90)

func _anticipate_attack(attack_id: String, charge_time: float) -> void:
	_clear_attack_anticipation()
	if not enable_attack_anticipation or charge_time <= 0.08:
		return
	var cue_key: String = "cue_" + attack_id.to_lower()
	if attack_id == "Stomp":
		cue_key = "cue_melee"
	_play_boss_audio(cue_key, boss_cue_volume_db)
	# Movimientos intencionalmente pequeños: el modelo final podrá reemplazarlos.
	var tilt := anticipation_strength * attack_cue_motion_scale
	var yaw := 0.0
	var vertical := 0.0
	match attack_id:
		"Rain":
			tilt *= -1.55
			vertical = 0.18
		"Beam":
			tilt *= 1.7
			yaw = 0.12
		"Eyes":
			tilt *= 0.85
			yaw = -0.18
		"Charge":
			tilt *= -1.2
			vertical = -0.10
		"Sweep":
			tilt *= 0.65
			yaw = -0.24
		"DarkMark":
			tilt *= 1.3
			vertical = -0.18
		"Melee", "Stomp":
			tilt *= 1.25
			vertical = -0.22
	if _head != null and is_instance_valid(_head):
		var target := _base_head.rotated_local(Vector3.RIGHT, tilt)
		target = target.rotated_local(Vector3.UP, yaw)
		target.origin += Vector3(0.0, vertical, 0.0)
		_anticipation_tween = create_tween()
		_anticipation_tween.tween_property(_head, "transform", target, minf(0.28, charge_time * 0.55)).set_trans(Tween.TRANS_SINE)
	if enable_attack_cue_light:
		_create_attack_cue_light()
		_attack_cue_light.omni_range = attack_cue_range
		_attack_cue_light.light_color = _cue_color(attack_id)
		_attack_cue_light.light_energy = 0.0
		_attack_cue_tween = create_tween()
		var rise: float = minf(0.16, charge_time * 0.30)
		_attack_cue_tween.tween_property(_attack_cue_light, "light_energy", attack_cue_energy, rise)
		_attack_cue_tween.tween_property(_attack_cue_light, "light_energy", attack_cue_energy * 0.35, maxf(0.01, charge_time - rise))

func _clear_attack_anticipation() -> void:
	if _anticipation_tween and _anticipation_tween.is_running():
		_anticipation_tween.kill()
	if _attack_cue_tween and _attack_cue_tween.is_running():
		_attack_cue_tween.kill()
	if _attack_cue_light != null and is_instance_valid(_attack_cue_light):
		_attack_cue_light.light_energy = 0.0
	if _head != null and is_instance_valid(_head):
		_head.transform = _base_head

func telegraph(data: AttackData):
	if body_mesh == null:
		print("body_mesh es null, revisa la ruta")
		return
	
	var mat = body_mesh.get_active_material(0) as StandardMaterial3D
	if mat == null:
		mat = body_mesh.material_override as StandardMaterial3D
	
	if mat == null:
		mat = StandardMaterial3D.new()
		body_mesh.material_override = mat
	
	# Ahora si es seguro
	mat.emission_enabled = true
	mat.emission = data.telegraph_color

const BASE_EMISSION := Color(0.24, 0.07, 0.38)

func _clear_telegraph() -> void:
	var mat := _body_material()
	if mat:
		# Restaura el brillo cósmico base en lugar de apagarlo del todo.
		mat.emission = BASE_EMISSION

func _body_material() -> StandardMaterial3D:
	if body_mesh == null:
		return null
	var mat := body_mesh.get_active_material(0) as StandardMaterial3D
	if mat == null:
		mat = body_mesh.material_override as StandardMaterial3D
	if mat == null:
		mat = StandardMaterial3D.new()
		body_mesh.material_override = mat
	return mat

# F1: ajusta vida maxima y actual sin desincronizar la barra ni sus tres sellos.
# Conserva la proporcion del tramo actual al modificar la vida maxima.
func set_max_health_for_debug(new_max: int) -> void:
	var old_max: int = maxi(max_health, 1)
	var ratio: float = clampf(float(current_health) / float(old_max), 0.0, 1.0)
	max_health = maxi(new_max, 4)
	current_health = clampi(int(round(float(max_health) * ratio)), 0, max_health)
	_update_health_ui()

func _update_health_ui() -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if not hud:
		hud = get_tree().get_first_node_in_group("HUD")
	if hud and hud.has_method("sync_boss_health_limits"):
		hud.sync_boss_health_limits(max_health, current_health)
	elif hud and hud.has_method("update_boss_health"):
		hud.update_boss_health(current_health)
	if hud and hud.has_method("set_boss_eye_gate"):
		hud.set_boss_eye_gate(is_eye_gate_active(), eyes_broken)
	if hud and hud.has_method("update_fury"):
		hud.update_fury(fury, fury_max)
	
# El daño al cuerpo atraviesa cuatro tramos de vida. Cada ojo debe romperse
# al terminar su tramo; el daño sobrante nunca salta un bloqueo.
func _next_eye_gate_health() -> int:
	return maxi(0, int(round(float(max_health) * (3.0 - float(eyes_broken)) / 4.0)))

func is_eye_gate_active() -> bool:
	return use_eye_health_gates and not is_dead and eyes_broken < MAX_EYES and current_health <= _next_eye_gate_health()

func can_damage_eye(_index: int = -1) -> bool:
	return not is_dead and (not use_eye_health_gates or is_eye_gate_active())

func take_damage(amount: int) -> void:
	if is_dead or amount <= 0:
		return
	var previous_hp: int = current_health
	var gate_hp: int = _next_eye_gate_health() if use_eye_health_gates else 0
	current_health = maxi(gate_hp, current_health - amount)
	var actual_damage: int = previous_hp - current_health
	if actual_damage <= 0:
		_update_health_ui()
		return
	fury = minf(fury_max, fury + float(actual_damage) * 0.22)
	var hud := _hud()
	if hud and hud.has_method("pop_damage"):
		hud.pop_damage(actual_damage, global_position + Vector3(0, 8.0, 0), Color(1.0, 0.85, 0.6))
	_update_health_ui()
	if current_health <= 0 and eyes_broken >= MAX_EYES:
		die()

## El jugador ha clavado una estocada en un ojo (feedback de progreso).
func on_eye_hit(_index: int, _hits: int, _total: int) -> void:
	if is_dead:
		return
	Audio.play_sfx("hit", -5.0)
	# Reacción contenida: no interrumpe el combo ni la escalada.
	if _hump and eye_hit_reaction_strength > 0.0:
		if _eye_reaction_tween and _eye_reaction_tween.is_running():
			_eye_reaction_tween.kill()
		_hump.transform = _base_hump
		_eye_reaction_tween = create_tween()
		_eye_reaction_tween.tween_property(_hump, "rotation:z", _base_hump.basis.get_euler().z + eye_hit_reaction_strength, 0.07)
		_eye_reaction_tween.tween_property(_hump, "transform", _base_hump, 0.20).set_trans(Tween.TRANS_SINE)

## Reacción visual local del coloso a un ojo roto. No toca hitboxes ni temporizadores de ataques.
func _eye_break_feedback(eye_number: int) -> void:
	if not enable_phase_feedback or is_dead:
		return
	# Evitar gestos superpuestos de un ojo anterior.
	for tw in _phase_gesture_tweens:
		if tw and tw.is_running():
			tw.kill()
	_phase_gesture_tweens.clear()
	var intensity: float = eye_break_gesture_strength
	if _head:
		var base: Transform3D = _base_head
		var tilt: float = intensity if eye_number % 2 == 0 else -intensity
		var pose: Transform3D = base.rotated_local(Vector3.RIGHT, tilt)
		var tw: Tween = create_tween()
		tw.tween_property(_head, "transform", pose, 0.13).set_trans(Tween.TRANS_SINE)
		tw.tween_property(_head, "transform", base, 0.40).set_trans(Tween.TRANS_SINE)
		_phase_gesture_tweens.append(tw)
	# Halo temporal unido al coloso: enfatiza las transiciones sin crear luces permanentes.
	var tint: Color = Color(0.67, 0.38, 0.92) if eye_number < 3 else Color(1.0, 0.30, 0.23)
	_phase_flash(tint)

func _phase_flash(tint: Color) -> void:
	if not enable_phase_feedback or is_dead:
		return
	if _phase_light_tween and _phase_light_tween.is_running():
		_phase_light_tween.kill()
	if _phase_light and is_instance_valid(_phase_light):
		_phase_light.queue_free()
	_phase_light = OmniLight3D.new()
	_phase_light.name = "PhaseFeedbackLight"
	_phase_light.position = Vector3(0, 3.2, 0)
	_phase_light.light_color = tint
	_phase_light.light_energy = 0.0
	_phase_light.omni_range = 13.0
	_phase_light.shadow_enabled = false
	body_pivot.add_child(_phase_light)
	var light: OmniLight3D = _phase_light
	_phase_light_tween = create_tween()
	_phase_light_tween.tween_property(light, "light_energy", phase_light_energy, 0.12)
	_phase_light_tween.tween_property(light, "light_energy", 0.0, maxf(0.1, phase_light_duration - 0.12)).set_trans(Tween.TRANS_SINE)
	_phase_light_tween.tween_callback(func() -> void:
		if is_instance_valid(light):
			light.queue_free()
		if _phase_light == light:
			_phase_light = null
	)

func _clear_phase_feedback() -> void:
	for tw in _phase_gesture_tweens:
		if tw and tw.is_running():
			tw.kill()
	_phase_gesture_tweens.clear()
	if _phase_light_tween and _phase_light_tween.is_running():
		_phase_light_tween.kill()
	if _phase_light and is_instance_valid(_phase_light):
		_phase_light.queue_free()
	_phase_light = null
	if _head and is_instance_valid(_head):
		_head.transform = _base_head

## Un ojo ha reventado: el coloso grita, la arena se distorsiona y avanzan las fases.
func on_eye_broken(_index: int) -> void:
	if is_dead or (use_eye_health_gates and not is_eye_gate_active()):
		return
	eyes_broken = mini(eyes_broken + 1, MAX_EYES)
	_eye_break_feedback(eyes_broken)
	_play_boss_audio("colossus_pain", -3.5)
	_distort_arena()
	_roar_shake()
	var hud := _hud()
	if hud and hud.has_method("update_eyes_broken"):
		hud.update_eyes_broken(eyes_broken)
	# El ojo rompe el sello del tramo: NO quita vida por sí mismo.
	# Se mantiene el aumento de furia y la transición de fases originales.
	fury = minf(fury_max, fury + 25.0)
	_update_health_ui()
	if eyes_broken >= 3:
		enter_phase_three()
	elif eyes_broken == 1 and phase < 2:
		enter_phase_two()
	elif eyes_broken == 2 and phase == 2:
		_second_eye_recovery()

## El grito distorsiona la arena: la luz tiembla, el vacío vibra.
func _distort_arena() -> void:
	var env := get_tree().current_scene.find_child("WorldEnvironment", true, false) as WorldEnvironment
	if env and env.environment:
		var e := env.environment
		var base := e.background_energy_multiplier
		var t := create_tween()
		t.tween_property(e, "background_energy_multiplier", base * 2.4, 0.15)
		t.tween_property(e, "background_energy_multiplier", base, 0.9)
	var hud := _hud()
	if hud and hud.has_method("flash"):
		hud.flash(Color(0.6, 0.08, 0.5, 0.30), 0.6)

func _roar_shake() -> void:
	var t := create_tween()
	t.tween_property(body_pivot, "rotation:z", deg_to_rad(7), 0.08)
	t.tween_property(body_pivot, "rotation:z", deg_to_rad(-7), 0.08)
	t.tween_property(body_pivot, "rotation:z", 0.0, 0.12)

func _capture_part_bases() -> void:
	if _head: _base_head = _head.transform
	if _hump: _base_hump = _hump.transform
	if _arm_l: _base_arm_l = _arm_l.transform
	if _arm_r: _base_arm_r = _arm_r.transform

## "Respiración" constante para que no parezca una estatua muerta.
func _start_idle_anim() -> void:
	if _hump == null:
		return
	var b := _base_hump.origin
	var t := create_tween().set_loops()
	t.tween_property(_hump, "position", b + Vector3(0, 0.14, 0), 2.6).set_trans(Tween.TRANS_SINE)
	t.tween_property(_hump, "position", b, 2.6).set_trans(Tween.TRANS_SINE)

## Cada ataque gesticula con las partes correspondientes del coloso.
func play_anim(attack_id: String) -> void:
	match attack_id:
		"Sweep":
			_gesture(_arm_r, _base_arm_r, Vector3(0, 0, -65), Vector3(0, 1.0, 0), 0.16, 0.5)
		"Stomp", "Melee":
			_gesture(_arm_l, _base_arm_l, Vector3(-62, 0, 0), Vector3(0, -1.0, 0), 0.14, 0.5)
			_gesture(_arm_r, _base_arm_r, Vector3(-62, 0, 0), Vector3(0, -1.0, 0), 0.14, 0.5)
			_gesture(_head, _base_head, Vector3(22, 0, 0), Vector3(0, -0.5, 0), 0.14, 0.5)
		"DarkMark":
			_gesture(_head, _base_head, Vector3(26, 0, 0), Vector3(0, -0.6, 0.4), 0.3, 0.7)
		"Rain":
			_gesture(_head, _base_head, Vector3(-40, 0, 0), Vector3(0, 0.5, -0.3), 0.5, 0.8)
		"Beam", "Eyes":
			_gesture(_head, _base_head, Vector3(-16, 12, 0), Vector3(0, 0.3, 0), 0.3, 0.6)
		"Charge":
			_gesture(_arm_l, _base_arm_l, Vector3(30, 0, -25), Vector3(-0.6, 0, 0.6), 0.3, 0.6)
			_gesture(_arm_r, _base_arm_r, Vector3(30, 0, 25), Vector3(0.6, 0, 0.6), 0.3, 0.6)

func _gesture(node: Node3D, base: Transform3D, rot_deg: Vector3, move: Vector3, dur_up: float, dur_down: float) -> void:
	if node == null:
		return
	var target := base.rotated_local(Vector3.RIGHT, deg_to_rad(rot_deg.x))
	target = target.rotated_local(Vector3.UP, deg_to_rad(rot_deg.y))
	target = target.rotated_local(Vector3.BACK, deg_to_rad(rot_deg.z))
	target.origin = base.origin + move
	var t := create_tween()
	t.tween_property(node, "transform", target, dur_up).set_trans(Tween.TRANS_SINE)
	t.tween_property(node, "transform", base, dur_down).set_trans(Tween.TRANS_SINE)

## Deja una silueta del coloso donde estaba (Dash x3).
func _spawn_afterimage() -> void:
	var ghost := Node3D.new()
	get_tree().current_scene.add_child(ghost)
	ghost.global_transform = body_pivot.global_transform
	var gm := StandardMaterial3D.new()
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gm.albedo_color = Color(0.6, 0.2, 0.85, 0.5)
	gm.emission_enabled = true
	gm.emission = Color(0.7, 0.2, 1.0)
	# Copia cada parte del cuerpo para que la silueta sea el coloso entero.
	for child in body_pivot.get_children():
		if child is MeshInstance3D:
			var m := (child as MeshInstance3D).duplicate() as MeshInstance3D
			m.material_override = gm
			ghost.add_child(m)
	var t := create_tween().set_parallel(true)
	t.tween_property(ghost, "scale", Vector3.ONE * 1.1, 0.5)
	t.tween_property(gm, "albedo_color:a", 0.0, 0.5)
	t.chain().tween_callback(ghost.queue_free)

## Fase 2 — el puzzle: el coloso se teletransporta entre plataformas.
func _puzzle_teleport() -> void:
	_spawn_afterimage()
	var markers: Array[Node3D] = []
	for c in get_tree().current_scene.get_children():
		if c is Marker3D and String(c.name).begins_with("Pos"):
			markers.append(c)
	if markers.is_empty():
		return
	var m: Node3D = markers.pick_random()
	var target := m.global_position
	var decal := TELEGRAPH.instantiate() as TelegraphDecal
	get_tree().current_scene.add_child(decal)
	var g := TelegraphDecal.find_ground(get_tree(), target + Vector3(0, 5, 0))
	decal.place(g)
	decal.show_ring(3.0, Color(0.72, 0.2, 1.0, 0.9))
	decal.grow_to(3.0, teleport_warning)
	_play_boss_audio("boss_teleport", boss_cue_volume_db)
	await get_tree().create_timer(teleport_warning, false).timeout
	if is_dead or phase != 2 or _interrupted() or _player_is_climbing():
		if is_instance_valid(decal):
			decal.queue_free()
		return
	global_position = target
	_spawn_afterimage()
	if is_instance_valid(decal):
		decal.flash_and_free(Color(0.72, 0.2, 1.0, 0.9))
	await get_tree().create_timer(0.25, false).timeout

func _player_is_climbing() -> bool:
	var player: Node = get_tree().get_first_node_in_group("player")
	return is_instance_valid(player) and player.get("is_climbing") == true

## (El sistema de "derribo" se sustituyó por el puzzle de ojos: trepa y revienta.)

func enter_phase_two() -> void:
	# 1er ojo reventado: el coloso deja de ignorarte y empieza el puzzle.
	if is_dead or phase >= 2:
		return
	phase = 2
	_cancel_attack_sequence()
	current_state = State.PHASE_CHANGE
	_last_combo = []
	if enable_phase_feedback:
		_gesture(_arm_l, _base_arm_l, Vector3(-18, 0, -12), Vector3(-0.2, 0.4, 0), 0.20, 0.65)
	Audio.play_sfx("roar", 0.0)
	Audio.play_music("epic")
	var hud := _hud()
	if hud and hud.has_method("show_phase_text"):
		hud.show_phase_text("EL PUZZLE")
	if hud and hud.has_method("update_fury"):
		hud.update_fury(fury, fury_max)
	if orbit_eyes:
		orbit_eyes.visible = true
		orbit_eyes.scale = Vector3.ZERO
		create_tween().tween_property(orbit_eyes, "scale", Vector3.ONE, 0.8).set_trans(Tween.TRANS_BACK)
	await get_tree().create_timer(1.2, false).timeout
	if not is_dead and phase == 2:
		var epoch: int = _attack_epoch
		await _rest_phase_two(eye_break_opening, epoch)
		if not is_dead and phase == 2 and _attack_epoch == epoch:
			choose_attack()

func enter_phase_three() -> void:
	# Tercer ojo: el coloso despierta. Mantener la fase, vida y ataques originales.
	if is_dead or phase >= 3:
		return
	phase = 3
	_cancel_attack_sequence()
	current_state = State.PHASE_CHANGE
	_last_combo = []
	var epoch: int = _attack_epoch
	_clear_phase_feedback()
	_clear_attack_anticipation()
	if not enable_cinematic_awakening:
		Audio.play_sfx("roar", 0.0)
	Audio.play_music("epic")
	var hud := _hud()
	if hud and hud.has_method("show_phase_text"):
		hud.show_phase_text("TE MIRA")

	if enable_cinematic_awakening:
		await _play_awakening(epoch)
	else:
		# Modo alternativo: transición corta con las mismas condiciones de fase.
		var quick := create_tween().set_parallel(true)
		quick.tween_property(body_pivot, "rotation:x", _base_pivot_rotation.x, 1.2)
		quick.tween_property(body_pivot, "position:y", _base_pivot_position.y, 1.2)
		quick.tween_property(body_pivot, "scale", _base_pivot_scale * 1.2, 1.2)
		await get_tree().create_timer(1.6, false).timeout
	if not is_dead and phase == 3 and _attack_epoch == epoch:
		current_state = State.IDLE
		choose_attack()

func _play_awakening(epoch: int) -> void:
	# Es una transición visual: no altera colisiones, escalada ni control del jugador.
	_awakening_running = true
	var total: float = maxf(1.5, awakening_duration)
	var charge_time: float = total * 0.30
	var rise_time: float = total * 0.46
	var release_time: float = total - charge_time - rise_time
	_play_boss_audio("awakening_charge", boss_awakening_volume_db)
	if climb_zone:
		climb_zone.monitoring = true
	# Halo carmesí local, sin sombras, que desaparece al terminar.
	_awakening_light = OmniLight3D.new()
	_awakening_light.name = "AwakeningLight"
	_awakening_light.position = Vector3(0, 3.5, 0)
	_awakening_light.light_color = Color(1.0, 0.21, 0.19)
	_awakening_light.light_energy = 0.0
	_awakening_light.omni_range = awakening_light_range
	_awakening_light.shadow_enabled = false
	body_pivot.add_child(_awakening_light)
	var light: OmniLight3D = _awakening_light
	_awakening_light_tween = create_tween()
	_awakening_light_tween.tween_property(light, "light_energy", awakening_light_energy, charge_time + rise_time).set_trans(Tween.TRANS_SINE)
	_awakening_light_tween.tween_property(light, "light_energy", 0.0, release_time).set_trans(Tween.TRANS_SINE)
	# El movimiento inicial contiene el cuerpo; después lo alza lentamente.
	_awakening_body_tween = create_tween().set_parallel(true)
	_awakening_body_tween.tween_property(body_pivot, "rotation:x", _base_pivot_rotation.x + deg_to_rad(-18.0), charge_time).set_trans(Tween.TRANS_SINE)
	_awakening_body_tween.tween_property(body_pivot, "position:y", _base_pivot_position.y - 1.0, charge_time).set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(charge_time, false).timeout
	if is_dead or phase != 3 or _attack_epoch != epoch:
		_clear_awakening()
		return
	_play_boss_audio("awakening_stone", boss_awakening_volume_db)
	_awakening_body_tween = create_tween().set_parallel(true)
	_awakening_body_tween.tween_property(body_pivot, "rotation:x", _base_pivot_rotation.x, rise_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_awakening_body_tween.tween_property(body_pivot, "position:y", _base_pivot_position.y, rise_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_awakening_body_tween.tween_property(body_pivot, "scale", _base_pivot_scale * 1.2, rise_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if _arm_l:
		_gesture(_arm_l, _base_arm_l, Vector3(-35, 0, -22), Vector3(-0.5, 0.5, 0), rise_time * 0.65, rise_time * 0.35)
	if _arm_r:
		_gesture(_arm_r, _base_arm_r, Vector3(-35, 0, 22), Vector3(0.5, 0.5, 0), rise_time * 0.65, rise_time * 0.35)
	await get_tree().create_timer(rise_time, false).timeout
	if is_dead or phase != 3 or _attack_epoch != epoch:
		_clear_awakening()
		return
	# Audio y onda se disparan simultáneamente, sin tocar el daño ni los hitboxes.
	_play_boss_audio("awakening_release", boss_awakening_volume_db)
	# Ruptura ceremonial: onda radial VISUAL, sin daño ni hitboxes adicionales.
	_distort_arena()
	_roar_shake()
	var wave := TELEGRAPH.instantiate() as TelegraphDecal
	get_tree().current_scene.add_child(wave)
	var ground_pos: Vector3 = TelegraphDecal.find_ground(get_tree(), global_position + Vector3(0, 2, 0))
	wave.place(ground_pos)
	wave.show_ring(2.0, Color(1.0, 0.28, 0.18, 0.95))
	wave.grow_to(14.0, maxf(0.2, release_time))
	wave.flash_and_free(Color(1.0, 0.28, 0.18, 0.95))
	await get_tree().create_timer(release_time, false).timeout
	_clear_awakening()

func _clear_awakening() -> void:
	_awakening_running = false
	if _awakening_light_tween and _awakening_light_tween.is_running():
		_awakening_light_tween.kill()
	if _awakening_body_tween and _awakening_body_tween.is_running():
		_awakening_body_tween.kill()
	if _awakening_light and is_instance_valid(_awakening_light):
		_awakening_light.queue_free()
	_awakening_light = null


func _update_climb_shake(delta: float) -> void:
	if not enable_climb_shakes or is_dead or phase < 2 or _awakening_running:
		_climb_hold_time = 0.0
		return
	_climb_shake_cooldown_left = maxf(0.0, _climb_shake_cooldown_left - delta)
	var player: Node = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player) or player.get("is_climbing") != true:
		_climb_hold_time = 0.0
		return
	if _climb_shaking:
		return
	_climb_hold_time += delta
	if _climb_hold_time >= climb_shake_after and _climb_shake_cooldown_left <= 0.0:
		_climb_hold_time = 0.0
		_climb_shake_cooldown_left = climb_shake_cooldown
		_execute_climb_shake(player)

func _execute_climb_shake(player: Node) -> void:
	if _climb_shaking or not is_instance_valid(player):
		return
	_climb_shaking = true
	if player.has_method("warn_colossus_shake"):
		player.warn_colossus_shake()
	# Señal física contenida en las piezas del prototipo.
	if is_instance_valid(_head):
		_gesture(_head, _base_head, Vector3(-14, 10, 0), Vector3.ZERO, climb_shake_warning * 0.65, climb_shake_warning * 0.35)
	await get_tree().create_timer(climb_shake_warning, false).timeout
	_climb_shaking = false
	if not is_instance_valid(player):
		return
	if is_dead or phase < 2:
		if player.has_method("cancel_colossus_shake_warning"):
			player.cancel_colossus_shake_warning()
		return
	if player.has_method("resolve_colossus_shake"):
		player.resolve_colossus_shake()

func _physics_process(delta: float) -> void:
	if debug_passive:
		# Detener también el movimiento de un ataque que había tomado el control.
		external_control = false
		velocity = Vector3.ZERO
		move_and_slide()
		return
	_update_climb_shake(delta)
	if is_dead:
		return
	if external_control:
		# Un ataque (p. ej. la embestida) controla el movimiento del coloso.
		velocity = Vector3.ZERO
		move_and_slide()
		return
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= gravity * delta
	# FASE 1: inmóvil, te ignora. FASE 2: no te sigue, se teletransporta.
	# FASE 3: por fin te persigue.
	if phase == 3 and not _interrupted():
		var player := get_tree().get_first_node_in_group("player") as Node3D
		if player:
			var to := player.global_position - global_position
			to.y = 0.0
			if to.length() > approach_range:
				velocity.x = to.normalized().x * approach_speed
				velocity.z = to.normalized().z * approach_speed
			else:
				velocity.x = move_toward(velocity.x, 0.0, approach_speed * 2.0)
				velocity.z = move_toward(velocity.z, 0.0, approach_speed * 2.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, approach_speed * 2.0)
		velocity.z = move_toward(velocity.z, 0.0, approach_speed * 2.0)
	move_and_slide()
	if phase == 3:
		_face_player(delta)

func _face_player(delta: float) -> void:
	if debug_passive or current_state == State.STAGGERED:
		return
	var player = get_tree().get_first_node_in_group("player") as Node3D
	if not player:
		return
	var to = player.global_position - global_position
	to.y = 0.0
	if to.length() < 0.2:
		return
	rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), turn_speed * delta)

func die() -> void:
	if is_dead:
		return
	is_dead = true
	var player: Node = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player) and player.has_method("cancel_colossus_shake_warning"):
		player.cancel_colossus_shake_warning()
	_cancel_attack_sequence()
	_clear_phase_feedback()
	_clear_attack_anticipation()
	_clear_awakening()
	current_state = State.DEAD
	attack_loop_running = false
	if climb_zone:
		climb_zone.monitoring = false
	_set_eyes_visible(false)
	Audio.stop_music()
	Audio.play_sfx("weak_break", -1.0)
	# Animación de disipación (usamos el pivote para no pelear con el scale de la malla).
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(body_pivot, "scale", Vector3.ZERO, 0.6)
	await tween.finished
	var hud = get_tree().get_first_node_in_group("hud")
	if not hud:
		hud = get_tree().get_first_node_in_group("HUD")
	if hud and hud.has_method("show_victory"):
		hud.show_victory()
	queue_free()
