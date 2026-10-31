extends Node3D
## Embestidas secuenciales: cada movimiento fija dirección tras una señal legible.
## El visual vive en charge_warning.tscn y su material/shader, no en este script.

const WARNING_SCENE: PackedScene = preload("res://scenes/charge_warning.tscn")

@export_group("Daño y desplazamiento")
@export var damage: int = 26
@export_range(5.0, 55.0, 0.5) var charge_speed: float = 26.0
@export_range(0.1, 3.0, 0.1) var max_time: float = 1.0
@export_range(0.5, 7.0, 0.1) var hit_radius: float = 3.2
@export_range(1, 5, 1) var dashes: int = 3

@export_group("Anticipación de cada embestida")
@export_range(0.25, 3.0, 0.05) var first_warning: float = 0.9
@export_range(0.25, 3.0, 0.05) var next_warning: float = 0.7
@export_range(0.0, 2.0, 0.05) var dash_pause: float = 0.5
@export_range(5.0, 45.0, 1.0) var warning_length: float = 22.0
@export_range(1.0, 9.0, 0.1) var warning_width: float = 4.0
@export var enable_warning: bool = true

var _running: bool = false
var _serial: int = 0
var _warning: Node3D = null

func _boss() -> Node3D:
	return get_parent().get_parent() as Node3D

func _exit_tree() -> void:
	_serial += 1
	_clear_warning()
	var boss: Node3D = _boss() if is_inside_tree() else null
	if is_instance_valid(boss):
		boss.set("external_control", false)

func _can_continue(serial: int, boss: Node3D) -> bool:
	return serial == _serial and is_inside_tree() and is_instance_valid(boss) and boss.get("is_dead") != true and boss.get("debug_passive") != true

func fire() -> void:
	if _running:
		return
	var boss: Node3D = _boss()
	if not is_instance_valid(boss):
		return
	var player: Node3D = get_tree().get_first_node_in_group("player") as Node3D
	if not is_instance_valid(player):
		return
	_running = true
	_serial += 1
	var serial: int = _serial
	boss.set("external_control", true)
	var pivot: Node3D = boss.get_node_or_null("BodyPivot") as Node3D
	var initial_pitch: float = pivot.rotation.x if is_instance_valid(pivot) else 0.0

	for index in range(dashes):
		if not _can_continue(serial, boss):
			break
		player = get_tree().get_first_node_in_group("player") as Node3D
		if not is_instance_valid(player):
			break
		# Dirección fija por embestida: nunca corrige hacia el jugador después del aviso.
		var direction: Vector3 = player.global_position - boss.global_position
		direction.y = 0.0
		if direction.length_squared() < 0.0001:
			direction = -boss.global_basis.z
		direction = direction.normalized()
		_show_warning(boss.global_position, direction)
		Audio.play_sfx("cue_charge", -2.0)
		if is_instance_valid(pivot):
			var lean: Tween = create_tween()
			lean.tween_property(pivot, "rotation:x", initial_pitch - deg_to_rad(12.0), 0.25)

		var duration: float = first_warning if index == 0 else next_warning
		var elapsed: float = 0.0
		while elapsed < duration and _can_continue(serial, boss):
			elapsed += get_process_delta_time()
			await get_tree().process_frame
		_clear_warning()
		if not _can_continue(serial, boss):
			break
		if boss.has_method("_spawn_afterimage"):
			boss._spawn_afterimage()
		Audio.play_sfx("dash", -2.0)
		var hit: bool = false
		elapsed = 0.0
		while elapsed < max_time and _can_continue(serial, boss):
			var delta: float = get_process_delta_time()
			boss.global_position += direction * charge_speed * delta
			if not hit and is_instance_valid(player) and player.has_method("take_damage"):
				var to_player: Vector3 = player.global_position - boss.global_position
				to_player.y = 0.0
				if to_player.length() < hit_radius:
					player.take_damage(damage, "Embestida")
					hit = true
			elapsed += delta
			await get_tree().process_frame
		if index < dashes - 1 and _can_continue(serial, boss):
			await get_tree().create_timer(dash_pause, false).timeout

	_clear_warning()
	if is_instance_valid(pivot):
		var reset_tween: Tween = create_tween()
		reset_tween.tween_property(pivot, "rotation:x", initial_pitch, 0.25)
	if is_instance_valid(boss):
		boss.set("external_control", false)
	_running = false

func _show_warning(origin: Vector3, direction: Vector3) -> void:
	_clear_warning()
	if not enable_warning:
		return
	_warning = WARNING_SCENE.instantiate() as Node3D
	get_tree().current_scene.add_child(_warning)
	var center: Vector3 = origin + direction * warning_length * 0.5
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(center + Vector3.UP * 25.0, center - Vector3.UP * 60.0)
	query.collision_mask = 1
	var boss: Node3D = _boss()
	if boss is CollisionObject3D:
		query.exclude = [(boss as CollisionObject3D).get_rid()]
	var result: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if result.has("position"):
		center.y = (result["position"] as Vector3).y
	else:
		center.y = get_tree().get_first_node_in_group("player").global_position.y - 1.0
	_warning.global_position = center + Vector3.UP * 0.08
	_warning.look_at(_warning.global_position + direction, Vector3.UP)
	_warning.scale = Vector3(warning_width, 1.0, warning_length)

func _clear_warning() -> void:
	if is_instance_valid(_warning):
		_warning.queue_free()
	_warning = null
