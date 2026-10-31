extends Node3D
## Ruinas pintadas y borde erosionado, únicamente decorativos.
## No altera colisiones, navegación ni físicas de la arena.

@export_range(0, 48) var edge_rocks: int = 30
@export_range(0, 12) var ruin_groups: int = 5
@export_range(0, 30) var floating_stones: int = 8

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var stone: StandardMaterial3D

func _ready() -> void:
	rng.seed = 29102026
	stone = StandardMaterial3D.new()
	stone.vertex_color_use_as_albedo = true
	stone.roughness = 1.0
	stone.metallic = 0.0
	stone.cull_mode = BaseMaterial3D.CULL_DISABLED
	_build_edge()
	_build_ruins()
	_build_floating()

func _face(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, col: Color) -> void:
	st.set_color(col)
	st.add_vertex(a)
	st.set_color(col)
	st.add_vertex(b)
	st.set_color(col)
	st.add_vertex(c)

func _rock_mesh(seed: int, radius: float, height: float, elongated: bool = false) -> ArrayMesh:
	var local_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	local_rng.seed = seed
	var sides: int = 9
	var rings: int = 4
	var levels: Array = []
	var tints: Array[Color] = [Color(0.20,0.21,0.29), Color(0.28,0.28,0.37), Color(0.35,0.34,0.43), Color(0.42,0.40,0.48), Color(0.25,0.24,0.33)]
	for j in range(rings):
		var level: Array[Vector3] = []
		var progress: float = float(j) / float(rings - 1)
		var width: float = 1.0 - 0.22 * progress
		if not elongated:
			width = 0.80 + 0.16 * sin(progress * PI)
		for i in range(sides):
			var ang: float = TAU * float(i) / float(sides)
			var r: float = radius * width * local_rng.randf_range(0.76, 1.20)
			var y: float = progress * height + local_rng.randf_range(-0.13, 0.13) * height / 4.0
			level.append(Vector3(cos(ang)*r + progress*0.15*radius, y, sin(ang)*r))
		levels.append(level)
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in range(rings-1):
		for i in range(sides):
			var n: int = (i+1) % sides
			var a: Vector3 = levels[j][i]
			var b: Vector3 = levels[j][n]
			var c: Vector3 = levels[j+1][n]
			var d: Vector3 = levels[j+1][i]
			var pigment: Color = tints[(i + 2*j + seed) % tints.size()]
			_face(st, a, c, b, pigment)
			_face(st, a, d, c, pigment.darkened(0.07))
	var top: Vector3 = Vector3(0.15*radius,height,0)
	for i in range(sides):
		var n: int = (i+1) % sides
		_face(st, top, levels[rings-1][i], levels[rings-1][n], tints[(i+seed) % tints.size()].lightened(0.10))
	st.generate_normals()
	return st.commit()

func _piece(parent: Node3D, pos: Vector3, r: float, h: float, seed: int, angles: Vector3 = Vector3.ZERO, scaling: Vector3 = Vector3.ONE, upright: bool = false) -> void:
	var visual: MeshInstance3D = MeshInstance3D.new()
	visual.mesh = _rock_mesh(seed,r,h,upright)
	visual.material_override = stone
	visual.position = pos
	visual.rotation = angles
	visual.scale = scaling
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(visual)

func _build_edge() -> void:
	var holder: Node3D = Node3D.new()
	holder.name = "BordeFracturadoSinColision"
	add_child(holder)
	for i in range(edge_rocks):
		var a: float = TAU * (float(i) + rng.randf_range(-0.32,0.32)) / float(maxi(edge_rocks, 1))
		var distance: float = rng.randf_range(29.2,31.8)
		var p: Vector3 = Vector3(cos(a)*distance, -2.2 + rng.randf_range(-0.6,0.25), sin(a)*distance)
		_piece(holder,p,rng.randf_range(1.2,2.8),rng.randf_range(1.9,4.2),400+i,Vector3(rng.randf_range(-0.20,0.20),a,rng.randf_range(-0.25,0.25)),Vector3(rng.randf_range(1.0,1.6),1.0,rng.randf_range(0.8,1.4)))

func _build_ruins() -> void:
	var holder: Node3D = Node3D.new()
	holder.name = "SantuariosRotosSinColision"
	add_child(holder)
	var angles: PackedFloat32Array = PackedFloat32Array([-2.15,-1.30,-0.34,0.88,2.55,3.55,4.65])
	for group_id in range(ruin_groups):
		var a: float = angles[group_id % angles.size()]
		var distance: float = rng.randf_range(44.0,64.0)
		var c: Vector3 = Vector3(cos(a)*distance,-5.0,sin(a)*distance)
		var side: Vector3 = Vector3(-sin(a),0,cos(a))
		var h: float = rng.randf_range(16.0,27.0)
		_piece(holder,c-side*5.0,2.3,h,800+group_id*4,Vector3(0,a, rng.randf_range(-0.2,0.07)),Vector3.ONE,true)
		_piece(holder,c+side*5.0,2.1,h*rng.randf_range(0.65,0.92),801+group_id*4,Vector3(0,a,rng.randf_range(0.0,0.23)),Vector3.ONE,true)
		_piece(holder,c+side*3.0+Vector3(0,h*0.52,0),2.0,h*0.37,802+group_id*4,Vector3(0.1,a,1.2),Vector3.ONE,true)
		for j in range(3):
			var drift: Vector3 = Vector3(rng.randf_range(-8.0,8.0), -1.0, rng.randf_range(-8.0,8.0))
			_piece(holder,c+drift,rng.randf_range(1.4,3.0),rng.randf_range(2.0,6.0),900+group_id*5+j,Vector3(rng.randf_range(-0.3,0.3),a,rng.randf_range(-0.35,0.35)))

func _build_floating() -> void:
	var holder: Node3D = Node3D.new()
	holder.name = "FragmentosLejanosSinColision"
	add_child(holder)
	for i in range(floating_stones):
		var a: float = rng.randf_range(0.0,TAU)
		var d: float = rng.randf_range(54.0,86.0)
		var p: Vector3 = Vector3(cos(a)*d,rng.randf_range(17.0,38.0),sin(a)*d)
		_piece(holder,p,rng.randf_range(0.7,2.1),rng.randf_range(1.8,4.6),1200+i,Vector3(rng.randf_range(-0.8,0.8),a,rng.randf_range(-0.7,0.7)))
