extends Node3D

# La pausa se gestiona exclusivamente en pausemenu.gd para evitar que
# una misma tecla pause y reanude el juego en el mismo evento.

@export_group("Intro cinematográfica")
@export var play_intro_on_start: bool = true
@export_range(0.5, 8.0, 0.1) var intro_duration: float = 4.4
@export_range(10.0, 35.0, 0.5) var intro_start_distance: float = 21.0
@export_range(3.0, 16.0, 0.5) var intro_start_height: float = 8.5
@export_range(0.0, 3.0, 0.1) var title_fade_time: float = 0.35
@export_range(0.0, 3.0, 0.1) var end_delay: float = 0.15
@export var boss_title: String = "EL QUE SOSTIENE"
@export var boss_subtitle: String = "Aquel que soporta el peso del abismo"

var _player: Node = null
var _boss: Node3D = null
var _player_camera: Camera3D = null
var _player_hud: CanvasLayer = null
var _intro_camera: Camera3D = null
var _intro_layer: CanvasLayer = null
var _intro_root: Control = null
var _top_bar: ColorRect = null
var _bottom_bar: ColorRect = null
var _title_label: Label = null
var _subtitle_label: Label = null
var _skip_label: Label = null
var _intro_active: bool = false
var _intro_finished: bool = false
var _camera_tween: Tween = null
var _overlay_tween: Tween = null
var _fade_rect: ColorRect = null
var _pulse_rect: ColorRect = null
var _ending_intro: bool = false

func _ready() -> void:
	_cache_nodes()
	# Vestigios ocultos temporalmente por decisión de diseño.
	# _build_lore_monuments()
	_build_intro_overlay()
	_build_tutorial()
	if play_intro_on_start:
		call_deferred("_start_intro")

func _unhandled_input(event: InputEvent) -> void:
	if _intro_active:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
				_skip_intro()
		return
	# Teclas 1-5: cambian la paleta / variante visual del coloso (hoja de concepto).
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.keycode
		if k >= KEY_1 and k <= KEY_5:
			var pal := get_node_or_null("Palette")
			if pal and pal.has_method("apply"):
				pal.apply(k - KEY_0)

func _cache_nodes() -> void:
	_player = get_node_or_null("Player")
	_boss = get_node_or_null("DummyEnemy") as Node3D
	if _player:
		_player_camera = _player.get_node_or_null("CameraPivot/SpringArm3D/Camera3D") as Camera3D
		_player_hud = _player.get_node_or_null("HUD") as CanvasLayer

