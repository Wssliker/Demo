extends AnimatableBody3D
class_name BossEye
## Un ojo del coloso. No es un punto débil normal: es un puzzle.
## Debes treparlo y clavarle `hits_to_break` estocadas para reventarlo.

@export var eye_index: int = 0          # 0, 1, 2 (primero, segundo, tercer ojo)
@export var hits_to_break: int = 5      # El concepto: 5 estocadas por ojo
@export var damage_to_boss: int = 40    # Cuando revienta, le muerde la salud al jefe

var hits: int = 0
var is_broken: bool = false
var mat: StandardMaterial3D
var pulse_tween: Tween
var hit_tween: Tween

@export_group("Combat Polish V2 — impactos")
@export var enable_impact_fx: bool = true
@export_range(0, 24, 1) var hit_particles: int = 8
@export_range(0, 48, 1) var break_particles: int = 28
@export_range(0.0, 3.0, 0.1) var hit_flash_energy: float = 1.3
@export_range(0.0, 5.0, 0.1) var break_flash_energy: float = 3.0

@onready var mesh: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	add_to_group("weak_point")
	add_to_group("boss_eye")
	# Los ojos se seleccionan por distancia en player.gd; no necesitan
	# colisionar físicamente con el jugador ni sostenerlo en el aire.
	# Conservamos la malla y el script para que puedan dañarse normalmente.
	collision_layer = 0
	collision_mask = 0
	var solid_shape := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if solid_shape:
		solid_shape.set_deferred("disabled", true)
	# Núcleo cósmico: un ojo que no es un ojo, sino un agujero con brillo de brasa.
	mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.42, 0.04, 0.26)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.16, 0.5)
	mat.emission_energy_multiplier = 1.8
	mat.roughness = 0.35
	if mesh:
		mesh.material_override = mat
	start_pulsing(1.6)

func start_pulsing(speed: float) -> void:
	if pulse_tween and pulse_tween.is_valid():
		pulse_tween.kill()
	var half: float = maxf(0.12, speed * 0.5)
	pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(mat, "emission_energy_multiplier", 3.6, half).set_trans(Tween.TRANS_SINE)
	pulse_tween.tween_property(mat, "emission_energy_multiplier", 1.4, half).set_trans(Tween.TRANS_SINE)

func take_damage(_amount: int) -> void:
	if is_broken:
		return
	var gate_boss := get_tree().get_first_node_in_group("boss")
	if gate_boss and gate_boss.has_method("can_damage_eye"):
		if not gate_boss.can_damage_eye(eye_index):
			return
	hits += 1
	Audio.play_sfx("eye_pierce", -5.0)
	# Reacción al golpe: destello blanco y temblor.
	if mat:
		mat.emission = Color.WHITE
		create_tween().tween_property(mat, "emission", Color(1.0, 0.16, 0.5), 0.25)
	if mesh:
		if hit_tween and hit_tween.is_running():
			hit_tween.kill()
		mesh.position = Vector3.ZERO
		mesh.scale = Vector3.ONE
		hit_tween = create_tween()
		hit_tween.tween_property(mesh, "scale", Vector3(1.18, 1.18, 1.18), 0.065)
		hit_tween.tween_property(mesh, "scale", Vector3.ONE, 0.16).set_trans(Tween.TRANS_SINE)
	if enable_impact_fx:
		_spawn_impact_fx(false)
	var boss := get_tree().get_first_node_in_group("boss")
	if hits >= hits_to_break:
		break_eye()
	else:
		# El latido se acelera como un corazón asustado.
		start_pulsing(maxf(0.3, 1.6 - hits * 0.25))
		if boss and boss.has_method("on_eye_hit"):
			boss.on_eye_hit(eye_index, hits, hits_to_break)

func break_eye() -> void:
	if is_broken:
		return
	var gate_boss := get_tree().get_first_node_in_group("boss")
	if gate_boss and gate_boss.has_method("can_damage_eye"):
		if not gate_boss.can_damage_eye(eye_index):
			return
	is_broken = true
	remove_from_group("weak_point")
	add_to_group("broken_eye")
	# Ocultar el ojo de inmediato: no debe quedar visible ni seleccionable.
	if mesh and is_instance_valid(mesh):
		mesh.visible = false
	var eye_collision := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if eye_collision:
		eye_collision.set_deferred("disabled", true)
	collision_layer = 0
	collision_mask = 0
	Audio.play_sfx("eye_shatter", -2.0)
	if enable_impact_fx:
		_spawn_impact_fx(true)
	if hit_tween and hit_tween.is_running():
		hit_tween.kill()
	if pulse_tween and pulse_tween.is_valid():
		pulse_tween.kill()
	var boss := get_tree().get_first_node_in_group("boss")
	if boss and boss.has_method("on_eye_broken"):
		boss.on_eye_broken(eye_index)
	# Diferir la eliminación para evitar cambios del árbol durante la colisión.
	call_deferred("queue_free")


## Efectos ligeros y efímeros, sin alterar la colisión ni el conteo de estocadas.
## Usamos un nodo bajo la escena para que la ruptura siga visible tras liberar el ojo.
func _spawn_impact_fx(broken: bool) -> void:
	var parent: Node = get_tree().current_scene
	if parent == null:
		return
	var effect := Node3D.new()
	effect.name = "RupturaOjoFX" if broken else "ImpactoOjoFX"
	parent.add_child(effect)
	effect.global_position = global_position

	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.22, 0.28) if broken else Color(0.98, 0.58, 0.87)
	light.light_energy = break_flash_energy if broken else hit_flash_energy
	light.omni_range = 5.5 if broken else 3.0
	light.shadow_enabled = false
	effect.add_child(light)
	var light_tween := effect.create_tween()
	light_tween.tween_property(light, "light_energy", 0.0, 0.38 if broken else 0.18).set_trans(Tween.TRANS_CUBIC)

	var count: int = break_particles if broken else hit_particles
	if count > 0:
		var particles := GPUParticles3D.new()
		particles.name = "FragmentosCarmesies"
		particles.amount = count
		particles.lifetime = 0.60 if broken else 0.32
		particles.one_shot = true
		particles.explosiveness = 1.0
		particles.emitting = false
		particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var process := ParticleProcessMaterial.new()
		process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		process.emission_sphere_radius = 0.12 if broken else 0.04
		process.direction = Vector3(0, 1, 0)
		process.spread = 180.0
		process.gravity = Vector3(0, -1.4, 0)
		process.initial_velocity_min = 2.0 if broken else 0.7
		process.initial_velocity_max = 5.0 if broken else 2.0
		process.color = Color(1.0, 0.18, 0.38, 0.9) if broken else Color(1.0, 0.5, 0.75, 0.8)
		particles.process_material = process
		var shard := SphereMesh.new()
		shard.radius = 0.055 if broken else 0.032
		shard.height = 0.11 if broken else 0.064
		shard.radial_segments = 4
		shard.rings = 2
		var shard_mat := StandardMaterial3D.new()
		shard_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		shard_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		shard_mat.albedo_color = Color(1.0, 0.24, 0.40, 0.9) if broken else Color(1.0, 0.54, 0.72, 0.85)
		shard.material = shard_mat
		particles.draw_pass_1 = shard
		effect.add_child(particles)
		particles.emitting = true

	# Sin timers asíncronos ligados al ojo destruido.
	var cleanup := effect.create_tween()
	cleanup.tween_interval(1.25)
	cleanup.tween_callback(effect.queue_free)
