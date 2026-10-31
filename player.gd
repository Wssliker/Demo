extends CharacterBody3D

@export_group("Movimiento Base")
@export var speed: float = 7.0
@export var jump_velocity: float = 5.0
@export var rotation_speed: float = 12.0
@export var max_player_health: int = 100
@export var player_health: int = 100
 
@export_group("Plataformas Avanzadas")
@export var max_jumps: int = 2               # Salto normal + Doble salto
@export var coyote_time_duration: float = 0.15 # Segundos para saltar tras dejar el suelo
@export var dash_speed: float = 22.0         # Velocidad durante el dash
@export var dash_duration: float = 0.2       # Duración del dash en segundos
@export var dash_cooldown: float = 0.8       # Tiempo de espera entre dashes

@export_group("Daño al cuerpo del coloso — Balance")
@export_range(1, 100, 1) var light_attack_one_damage: int = 8
@export_range(1, 100, 1) var light_attack_two_damage: int = 11
@export_range(1, 100, 1) var heavy_attack_damage: int = 20
@export_range(0.0, 0.5, 0.01) var climb_body_damage_factor: float = 0.12

@export_group("Golpes al cuerpo del jefe — Precisión")
@export var comprobar_cuerpo_visible: bool = true
@export_range(0.3, 3.0, 0.1) var margen_golpe_visible: float = 0.65

@export_group("Combate y Combos")
@export var combo_reset_time: float = 0.8

@export_group("Cámara")
@export var mouse_sensitivity: float = 0.003

@export_group("Sensación (Combat Feel)")
@export var jump_buffer_time: float = 0.12   # Buffer de input de salto
@export var air_control: float = 0.55        # Fracción de velocidad controlable en el aire
var jump_buffer_timer: float = 0.0

var wall_detector: RayCast3D
var grab_detector: Area3D
#Canara dubanuca
@export_group("Cámara Dinámica")
@export var default_fov: float = 75.0
@export var locked_fov: float = 84.0 # Más amplio para ver al jefe completo

@export_group("Camera Polish V1")
@export var camera_polish_enabled: bool = true
@export_range(2.0, 16.0, 0.5) var camera_turn_follow: float = 7.0
@export_range(1.0, 12.0, 0.5) var camera_pitch_follow: float = 5.0
@export_range(1.0, 12.0, 0.5) var camera_fov_follow: float = 4.0
@export_range(70.0, 100.0, 1.0) var climb_fov: float = 88.0
@export_range(70.0, 105.0, 1.0) var awakening_fov: float = 91.0
@export_range(1.0, 10.0, 0.5) var climb_look_height: float = 2.8
@export_range(1.0, 12.0, 0.5) var lock_look_height: float = 3.5
@export_range(3.0, 20.0, 0.5) var teleport_snap_distance: float = 12.0
@export_range(0.0, 1.0, 0.05) var climbing_target_weight: float = 0.65
var _camera_last_boss_position: Vector3 = Vector3.ZERO
var _camera_boss_position_ready: bool = false
var locked_target: Node3D = null
var lock_active: bool = false
var last_hit_source: String = ""
@onready var camera_3d: Camera3D = $CameraPivot/SpringArm3D/Camera3D# Ajusta la ruta si es diferente
@onready var camera_pivot: Node3D = $CameraPivot
@onready var visual_mesh: Node3D = $MeshInstance3D
@onready var attack_area: Area3D = $MeshInstance3D/AttackArea
@onready var hud: CanvasLayer = $HUD
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var ink_effect_scene: PackedScene # Asigna InkImpactEffect.tscn en el Inspector

#Escalada
@export_group("Escalada")
@export var climb_speed: float = 4.0
var is_climbing: bool = false
var current_climb_zone: Area3D = null

@export_group("Agarre (Shadow of the Colossus)")
@export var grip_max: float = 100.0      # Resistencia de agarre
@export var grip_drain_idle: float = 6.0 # Consumo por segundo al agarrarse quieto
@export var grip_drain_move: float = 15.0# Consumo extra al trepar
@export var grip_recover: float = 32.0   # Recuperación por segundo
@export var climb_stab_damage: int = 90   # Estocada pesada (golpe fuerte)
@export var climb_jab_damage: int = 25    # Estocada ligera
@export var climb_attack_range: float = 6.5  # El ojo superior debe ser alcanzable desde la espalda alta.
@export_range(0.0, 6.0, 0.1) var climb_surface_pull: float = 2.2
var grip: float = 100.0
var is_exhausted: bool = false