func _build_intro_overlay() -> void:
	_intro_layer = CanvasLayer.new()
	_intro_layer.name = "IntroLayer"
	_intro_layer.layer = 40
	add_child(_intro_layer)

	_intro_root = Control.new()
	_intro_root.name = "IntroRoot"
	_intro_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_intro_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_intro_root.visible = false
	_intro_layer.add_child(_intro_root)

	_fade_rect = ColorRect.new()
	_fade_rect.name = "IntroFade"
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.color = Color(0.015, 0.012, 0.035, 1.0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.modulate.a = 0.0
	_intro_root.add_child(_fade_rect)

	_pulse_rect = ColorRect.new()
	_pulse_rect.name = "FinalPulse"
	_pulse_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pulse_rect.color = Color(0.70, 0.16, 0.30, 0.20)
	_pulse_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pulse_rect.modulate.a = 0.0
	_intro_root.add_child(_pulse_rect)

	_top_bar = ColorRect.new()
	_top_bar.name = "TopBar"
	_top_bar.color = Color(0.0, 0.0, 0.0, 1.0)
	_top_bar.anchor_right = 1.0
	_top_bar.anchor_bottom = 0.18
	_top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top_bar.modulate.a = 0.0
	_intro_root.add_child(_top_bar)

	_bottom_bar = ColorRect.new()
	_bottom_bar.name = "BottomBar"
	_bottom_bar.color = Color(0.0, 0.0, 0.0, 1.0)
	_bottom_bar.anchor_top = 0.82
	_bottom_bar.anchor_right = 1.0
	_bottom_bar.anchor_bottom = 1.0
	_bottom_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bottom_bar.modulate.a = 0.0
	_intro_root.add_child(_bottom_bar)

	_title_label = Label.new()
	_title_label.name = "Title"
	_title_label.text = boss_title
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.anchor_left = 0.18
	_title_label.anchor_top = 0.10
	_title_label.anchor_right = 0.82
	_title_label.anchor_bottom = 0.22
	_title_label.add_theme_font_size_override("font_size", 39)
	_title_label.add_theme_constant_override("outline_size", 2)
	_title_label.add_theme_color_override("font_outline_color", Color(0.15, 0.07, 0.16))
	_title_label.add_theme_color_override("font_color", Color(0.95, 0.92, 0.84))
	_title_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.7))
	_title_label.add_theme_constant_override("shadow_offset_x", 2)
	_title_label.add_theme_constant_override("shadow_offset_y", 2)
	_title_label.modulate.a = 0.0
	_intro_root.add_child(_title_label)

	_subtitle_label = Label.new()
	_subtitle_label.name = "Subtitle"
	_subtitle_label.text = boss_subtitle
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_subtitle_label.anchor_left = 0.16
	_subtitle_label.anchor_top = 0.18
	_subtitle_label.anchor_right = 0.84
	_subtitle_label.anchor_bottom = 0.28
	_subtitle_label.add_theme_font_size_override("font_size", 15)
	_subtitle_label.add_theme_color_override("font_color", Color(0.83, 0.73, 0.84))
	_subtitle_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.65))
	_subtitle_label.add_theme_constant_override("shadow_offset_x", 2)
	_subtitle_label.add_theme_constant_override("shadow_offset_y", 2)
	_subtitle_label.modulate.a = 0.0
	_intro_root.add_child(_subtitle_label)

	_skip_label = Label.new()
	_skip_label.name = "SkipHint"
	_skip_label.text = "ESPACIO / ENTER · OMITIR"
	_skip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_skip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_skip_label.anchor_left = 0.32
	_skip_label.anchor_top = 0.90
	_skip_label.anchor_right = 0.68
	_skip_label.anchor_bottom = 0.97
	_skip_label.add_theme_font_size_override("font_size", 12)
	_skip_label.add_theme_color_override("font_color", Color(0.70, 0.68, 0.75, 0.85))
	_skip_label.modulate.a = 0.0
	_intro_root.add_child(_skip_label)

func _start_intro() -> void:
	if _intro_finished or _intro_active:
		return
	if not is_instance_valid(_player) or not is_instance_valid(_boss) or not is_instance_valid(_player_camera):
		return
	_intro_active = true
	_intro_root.visible = true
	_set_hud_visible(false)
	_set_player_enabled(false)
	_set_boss_enabled(false)
	_create_intro_camera()

	_intro_camera.global_transform = _make_intro_transform()
	_intro_camera.current = true
	_fade_rect.modulate.a = 1.0
	_pulse_rect.modulate.a = 0.0
	for control in [_top_bar, _bottom_bar, _title_label, _subtitle_label, _skip_label]:
		control.modulate.a = 0.0

	_overlay_tween = create_tween()
	_overlay_tween.set_parallel(true)
	_overlay_tween.tween_property(_fade_rect, "modulate:a", 0.0, 0.85)
	_overlay_tween.tween_property(_top_bar, "modulate:a", 1.0, title_fade_time).set_delay(0.35)
	_overlay_tween.tween_property(_bottom_bar, "modulate:a", 1.0, title_fade_time).set_delay(0.35)
	_overlay_tween.tween_property(_title_label, "modulate:a", 1.0, 0.65).set_delay(0.50)
	_overlay_tween.tween_property(_subtitle_label, "modulate:a", 1.0, 0.75).set_delay(0.75)
	_overlay_tween.tween_property(_skip_label, "modulate:a", 0.85, 0.50).set_delay(0.9)

	_camera_tween = create_tween()
	_camera_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_camera_tween.tween_property(_intro_camera, "global_transform", _player_camera.global_transform, intro_duration)
	_camera_tween.finished.connect(_finish_intro)

