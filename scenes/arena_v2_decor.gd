extends Node3D
## Arena V2: geometría ambiental procedural exclusivamente visual.
## No crea StaticBody3D, Area3D ni CollisionShape3D.

const STONE := Color(0.22, 0.22, 0.31)
const SHADOW := Color(0.11, 0.12, 0.19)
const HIGHLIGHT := Color(0.36, 0.33, 0.43)

func _ready() -> void:
	_build_ruins()
	_build_floating_stones()
	_build_ritual_perimeter()
	_build_atmosphere()

func _material(c: Color, emission: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.97
	m.metallic = 0.0
	if emission:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = 0.7
	return m

func _box(parent: Node3D, p: Vector3, size: Vector3, rot: Vector3, mat: Material) -> void:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = mat
	node.mesh = mesh
	node.position = p
	node.rotation = rot
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)

func _build_ruins() -> void:
	var layer := Node3D.new()
	layer.name = "RuinasLejanas"
	add_child(layer)
	var mat1 := _material(STONE)
	var mat2 := _material(SHADOW)
	var mat3 := _material(HIGHLIGHT)
	var rng := RandomNumberGenerator.new()
	rng.seed = 142917
	# El perímetro jugable termina a unos 30 metros: ruinas >= 39 m.
	for i in range(18):
		var a := TAU * float(i) / 18.0 + rng.randf_range(-0.13, 0.13)
		var radius := rng.randf_range(43.0, 64.0)
		var h := rng.randf_range(9.0, 30.0)
		var w := rng.randf_range(2.0, 4.4)
		var p := Vector3(cos(a) * radius, h * 0.5 - 3.0, sin(a) * radius)
		_box(layer, p, Vector3(w, h, w * 0.8), Vector3(rng.randf_range(-0.18, 0.18), a, rng.randf_range(-0.24, 0.24)), mat1 if i % 3 else mat2)
		if i % 2 == 0:
			_box(layer, p + Vector3(0, h * 0.49, 0), Vector3(w * 1.5, 1.1, w * 1.3), Vector3(0, a, rng.randf_range(-0.12, 0.12)), mat3)
		if i % 3 == 0:
			_box(layer, p + Vector3(0, -h * 0.48, 0), Vector3(w * 1.8, 1.4, w * 1.7), Vector3(0, a, 0), mat2)
	# Arcos destruidos, lejanos y no transitables.
	for j in range(4):
		var angle := 0.3 + float(j) * TAU / 4.0
		var center := Vector3(cos(angle) * 66.0, 12.0, sin(angle) * 66.0)
		var direction := Vector3(-sin(angle), 0, cos(angle))
		_box(layer, center + direction * 8.0, Vector3(3, 27, 3), Vector3(0, angle, -0.06), mat2)
		_box(layer, center - direction * 8.0, Vector3(3, 23, 3), Vector3(0, angle, 0.1), mat2)
		_box(layer, center + Vector3(0, 12, 0), Vector3(19, 2.4, 4.0), Vector3(0, angle, -0.13), mat1)

func _build_floating_stones() -> void:
	var layer := Node3D.new()
	layer.name = "FragmentosSuspendidos"
	add_child(layer)
	var dark := _material(Color(0.17, 0.17, 0.26))
	var light := _material(Color(0.31, 0.27, 0.38))
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261029
	for i in range(27):
		var a := rng.randf_range(0.0, TAU)
		var d := rng.randf_range(42.0, 83.0)
		var y := rng.randf_range(15.0, 44.0)
		var scale := rng.randf_range(1.1, 5.0)
		_box(layer, Vector3(cos(a) * d, y, sin(a) * d), Vector3(scale, scale * rng.randf_range(0.5, 1.7), scale * 0.9), Vector3(rng.randf_range(-0.4, 0.4), a, rng.randf_range(-0.35, 0.35)), dark if i % 3 else light)

func _build_ritual_perimeter() -> void:
	var layer := Node3D.new()
	layer.name = "AnilloRitualExterior"
	add_child(layer)
	var mat := _material(Color(0.3, 0.25, 0.36))
	# Segmentos fuera de la plataforma central; sin geometría dentro de los 30 m.
	for i in range(36):
		var a := TAU * float(i) / 36.0
		var r := 34.0
		var p := Vector3(cos(a) * r, -0.25, sin(a) * r)
		_box(layer, p, Vector3(3.0, 0.8, 1.2), Vector3(0, -a, 0.0), mat)

func _build_atmosphere() -> void:
	# Luz de recorte distante. No se crean partículas ni sombras extra.
	var rim := OmniLight3D.new()
	rim.name = "ResplandorVioletaLejano"
	rim.position = Vector3(0, 24, -35)
	rim.light_color = Color(0.43, 0.35, 0.75)
	rim.light_energy = 0.55
	rim.omni_range = 65.0
	rim.shadow_enabled = false
	add_child(rim)
