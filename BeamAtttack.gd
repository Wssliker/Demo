extends Node3D
## Alpha 0.2: rayo con trayectoria bloqueada, tiempo de reacción y limpieza segura.
## No cambia la vida, el daño ni la lógica de las fases.

const BEAM_WARNING_LINE: PackedScene = preload("res://scenes/beam_warning_line.tscn")
const BEAM_CHARGE_CORE: PackedScene = preload("res://scenes/beam_charge_core.tscn")

@onready var beam_mesh: MeshInstance3D = $LaserBeam
@onready var boss: Node3D = get_parent().get_parent() as Node3D
@onready var beam_source: Node3D = null

@export var damage: int = 25
@export var warning_time: float = 3.6
@export var firing_time: float = 1.6
@export var beam_radius: float = 0.9

@export_group("Origen y apariencia del rayo")
@export var use_head_as_beam_source: bool = true
@export_range(0.0, 3.0, 0.05) var source_forward_offset: float = 0.85
@export_range(-1.0, 2.0, 0.05) var source_vertical_offset: float = 0.15

@export_group("Lectura y precisión del rayo")
@export_range(0.05, 1.0, 0.01) var final_lock_time: float = 0.22
@export_range(0.0, 1.5, 0.01) var movement_prediction_time: float = 0.0
@export_range(0.0, 8.0, 0.1) var max_prediction_distance: float = 5.5
@export_group("Recursos visuales del rayo")
@export var show_charge_core: bool = true
@export var show_warning_line: bool = true
@export_range(0.2, 2.0, 0.05) var charge_core_scale: float = 0.9
@export_range(0.5, 4.0, 0.05) var warning_line_width: float = 1.2
@export_group("Comportamiento del disparo")
@export var beam_tracks_player_while_firing: bool = true
@export_range(0.0, 0.5, 0.01) var prefire_hold_time: float = 0.14
# Fragmentos pequeños decorativos de V1, reemplazados por coberturas sólidas.
const COVER_COLLISION_BIT: int = 1 << 15

@export_group("Cobertura contra el rayo")
@export var enable_stone_cover: bool = true
@export_range(1, 6, 1) var cover_count: int = 5
# Posiciones FIJAS en el sistema global de la arena. No dependen del jugador.
# El suelo jugable tiene un radio aproximado de 30 unidades.
const COVER_POINTS: Array[Vector2] = [
	Vector2(-8.0, 9.0),
	Vector2(8.0, 11.0),
	Vector2(0.0, 2.0),
	Vector2(-12.0, -4.0),
	Vector2(11.0, -7.0),
	Vector2(2.0, -15.0)
]
@export_range(3.0, 12.0, 0.5) var cover_height: float = 7.0
@export_range(1.0, 5.0, 0.25) var cover_width: float = 2.7
@export_range(0.5, 4.0, 0.25) var cover_depth: float = 1.8

var _active: bool = false
var _shot_serial: int = 0
var _cover_root: Node3D
var _beam_material: ShaderMaterial
var _beam_cylinder: CylinderMesh
var _inner_mesh: MeshInstance3D
var _inner_cylinder: CylinderMesh
var _inner_material: ShaderMaterial
var _warning_line: Node3D
var _charge_core: Node3D

func _ready() -> void:
	beam_mesh.visible = false
	_inner_mesh = get_node_or_null("LaserBeam/InnerCore") as MeshInstance3D
	_beam_material = beam_mesh.material_override.duplicate() as ShaderMaterial if beam_mesh.material_override is ShaderMaterial else null
	if _beam_material != null:
		beam_mesh.material_override = _beam_material
	if beam_mesh.mesh is CylinderMesh:
		_beam_cylinder = (beam_mesh.mesh as CylinderMesh).duplicate() as CylinderMesh
		beam_mesh.mesh = _beam_cylinder
	if is_instance_valid(_inner_mesh):
		_inner_material = _inner_mesh.material_override.duplicate() as ShaderMaterial if _inner_mesh.material_override is ShaderMaterial else null
		if _inner_material != null:
			_inner_mesh.material_override = _inner_material
		if _inner_mesh.mesh is CylinderMesh:
			_inner_cylinder = (_inner_mesh.mesh as CylinderMesh).duplicate() as CylinderMesh
			_inner_mesh.mesh = _inner_cylinder
	_prepare_material()
	_resolve_beam_source()

func _exit_tree() -> void:
	_shot_serial += 1
	_cleanup()

func _resolve_beam_source() -> void:
	beam_source = null
	if not is_instance_valid(boss):
		return
	if use_head_as_beam_source:
		beam_source = boss.get_node_or_null("BodyPivot/Head") as Node3D
	if beam_source == null:
		beam_source = boss.get_node_or_null("BodyPivot") as Node3D

