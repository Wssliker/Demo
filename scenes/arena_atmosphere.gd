extends Node3D
class_name ArenaAtmosphere
## Atmósfera de la arena: polvo suspendido y brasas del eclipse.
## Solo presentación. No altera colisiones, navegación, IA ni lógica de combate.

@export var dust_amount: int = 180
@export var ember_amount: int = 70
@export var dust_extents: Vector3 = Vector3(60.0, 26.0, 60.0)
@export var ember_extents: Vector3 = Vector3(46.0, 34.0, 46.0)
@export var ember_center: Vector3 = Vector3(-14.0, 22.0, -70.0)

const ORB_TEX: Texture2D = preload("res://assets/generated/fx_orb.png")
const FISSURE_TEX: Texture2D = preload("res://assets/generated/fissure_glow.png")

@export var fissure_count: int = 6
@export var fissure_ring_min: float = 19.0
@export var fissure_ring_max: float = 27.0

func _ready() -> void:
	_build_dust()
	_build_embers()
	_build_fissures()

## Malla de mota suave: quad billboard aditivo. Sin sombras ni profundidad.
func _mote_mesh(color: Color, size: float) -> Mesh:
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.albedo_color = color
	mat.albedo_texture = ORB_TEX
	mat.disable_receive_shadows = true
	mat.no_depth_test = false
	q.material = mat
	return q

func _build_dust() -> void:
	var dust := GPUParticles3D.new()
	dust.name = "PolvoSuspendido"
	dust.amount = dust_amount
	dust.lifetime = 16.0
	dust.preprocess = 8.0
	dust.explosiveness = 0.0
	dust.fixed_fps = 0
	dust.local_coords = false
	dust.position = Vector3(0.0, dust_extents.y * 0.5, 0.0)
	dust.visibility_aabb = AABB(-dust_extents - Vector3(4, 4, 4), (dust_extents + Vector3(4, 4, 4)) * 2.0)

	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	m.emission_box_extents = dust_extents
	m.direction = Vector3(0.0, 1.0, 0.0)
	m.spread = 180.0
	m.initial_velocity_min = 0.03
	m.initial_velocity_max = 0.18
	m.gravity = Vector3(0.015, -0.005, 0.0)
	m.scale_min = 0.5
	m.scale_max = 1.6
	m.color = Color(0.80, 0.74, 0.86, 0.30)
	dust.process_material = m
	dust.draw_pass_1 = _mote_mesh(Color(0.88, 0.83, 0.92, 0.32), 0.07)
	add_child(dust)

func _build_embers() -> void:
	var embers := GPUParticles3D.new()
	embers.name = "BrasasEclipse"
	embers.amount = ember_amount
	embers.lifetime = 11.0
	embers.preprocess = 6.0
	embers.local_coords = false
	embers.position = ember_center
	embers.visibility_aabb = AABB(-ember_extents - Vector3(6, 6, 6), (ember_extents + Vector3(6, 6, 6)) * 2.0)

	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	m.emission_box_extents = ember_extents
	m.direction = Vector3(0.05, 1.0, 0.0)
	m.spread = 22.0
	m.initial_velocity_min = 0.4
	m.initial_velocity_max = 1.1
	m.gravity = Vector3(0.03, 0.12, 0.0)
	m.scale_min = 0.35
	m.scale_max = 1.1
	m.color = Color(0.95, 0.62, 0.38, 0.42)
	embers.process_material = m
	embers.draw_pass_1 = _mote_mesh(Color(1.0, 0.66, 0.42, 0.45), 0.11)
	add_child(embers)

## Grietas incandescentes en el anillo perimetral (el centro queda limpio).
func _build_fissures() -> void:
	var holder := Node3D.new()
	holder.name = "GrietasIncandescentes"
	add_child(holder)
	var rng := RandomNumberGenerator.new()
	rng.seed = 553311
	for i in fissure_count:
		var a := TAU * float(i) / float(maxi(fissure_count, 1)) + rng.randf_range(-0.30, 0.30)
		var d := rng.randf_range(fissure_ring_min, fissure_ring_max)
		var size := rng.randf_range(7.0, 12.0)
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mat.albedo_texture = FISSURE_TEX
		mat.albedo_color = Color(0.90, 0.55, 0.40, 0.45)
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.disable_receive_shadows = true
		var mi := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(size, size * rng.randf_range(0.8, 1.2))
		q.material = mat
		mi.mesh = q
		mi.material_override = mat
		mi.position = Vector3(cos(a) * d, 0.54, sin(a) * d)
		mi.rotation = Vector3(deg_to_rad(-90.0), 0.0, rng.randf_range(0.0, TAU))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(mi)
		# Pulso lento de brasa.
		var pulse := rng.randf_range(2.2, 4.0)
		var t := create_tween().set_loops()
		t.tween_property(mat, "albedo_color:a", 0.26, pulse).set_trans(Tween.TRANS_SINE)
		t.tween_property(mat, "albedo_color:a", 0.52, pulse).set_trans(Tween.TRANS_SINE)