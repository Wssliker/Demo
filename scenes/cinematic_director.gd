extends CanvasLayer
## Secuencias visuales cortas; no altera la cámara ni los controles del jugador.
signal sequence_finished

@export var intro_duration: float = 3.2
@export var victory_duration: float = 1.8
@export var defeat_duration: float = 1.2

var _running: bool = false
var _seconds_left: float = 0.0
var _screen: Control
var _top: ColorRect
var _bottom: ColorRect
var _veil: ColorRect
var _heading: Label
var _subtitle: Label
var _skip: Label

func _ready() -> void:
	name = "CinematicDirector"
	layer = 85
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_overlay()

func _build_overlay() -> void:
	_screen = Control.new()
	_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_screen)
	_veil = ColorRect.new()
	_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_veil.color = Color(0.035, 0.045, 0.08, 0.0)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen.add_child(_veil)
	_top = ColorRect.new()
	_top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_top.custom_minimum_size.y = 72.0
	_top.offset_bottom = 72.0
	_top.color = Color(0.025, 0.03, 0.055, 0.96)
	_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen.add_child(_top)
	_bottom = ColorRect.new()
	_bottom.anchor_top = 1.0
	_bottom.anchor_bottom = 1.0
	_bottom.anchor_right = 1.0
	_bottom.offset_top = -72.0
	_bottom.color = Color(0.025, 0.03, 0.055, 0.96)
	_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen.add_child(_bottom)
	_heading = Label.new()
	_heading.anchor_left = 0.1
	_heading.anchor_right = 0.9
	_heading.anchor_top = 0.40
	_heading.anchor_bottom = 0.54
	_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_heading.add_theme_font_size_override("font_size", 37)
	_heading.add_theme_color_override("font_color", Color("f0e5db"))
	_heading.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_heading.add_theme_constant_override("shadow_offset_x", 2)
	_heading.add_theme_constant_override("shadow_offset_y", 3)
	_heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen.add_child(_heading)
	_subtitle = Label.new()
	_subtitle.anchor_left = 0.12
	_subtitle.anchor_right = 0.88
	_subtitle.anchor_top = 0.56
	_subtitle.anchor_bottom = 0.64
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.add_theme_font_size_override("font_size", 17)
	_subtitle.add_theme_color_override("font_color", Color("c9a7b4"))
	_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen.add_child(_subtitle)
	_skip = Label.new()
	_skip.anchor_left = 0.56
	_skip.anchor_right = 0.97
	_skip.anchor_top = 0.94
	_skip.anchor_bottom = 0.99
	_skip.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_skip.add_theme_font_size_override("font_size", 12)
	_skip.add_theme_color_override("font_color", Color("b8a7b7"))
	_skip.text = "ESPACIO / ENTER  ·  OMITIR"
	_skip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen.add_child(_skip)
	_screen.visible = false

func _process(delta: float) -> void:
	if not _running:
		return
	_seconds_left -= delta
	if _seconds_left <= 0.0:
		_finish()

func _unhandled_input(event: InputEvent) -> void:
	if not _running:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			get_viewport().set_input_as_handled()
			_finish()

func _start(title: String, line: String, seconds: float, hue: Color) -> void:
	if _running:
		_finish()
	_heading.text = title
	_subtitle.text = line
	_heading.add_theme_color_override("font_color", hue)
	_seconds_left = seconds
	_running = true
	_screen.visible = true
	_screen.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(_screen, "modulate:a", 1.0, 0.28)

func _finish() -> void:
	if not _running:
		return
	_running = false
	_screen.visible = false
	sequence_finished.emit()

func play_intro() -> void:
	_start("EL QUE SOSTIENE", "Lo que permanece no siempre debe despertar.", intro_duration, Color("e4d7d4"))
	await sequence_finished

func play_victory() -> void:
	_start("EL SILENCIO PERMANECE", "Has derribado al guardián. ¿Qué sostenía?", victory_duration, Color("e3c0ac"))
	await sequence_finished

func play_defeat() -> void:
	_start("LA PRESENCIA PERDURA", "La piedra recuerda cada caída.", defeat_duration, Color("e28c9b"))
	await sequence_finished