func _get_beam_start(target: Vector3) -> Vector3:
	if not is_instance_valid(boss):
		return Vector3.ZERO
	if not is_instance_valid(beam_source):
		_resolve_beam_source()
	var start: Vector3 = boss.global_position + Vector3.UP * 2.0
	if is_instance_valid(beam_source):
		start = beam_source.global_position + Vector3.UP * source_vertical_offset
	var dir: Vector3 = (target - start).normalized()
	if dir.length_squared() < 0.0001:
		dir = -boss.global_basis.z.normalized()
	return start + dir * source_forward_offset

func _predict_player_target(player: Node3D) -> Vector3:
	var target: Vector3 = player.global_position + Vector3.UP
	if player == null:
		return target
	var vel: Vector3 = Vector3.ZERO
	# CharacterBody3D del jugador expone `velocity`; hacemos comprobación defensiva.
	var raw_velocity: Variant = player.get("velocity")
	if raw_velocity is Vector3:
		vel = raw_velocity
	vel.y = 0.0
	if movement_prediction_time <= 0.0 or vel.length_squared() < 0.0001:
		return target
	var prediction: Vector3 = vel * movement_prediction_time
	if prediction.length() > max_prediction_distance:
		prediction = prediction.normalized() * max_prediction_distance
	return target + prediction

func _get_tracking_target(player: Node3D) -> Vector3:
	if not is_instance_valid(player):
		return Vector3.ZERO
	return player.global_position + Vector3.UP

func _spawn_charge_core() -> void:
	_free_charge_core()
	if not show_charge_core:
		return
	if not is_instance_valid(beam_source):
		_resolve_beam_source()
	_charge_core = BEAM_CHARGE_CORE.instantiate() as Node3D
	if _charge_core == null:
		return
	boss.add_child(_charge_core)
	if is_instance_valid(beam_source):
		_charge_core.global_position = beam_source.global_position + Vector3.UP * source_vertical_offset
	else:
		_charge_core.global_position = boss.global_position + Vector3.UP * 2.0
	_charge_core.scale = Vector3.ONE * charge_core_scale

func _update_charge_core(target: Vector3, charge_ratio: float, locked: bool) -> void:
	if not is_instance_valid(_charge_core):
		return
	if is_instance_valid(beam_source):
		_charge_core.global_position = beam_source.global_position + Vector3.UP * source_vertical_offset
	var pulse: float = 0.85 + sin(Time.get_ticks_msec() * 0.01) * 0.08
	var extra: float = 1.0 + charge_ratio * 0.45
	_charge_core.scale = Vector3.ONE * charge_core_scale * pulse * extra
	_charge_core.look_at(target, Vector3.UP)
	var mesh := _charge_core.get_node_or_null("Core") as MeshInstance3D
	if mesh != null and mesh.material_override is ShaderMaterial:
		var mat := mesh.material_override as ShaderMaterial
		mat.set_shader_parameter("energy", 0.7 + charge_ratio * 0.8 + (0.45 if locked else 0.0))
		mat.set_shader_parameter("locked", 1.0 if locked else 0.0)

func _free_charge_core() -> void:
	if is_instance_valid(_charge_core):
		_charge_core.queue_free()
	_charge_core = null

func _spawn_warning_line() -> void:
	_free_warning_line()
	if not show_warning_line:
		return
	_warning_line = BEAM_WARNING_LINE.instantiate() as Node3D
	if _warning_line == null:
		return
	get_tree().current_scene.add_child(_warning_line)

func _update_warning_line(start: Vector3, end: Vector3, locked: bool) -> void:
	if not is_instance_valid(_warning_line):
		return
	if _warning_line.has_method("set_beam_warning"):
		_warning_line.call("set_beam_warning", start, end, warning_line_width, locked)

func _free_warning_line() -> void:
	if is_instance_valid(_warning_line):
		_warning_line.queue_free()
	_warning_line = null