# ESCALADA V2 — Anclaje deliberado. Shift solo funciona como anclaje al escalar.
@export_group("Escalada V2 — Sacudida y Anclaje")
@export var enable_colossus_anchor: bool = true
@export_range(0.0, 30.0, 1.0) var anchor_cost_on_shake: float = 14.0
@export_range(0.0, 30.0, 1.0) var shake_grip_damage: float = 32.0
@export_range(0.1, 1.0, 0.05) var anchored_climb_speed_factor: float = 0.4
@export_range(0.0, 25.0, 0.5) var anchor_drain_per_second: float = 8.0
@export_range(0.0, 2.0, 0.05) var anchor_prepare_time: float = 0.25
@export_range(0.0, 30.0, 1.0) var prepared_anchor_shake_cost: float = 8.0
var _anchor_held_time: float = 0.0
var _shake_warning_active: bool = false
var _shake_hint_layer: CanvasLayer = null
var _shake_hint: Label = null
# Variables de estado de movimiento
var jumps_left: int = 0
var coyote_timer: float = 0.0
var is_dashing: bool = false
var can_dash: bool = true
var dash_direction: Vector3 = Vector3.ZERO
var debug_invulnerable: bool = false # Depuración: inmortalidad independiente del dash
var is_invulnerable: bool = false
var dash_start_time: int = 0
# Variables de combate
var combo_step: int = 0
var is_attacking: bool = false
var current_attack_damage: int = 10
var combo_timer: SceneTreeTimer = null
var is_stunned: bool = false 

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	attack_area.monitoring = false
	add_to_group("player")
	# El autoload vuelve a aplicar ajustes al entrar/reiniciar la arena.
	get_node("/root/Debug").apply_saved_to(self, "player")
	grip = grip_max
	_build_shake_hint()
	#HUD
	if hud and hud.has_method("setup_hud"):
		hud.setup_hud(player_health)
	locked_target = get_tree().get_first_node_in_group("boss")
	# Detector interno para saber si estamos tocando un coloso
	grab_detector = Area3D.new()
	var collision = CollisionShape3D.new()
	collision.shape = CapsuleShape3D.new() 
	collision.shape.radius = 0.6 # Un poco más ancho que el jugador
	grab_detector.add_child(collision)
	grab_detector.monitoring = true
	add_child(grab_detector)
	
	grab_detector.area_entered.connect(_on_grab_area_entered)
	grab_detector.area_exited.connect(_on_grab_area_exited)
	# Creamos el detector de paredes sólidas
	wall_detector = RayCast3D.new()
	wall_detector.target_position = Vector3(0, 0, -1.5) # Apunta hacia adelante
	add_child(wall_detector)
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Con lock-on activo el giro horizontal lo controla el objetivo, no el ratón.
		if not lock_active:
			rotate_y(-event.relative.x * mouse_sensitivity)
		camera_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg_to_rad(-60), deg_to_rad(30))

	if event.is_action_pressed("lock_on"):
		toggle_lock()

	# Ataques (diferentes si estamos trepando al coloso)
	if not is_attacking:
		if is_climbing:
			if event.is_action_pressed("attack_light"):
				climb_attack(false)
			elif event.is_action_pressed("attack_heavy"):
				climb_attack(true)
		elif event.is_action_pressed("attack_light"):
			execute_combo_attack("light")
		elif event.is_action_pressed("attack_heavy"):
			execute_combo_attack("heavy")

