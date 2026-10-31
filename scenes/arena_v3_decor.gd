extends Node3D
## Arena V3: siluetas fracturadas tipo gouache. Solo geometría ambiental.
## No altera físicas, posiciones jugables, NavigationRegion ni IA.

@export var ruin_count: int = 13
@export var shard_count: int = 16
@export var show_arches: bool = true

var _rng := RandomNumberGenerator.new()
var _stone: StandardMaterial3D

func _ready() -> void:
	_rng.seed = 31102026
	_stone = StandardMaterial3D.new()
	_stone.vertex_color_use_as_albedo = true
	_stone.roughness = 1.0
	_stone.metallic = 0.0
	_stone.cull_mode = BaseMaterial3D.CULL_DISABLED
	_build_ruins()
	_build_fragments()
	if show_arches:
		_build_arches()
	_light_accent()

func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, tint: Color) -> void:
	st.set_color(tint)
	st.add_vertex(a)
	st.set_color(tint)
	st.add_vertex(b)
	st.set_color(tint)
	st.add_vertex(c)

func _fractured_mesh(radius: float, height: float, seed: int, cap: bool = true) -> ArrayMesh:
	var rand := RandomNumberGenerator.new()
	rand.seed = seed
	var sides := 7
	var rings := 4
	var levels: Array = []
	var taper_values: PackedFloat32Array = PackedFloat32Array([1.08, 0.92, 0.83, 0.64])
	for j in range(rings):
		var ring: Array = []
		var y := height * float(j) / float(rings - 1)
		var taper: float = taper_values[j]
		for i in range(sides):
			var angle := TAU * float(i) / float(sides)
			var rad: float = radius * taper * rand.randf_range(0.76, 1.19)
			ring.append(Vector3(cos(angle) * rad + 0.14 * j, y + rand.randf_range(-0.22, 0.22), sin(angle) * rad))
		levels.append(ring)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pigments := [Color(0.16, 0.18, 0.25), Color(0.24, 0.23, 0.33), Color(0.31, 0.30, 0.39), Color(0.39, 0.34, 0.42), Color(0.21, 0.19, 0.29)]
	for j in range(rings - 1):
		for i in range(sides):
			var nxt := (i + 1) % sides
			var a: Vector3 = levels[j][i]
			var b: Vector3 = levels[j][nxt]
			var c: Vector3 = levels[j + 1][nxt]
			var d: Vector3 = levels[j + 1][i]
			var tint: Color = pigments[(i + j * 2 + seed % 5) % pigments.size()]
			_tri(st, a, b, c, tint)
			_tri(st, a, c, d, tint.darkened(0.09))
	if cap:
		for i in range(sides):
			var nxt := (i + 1) % sides
			_tri(st, Vector3(0, height, 0), levels[rings - 1][i], levels[rings - 1][nxt], Color(0.42, 0.38, 0.43))
	st.generate_normals()
	return st.commit()

func _piece(parent: Node3D, pos: Vector3, rad: float, ht: float, seed: int, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = _fractured_mesh(rad, ht, seed)
	m.material_override = _stone
	m.position = pos
	m.rotation = rot
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(m)
	return m

func _build_ruins() -> void:
	var layer := Node3D.new()
	layer.name = "RuinasFracturadas"
	add_child(layer)
	for i in range(ruin_count):
		var a := TAU * (float(i) + _rng.randf_range(-0.16, 0.16)) / float(ruin_count)
		var distance := _rng.randf_range(43.0, 67.0)
		var h := _rng.randf_range(13.0, 32.0)
		var loc := Vector3(cos(a) * distance, -4.0, sin(a) * distance)
		_piece(layer, loc, _rng.randf_range(1.6, 3.6), h, 500 + i, Vector3(_rng.randf_range(-0.09, 0.09), a, _rng.randf_range(-0.17, 0.17)))
		if i % 3 == 0:
			_piece(layer, loc + Vector3(3, -1, 2), 1.35, h * 0.43, 700 + i, Vector3(0.18, 0.3, -0.28))

func _build_fragments() -> void:
	var layer := Node3D.new()
	layer.name = "RocasSuspendidasIrregulares"
	add_child(layer)
	for i in range(shard_count):
		var a := _rng.randf_range(0.0, TAU)
		var d := _rng.randf_range(47.0, 85.0)
		var h := _rng.randf_range(2.0, 7.5)
		var loc := Vector3(cos(a) * d, _rng.randf_range(17, 37), sin(a) * d)
		_piece(layer, loc, _rng.randf_range(1.1, 3.2), h, 900 + i, Vector3(_rng.randf_range(-0.7, 0.7), a, _rng.randf_range(-1.2, 1.2)))

func _build_arches() -> void:
	var layer := Node3D.new()
	layer.name = "UmbralesRotos"
	add_child(layer)
	# Dos conjuntos escasos y asimetricos; sin vigas rectangulares.
	for i in range(2):
		var a := 0.8 + float(i) * PI
		var center := Vector3(cos(a) * 72.0, -5, sin(a) * 72.0)
		var tangent := Vector3(-sin(a), 0, cos(a))
		_piece(layer, center + tangent * 7.0, 2.9, 27, 1500 + i, Vector3(0, a, -0.15))
		_piece(layer, center - tangent * 7.0, 2.5, 18, 1600 + i, Vector3(0, a, 0.18))
		# Dintel fracturado, inclinado, suspendido entre columnas.
		_piece(layer, center + Vector3(0, 20, 0), 2.2, 11, 1700 + i, Vector3(1.48, a, -0.19))

func _light_accent() -> void:
	var light := OmniLight3D.new()
	light.name = "ContraluzDistanteSuave"
	light.position = Vector3(-8, 25, -29)
	light.light_color = Color(0.80, 0.58, 0.43)
	light.light_energy = 0.26
	light.omni_range = 54.0
	light.shadow_enabled = false
	add_child(light)
