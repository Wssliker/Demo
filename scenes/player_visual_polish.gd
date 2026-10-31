extends Node3D
## Ornamentos visuales desmontables del protagonista provisional.
## No crea Areas ni CollisionShapes y no altera player.gd.

@export_group("Protagonista — aspecto provisional")
@export var enable_visual_polish: bool = true:
	set(value):
		enable_visual_polish = value
		if is_inside_tree():
			visible = value
@export_range(0.0, 1.0, 0.05) var cloak_motion: float = 0.55
@export_range(0.0, 1.0, 0.05) var idle_breathing: float = 0.18
@export_range(0.0, 1.0, 0.05) var ceremonial_red: float = 0.32

var _cloak_segments: Array[MeshInstance3D] = []
var _cloak_rest: Array[Vector3] = []
var _mask: MeshInstance3D
var _hood: MeshInstance3D
var _time: float = 0.0
var _body: CharacterBody3D

func _ready() -> void:
	visible = enable_visual_polish
	_body = get_parent().get_parent() as CharacterBody3D
	_build_costume()

func _process(delta: float) -> void:
	if not enable_visual_polish:
		return
	_time += delta
	var motion: float = 0.0
	if is_instance_valid(_body):
		motion = clampf(Vector2(_body.velocity.x, _body.velocity.z).length() / 12.0, 0.0, 1.0)
	for i in range(_cloak_segments.size()):
		var part: MeshInstance3D = _cloak_segments[i]
		var phase: float = _time * (2.0 + motion * 4.0) - float(i) * 0.48
		part.rotation.x = PI * 0.5 - 0.08 - motion * 0.28 - sin(phase) * cloak_motion * (0.10 + float(i) * 0.05)
		part.rotation.z = sin(phase * 0.65) * cloak_motion * 0.035
		part.position = _cloak_rest[i]
	if is_instance_valid(_hood):
		_hood.scale.y = 1.0 + sin(_time * 1.6) * idle_breathing * 0.014

func _material(color: Color, roughness: float = 0.93) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = 0.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat

func _box(name: String, size: Vector3, position_value: Vector3, material: Material, parent_node: Node3D = null) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.name = name
	instance.mesh = mesh
	instance.material_override = material
	if parent_node == null:
		add_child(instance)
	else:
		parent_node.add_child(instance)
	instance.position = position_value
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance

func _sphere(name: String, radius: float, height: float, position_value: Vector3, material: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	mesh.rings = 6
	var instance := MeshInstance3D.new()
	instance.name = name
	instance.mesh = mesh
	instance.material_override = material
	add_child(instance)
	instance.position = position_value
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance

func _build_costume() -> void:
	var cloth := _material(Color(0.12, 0.16, 0.23, 1.0))
	var cloth_edge := _material(Color(0.26, 0.31, 0.40, 1.0))
	var slate := _material(Color(0.29, 0.31, 0.38, 1.0))
	var bone := _material(Color(0.65, 0.65, 0.62, 1.0))
	var thread := _material(Color(0.37 + ceremonial_red * 0.26, 0.20, 0.23, 1.0))
	var steel := _material(Color(0.38, 0.47, 0.50, 1.0), 0.7)

	# Mantener el visor existente como parte de la máscara; nada se sustituye.
	_hood = _sphere("CapuchaOscura", 0.47, 0.67, Vector3(0.0, 0.48, 0.02), cloth)
	_hood.scale = Vector3(1.06, 1.0, 0.98)
	_mask = _box("MascaraCeremonial", Vector3(0.62, 0.40, 0.13), Vector3(0.0, 0.50, -0.45), bone)
	_box("FrenteDeMascara", Vector3(0.46, 0.075, 0.04), Vector3(0.0, 0.67, -0.54), slate)
	_box("MarcaCentral", Vector3(0.07, 0.21, 0.045), Vector3(0.0, 0.46, -0.535), thread)
	for side in [-1.0, 1.0]:
		_box("RibeteMascara", Vector3(0.055, 0.25, 0.055), Vector3(side * 0.28, 0.50, -0.53), slate)
		_box("HombroDeTela", Vector3(0.30, 0.13, 0.40), Vector3(side * 0.40, 0.13, 0.01), cloth_edge)

	# Capa de paños solapados: articulación visual simple, sin física ni colisiones.
	for i in range(3):
		var section := MeshInstance3D.new()
		section.name = "Manto_%02d" % (i + 1)
		var plane := PlaneMesh.new()
		plane.size = Vector2(0.96 - float(i) * 0.10, 0.43)
		section.mesh = plane
		section.material_override = cloth if i != 2 else cloth_edge
		add_child(section)
		section.rotation_degrees.x = 90.0
		var rest := Vector3(0.0, 0.16 - float(i) * 0.31, 0.40 + float(i) * 0.085)
		section.position = rest
		section.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_cloak_segments.append(section)
		_cloak_rest.append(rest)

	# Hoja de piedra/acero provisional, en la espalda, sin modificar hitboxes.
	var weapon := Node3D.new()
	weapon.name = "ArmaCeremonialProvisional"
	add_child(weapon)
	weapon.position = Vector3(-0.28, 0.03, 0.52)
	weapon.rotation_degrees = Vector3(10.0, 0.0, -26.0)
	_box("Empunadura", Vector3(0.09, 0.37, 0.09), Vector3(0.0, -0.14, 0.0), thread, weapon)
	_box("Hoja", Vector3(0.12, 0.67, 0.055), Vector3(0.0, 0.35, 0.0), steel, weapon)
	_box("Guarda", Vector3(0.27, 0.065, 0.12), Vector3(0.0, 0.06, 0.0), slate, weapon)