func _physics_process(delta: float) -> void:
	# --- LÓGICA DE AGARRE Y ESCALADA (SHADOW OF THE COLOSSUS) ---
	_refresh_climb_zone()
	var wants_climb := Input.is_action_pressed("grab") or Input.is_action_pressed("interact")
	if is_instance_valid(current_climb_zone) and wants_climb and not is_exhausted and not is_stunned and not is_dashing:
		is_climbing = true
	else:
		is_climbing = false
	
	if not is_climbing and _shake_warning_active:
		cancel_colossus_shake_warning()
	# Shift se consulta por la acción del proyecto, no por el código físico de una tecla.
	var anchoring: bool = is_climbing and enable_colossus_anchor and Input.is_action_pressed("dash")
	if anchoring:
		_anchor_held_time += delta
	else:
		_anchor_held_time = 0.0
	if is_climbing:
		velocity.y = 0.0 # Anulamos la gravedad
		var input_dir := Input.get_vector("ui_left", "ui_right", "ui_down", "ui_up")
		
		# La zona escalable solo autoriza el agarre. La normal viene del CUERPO,
		# no de un ojo ni de un rayo que puede perder contacto en la espalda.
		var wall_normal: Vector3 = _boss_climb_normal()
		# Proyectar ARRIBA sobre la tangente evita quedarse bloqueado en la
		# curvatura de hombros y parte alta de la espalda.
		var climb_up: Vector3 = Vector3.UP.slide(wall_normal).normalized()
		if climb_up.length_squared() < 0.01:
			climb_up = Vector3.UP
		var climb_right: Vector3 = climb_up.cross(wall_normal).normalized()
		var move_dir: Vector3 = climb_right * input_dir.x + climb_up * input_dir.y
		var effective_climb_speed: float = climb_speed * (anchored_climb_speed_factor if anchoring else 1.0)
		# Adherencia suave hacia el volumen real del coloso, no al ojo.
		velocity = move_dir * effective_climb_speed - wall_normal * climb_surface_pull
		var target_rot_global: float = atan2(wall_normal.x, wall_normal.z) + PI
		visual_mesh.global_rotation.y = lerp_angle(visual_mesh.global_rotation.y, target_rot_global, 15.0 * delta)
		# 6. Resistencia de agarre: se agota y nos sacude el coloso.
		var drain: float = grip_drain_move if input_dir.length() > 0.1 else grip_drain_idle
		if anchoring:
			drain += anchor_drain_per_second
		grip = maxf(0.0, grip - drain * delta)
		if grip <= 0.0:
			_buck_off(14.0, 8)
	else:
		# Recuperamos resistencia (más rápido pisando firme).
		var rate := grip_recover * (1.5 if is_on_floor() else 1.0)
		grip = minf(grip_max, grip + rate * delta)
		if grip > grip_max * 0.35:
			is_exhausted = false

	_update_anchor_feedback(anchoring)
	if hud and hud.has_method("set_climbing"):
		hud.set_climbing(is_climbing)
	if hud and hud.has_method("update_grip"):
		hud.update_grip(grip, grip_max)

	# Salto hacia atrás para huir de la sacudida.
	if is_climbing and Input.is_action_just_pressed("ui_accept"):
		force_detach(10.0, 0)
		return
	if is_climbing:
		_update_lock_camera(delta)
		move_and_slide()
		return
	# --- MANEJO DE COYOTE TIME Y RESET DE JUMPS ---
	if is_on_floor():
		coyote_timer = coyote_time_duration
		jumps_left = max_jumps
	elif not is_climbing:
		coyote_timer -= delta
		velocity.y -= gravity * delta

	# --- MANEJO DEL DASH ---
	if not is_climbing and Input.is_action_just_pressed("dash") and can_dash and not is_dashing:
		start_dash()

	if is_dashing:
		# Durante el dash el jugador se desplaza en línea recta sin gravedad
		velocity.x = dash_direction.x * dash_speed
		velocity.z = dash_direction.z * dash_speed
		velocity.y = 0.0
		move_and_slide()
		return # Saltamos el resto de física mientras dure el dash

	# --- MANEJO DEL SALTO / DOBLE SALTO (con input buffering) ---
	if not is_climbing and Input.is_action_just_pressed("ui_accept"):
		jump_buffer_timer = jump_buffer_time
	jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)
	if jump_buffer_timer > 0.0 and not is_climbing:
		if is_on_floor() or coyote_timer > 0.0:
			perform_jump()
			jump_buffer_timer = 0.0
		elif jumps_left > 1: # Doble salto en el aire
			perform_jump()
			jump_buffer_timer = 0.0

	# --- DESPLAZAMIENTO REGULAR ---
	if not is_stunned and not is_climbing:
		var move_speed = speed * 0.3 if (is_attacking and combo_step == 3) else speed
		if not is_on_floor():
			move_speed *= air_control
		var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

		if direction:
			velocity.x = direction.x * move_speed
			velocity.z = direction.z * move_speed
			
			var target_rotation = atan2(-direction.x, -direction.z)
			visual_mesh.rotation.y = lerp_angle(visual_mesh.rotation.y, target_rotation, rotation_speed * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)
	# --- CÁMARA DINÁMICA (SHADOW OF THE COLOSSUS / SOULS STYLE) ---
	_update_lock_camera(delta)
	move_and_slide()

func _camera_smooth(rate: float, delta: float) -> float:
	# Amortiguación independiente del número de FPS.
	return 1.0 - exp(-maxf(rate, 0.01) * delta)

func _camera_weak_point_position() -> Vector3:
	# Solo se usa para orientar la cámara; no altera el targeting ni el daño.
	var best := Vector3.ZERO
	var best_dist := INF
	for node in get_tree().get_nodes_in_group("weak_point"):
		if not (node is Node3D) or not is_instance_valid(node):
			continue
		if node.is_in_group("broken_eye"):
			continue
		if node.has_method("is_broken") and node.is_broken():
			continue
		var d := global_position.distance_squared_to(node.global_position)
		if d < best_dist:
			best_dist = d
			best = node.global_position
	return best if best_dist < INF else Vector3.ZERO

