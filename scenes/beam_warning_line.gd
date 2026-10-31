extends Node3D

@onready var _mesh: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	if _mesh.material_override != null:
		_mesh.material_override = _mesh.material_override.duplicate()
	if _mesh.mesh != null:
		_mesh.mesh = _mesh.mesh.duplicate()

func set_beam_warning(start: Vector3, end: Vector3, width: float, locked: bool) -> void:
	var direction: Vector3 = end - start
	var length: float = direction.length()
	if length < 0.05:
		visible = false
		return
	visible = true
	var ground_start := start
	var ground_end := end
	ground_start.y = 0.12
	ground_end.y = 0.12
	direction = ground_end - ground_start
	length = direction.length()
	global_position = ground_start + direction * 0.5
	rotation.y = atan2(direction.x, direction.z)
	var mesh := _mesh.mesh as PlaneMesh
	if mesh != null:
		mesh.size = Vector2(width, length)
	var mat := _mesh.material_override as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter("locked", 1.0 if locked else 0.0)
		mat.set_shader_parameter("line_length", length)
