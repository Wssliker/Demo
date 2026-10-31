extends RefCounted
## Estética unificada de interfaz: tinta, piedra y acentos carmesí.

const IVORY := Color(0.91, 0.88, 0.85)
const MUTED := Color(0.68, 0.67, 0.73)
const RED := Color(0.78, 0.24, 0.33)
const HOVER := Color(0.98, 0.52, 0.53)

static func style_button(b: Button, primary: bool = false, font_size: int = 19) -> void:
    b.add_theme_font_size_override("font_size", font_size)
    b.add_theme_color_override("font_color", IVORY if not primary else Color(1.0, 0.86, 0.85))
    b.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.90))
    b.add_theme_color_override("font_pressed_color", Color(1.0, 0.92, 0.90))
    b.add_theme_color_override("font_focus_color", IVORY)
    b.add_theme_color_override("font_disabled_color", MUTED.darkened(0.25))
    b.add_theme_constant_override("h_separation", 12)
    var normal := StyleBoxFlat.new()
    normal.bg_color = Color(0.02, 0.025, 0.045, 0.22 if not primary else 0.64)
    normal.content_margin_left = 18.0
    normal.content_margin_right = 14.0
    normal.set_corner_radius_all(1)
    if primary:
        normal.border_color = Color(0.71, 0.20, 0.30, 0.86)
        normal.border_width_left = 3
    var hover := normal.duplicate() as StyleBoxFlat
    hover.bg_color = Color(0.47, 0.10, 0.18, 0.85)
    hover.border_color = Color(0.98, 0.49, 0.51)
    hover.border_width_left = 4
    var pressed := hover.duplicate() as StyleBoxFlat
    pressed.bg_color = Color(0.29, 0.07, 0.13, 0.92)
    var focus := StyleBoxFlat.new()
    focus.bg_color = Color(0, 0, 0, 0)
    focus.border_color = Color(0.85, 0.51, 0.56, 0.75)
    focus.set_border_width_all(1)
    b.add_theme_stylebox_override("normal", normal)
    b.add_theme_stylebox_override("hover", hover)
    b.add_theme_stylebox_override("pressed", pressed)
    b.add_theme_stylebox_override("focus", focus)
    b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    b.alignment = HORIZONTAL_ALIGNMENT_LEFT

static func add_veil(root: Control, opacity: float = 0.78, width_fraction: float = 0.55) -> ColorRect:
    var shade := ColorRect.new()
    shade.name = "ConceptInkVeil"
    shade.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
    shade.anchor_left = 0.0
    shade.anchor_top = 0.0
    shade.anchor_right = width_fraction
    shade.anchor_bottom = 1.0
    shade.offset_left = 0.0
    shade.offset_right = 0.0
    shade.offset_top = 0.0
    shade.offset_bottom = 0.0
    shade.color = Color(0.025, 0.025, 0.045, opacity)
    shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(shade)
    root.move_child(shade, 1)
    return shade

static func style_title(label: Label, size: int = 46) -> void:
    label.add_theme_font_size_override("font_size", size)
    label.add_theme_color_override("font_color", IVORY)
    label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.65))
    label.add_theme_constant_override("shadow_offset_x", 2)
    label.add_theme_constant_override("shadow_offset_y", 3)

static func make_caption(parent: Control, text: String, position: Vector2, size: Vector2) -> Label:
    var l := Label.new()
    l.text = text
    l.position = position
    l.size = size
    l.add_theme_font_size_override("font_size", 13)
    l.add_theme_color_override("font_color", MUTED)
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(l)
    return l