func _update_lock_camera(delta: float) -> void:
	if not camera_polish_enabled:
		# Sin el pulido, conservar la perspectiva manual y el FOV por defecto.
		camera_3d.fov = lerpf(camera_3d.fov, default_fov, _camera_smooth(3.0, delta))
		return

	if not is_instance_valid(locked_target):
		locked_target = get_tree().get_first_node_in_group("boss")
	if not is_instance_valid(locked_target):
		lock_active = false
		_camera_boss_position_ready = false
		camera_3d.fov = lerpf(camera_3d.fov, default_fov, _camera_smooth(camera_fov_follow, delta))
		return

	var boss_pos: Vector3 = locked_target.global_position
	var distance_to_boss: float = global_position.distance_to(boss_pos)
	var phase_value: Variant = locked_target.get("phase")
	var boss_phase: int = int(phase_value) if phase_value != null else 1
	var awakening_value: Variant = locked_target.get("_awakening_running")
	var awakening: bool = awakening_value == true and boss_phase == 3

	# Tras un teletransporte se sigue la NUEVA posición sin interpolar el desplazamiento.
	# La rotación sigue amortiguada para evitar un giro instantáneo de cámara.
	if _camera_boss_position_ready and boss_pos.distance_to(_camera_last_boss_position) > teleport_snap_distance:
		_camera_boss_position_ready = false
	_camera_last_boss_position = boss_pos
	_camera_boss_position_ready = true

	var desired_fov: float = default_fov
	if lock_active:
		desired_fov = locked_fov
	if is_climbing and lock_active:
		desired_fov = climb_fov
	if awakening and lock_active:
		desired_fov = awakening_fov
	camera_3d.fov = lerpf(camera_3d.fov, desired_fov, _camera_smooth(camera_fov_follow, delta))

	if lock_active:
		var aim_pos: Vector3 = boss_pos + Vector3.UP * lock_look_height
		if awakening:
			aim_pos = boss_pos + Vector3.UP * (lock_look_height + 2.0)

		var to_target: Vector3 = aim_pos - (global_position + Vector3.UP * 1.5)
		var flat: Vector3 = Vector3(to_target.x, 0.0, to_target.z)
		if flat.length_squared() > 0.01:
			var desired_yaw: float = atan2(-flat.x, -flat.z)
			rotation.y = lerp_angle(rotation.y, desired_yaw, _camera_smooth(camera_turn_follow, delta))
			var desired_pitch: float = atan2(to_target.y, flat.length())
			camera_pivot.rotation.x = lerp_angle(camera_pivot.rotation.x, clampf(desired_pitch, deg_to_rad(-55), deg_to_rad(30)), _camera_smooth(camera_pitch_follow, delta))
	elif is_attacking and combo_step > 0:
		var look_dir: Vector3 = boss_pos - global_position
		look_dir.y = 0.0
		if look_dir.length_squared() > 0.01:
			var desired_visual_yaw: float = atan2(-look_dir.x, -look_dir.z)
			visual_mesh.rotation.y = lerp_angle(visual_mesh.rotation.y, desired_visual_yaw, _camera_smooth(rotation_speed * 2.0, delta))

func toggle_lock() -> void:
	lock_active = not lock_active
	if lock_active:
		if locked_target == null or not is_instance_valid(locked_target):
			locked_target = get_tree().get_first_node_in_group("boss")
		Audio.play_sfx("ui", -6.0, 1.3)
	else:
		Audio.play_sfx("ui", -9.0, 0.9)

func _do_camera_shake(intensity: float, duration: float) -> void:
	var t := create_tween()
	t.tween_method(func(_v):
		camera_3d.h_offset = randf_range(-intensity, intensity) * 0.05
		camera_3d.v_offset = randf_range(-intensity, intensity) * 0.05
	, 0.0, 1.0, duration)
	t.tween_callback(func():
		camera_3d.h_offset = 0.0
		camera_3d.v_offset = 0.0)

# --- LÓGICA DE SALTO Y DASH ---

func perform_jump() -> void:
	velocity.y = jump_velocity
	jumps_left -= 1
	coyote_timer = 0.0 # Consumir el coyote time al saltar
	
	# Efecto de escala al saltar (aplastamiento suave)
	var tween = create_tween()
	tween.tween_property(visual_mesh, "scale", Vector3(0.8, 1.25, 0.8), 0.08)
	tween.tween_property(visual_mesh, "scale", Vector3.ONE, 0.1)


func start_dash() -> void:
	is_dashing = true
	can_dash = false
	is_invulnerable = true
	dash_start_time = Time.get_ticks_msec()
	Audio.play_sfx("dash", -3.0)
	# Instanciar ráfaga de tinta al iniciar el dash
	spawn_ink_particles(global_position + Vector3(0, 0.5, 0))

	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var move_dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if move_dir != Vector3.ZERO:
		dash_direction = move_dir
	else:
		dash_direction = -visual_mesh.global_transform.basis.z.normalized()

	var tween = create_tween()
	tween.tween_property(visual_mesh, "scale", Vector3(0.6, 0.6, 1.5), 0.05)

	_trail_dash()

	await get_tree().create_timer(dash_duration).timeout
	is_dashing = false
	is_invulnerable = false
	create_tween().tween_property(visual_mesh, "scale", Vector3.ONE, 0.1)

	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true

func spawn_ink_particles(pos: Vector3) -> void:
	if ink_effect_scene:
		var effect = ink_effect_scene.instantiate()
		get_parent().add_child(effect)
		effect.global_position = pos

