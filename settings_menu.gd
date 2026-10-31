extends Control
class_name SettingsMenu
## Menú de AJUSTES (hoja de concepto): pestañas + filas de opciones.
## Se usa como superposición: el que lo abre se encarga de mostrarlo/ocultarlo.

const VISUAL := preload("res://menu_visuals.gd")

signal closed

const BONE := Color(0.91, 0.88, 0.85)
const GOLD := Color(0.86, 0.69, 0.72)
const CRIMSON := Color(1.0, 0.34, 0.34)

var _box: VBoxContainer
var _active_tab: String = "audio"
var _tab_row: HBoxContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_concept_style()
	_box = get_node_or_null("Rows") as VBoxContainer
	_setup_scroll()
	_build_tabs()
	var back := get_node_or_null("BackButton") as Button
	if back:
		_style_button(back, true)
		back.pressed.connect(_close)
	_populate()

func _setup_scroll() -> void:
	if _box == null:
		return
	# La pantalla debe poder mostrar todos los ajustes a 720p sin recortar filas.
	var scroll := ScrollContainer.new()
	scroll.name = "SettingsScroll"
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.anchor_left = 0.5
	scroll.anchor_right = 0.5
	scroll.anchor_top = 0.5
	scroll.anchor_bottom = 0.5
	scroll.offset_left = -345.0
	scroll.offset_right = 365.0
	scroll.offset_top = -135.0
	scroll.offset_bottom = 220.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_box.get_parent().add_child(scroll)
	_box.reparent(scroll)
	_box.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_box.add_theme_constant_override("separation", 9)


func _build_tabs() -> void:
	_tab_row = HBoxContainer.new()
	_tab_row.name = "SettingsTabs"
	_tab_row.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_tab_row.anchor_left = 0.5
	_tab_row.anchor_right = 0.5
	_tab_row.offset_left = -345.0
	_tab_row.offset_right = 365.0
	_tab_row.offset_top = 130.0
	_tab_row.offset_bottom = 171.0
	_tab_row.add_theme_constant_override("separation", 12)
	add_child(_tab_row)
	for entry in [["audio", "AUDIO"], ["video", "GRÁFICOS"], ["access", "ACCESIBILIDAD"]]:
		var tab_id: String = entry[0]
		var button := Button.new()
		button.text = entry[1]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = false
		button.add_theme_font_size_override("font_size", 16)
		button.add_theme_color_override("font_color", BONE)
		button.pressed.connect(func() -> void:
			_active_tab = tab_id
			_populate()
		)
		_tab_row.add_child(button)

func _settings() -> Node:
	return get_node_or_null("/root/Settings")

## (Re)construye las filas según el idioma actual. Cada opción aplica y guarda.
func _populate() -> void:
	var s := _settings()
	if s == null or _box == null:
		return
	for c in _box.get_children():
		_box.remove_child(c)
		c.queue_free()
	var title := get_node_or_null("Title") as Label
	if title:
		title.text = s.t("ajustes")
	var back := get_node_or_null("BackButton") as Button
	if back:
		back.text = s.t("volver")

	if _tab_row:
		for child in _tab_row.get_children():
			var b := child as Button
			if b:
				b.modulate = Color(1.0, 0.48, 0.53) if ((b.text == "AUDIO" and _active_tab == "audio") or (b.text == "GRÁFICOS" and _active_tab == "video") or (b.text == "ACCESIBILIDAD" and _active_tab == "access")) else Color(0.75, 0.75, 0.8)

	match _active_tab:
		"audio":
			_add_slider(_box, s.t("vol_master"), s.master_volume, 0.0, 1.0,
				func(v): s.master_volume = v; s.set_volume("Master", v); s.save_settings())
			_add_slider(_box, s.t("vol_music"), s.music_volume, 0.0, 1.0,
				func(v): s.music_volume = v; s.set_volume("Music", v); s.save_settings())
			_add_slider(_box, s.t("vol_sfx"), s.sfx_volume, 0.0, 1.0,
				func(v): s.sfx_volume = v; s.set_volume("SFX", v); s.save_settings())
		"video":
			_add_choice(_box, s.t("modo_pantalla"),
				["Ventana con bordes", "Ventana sin bordes", "Pantalla completa"] if s.language == "es" else ["Windowed", "Borderless", "Fullscreen"],
				[0, 1, 2], s.display_mode,
				func(v): s.display_mode = v; s.apply_display_mode(); s.save_settings())
			_add_slider(_box, s.t("brillo"), s.brightness, 0.5, 1.5,
				func(v): s.brightness = v; s.set_brightness(v); s.save_settings())
			_add_choice(_box, s.t("calidad_grafica"), ["Baja", "Media", "Alta"] if s.language == "es" else ["Low", "Medium", "High"], [0, 1, 2], s.graphics_quality,
				func(v): s.graphics_quality = v; s.apply_video(); s.save_settings())
			_add_toggle(_box, s.t("niebla_vol"), s.volumetric_fog,
				func(v): s.volumetric_fog = v; s.apply_video(); s.save_settings())
			_add_toggle(_box, s.t("resplandor"), s.screen_glow,
				func(v): s.screen_glow = v; s.apply_video(); s.save_settings())
		"access":
			_add_choice(_box, s.t("idioma"), ["Español", "English"], ["es", "en"], s.language,
				func(v): s.language = v; s.save_settings(); _populate())
			_add_toggle(_box, s.t("subtitulos"), s.subtitles,
				func(v): s.subtitles = v; s.save_settings())
			_add_toggle(_box, s.t("vibracion"), s.vibration,
				func(v): s.vibration = v; s.save_settings())
			_add_toggle(_box, s.t("destellos"), s.reduce_flashes,
				func(v): s.reduce_flashes = v; s.apply_video(); s.save_settings())

