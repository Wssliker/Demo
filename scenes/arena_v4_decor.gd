extends Node3D
## Arena V4: composición más ceremonial y con punto focal.
## Solo geometría ambiental y luces suaves. No altera físicas ni lógica del combate.

@export var cluster_count: int = 6
@export var floating_count: int = 11
@export var perimeter_count: int = 18

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _stone: StandardMaterial3D
var _stone_dark: StandardMaterial3D

func _ready() -> void:
    _rng.seed = 40112026
    _build_materials()
    _build_focal_eclipse()
    _light_accent()

func _build_materials() -> void:
    _stone = StandardMaterial3D.new()
    _stone.vertex_color_use_as_albedo = true
    _stone.roughness = 1.0
    _stone.metallic = 0.0
    _stone.cull_mode = BaseMaterial3D.CULL_DISABLED
    _stone.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

    _stone_dark = StandardMaterial3D.new()
    _stone_dark.vertex_color_use_as_albedo = true
    _stone_dark.roughness = 1.0
    _stone_dark.metallic = 0.0
    _stone_dark.cull_mode = BaseMaterial3D.CULL_DISABLED
    _stone_dark.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, tint: Color) -> void:
    st.set_color(tint)
    st.add_vertex(a)
    st.set_color(tint)
    st.add_vertex(b)
    st.set_color(tint)
    st.add_vertex(c)

func _fractured_mesh(radius: float, height: float, seed: int, rings: int = 5, sides: int = 8, cap_top: bool = true, squat: bool = false) -> ArrayMesh:
    var rand: RandomNumberGenerator = RandomNumberGenerator.new()
    rand.seed = seed
    var taper_values: PackedFloat32Array = PackedFloat32Array([1.16, 1.0, 0.88, 0.76, 0.58, 0.42])
    var levels: Array = []
    for j in range(rings):
        var ring: Array = []
        var t: float = 0.0 if rings <= 1 else float(j) / float(rings - 1)
        var y: float = lerp(0.0, height, t)
        var taper_index: int = mini(j, taper_values.size() - 1)
        var taper: float = taper_values[taper_index]
        if squat:
            taper = lerp(1.08, 0.74, t)
        for i in range(sides):
            var angle: float = TAU * float(i) / float(sides)
            var jitter: float = rand.randf_range(0.78, 1.22)
            var rad: float = radius * taper * jitter
            var drift_x: float = rand.randf_range(-0.12, 0.12) + 0.10 * j
            var drift_z: float = rand.randf_range(-0.12, 0.12)
            ring.append(Vector3(cos(angle) * rad + drift_x, y + rand.randf_range(-0.18, 0.18), sin(angle) * rad + drift_z))
        levels.append(ring)
    var st: SurfaceTool = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var pigments: Array = [
        Color(0.18, 0.18, 0.23),
        Color(0.25, 0.24, 0.31),
        Color(0.31, 0.29, 0.37),
        Color(0.39, 0.36, 0.43),
        Color(0.45, 0.43, 0.50),
        Color(0.23, 0.21, 0.28)
    ]
    for j in range(rings - 1):
        for i in range(sides):
            var nxt: int = (i + 1) % sides
            var a: Vector3 = levels[j][i]
            var b: Vector3 = levels[j][nxt]
            var c: Vector3 = levels[j + 1][nxt]
            var d: Vector3 = levels[j + 1][i]
            var tint: Color = pigments[(i + j * 2 + seed) % pigments.size()]
            _tri(st, a, b, c, tint)
            _tri(st, a, c, d, tint.darkened(0.08))
        # missing chunks
        if j == rings - 2 and not squat:
            var cut_i: int = (seed + j) % sides
            var cut_nxt: int = (cut_i + 1) % sides
            _tri(st, levels[j][cut_i], levels[j+1][cut_i], levels[j+1][cut_nxt], Color(0.12, 0.11, 0.17))
    if cap_top:
        var top_color: Color = Color(0.52, 0.48, 0.55)
        for i in range(sides):
            var nxt: int = (i + 1) % sides
            _tri(st, Vector3(0, height, 0), levels[rings - 1][i], levels[rings - 1][nxt], top_color)
    st.generate_normals()
    return st.commit()

func _add_piece(parent: Node3D, pos: Vector3, radius: float, height: float, seed: int, rot: Vector3, scale_v: Vector3 = Vector3.ONE, material: Material = null, squat: bool = false) -> MeshInstance3D:
    var m: MeshInstance3D = MeshInstance3D.new()
    m.mesh = _fractured_mesh(radius, height, seed, 5 if not squat else 4, 8 if not squat else 7, true, squat)
    m.material_override = _stone if material == null else material
    m.position = pos
    m.rotation = rot
    m.scale = scale_v
    m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(m)
    return m

func _build_perimeter_slabs() -> void:
    var layer: Node3D = Node3D.new()
    layer.name = "PerimetroCeremonial"
    add_child(layer)
    for i in range(perimeter_count):
        var a: float = TAU * float(i) / float(perimeter_count) + _rng.randf_range(-0.08, 0.08)
        var d: float = _rng.randf_range(28.8, 33.2)
        var pos: Vector3 = Vector3(cos(a) * d, -0.58 + _rng.randf_range(-0.12, 0.08), sin(a) * d)
        var rot: Vector3 = Vector3(_rng.randf_range(-0.15, 0.12), a + _rng.randf_range(-0.25, 0.25), _rng.randf_range(-0.12, 0.12))
        var scale_v: Vector3 = Vector3(_rng.randf_range(1.0, 1.7), _rng.randf_range(0.28, 0.55), _rng.randf_range(1.8, 3.4))
        _add_piece(layer, pos, _rng.randf_range(1.4, 2.2), _rng.randf_range(1.4, 2.8), 1100 + i, rot, scale_v, _stone_dark, true)