## Estela del dash: deja copias translúcidas del mesh que se desvanecen.
func _trail_dash() -> void:
	for i in 3:
		_spawn_dash_afterimage()
		await get_tree().create_timer(0.05).timeout

func _spawn_dash_afterimage() -> void:
	var src: MeshInstance3D = null
	if visual_mesh is MeshInstance3D:
		src = visual_mesh as MeshInstance3D
	else:
		for c in visual_mesh.get_children():
			if c is MeshInstance3D:
				src = c as MeshInstance3D
				break
	if src == null or src.mesh == null:
		return
	var ghost := MeshInstance3D.new()
	ghost.mesh = src.mesh
	ghost.global_transform = src.global_transform
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = Color(0.55, 0.68, 1.0, 0.4)
	mat.disable_receive_shadows = true
	ghost.material_override = mat
	ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_parent().add_child(ghost)
	var t := create_tween()
	t.tween_property(ghost, "transparency", 1.0, 0.28)
	t.tween_callback(ghost.queue_free)

# --- LÓGICA DE COMBOS Y COMBATE ---

func execute_combo_attack(type: String) -> void:
	is_attacking = true
	Audio.play_sfx("heavy_swing" if type == "heavy" else "swing", -3.0)
	if type == "heavy":
		combo_step = 3
	else:
		combo_step += 1

	if combo_step > 3:
		combo_step = 1

	if hud and hud.has_method("update_combo"):
		hud.update_combo(combo_step)

	var attack_duration: float = 0.3
	match combo_step:
		1:
			current_attack_damage = light_attack_one_damage
			attack_duration = 0.25
			animate_attack(Vector3(0, deg_to_rad(-30), 0), Vector3(1.1, 0.9, 1.1))
		2:
			current_attack_damage = light_attack_two_damage
			attack_duration = 0.25
			animate_attack(Vector3(0, deg_to_rad(30), 0), Vector3(0.9, 1.1, 0.9))
		3:
			current_attack_damage = heavy_attack_damage
			attack_duration = 0.4
			velocity += -transform.basis.z * 6.0
			move_and_slide() # Aplicar el empuje del golpe pesado
			animate_attack(Vector3(deg_to_rad(-25), 0, 0), Vector3(1.4, 0.7, 1.4))

	attack_area.monitoring = true
	await get_tree().create_timer(attack_duration * 0.7).timeout
	attack_area.monitoring = false
	await get_tree().create_timer(attack_duration * 0.3).timeout
	
	is_attacking = false
	restart_combo_timer()

func animate_attack(target_rotation: Vector3, target_scale: Vector3) -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(visual_mesh, "rotation", target_rotation, 0.08)
	tween.tween_property(visual_mesh, "scale", target_scale, 0.08)
	
	var reset_tween = create_tween().set_parallel(true)
	reset_tween.chain().tween_property(visual_mesh, "rotation", Vector3.ZERO, 0.12)
	reset_tween.chain().tween_property(visual_mesh, "scale", Vector3.ONE, 0.12)

func restart_combo_timer() -> void:
	if combo_timer:
		combo_timer = null

	if combo_step >= 3:
		reset_combo()
		return

	combo_timer = get_tree().create_timer(combo_reset_time)
	await combo_timer.timeout
	
	if not is_attacking:
		reset_combo()

func reset_combo() -> void:
	combo_step = 0
	if hud and hud.has_method("update_combo"):
		hud.update_combo(0)
# La colisión física del coloso se conserva para no alterar la escalada.
# Esta prueba adicional solo determina si un golpe corporal conecta visualmente.
# Calcula distancia a la SUPERFICIE de mallas esfericas y capsulas.
# A diferencia de un AABB, no incluye el espacio vacio de su caja envolvente.
# Tambien evita considerar un punto muy adentro de una malla gigante como un impacto.
func _distancia_superficie_malla(parte: MeshInstance3D, punto_mundo: Vector3) -> float:
	var mesh: Mesh = parte.mesh
	var punto: Vector3 = parte.to_local(punto_mundo)
	var superficie_local: Vector3
	if mesh is SphereMesh:
		var esfera: SphereMesh = mesh as SphereMesh
		var radio_xz: float = maxf(esfera.radius, 0.001)
		var radio_y: float = maxf(esfera.height * 0.5, 0.001)
		var direccion: Vector3 = Vector3(
			punto.x / radio_xz,
			punto.y / radio_y,
			punto.z / radio_xz
		)
		if direccion.length_squared() < 0.000001:
			# Centro de una malla: no es su superficie.
			return radio_xz * parte.global_basis.x.length()
		var factor: float = 1.0 / direccion.length()
		superficie_local = punto * factor
	elif mesh is CapsuleMesh:
		var capsula: CapsuleMesh = mesh as CapsuleMesh
		var radio: float = maxf(capsula.radius, 0.001)
		var semieje: float = maxf(0.0, capsula.height * 0.5 - radio)
		var eje: Vector3 = Vector3(0.0, clampf(punto.y, -semieje, semieje), 0.0)
		var vector_radial: Vector3 = punto - eje
		if vector_radial.length_squared() < 0.000001:
			vector_radial = Vector3.RIGHT
		superficie_local = eje + vector_radial.normalized() * radio
	else:
		# Solo comprobamos las primitivas utilizadas en el jefe provisional.
		# Otras mallas pueden integrarse mas adelante con hitboxes dedicadas.
		return INF
	return punto_mundo.distance_to(parte.to_global(superficie_local))

