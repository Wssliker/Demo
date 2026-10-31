extends Node3D
class_name TelegraphDecal
## Marca en el suelo que avisa dónde golpeará un ataque.
## Reutilizable por Rain, Melee y Beam.

@onready var mesh: MeshInstance3D = $Mesh
var _mat: ShaderMaterial
var _grow_tween: Tween

const DANGER := Color(1.0, 0.28, 0.12, 0.95)
const BEAM_COLOR := Color(1.0, 0.75, 0.2, 0.95)
const RING_TEX: Texture2D = preload("res://assets/generated/fx_ring.png")

func _ready() -> void:
	# Cada marca necesita su propio material para evitar que un aviso
	# modifique el relleno de otros indicadores activos.
	var original := mesh.material_override as ShaderMaterial
	if original != null:
		_mat = original.duplicate() as ShaderMaterial
		mesh.material_override = _mat
	_apply_readability_settings()
	_add_painted_ring()

## Añade el aro pintado (gouache) encima del decal procedural: mismo lenguaje visual que el resto.
func _add_painted_ring() -> void:
	var ring := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(2.0, 2.0)
	ring.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_texture = RING_TEX
	m.albedo_color = Color(1.0, 0.73, 0.62, 0.45)
	ring.material_override = m
	ring.rotation.x = deg_to_rad(-90)
	ring.position.y = 0.02
	add_child(ring)
	# Gira despacio para que respire.
	var t := create_tween().set_loops()
	t.tween_property(ring, "rotation:z", TAU, 6.0).from(0.0)

func _apply_readability_settings() -> void:
	if _mat == null:
		return
	var boss := get_tree().get_first_node_in_group("boss")
	if boss == null:
		return
	if "telegraph_visibility" in boss:
		_mat.set_shader_parameter("visibility_scale", float(boss.get("telegraph_visibility")))
	if "telegraph_outline" in boss:
		_mat.set_shader_parameter("outline_scale", float(boss.get("telegraph_outline")))
	if "telegraph_pulse_speed" in boss:
		_mat.set_shader_parameter("pulse_speed", float(boss.get("telegraph_pulse_speed")))

func _ensure() -> void:
	if _mat == null:
		_mat = mesh.material_override as ShaderMaterial

func _process(_delta: float) -> void:
	# Permite ajustar los indicadores en directo desde el panel F1.
	_apply_readability_settings()

func place(p: Vector3) -> void:
	global_position = p

## Deja el aro visible de inmediato con este radio, sin animación.
func show_ring(radius: float, color: Color = DANGER) -> void:
	_ensure()
	_mat.set_shader_parameter("decal_color", color)
	_mat.set_shader_parameter("progress", 0.0)
	_mat.set_shader_parameter("flash", 0.0)
	scale = Vector3(radius, 1.0, radius)

## Anima el relleno creciendo hasta "radius" en "duration" segundos.
func grow_to(radius: float, duration: float) -> void:
	_ensure()
	if _grow_tween and _grow_tween.is_valid():
		_grow_tween.kill()
	scale = Vector3(radius * 0.55, 1.0, radius * 0.55)
	_grow_tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_grow_tween.tween_property(self, "scale", Vector3(radius, 1.0, radius), duration)
	_grow_tween.tween_method(func(v): _mat.set_shader_parameter("progress", v), 0.0, 1.0, duration)

## Destella en el momento del impacto y se autodestruye.
func flash_and_free(color: Color = DANGER) -> void:
	_ensure()
	_mat.set_shader_parameter("decal_color", color)
	_mat.set_shader_parameter("progress", 1.0)
	var t := create_tween()
	t.tween_method(func(v): _mat.set_shader_parameter("flash", v), 1.0, 0.0, 0.28)
	await t.finished
	queue_free()

## Conveniencia: colocar + mostrar + crecer + destellar + liberar.
func arm(p: Vector3, radius: float, duration: float, color: Color = DANGER) -> void:
	place(p)
	show_ring(radius, color)
	grow_to(radius, duration)
	await get_tree().create_timer(duration, false).timeout
	flash_and_free(color)

## Busca la superficie del suelo bajo una posición (para apoyar el decal).
static func find_ground(tree: SceneTree, from: Vector3) -> Vector3:
	var space := tree.root.world_3d.direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, from + Vector3(0, -60, 0))
	var hit := space.intersect_ray(query)
	if hit.has("position"):
		return hit.position + Vector3(0, 0.05, 0)
	return from