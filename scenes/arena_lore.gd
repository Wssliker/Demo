extends Node3D
## Narrativa ambiental opcional. Los objetos no tienen colisiones ni afectan al jefe.
## F examina el vestigio cercano. F o Esc cierra la lectura.

@export_group("Vestigios")
@export var active: bool = true
@export_range(1.5, 8.0, 0.5) var inspect_distance: float = 4.0
@export var enable_glow: bool = true

const STONE := Color(0.29, 0.31, 0.39)
const EDGE := Color(0.53, 0.56, 0.68)
const GLOW := Color(0.62, 0.24, 0.40)
const PARCHMENT := Color(0.92, 0.87, 0.78)

const LORE := [
	{
		"title": "I · EL JURAMENTO",
		"text": "Le pidieron sostener el umbral.\nNo preguntó cuánto tiempo.\n\nY el cielo dejó de avanzar.",
		"position": Vector3(9.0, 0.85, 15.0)
	},
	{
		"title": "II · LOS TESTIGOS",
		"text": "Tres ojos vigilaban la grieta.\nTres promesas, una por cada mirada.\n\nLa última nunca debió romperse.",
		"position": Vector3(-20.0, 0.85, 4.0)
	},
	{
		"title": "III · LA CARGA",
		"text": "No era un trono. Era una prisión.\nNo era un guardián. Era el sello.\n\n¿Qué quedará cuando deje de sostener?",
		"position": Vector3(17.0, 0.85, -14.0)
	}
]

var _player: Node3D
var _points: Array[Vector3] = []
var _nearest: int = -1
var _opened: bool = false
var _found: Dictionary = {}
var _layer: CanvasLayer
var _root: Control
var _hint: Label
var _veil: ColorRect
var _panel: PanelContainer
var _heading: Label
var _body: Label
var _footer: Label

func _ready() -> void:
	_player = get_parent().get_node_or_null("Player") as Node3D
	_build_monuments()
	_build_ui()

func _process(_delta: float) -> void:
	if not active or not is_instance_valid(_player):
		_hint.visible = false
		return
	if _is_intro_active():
		_hint.visible = false
		if _opened:
			_close_reading()
		return
	_nearest = -1
	var nearest_distance: float = inspect_distance
	for i in range(_points.size()):
		var distance: float = _player.global_position.distance_to(_points[i])
		if distance <= nearest_distance:
			nearest_distance = distance
			_nearest = i
	_hint.visible = _nearest >= 0 and not _opened and not get_tree().paused
	if _hint.visible:
		_hint.text = "F · EXAMINAR VESTIGIO"

func _unhandled_input(event: InputEvent) -> void:
	if not active or _is_intro_active():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if _opened and (event.keycode == KEY_F or event.keycode == KEY_ESCAPE):
			_close_reading()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F and _nearest >= 0 and not get_tree().paused:
			_open_reading(_nearest)
			get_viewport().set_input_as_handled()

func _is_intro_active() -> bool:
	var arena: Node = get_parent()
	return arena != null and "_intro_active" in arena and bool(arena.get("_intro_active"))

func _make_material(color: Color, emissive: bool = false) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	if emissive and enable_glow:
		material.emission_enabled = true
		material.emission = GLOW
		material.emission_energy_multiplier = 1.4
	return material

func _add_box(root: Node3D, local_pos: Vector3, size: Vector3, material: Material, rotation: float = 0.0) -> void:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = material
	mesh.position = local_pos
	mesh.rotation.y = rotation
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mesh)

func _build_monuments() -> void:
	var stone: StandardMaterial3D = _make_material(STONE)
	var edge: StandardMaterial3D = _make_material(EDGE)
	var glow: StandardMaterial3D = _make_material(GLOW, true)
	for i in range(LORE.size()):
		var entry: Dictionary = LORE[i]
		var pillar: Node3D = Node3D.new()
		pillar.name = "Vestigio_%d" % (i + 1)
		pillar.position = entry["position"]
		add_child(pillar)
		_points.append(pillar.global_position)
		# Pedestal de piedra fragmentado; sin CollisionShape3D.
		_add_box(pillar, Vector3(0, -0.30, 0), Vector3(2.0, 0.50, 1.4), stone, 0.10)
		_add_box(pillar, Vector3(0, 0.85, 0), Vector3(1.15, 2.05, 0.45), stone, -0.12)
		_add_box(pillar, Vector3(0.08, 1.82, 0), Vector3(1.25, 0.24, 0.52), edge, -0.08)
		_add_box(pillar, Vector3(0, 0.9, -0.275), Vector3(0.70, 0.05, 0.08), glow)
		_add_box(pillar, Vector3(0, 1.17, -0.28), Vector3(0.45, 0.05, 0.08), glow)
		_add_box(pillar, Vector3(0, 0.63, -0.28), Vector3(0.45, 0.05, 0.08), glow)

func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.name = "LoreUILayer"
	_layer.layer = 35
	add_child(_layer)
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_root)

	_hint = Label.new()
	_hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_hint.position = Vector2(-175.0, -100.0)
	_hint.custom_minimum_size = Vector2(350.0, 28.0)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_color_override("font_color", PARCHMENT)
	_hint.add_theme_font_size_override("font_size", 16)
	_hint.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	_hint.add_theme_constant_override("shadow_offset_x", 2)
	_hint.add_theme_constant_override("shadow_offset_y", 2)
	_hint.visible = false
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_hint)

	_veil = ColorRect.new()
	_veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	_veil.color = Color(0.02, 0.02, 0.06, 0.78)
	_veil.visible = false
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_veil)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -350.0
	_panel.offset_top = -150.0
	_panel.offset_right = 350.0
	_panel.offset_bottom = 150.0
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.045, 0.105, 0.95)
	style.border_color = Color(0.57, 0.29, 0.40, 0.87)
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	_panel.add_theme_stylebox_override("panel", style)
	_panel.visible = false
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_panel)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 15)
	_panel.add_child(column)

	_heading = Label.new()
	_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_heading.add_theme_font_size_override("font_size", 25)
	_heading.add_theme_color_override("font_color", PARCHMENT)
	column.add_child(_heading)

	_body = Label.new()
	_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body.add_theme_font_size_override("font_size", 19)
	_body.add_theme_color_override("font_color", Color(0.83, 0.76, 0.82))
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(610.0, 135.0)
	column.add_child(_body)

	_footer = Label.new()
	_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_footer.add_theme_font_size_override("font_size", 13)
	_footer.add_theme_color_override("font_color", Color(0.65, 0.61, 0.71))
	column.add_child(_footer)

func _open_reading(index: int) -> void:
	if _opened or index < 0 or index >= LORE.size():
		return
	_opened = true
	_found[index] = true
	var entry: Dictionary = LORE[index]
	_heading.text = entry["title"]
	_body.text = entry["text"]
	_footer.text = "F / ESC · CERRAR    |    FRAGMENTOS: %d / 3" % _found.size()
	_hint.visible = false
	_veil.visible = true
	_panel.visible = true

func _close_reading() -> void:
	_opened = false
	_veil.visible = false
	_panel.visible = false