func _create_intro_camera() -> void:
	if is_instance_valid(_intro_camera):
		_intro_camera.queue_free()
	_intro_camera = Camera3D.new()
	_intro_camera.name = "IntroCamera"
	_intro_camera.current = true
	_intro_camera.fov = _player_camera.fov if _player_camera else 75.0
	add_child(_intro_camera)

func _make_intro_transform() -> Transform3D:
	var boss_origin: Vector3 = _boss.global_position
	var player_origin: Vector3 = (_player as Node3D).global_position
	var to_player: Vector3 = player_origin - boss_origin
	to_player.y = 0.0
	if to_player.length() < 0.001:
		to_player = Vector3.FORWARD
	var direction: Vector3 = to_player.normalized()
	# Cámara situada delante del jefe, en dirección al jugador, con encuadre amplio.
	var position: Vector3 = boss_origin + direction * intro_start_distance + Vector3.UP * intro_start_height
	var target: Vector3 = boss_origin + Vector3.UP * 5.0
	var basis: Basis = Basis.looking_at((target - position).normalized(), Vector3.UP)
	return Transform3D(basis, position)

func _skip_intro() -> void:
	if not _intro_active:
		return
	_finish_intro(true)

func _finish_intro(skipped: bool = false) -> void:
	if _ending_intro or _intro_finished:
		return
	_ending_intro = true
	_intro_active = false
	if _camera_tween and _camera_tween.is_running():
		_camera_tween.kill()
	if _overlay_tween and _overlay_tween.is_running():
		_overlay_tween.kill()

	if not skipped:
		# Pulso final breve: una transición de la presentación al combate.
		_pulse_rect.modulate.a = 0.65
		var pulse_tween: Tween = create_tween()
		pulse_tween.tween_property(_pulse_rect, "modulate:a", 0.0, 0.30)
		var text_tween: Tween = create_tween()
		text_tween.set_parallel(true)
		for control in [_top_bar, _bottom_bar, _title_label, _subtitle_label, _skip_label]:
			text_tween.tween_property(control, "modulate:a", 0.0, 0.20)
		await get_tree().create_timer(end_delay).timeout

	# La cámara del personaje toma el control explícitamente ANTES de liberar la temporal.
	if is_instance_valid(_player_camera):
		_player_camera.current = true
	if is_instance_valid(_intro_camera):
		_intro_camera.queue_free()
		_intro_camera = null
	_intro_root.visible = false
	_intro_finished = true
	_ending_intro = false
	_set_hud_visible(true)
	_set_player_enabled(true)
	_set_boss_enabled(true)

func _set_hud_visible(value: bool) -> void:
	if is_instance_valid(_player_hud):
		_player_hud.visible = value

func _set_player_enabled(enabled: bool) -> void:
	if _player == null:
		return
	_player.set_process(enabled)
	_player.set_physics_process(enabled)
	_player.set_process_input(enabled)
	_player.set_process_unhandled_input(enabled)

func _set_boss_enabled(enabled: bool) -> void:
	if _boss == null:
		return
	_boss.set_process(enabled)
	_boss.set_physics_process(enabled)
	_boss.set_process_input(enabled)
	_boss.set_process_unhandled_input(enabled)

func _build_lore_monuments() -> void:
	# Vestigios independientes: no cambian las colisiones ni la IA del combate.
	var lore_script: Script = load("res://scenes/arena_lore.gd") as Script
	if lore_script == null:
		push_warning("No se encontró scenes/arena_lore.gd")
		return
	var monuments: Node3D = Node3D.new()
	monuments.name = "VestigiosDelUmbral"
	monuments.set_script(lore_script)
	add_child(monuments)

func _build_tutorial() -> void:
	# Tutor contextual y opcional. No modifica la IA, el HUD ni los controles.
	var script: Script = load("res://scenes/arena_tutorial.gd") as Script
	if script == null:
		push_warning("Falta scenes/arena_tutorial.gd")
		return
	var tutorial: Node = Node.new()
	tutorial.name = "TutorialOrganico"
	tutorial.set_script(script)
	add_child(tutorial)