func _golpe_alcanza_cuerpo_visible(boss: Node3D) -> bool:
	if not comprobar_cuerpo_visible:
		return true
	if not is_instance_valid(attack_area):
		return false
	# El area de ataque representa el contacto. No usamos la posicion del
	# centro del boss, porque su cuerpo enorme incluye espacios vacios debajo.
	var centro_golpe: Vector3 = attack_area.global_position
	var partes: Array[String] = [
		"BodyPivot/MeshInstance3D", "BodyPivot/Base", "BodyPivot/Head",
		"BodyPivot/Hump", "BodyPivot/Arm_L", "BodyPivot/Arm_R",
		"BodyPivot/Hand_L", "BodyPivot/Hand_R",
		"BodyPivot/Leg_L", "BodyPivot/Leg_R"
	]
	var mallas_encontradas: int = 0
	for ruta: String in partes:
		var parte: MeshInstance3D = boss.get_node_or_null(ruta) as MeshInstance3D
		if not is_instance_valid(parte) or parte.mesh == null or not parte.is_visible_in_tree():
			continue
		mallas_encontradas += 1
		if _distancia_superficie_malla(parte, centro_golpe) <= margen_golpe_visible:
			return true
	# Si los meshes de este provisional han sido reemplazados por un modelo
	# definitivo, no bloquear silenciosamente TODOS los golpes.
	return mallas_encontradas == 0

func _on_attack_area_body_entered(body: Node3D) -> void:
	if body == self:
		return
	# El cuerpo físico es más grande que ciertas partes visibles del coloso.
	# No alteramos la física, solo evitamos golpes sobre espacios vacíos.
	if body.is_in_group("boss") and not _golpe_alcanza_cuerpo_visible(body):
		return
		
	if body.has_method("take_damage"):
		body.take_damage(current_attack_damage)
		
		# Feedback sonoro del impacto (más grave en el combo pesado).
		Audio.play_sfx("heavy_hit" if combo_step == 3 else "hit", 0.0)
		
		# Crear impacto de tinta en la posición del objetivo
		spawn_ink_particles(body.global_position + Vector3(0, 1.0, 0))
		
		# GAME FEEL: Micro-pausa al impactar
		if combo_step == 3:
			# El golpe pesado congela la pantalla más tiempo, dándole un peso brutal
			do_hit_stop(0.15) 
		else:
			# Los golpes ligeros solo tienen un pequeño "enganche"
			do_hit_stop(0.05)
func take_damage(amount: int, source: String = "") -> void:
	if debug_invulnerable:
		return
	if is_invulnerable:
		# Calculamos cuántos segundos han pasado desde que apretaste el botón de dash
		var elapsed_time = (Time.get_ticks_msec() - dash_start_time) / 1000.0
		
		# Si el ataque te toca en los primeros 0.1 segundos (reflejos perfectos)
		if elapsed_time <= 0.1:
			trigger_perfect_dodge()
		return # El ataque te atraviesa de todos modos
		
	last_hit_source = source
	player_health -= amount
	player_health = max(player_health, 0)
	if hud and hud.has_method("pop_damage"):
		hud.pop_damage(amount, global_position + Vector3(0, 2.0, 0), Color(1.0, 0.32, 0.32))
	if hud and hud.has_method("register_player_damage"):
		hud.register_player_damage(amount)
	if hud and hud.has_method("show_combat_notice"):
		hud.show_combat_notice("IMPACTO RECIBIDO", Color(1.0, 0.61, 0.62))
	
	# Juice: sonido, sacudida de cámara y destello rojo.
	Audio.play_sfx("hurt", -2.0)
	_do_camera_shake(0.8, 0.25)
	if hud and hud.has_method("flash"):
		hud.flash(Color(0.85, 0.08, 0.12, 0.35), 0.25)
	
	if hud and hud.has_method("update_health"):
		hud.update_health(player_health)
		
	var tween = create_tween()
	tween.tween_property(visual_mesh, "scale", Vector3(0.8, 0.8, 0.8), 0.05)
	tween.tween_property(visual_mesh, "scale", Vector3.ONE, 0.1)

	if player_health <= 0:
		set_physics_process(false)
		set_process_unhandled_input(false)
		if hud and hud.has_method("show_defeat"):
			hud.show_defeat(source)