func _close() -> void:
	var s := _settings()
	if s:
		s.save_settings()
	closed.emit()
	queue_free()

# --- Fábrica de filas --------------------------------------------------------

func _make_row(box: VBoxContainer, label: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	var title := Label.new()
	title.text = label
	title.custom_minimum_size = Vector2(250, 0)
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", BONE)
	row.add_child(title)
	return row

func _value_label() -> Label:
	var value := Label.new()
	value.custom_minimum_size = Vector2(200, 0)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.add_theme_font_size_override("font_size", 19)
	value.add_theme_color_override("font_color", GOLD)
	return value

func _arrow(row: HBoxContainer, glyph: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = glyph
	b.custom_minimum_size = Vector2(34, 30)
	_style_button(b, false)
	b.pressed.connect(on_press)
	row.add_child(b)
	return b

## Fila de opción (◀ valor ▶). `values` guarda el valor; `display` su etiqueta.
func _add_choice(box: VBoxContainer, label: String, display: Array, values: Array, current: Variant, on_change: Callable) -> void:
	var row := _make_row(box, label)
	var idx := [maxi(values.find(current), 0)]
	var value := _value_label()
	value.text = str(display[idx[0]])
	var apply := func(delta: int):
		idx[0] = (idx[0] + delta + values.size()) % values.size()
		value.text = str(display[idx[0]])
		on_change.call(values[idx[0]])
	_arrow(row, "◀", func(): apply.call(-1))
	row.add_child(value)
	_arrow(row, "▶", func(): apply.call(1))

## Fila Sí/No (usa el idioma actual).
func _add_toggle(box: VBoxContainer, label: String, current: bool, on_change: Callable) -> void:
	var s := _settings()
	var yes: String = "Sí" if s == null else s.t("si")
	var no: String = "No" if s == null else s.t("no")
	_add_choice(box, label, [yes, no], [true, false], current, on_change)

## Fila de valor numérico (◀ % ▶) entre minv y maxv.
func _add_slider(box: VBoxContainer, label: String, current: float, minv: float, maxv: float, on_change: Callable) -> void:
	var row := _make_row(box, label)
	var amount := [clampf(current, minv, maxv)]
	var value := _value_label()
	var refresh := func():
		value.text = str(int(round(amount[0] / maxv * 100.0))) + "%"
	refresh.call()
	var step := func(delta: float):
		amount[0] = clampf(amount[0] + delta, minv, maxv)
		refresh.call()
		on_change.call(amount[0])
	_arrow(row, "◀", func(): step.call(-0.1))
	row.add_child(value)
	_arrow(row, "▶", func(): step.call(0.1))

func _style_button(b: Button, accent: bool) -> void:
	b.add_theme_font_size_override("font_size", 20 if accent else 22)
	b.add_theme_color_override("font_color", CRIMSON if accent else BONE)
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.55, 0.5))
	var empty := StyleBoxEmpty.new()
	for s in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(s, empty)
func _apply_concept_style() -> void:
	var bg: ColorRect = $Bg
	bg.color = Color(0.018, 0.023, 0.043, 0.97)
	var title: Label = $Title
	VISUAL.style_title(title, 42)
	var rows: VBoxContainer = $Rows
	rows.add_theme_constant_override("separation", 9)
	rows.custom_minimum_size = Vector2(690.0, 0.0)
	title.anchor_left = 0.5
	title.anchor_right = 0.5
	title.offset_left = -325.0
	title.offset_right = 345.0
	title.offset_top = 56.0
	title.offset_bottom = 114.0
	var back: Button = $BackButton
	back.anchor_left = 0.5
	back.anchor_right = 0.5
	back.anchor_top = 1.0
	back.anchor_bottom = 1.0
	back.offset_left = -325.0
	back.offset_right = -80.0
	back.offset_top = -74.0
	back.offset_bottom = -28.0
	var bg_texture := TextureRect.new()
	bg_texture.name = "ConceptBackground"
	bg_texture.texture = load("res://assets/generated/ui_menu_bg.png")
	bg_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_texture.modulate = Color(0.45, 0.46, 0.61, 0.25)
	bg_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg_texture)
	move_child(bg_texture, 1)
	var divider := ColorRect.new()
	divider.name = "AccentLine"
	divider.color = Color(0.71, 0.22, 0.33, 0.9)
	divider.anchor_left = 0.5
	divider.anchor_right = 0.5
	divider.offset_left = -325.0
	divider.offset_right = 325.0
	divider.offset_top = 123.0
	divider.offset_bottom = 125.0
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(divider)