func fire() -> void:
	if _active or not is_inside_tree():
		return
	if not is_instance_valid(boss):
		boss = get_parent().get_parent() as Node3D
	if not is_instance_valid(boss):
		return
	var player: Node3D = get_tree().get_first_node_in_group("player") as Node3D
	if not is_instance_valid(player):
		return
	_active = true
	_shot_serial += 1
	var serial: int = _shot_serial
	beam_mesh.visible = true
	_prepare_material()
	Audio.play_sfx("beam_charge", -3.0)
	_create_cover()
	_spawn_warning_line()
	_spawn_charge_core()

	# Primero sigue al personaje con un rayo tenue: todavía no causa daño.
	var t: float = 0.0
	var follow_duration: float = maxf(0.15, warning_time)
	var lock_duration: float = minf(final_lock_time, follow_duration * 0.45)
	while t < follow_duration - lock_duration:
		if not _valid_shot(serial, player):
			_abort_shot(serial)
			return
		var end: Vector3 = _get_tracking_target(player)
		var start: Vector3 = _get_beam_start(end)
		var ratio: float = clampf(t / maxf(0.001, follow_duration), 0.0, 1.0)
		update_beam(start, end, lerpf(0.06, beam_radius * 0.72, ratio))
		_update_warning_line(start, end, false)
		_update_charge_core(end, ratio, false)
		_update_cover()
		t += get_process_delta_time()
		await get_tree().process_frame

	if not _valid_shot(serial, player):
		_abort_shot(serial)
		return
	# Pausa final breve: el ataque entra en estado peligroso, pero sin fijar una trayectoria adelantada.
	t = 0.0
	while t < minf(prefire_hold_time, follow_duration):
		if not _valid_shot(serial, player):
			_abort_shot(serial)
			return
		var armed_target: Vector3 = _get_tracking_target(player)
		var armed_start: Vector3 = _get_beam_start(armed_target)
		var armed_dir: Vector3 = (armed_target - armed_start).normalized()
		if armed_dir.length_squared() < 0.0001:
			armed_dir = Vector3.FORWARD
		var armed_end: Vector3 = armed_start + armed_dir * maxf(30.0, armed_start.distance_to(armed_target) + 12.0)
		var armed_cover_hit: Dictionary = _first_cover_hit(armed_start, armed_end)
		var armed_visible_end: Vector3 = armed_cover_hit.get("position", armed_end) if not armed_cover_hit.is_empty() else armed_end
		update_beam(armed_start, armed_visible_end, beam_radius * 0.58)
		_update_warning_line(armed_start, armed_visible_end, true)
		_update_charge_core(armed_visible_end, 1.0, true)
		_update_cover()
		t += get_process_delta_time()
		await get_tree().process_frame

	if not _valid_shot(serial, player):
		_abort_shot(serial)
		return
	_charge_color()
	Audio.play_sfx("beam_fire", 0.0)
	# La línea de advertencia desaparece al comenzar el disparo.
	_free_warning_line()
	_free_charge_core()
	t = 0.0
	while t < firing_time:
		if not _valid_shot(serial, player):
			_abort_shot(serial)
			return
		var live_target: Vector3 = _get_tracking_target(player)
		var live_start: Vector3 = _get_beam_start(live_target)
		var live_dir: Vector3 = (live_target - live_start).normalized()
		if live_dir.length_squared() < 0.0001:
			live_dir = Vector3.FORWARD
		var live_end: Vector3 = live_start + live_dir * maxf(30.0, live_start.distance_to(live_target) + 12.0)
		# La cobertura INTERCEPTA el rayo y rompe el seguimiento visual más allá del muro.
		var cover_hit: Dictionary = _first_cover_hit(live_start, live_end)
		var visible_end: Vector3 = cover_hit.get("position", live_end) if not cover_hit.is_empty() else live_end
		update_beam(live_start, visible_end, beam_radius * 1.55)
		# Al chocar con una cobertura, el disparo se interrumpe inmediatamente.
		if not cover_hit.is_empty():
			_abort_shot(serial)
			return
		# El impacto al jugador termina el ataque en este mismo fotograma.
		if player.has_method("take_damage") and _segment_hits_player(player, live_start, visible_end):
			player.take_damage(damage, "Beam")
			_abort_shot(serial)
			return
		t += get_process_delta_time()
		await get_tree().process_frame
	_abort_shot(serial)

func _valid_shot(serial: int, player: Node3D) -> bool:
	if not is_inside_tree() or serial != _shot_serial:
		return false
	if not is_instance_valid(boss) or not is_instance_valid(player):
		return false
	if boss.get("is_dead") == true or boss.get("debug_passive") == true:
		return false
	return true

func _abort_shot(serial: int) -> void:
	if serial != _shot_serial:
		return
	_shot_serial += 1
	_cleanup()
	_active = false

func _cleanup() -> void:
	if is_instance_valid(beam_mesh):
		beam_mesh.visible = false
	_free_cover()
	_free_warning_line()
	_free_charge_core()