func trigger_perfect_dodge() -> void:
	# 1. Sonido, flash blanco y sacudida para que el jugador SEPA que fue perfecto.
	Audio.play_sfx("parry", -1.0)
	if hud and hud.has_method("show_combat_notice"):
		hud.show_combat_notice("ESQUIVA PERFECTA", Color(0.66, 0.82, 1.0))
	if hud and hud.has_method("flash"):
		hud.flash(Color(1.0, 1.0, 1.0, 0.5), 0.15)
	_do_camera_shake(1.2, 0.2)
	# 2. Congelar el tiempo para dar feedback de impacto brutal
	Engine.time_scale = 0.05
	await get_tree().create_timer(0.01, false, false, true).timeout
	Engine.time_scale = 1.0
	
	# 2. Recompensa visual (Flash estético)
	var tween = create_tween()
	tween.tween_property(visual_mesh, "scale", Vector3(1.5, 1.5, 1.5), 0.05)
	tween.tween_property(visual_mesh, "scale", Vector3.ONE, 0.1)
	
	# 3. Recompensa mecánica (Ejemplo: Curar 5 puntos de vida o resetear el cooldown del dash)
	player_health += 5
	player_health = min(player_health, max_player_health)
	if hud and hud.has_method("update_health"):
		hud.update_health(player_health)

func do_hit_stop(duration: float) -> void:
	Engine.time_scale = 0.05
	# Usamos el flag 'true' al final para que el timer ignore el time_scale y no se quede pegado
	await get_tree().create_timer(duration * 0.05, false, false, true).timeout
	Engine.time_scale = 1.0


## El aviso se dibuja fuera del HUD y nunca secuestra cámara o controles.
func _build_shake_hint() -> void:
	_shake_hint_layer = CanvasLayer.new()
	_shake_hint_layer.name = "AvisoSacudida"
	_shake_hint_layer.layer = 21
	add_child(_shake_hint_layer)
	_shake_hint = Label.new()
	_shake_hint.name = "TextoAnclaje"
	_shake_hint.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_shake_hint.position = Vector2(-230.0, 130.0)
	_shake_hint.custom_minimum_size = Vector2(460.0, 55.0)
	_shake_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_shake_hint.add_theme_font_size_override("font_size", 21)
	_shake_hint.add_theme_color_override("font_color", Color(1.0, 0.77, 0.62))
	_shake_hint.add_theme_color_override("font_shadow_color", Color(0.02, 0.02, 0.06, 0.9))
	_shake_hint.add_theme_constant_override("shadow_offset_x", 2)
	_shake_hint.add_theme_constant_override("shadow_offset_y", 2)
	_shake_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shake_hint.visible = false
	_shake_hint_layer.add_child(_shake_hint)

func _update_anchor_feedback(anchoring: bool) -> void:
	if not is_instance_valid(_shake_hint) or _shake_warning_active:
		return
	if anchoring:
		_shake_hint.text = "ANCLAJE PREPARADO" if _anchor_held_time >= anchor_prepare_time else "PREPARANDO ANCLAJE"
		_shake_hint.visible = true
	elif _shake_hint.text == "ANCLAJE PREPARADO" or _shake_hint.text == "PREPARANDO ANCLAJE":
		_shake_hint.visible = false

func warn_colossus_shake() -> void:
	if not is_climbing:
		return
	_shake_warning_active = true
	if is_instance_valid(_shake_hint):
		_shake_hint.text = "¡SACUDIDA!  MANTÉN SHIFT PARA ANCLARTE"
		_shake_hint.visible = true

func cancel_colossus_shake_warning() -> void:
	_shake_warning_active = false
	if is_instance_valid(_shake_hint):
		_shake_hint.visible = false

## Invocado por el coloso al terminar su aviso. No concede invulnerabilidad.
func resolve_colossus_shake() -> void:
	cancel_colossus_shake_warning()
	if not is_climbing:
		return
	var holding_anchor: bool = enable_colossus_anchor and Input.is_action_pressed("dash")
	var prepared: bool = _anchor_held_time >= anchor_prepare_time
	var shake_cost: float = prepared_anchor_shake_cost if prepared else anchor_cost_on_shake
	var anchored: bool = holding_anchor and grip >= shake_cost
	if anchored:
		grip = maxf(0.0, grip - shake_cost)
		_do_camera_shake(0.7, 0.16)
		if is_instance_valid(_shake_hint):
			_shake_hint.text = "ANCLAJE RESISTIDO"
			_shake_hint.visible = true
			get_tree().create_timer(0.6).timeout.connect(func() -> void:
				if is_instance_valid(_shake_hint) and not _shake_warning_active:
					_shake_hint.visible = false
			)
	else:
		apply_climb_shake(shake_grip_damage)