func _build_ruin_clusters() -> void:
    var layer: Node3D = Node3D.new()
    layer.name = "RuinasMayores"
    add_child(layer)
    var angles: PackedFloat32Array = PackedFloat32Array([-0.25, 0.82, 1.92, 3.12, 4.20, 5.18])
    for i in range(cluster_count):
        var a: float = angles[i % angles.size()] + _rng.randf_range(-0.10, 0.10)
        var center_dist: float = _rng.randf_range(50.0, 71.0)
        var center: Vector3 = Vector3(cos(a) * center_dist, -4.8, sin(a) * center_dist)
        var tangent: Vector3 = Vector3(-sin(a), 0.0, cos(a))
        var count: int = 2 + int(i % 3)
        for j in range(count):
            var offset: Vector3 = tangent * _rng.randf_range(-8.5, 8.5) + Vector3(_rng.randf_range(-3.2, 3.2), 0, _rng.randf_range(-3.2, 3.2))
            var pos: Vector3 = center + offset
            var h: float = _rng.randf_range(17.0, 34.0)
            var rot: Vector3 = Vector3(_rng.randf_range(-0.08, 0.1), a + _rng.randf_range(-0.25, 0.25), _rng.randf_range(-0.23, 0.23))
            _add_piece(layer, pos, _rng.randf_range(1.6, 3.0), h, 2000 + i * 10 + j, rot)
            if j == 0:
                _add_piece(layer, pos + Vector3(_rng.randf_range(-2.8, 2.8), -0.8, _rng.randf_range(-2.8, 2.8)), _rng.randf_range(1.0, 1.8), h * _rng.randf_range(0.34, 0.56), 2200 + i * 10 + j, rot + Vector3(0.2, 0, -0.18), Vector3.ONE * _rng.randf_range(0.8, 1.2))

func _build_distant_spires() -> void:
    var layer: Node3D = Node3D.new()
    layer.name = "AgujasDistantes"
    add_child(layer)
    var backdrop_positions: Array = [
        Vector3(-10, -7, -92), Vector3(15, -6, -88), Vector3(-34, -8, -81),
        Vector3(38, -9, -77), Vector3(-2, -7, -108)
    ]
    for i in range(backdrop_positions.size()):
        var pos: Vector3 = backdrop_positions[i]
        var h: float = 34.0 + float(i % 3) * 8.0 + _rng.randf_range(-2.0, 5.0)
        var rot: Vector3 = Vector3(_rng.randf_range(-0.06, 0.06), _rng.randf_range(-0.6, 0.6), _rng.randf_range(-0.16, 0.16))
        _add_piece(layer, pos, 2.6 + float(i % 2) * 0.8, h, 2600 + i, rot, Vector3(_rng.randf_range(0.8, 1.2), 1.0, _rng.randf_range(0.8, 1.2)), _stone)

func _build_floating_fragments() -> void:
    var layer: Node3D = Node3D.new()
    layer.name = "FragmentosSuspendidos"
    add_child(layer)
    for i in range(floating_count):
        var a: float = _rng.randf_range(-1.15, 1.15)
        var d: float = _rng.randf_range(44.0, 86.0)
        var z_bias: float = _rng.randf_range(-72.0, 28.0)
        var pos: Vector3 = Vector3(cos(a) * d, _rng.randf_range(18.0, 39.0), z_bias)
        if i % 3 == 0:
            pos.x *= 0.65
        var rot: Vector3 = Vector3(_rng.randf_range(-0.8, 0.8), _rng.randf_range(0.0, TAU), _rng.randf_range(-1.0, 1.0))
        _add_piece(layer, pos, _rng.randf_range(0.9, 2.6), _rng.randf_range(2.4, 7.0), 3000 + i, rot, Vector3(_rng.randf_range(0.7, 1.3), _rng.randf_range(0.8, 1.6), _rng.randf_range(0.7, 1.3)), _stone, true)

func _build_focal_eclipse() -> void:
    # Imagen con transparencia, lejos de la arena. No es geometria solida.
    var focal: Sprite3D = Sprite3D.new()
    focal.name = "EclipseAtmosferico"
    focal.texture = preload("res://assets/generated/arena_v6_eclipse.png")
    focal.pixel_size = 0.085
    focal.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    focal.shaded = false
    focal.no_depth_test = false
    focal.position = Vector3(-21.0, 43.0, -154.0)
    focal.modulate = Color(0.82, 0.62, 0.62, 0.72)
    focal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(focal)

func _light_accent() -> void:
    var warm: OmniLight3D = OmniLight3D.new()
    warm.name = "BackHaloLight"
    warm.position = Vector3(-17, 34, -102)
    warm.light_color = Color(0.92, 0.67, 0.48)
    warm.light_energy = 0.27
    warm.omni_range = 46.0
    warm.shadow_enabled = false
    add_child(warm)

    var cool: OmniLight3D = OmniLight3D.new()
    cool.name = "SideCoolLight"
    cool.position = Vector3(19, 12, -30)
    cool.light_color = Color(0.42, 0.58, 0.95)
    cool.light_energy = 0.18
    cool.omni_range = 34.0
    cool.shadow_enabled = false
    add_child(cool)