func _create_cover() -> void:
	_free_cover()
	if not enable_stone_cover:
		return
	_cover_root = Node3D.new()
	_cover_root.name = "CoberturasRayoTemporales"
	get_tree().current_scene.add_child(_cover_root)

	# Estas posiciones son parte de la arena, NO una barrera frente al jugador.
	# El jugador debe moverse a una columna y colocarse detrás de ella.
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.30, 0.32, 0.40, 1.0)
	mat.roughness = 1.0
	for i in range(mini(cover_count, COVER_POINTS.size())):
		var anchor: Vector2 = COVER_POINTS[i]
		var pos: Vector3 = Vector3(anchor.x, 0.0, anchor.y)
		var floor_point: Vector3 = _find_cover_floor(pos)
		var pillar_height: float = cover_height * (1.0 - 0.08 * float(i % 3))
		var width: float = cover_width * (1.0 - 0.08 * float(i % 2))
		var pillar: StaticBody3D = StaticBody3D.new()
		pillar.name = "CoberturaMapa_%02d" % i
		pillar.collision_layer = 1 | COVER_COLLISION_BIT
		pillar.collision_mask = 0
		_cover_root.add_child(pillar)
		pillar.global_position = floor_point + Vector3.UP * (pillar_height * 0.5)
		var collision: CollisionShape3D = CollisionShape3D.new()
		var shape: BoxShape3D = BoxShape3D.new()
		shape.size = Vector3(width, pillar_height, cover_depth)
		collision.shape = shape
		pillar.add_child(collision)
		var mesh: MeshInstance3D = MeshInstance3D.new()
		var stone: BoxMesh = BoxMesh.new()
		stone.size = shape.size
		mesh.mesh = stone
		mesh.material_override = mat
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		pillar.add_child(mesh)
		# Remate erosionado sin colisión adicional invisible.
		var cap: MeshInstance3D = MeshInstance3D.new()
		var cap_stone: SphereMesh = SphereMesh.new()
		cap_stone.radius = 0.55
		cap_stone.height = 0.55
		cap_stone.radial_segments = 8
		cap_stone.rings = 4
		cap.mesh = cap_stone
		cap.material_override = mat
		cap.scale = Vector3(width * 0.9, 0.7, cover_depth * 0.9)
		cap.position.y = pillar_height * 0.5 - 0.1
		pillar.add_child(cap)

func _find_cover_floor(world_pos: Vector3) -> Vector3:
	var origin: Vector3 = world_pos + Vector3.UP * 30.0
	var end: Vector3 = world_pos - Vector3.UP * 50.0
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin, end)
	query.collision_mask = 1
	var result: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if result.has("position"):
		return result["position"]
	return Vector3(world_pos.x, player_floor_guess(), world_pos.z)

func player_floor_guess() -> float:
	var player: Node3D = get_tree().get_first_node_in_group("player") as Node3D
	return player.global_position.y - 1.0 if is_instance_valid(player) else 0.0

func _first_cover_hit(start: Vector3, end: Vector3) -> Dictionary:
	if not is_instance_valid(_cover_root) or not is_inside_tree():
		return {}
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(start, end)
	query.collision_mask = COVER_COLLISION_BIT
	query.collide_with_bodies = true
	query.collide_with_areas = false
	return get_world_3d().direct_space_state.intersect_ray(query)

func _update_cover() -> void:
	# La cobertura permanece quieta y sólida durante toda la preparación.
	pass

func _free_cover() -> void:
	if is_instance_valid(_cover_root):
		_cover_root.queue_free()
	_cover_root = null

func _prepare_material() -> void:
	if _beam_material != null:
		_beam_material.set_shader_parameter("firing", 0.0)
	if _inner_material != null:
		_inner_material.set_shader_parameter("firing", 0.0)

func _charge_color() -> void:
	if _beam_material != null:
		_beam_material.set_shader_parameter("firing", 1.0)
	if _inner_material != null:
		_inner_material.set_shader_parameter("firing", 1.0)

func _segment_hits_player(player: Node3D, a: Vector3, b: Vector3) -> bool:
	var point: Vector3 = player.global_position + Vector3.UP
	var ab: Vector3 = b - a
	if ab.length_squared() < 0.0001:
		return point.distance_to(a) <= beam_radius
	var fraction: float = clampf((point - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return point.distance_to(a + ab * fraction) <= beam_radius

func update_beam(start: Vector3, end: Vector3, width: float = 0.36) -> void:
	if not is_inside_tree():
		return
	var direction: Vector3 = end - start
	var length: float = direction.length()
	if length < 0.1:
		beam_mesh.visible = false
		return
	beam_mesh.visible = true
	beam_mesh.global_position = start + direction * 0.5
	# CylinderMesh se construye sobre su eje Y, por eso usamos una rotación
	# entre UP y la dirección; look_at() lo orientaría incorrectamente.
	beam_mesh.global_basis = Basis(Quaternion(Vector3.UP, direction.normalized()))
	if _beam_cylinder != null:
		_beam_cylinder.height = length
		_beam_cylinder.top_radius = width * 0.52
		_beam_cylinder.bottom_radius = width * 0.52
	if _inner_cylinder != null:
		_inner_cylinder.height = length
		_inner_cylinder.top_radius = width * 0.19
		_inner_cylinder.bottom_radius = width * 0.19