func _boss_climb_normal() -> Vector3:
	# El cuerpo tiene una cápsula sólida centrada en la raíz del jefe.
	# Aproximamos el eje de esa cápsula para escalar correctamente también
	# en la zona curva de los hombros, incluso si el raycast deja de chocar.
	var boss: Node3D = get_tree().get_first_node_in_group("boss") as Node3D
	if boss == null:
		return -global_transform.basis.z.normalized()
	var axis_point: Vector3 = boss.global_position
	# El collider actual es una cápsula de 12.2 unidades de escala;
	# 6.1 es el semilargo de su tramo central aproximado.
	axis_point.y += clampf(global_position.y - boss.global_position.y, -6.1, 6.1)
	var out: Vector3 = global_position - axis_point
	if out.length_squared() < 0.01:
		out = global_position - boss.global_position
	if out.length_squared() < 0.01:
		out = -global_transform.basis.z
	return out.normalized()

func _refresh_climb_zone() -> void:
	# Recupera la zona tras una expulsión o un cambio de Area3D.
	# Al desprenderse, la señal area_entered NO vuelve a dispararse
	# si el detector continúa solapando la zona.
	if is_instance_valid(current_climb_zone) and current_climb_zone.monitoring and current_climb_zone.is_in_group("climbable"):
		return
	current_climb_zone = null
	if not is_instance_valid(grab_detector):
		return
	for area in grab_detector.get_overlapping_areas():
		if is_instance_valid(area) and area.monitoring and area.is_in_group("climbable"):
			current_climb_zone = area
			return

func _on_grab_area_entered(area: Area3D) -> void:
	if area.is_in_group("climbable") and area.monitoring:
		current_climb_zone = area
		print("ZONA ESCALABLE DETECTADA - mantén [E] o [Q]")

func _on_grab_area_exited(area: Area3D) -> void:
	if area == current_climb_zone:
		current_climb_zone = null
		is_climbing = false
		
func force_detach(knockback_strength: float, damage: int) -> void:
	cancel_colossus_shake_warning()
	if not is_climbing:
		return
		
	is_climbing = false
	is_stunned = true # Perder el control brevemente
	
	if damage > 0:
		take_damage(damage, "Coloso")
	
	# Calculamos el empuje hacia atrás y hacia arriba
	var knockback_dir = transform.basis.z.normalized()
	velocity = knockback_dir * knockback_strength
	velocity.y = knockback_strength * 0.5 
	
	do_hit_stop(0.1)
	
	# Te devolvemos el control después de medio segundo de volar por los aires
	await get_tree().create_timer(0.5).timeout
	is_stunned = false

## El coloso nos arroja: quedamos agotados y no podemos volver a agarrarnos de inmediato.
func _buck_off(knockback_strength: float, damage: int) -> void:
	is_exhausted = true
	force_detach(knockback_strength, damage)

## Sacudida del coloso mientras lo trepamos: consume agarre y puede arrojarnos.
func apply_climb_shake(grip_damage: float) -> void:
	if not is_climbing:
		return
	grip = maxf(0.0, grip - grip_damage)
	_do_camera_shake(2.2, 0.35)
	if hud and hud.has_method("update_grip"):
		hud.update_grip(grip, grip_max)
	if grip <= 0.0:
		_buck_off(18.0, 12)

## Estocada al coloso mientras estamos agarrados. Busca un punto débil cercano.
func climb_attack(heavy: bool) -> void:
	if is_attacking:
		return
	is_attacking = true
	# Atacar también exige fuerza en las manos.
	grip = maxf(0.0, grip - (12.0 if heavy else 4.0))
	Audio.play_sfx("heavy_swing" if heavy else "swing", -1.0)
	var dmg: int = climb_stab_damage if heavy else climb_jab_damage
	var wp := _nearest_weak_point(climb_attack_range)
	if wp != null and wp.has_method("take_damage"):
		wp.take_damage(dmg)
		Audio.play_sfx("heavy_hit" if heavy else "hit", 0.0)
		spawn_ink_particles(wp.global_position)
		_do_camera_shake(1.6 if heavy else 0.8, 0.25)
	else:
		var boss := get_tree().get_first_node_in_group("boss")
		if boss and boss.has_method("take_damage"):
			boss.take_damage(int(dmg * climb_body_damage_factor))
			Audio.play_sfx("hit", -3.0)
	var t := create_tween()
	t.tween_property(visual_mesh, "scale", Vector3(0.7, 1.45, 0.7), 0.08)
	t.tween_property(visual_mesh, "scale", Vector3.ONE, 0.16)
	await get_tree().create_timer(0.32, false).timeout
	is_attacking = false

func _nearest_weak_point(radius: float) -> Node3D:
	var best: Node3D = null
	var best_d := radius
	for wp in get_tree().get_nodes_in_group("weak_point"):
		if not is_instance_valid(wp) or wp.is_queued_for_deletion():
			continue
		if not wp.visible or wp.get("is_broken") == true:
			continue
		var d: float = global_position.distance_to(wp.global_position)
		if d < best_d:
			best_d = d
			best = wp
	return best
