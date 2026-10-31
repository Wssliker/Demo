extends CanvasLayer
## HUD estético acorde al concepto gouache / horror cósmico.

@onready var damage_flash: ColorRect = $Control/DamageFlash
@onready var low_health: ColorRect = $Control/LowHealthVignette

@onready var health_bar: ProgressBar = $Control/PlayerPanel/HealthBar
@onready var health_label: Label = $Control/PlayerPanel/HealthLabel
@onready var combo_label: Label = $Control/PlayerPanel/ComboLabel
@onready var dash_label: Label = $Control/PlayerPanel/DashLabel

@onready var boss_panel: Control = $Control/BossPanel
@onready var boss_name_label: Label = $Control/BossPanel/BossName
@onready var boss_health_bar: ProgressBar = $Control/BossPanel/BossBar

@onready var banner: Label = $Control/Banner

@onready var end_panel: ColorRect = $Control/EndGamePanel
@onready var title_label: Label = $Control/EndGamePanel/CenterContainer/VBoxContainer/TitleLabel
@onready var rank_label: Label = $Control/EndGamePanel/CenterContainer/VBoxContainer/RankLabel
@onready var cause_label: Label = $Control/EndGamePanel/CenterContainer/VBoxContainer/CauseLabel
@onready var stats_label: Label = $Control/EndGamePanel/CenterContainer/VBoxContainer/StatsLabel
@onready var tip_label: Label = $Control/EndGamePanel/CenterContainer/VBoxContainer/TipLabel
@onready var restart_button: Button = $Control/EndGamePanel/CenterContainer/VBoxContainer/RestartButton
@onready var options_button: Button = $Control/EndGamePanel/CenterContainer/VBoxContainer/OptionsButton
@onready var quit_button: Button = $Control/EndGamePanel/CenterContainer/VBoxContainer/QuitButton

static var attempt_count: int = 0
var _fight_time: float = 0.0
var _victory_recorded: bool = false
var _results_pending: bool = false
const RECORD_PATH: String = "user://bgo_combat_records.cfg"
var _damage_taken: int = 0
var _settings: Control = null
var _result_frame: PanelContainer
var _result_veil: ColorRect
var _help_hint: Label

@export_group("Feedback de combate")
@export var feedback_avisos: bool = true
@export_range(0.25, 2.0, 0.05) var feedback_duracion: float = 0.65
@export_range(0.0, 1.0, 0.05) var feedback_opacidad: float = 0.9
var _combat_notice: Label = null
var _notice_tween: Tween = null
var _flash_tween: Tween = null

const BAR_FRAME := preload("res://assets/generated/hud_bar_frame.png")
const BAR_FILL := preload("res://assets/generated/hud_bar_fill.png")
const EMBLEM := preload("res://assets/generated/ui_emblem.png")
const BOSSBAR := preload("res://assets/generated/ui_bossbar.png")
const CROSSHAIR := preload("res://assets/generated/ui_crosshair.png")
const RING_TEX := preload("res://assets/generated/fx_ring.png")
const VICTORY_ART := preload("res://assets/generated/bgo_result_victory.png")
const DEFEAT_ART := preload("res://assets/generated/bgo_result_defeat.png")

const BONE := Color(0.95, 0.92, 0.84)
const CRIMSON := Color(0.72, 0.09, 0.16)
const GOLD := Color(0.94, 0.78, 0.35)
const VIOLET := Color(0.55, 0.3, 0.72)
const DEEP := Color(0.06, 0.03, 0.11, 0.85)

const TIPS := {
	"Beam": "El rayo se congela antes de disparar: esquívalo con dash al ver el destello.",
	"Rain": "Mira el aro rojo en el suelo y sal de él antes de que caiga la tinta.",
	"Eyes": "Los proyectiles te persiguen 2 s: rompe su línea con un dash lateral.",
	"Melee": "Cuando el círculo marque el suelo, retrocede: el coloso aplasta esa zona.",
	"Caída": "No dejes que el borde de la arena te trague.",
}

var _player_max_health: int = 100
var _eye_gate_hint: Label = null
var _boss_health_tween: Tween = null

func _ready() -> void:
	end_panel.visible = false
	boss_panel.modulate.a = 0.0
	banner.modulate.a = 0.0
	damage_flash.color = Color(0, 0, 0, 0)
	low_health.modulate.a = 1.0
	if low_health.material is ShaderMaterial:
		(low_health.material as ShaderMaterial).set_shader_parameter("intensity", 0.0)
	_style_everything()
	_build_extras()
	_build_combat_hud()
	_build_eye_gate_hint()
	_build_result_style()
	_build_help_hint()
	_build_combat_notice()
	health_label.text = str(_player_max_health) + " / " + str(_player_max_health)
	attempt_count += 1
	restart_button.pressed.connect(_on_restart_pressed)
	options_button.pressed.connect(_open_settings)
	quit_button.pressed.connect(_on_quit_pressed)

func _process(_delta: float) -> void:
	if not get_tree().paused and not end_panel.visible and not _results_pending:
		var scene: Node = get_tree().current_scene
		if scene == null or not ("_intro_finished" in scene) or bool(scene.get("_intro_finished")):
			_fight_time += _delta
	# Pip de dash: leemos el estado del jugador (somos su hijo).
	var p := get_parent()
	if p and "can_dash" in p:
		if p.can_dash:
			dash_label.text = "DASH  ●"
			dash_label.modulate = GOLD
		else:
			dash_label.text = "DASH  ○"
			dash_label.modulate = Color(BONE.r, BONE.g, BONE.b, 0.35)
	_update_combat_hud()

func _style_everything() -> void:
	_style_bar(health_bar, Color("c95061"), Color("10131e"), Color("697181"))
	_style_bar(boss_health_bar, Color("d14b62"), Color("0b101b"), Color("6d657c"))
	health_label.add_theme_color_override("font_color", Color("f1e9e2"))
	health_label.add_theme_font_size_override("font_size", 12)
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	combo_label.add_theme_color_override("font_color", Color("d7c5ad"))
	combo_label.add_theme_font_size_override("font_size", 14)
	dash_label.add_theme_color_override("font_color", Color("aecad9"))
	dash_label.add_theme_font_size_override("font_size", 13)
	boss_name_label.add_theme_color_override("font_color", Color("ece1dc"))
	boss_name_label.add_theme_font_size_override("font_size", 18)
	boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_color_override("font_color", Color("d6bccd"))
	banner.add_theme_font_size_override("font_size", 34)

func _style_bar(bar: ProgressBar, fill: Color, back: Color, border: Color) -> void:
	# Forma simple y precisa: nada de texturas estiradas ni bordes de oro.
	var bg := StyleBoxFlat.new()
	bg.bg_color = back
	bg.border_color = border
	bg.set_border_width_all(1)
	bg.set_corner_radius_all(2)
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill
	fg.set_corner_radius_all(1)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)

# ---------------------------------------------------------------------------
# Extras animados (barras fantasma, agarre, furia, marcas de fase)
# ---------------------------------------------------------------------------

var _health_ghost: ProgressBar
var _boss_ghost: ProgressBar
var _grip_panel: Control
var _grip_bar: ProgressBar
var _fury_bar: ProgressBar
var _fury_pulse: Tween
var _eyes_broken: int = 0  # Progreso de ojos rotos (0-3)
var _eye_indicators: Array = []  # ColorRects sobre la barra del jefe
var _palette_label: Label      # Nombre de la variante de arena activa

func _build_extras() -> void:
	# Barras "fantasma": sangran lentamente tras el golpe (damage trail).
	_health_ghost = _make_ghost(health_bar, Color(0.76, 0.43, 0.46, 0.55))
	health_bar.get_parent().add_child(_health_ghost)
	health_bar.get_parent().move_child(_health_ghost, health_bar.get_index())

	_boss_ghost = _make_ghost(boss_health_bar, Color(0.7, 0.47, 0.58, 0.6))
	boss_health_bar.get_parent().add_child(_boss_ghost)
	boss_health_bar.get_parent().move_child(_boss_ghost, boss_health_bar.get_index())

	# (El agarre se muestra en la barra secundaria del panel del jugador.)

	# Barra de FURIA.
	_fury_bar = ProgressBar.new()
	_fury_bar.max_value = 100.0
	_fury_bar.value = 0.0
	_fury_bar.show_percentage = false
	_fury_bar.offset_top = 56.0
	_fury_bar.offset_bottom = 59.0
	_fury_bar.offset_right = 480.0
	_fury_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Estilo plano: el marco ornamental se veía como galones sueltos a esta altura.
	var fbg := StyleBoxFlat.new()
	fbg.bg_color = Color("12131f")
	fbg.set_corner_radius_all(3)
	_fury_bar.add_theme_stylebox_override("background", fbg)
	var ffill := StyleBoxFlat.new()
	ffill.bg_color = Color("a75168")
	ffill.set_corner_radius_all(3)
	_fury_bar.add_theme_stylebox_override("fill", ffill)
	boss_health_bar.get_parent().add_child(_fury_bar)
	# (Sin etiquetas ni marcas extra: la barra ornamental ya marca las fases.)

func _make_ghost(bar: ProgressBar, color: Color) -> ProgressBar:
	var g := ProgressBar.new()
	g.max_value = bar.max_value
	g.value = bar.value
	g.show_percentage = false
	g.offset_left = bar.offset_left
	g.offset_top = bar.offset_top
	g.offset_right = bar.offset_right
	g.offset_bottom = bar.offset_bottom
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(4)
	g.add_theme_stylebox_override("fill", sb)
	var sb_bg := StyleBoxFlat.new()
	sb_bg.bg_color = Color(0, 0, 0, 0)
	g.add_theme_stylebox_override("background", sb_bg)
	return g

func update_grip(value: float, maxv: float) -> void:
	if _grip_bar == null:
		_grip_bar = _stamina
	if _grip_bar == null:
		return
	_grip_bar.max_value = maxv
	_grip_bar.value = value
	var fill := _grip_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill:
		fill.bg_color = Color("d27d80") if value / maxf(maxv, 0.001) < 0.3 else Color("7195aa")

func set_climbing(climbing: bool) -> void:
	if _stamina == null:
		return
	var target := 1.0 if climbing else 0.72
	if not is_equal_approx(_stamina.modulate.a, target):
		create_tween().tween_property(_stamina, "modulate:a", target, 0.2)

func update_fury(value: float, maxv: float) -> void:
	if _fury_bar == null:
		return
	_fury_bar.max_value = maxv
	create_tween().tween_property(_fury_bar, "value", value, 0.2)
	if value >= maxv and (_fury_pulse == null or not _fury_pulse.is_running()):
		_fury_pulse = create_tween().set_loops()
		_fury_pulse.tween_property(_fury_bar, "modulate:a", 0.4, 0.35)
		_fury_pulse.tween_property(_fury_bar, "modulate:a", 1.0, 0.35)

## Nombre de la paleta / variante de arena activa.
func set_palette_name(palette_name: String) -> void:
	if _palette_label:
		_palette_label.text = palette_name

func update_eyes_broken(eyes: int) -> void:
	_eyes_broken = eyes
	for i in _eye_indicators.size():
		if i < eyes:
			_eye_indicators[i].color = Color("4b4656")  # Ojo destruido
		else:
			_eye_indicators[i].color = Color("e9a8a6")  # Ojo intacto

# ---------------------------------------------------------------------------
# Jugador
# ---------------------------------------------------------------------------

func setup_hud(max_health: int) -> void:
	_player_max_health = max(1, max_health)
	health_bar.max_value = max_health
	health_bar.value = max_health
	if _health_ghost:
		_health_ghost.max_value = max_health
		_health_ghost.value = max_health
	health_label.text = str(max_health) + " / " + str(max_health)
	update_combo(0)

func update_health(new_health: int) -> void:
	create_tween().tween_property(health_bar, "value", new_health, 0.12)
	health_label.text = str(new_health) + " / " + str(_player_max_health)
	# Barra fantasma: sangra lentamente tras el daño.
	if _health_ghost:
		_health_ghost.max_value = health_bar.max_value
		if new_health >= _health_ghost.value:
			_health_ghost.value = new_health
		else:
			var g := create_tween()
			g.tween_interval(0.25)
			g.tween_property(_health_ghost, "value", new_health, 0.45)
	# Viñeta roja que crece al acercarse la muerte.
	var hp_ratio := float(new_health) / float(_player_max_health)
	low_health.material.set_shader_parameter("intensity", clamp(1.0 - hp_ratio * 1.6, 0.0, 0.85))

func update_combo(step: int) -> void:
	if step > 0:
		combo_label.text = "COMBO  ×" + str(step)
		combo_label.modulate.a = 1.0
		combo_label.scale = Vector2(1.15, 1.15)
		create_tween().tween_property(combo_label, "scale", Vector2.ONE, 0.12)
	else:
		combo_label.modulate.a = 0.0

func flash(color: Color, duration: float = 0.2) -> void:
	# Una animación a la vez: evita flashes superpuestos o una viñeta atascada.
	if _flash_tween and _flash_tween.is_running():
		_flash_tween.kill()
	damage_flash.color = color
	_flash_tween = create_tween()
	_flash_tween.tween_property(damage_flash, "color:a", 0.0, maxf(duration, 0.01))

func _build_combat_notice() -> void:
	_combat_notice = Label.new()
	_combat_notice.name = "CombatFeedbackNotice"
	_combat_notice.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_combat_notice.anchor_left = 0.25
	_combat_notice.anchor_right = 0.75
	_combat_notice.anchor_top = 0.68
	_combat_notice.anchor_bottom = 0.68
	_combat_notice.offset_top = -18.0
	_combat_notice.offset_bottom = 18.0
	_combat_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combat_notice.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_combat_notice.add_theme_font_size_override("font_size", 17)
	_combat_notice.add_theme_color_override("font_shadow_color", Color(0.02, 0.01, 0.04, 0.9))
	_combat_notice.add_theme_constant_override("shadow_offset_y", 2)
	_combat_notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combat_notice.modulate.a = 0.0
	$Control.add_child(_combat_notice)

func show_combat_notice(message: String, color: Color) -> void:
	if not feedback_avisos or _combat_notice == null or end_panel.visible:
		return
	if _notice_tween and _notice_tween.is_running():
		_notice_tween.kill()
	_combat_notice.text = message
	_combat_notice.add_theme_color_override("font_color", color)
	_combat_notice.modulate.a = feedback_opacidad
	_notice_tween = create_tween()
	_notice_tween.tween_interval(0.17)
	_notice_tween.tween_property(_combat_notice, "modulate:a", 0.0, maxf(feedback_duracion, 0.1))

# ---------------------------------------------------------------------------
# Jefe
# ---------------------------------------------------------------------------

func setup_boss_hud(boss_display_name: String, max_hp: int) -> void:
	boss_name_label.text = boss_display_name
	boss_health_bar.max_value = max_hp
	boss_health_bar.value = max_hp
	if _boss_ghost:
		_boss_ghost.max_value = max_hp
		_boss_ghost.value = max_hp

func boss_intro(boss_display_name: String) -> void:
	boss_name_label.text = boss_display_name
	boss_panel.modulate.a = 0.0
	var base_top := boss_panel.offset_top
	var base_bottom := boss_panel.offset_bottom
	boss_panel.offset_top = base_top + 44.0
	boss_panel.offset_bottom = base_bottom + 44.0
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(boss_panel, "modulate:a", 1.0, 0.8)
	t.tween_property(boss_panel, "offset_top", base_top, 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(boss_panel, "offset_bottom", base_bottom, 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_show_banner(boss_display_name, Color("c8b0ca"), 1.5)

func sync_boss_health_limits(new_max_hp: int, new_hp: int) -> void:
	var limit: int = maxi(new_max_hp, 1)
	var max_changed: bool = int(boss_health_bar.max_value) != limit
	if max_changed:
		if _boss_health_tween and _boss_health_tween.is_running():
			_boss_health_tween.kill()
		boss_health_bar.max_value = limit
		if _boss_ghost:
			_boss_ghost.max_value = limit
			_boss_ghost.value = clampf(_boss_ghost.value, 0.0, float(limit))
		boss_health_bar.value = clampi(new_hp, 0, limit)
		if _boss_ghost:
			_boss_ghost.value = boss_health_bar.value
	else:
		update_boss_health(clampi(new_hp, 0, limit))

func update_boss_health(new_hp: int) -> void:
	if _boss_health_tween and _boss_health_tween.is_running():
		_boss_health_tween.kill()
	_boss_health_tween = create_tween()
	_boss_health_tween.tween_property(boss_health_bar, "value", new_hp, 0.12)
	if _boss_ghost:
		_boss_ghost.max_value = boss_health_bar.max_value
		if new_hp >= _boss_ghost.value:
			_boss_ghost.value = new_hp
		else:
			var g := create_tween()
			g.tween_interval(0.25)
			g.tween_property(_boss_ghost, "value", new_hp, 0.45)

func _build_eye_gate_hint() -> void:
	_eye_gate_hint = Label.new()
	_eye_gate_hint.name = "EyeGateHint"
	_eye_gate_hint.text = ""
	_eye_gate_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_eye_gate_hint.add_theme_font_size_override("font_size", 13)
	_eye_gate_hint.add_theme_color_override("font_color", Color("e9a8a6"))
	_eye_gate_hint.offset_left = 0.0
	_eye_gate_hint.offset_right = 480.0
	_eye_gate_hint.offset_top = 64.0
	_eye_gate_hint.offset_bottom = 84.0
	_eye_gate_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_eye_gate_hint.visible = false
	boss_health_bar.get_parent().add_child(_eye_gate_hint)

func set_boss_eye_gate(active: bool, broken_count: int) -> void:
	if _eye_gate_hint == null:
		return
	_eye_gate_hint.visible = active
	if active:
		_eye_gate_hint.text = "SELLO ACTIVO  ·  ROMPE UN OJO  (%d/3)" % broken_count

func show_phase_text(text: String) -> void:
	_show_banner(text, Color(1.0, 0.35, 0.65), 2.4)

func _show_banner(text: String, color: Color, hold: float) -> void:
	banner.text = text
	banner.add_theme_color_override("font_color", color)
	banner.modulate.a = 0.0
	var vp := get_viewport().get_visible_rect().size
	banner.offset_top = vp.y * 0.18
	banner.offset_bottom = vp.y * 0.18 + 54.0
	var t := create_tween()
	t.tween_property(banner, "modulate:a", 1.0, 0.4)
	t.tween_interval(hold)
	t.tween_property(banner, "modulate:a", 0.0, 0.7)

# ---------------------------------------------------------------------------
# Fin de partida
# ---------------------------------------------------------------------------

func show_victory() -> void:
	_results_pending = true
	var director: Node = get_tree().current_scene.get_node_or_null("CinematicDirector") if get_tree().current_scene else null
	if director and director.has_method("play_victory"):
		await director.play_victory()
	title_label.text = "EL QUE SOSTIENE DERROTADO"
	title_label.add_theme_color_override("font_color", GOLD)
	var rank: String = _calculate_rank()
	rank_label.text = "✧  RANGO %s  ✧" % rank
	rank_label.add_theme_color_override("font_color", Color("e7b7a8"))
	_apply_result_background(true)
	cause_label.text = "La presencia se disipa en tinta."
	var record: Dictionary = _register_victory_once()
	stats_label.text = _stats_text() + "\nMejor tiempo  %s\nVictorias registradas  %d" % [_format_time(float(record.get("best", _fight_time))), int(record.get("wins", 1))]
	tip_label.text = "NUEVO RÉCORD" if bool(record.get("new", false)) else "El eco del coloso se desvanece. Por ahora."
	_display_end_screen()

func show_defeat(cause: String = "") -> void:
	_results_pending = true
	var director: Node = get_tree().current_scene.get_node_or_null("CinematicDirector") if get_tree().current_scene else null
	if director and director.has_method("play_defeat"):
		await director.play_defeat()
	title_label.text = "CAÍSTE"
	title_label.add_theme_color_override("font_color", CRIMSON)
	rank_label.text = "✧  LA PRESENCIA PERDURA  ✧"
	rank_label.add_theme_color_override("font_color", Color("d47e8b"))
	_apply_result_background(false)
	cause_label.text = ("Te mató: " + cause) if cause != "" else ""
	stats_label.text = _stats_text()
	tip_label.text = TIPS.get(cause, "Observa la telegrafía: cada ataque avisa antes de golpear.")
	_display_end_screen()

func _stats_text() -> String:
	var total := int(_fight_time)
	return "Tiempo  %02d:%02d\nDaño recibido  %d\nIntentos  %d" % [int(total / 60.0), total % 60, _damage_taken, attempt_count]

# Rejugabilidad V1: rango y récord local (solo partidas ganadas).
# No se almacena ni modifica ningún ajuste del panel de depuración.
func _calculate_rank() -> String:
	if _damage_taken == 0 and _fight_time <= 360.0:
		return "S"
	if _damage_taken <= 30 and _fight_time <= 540.0:
		return "A"
	if _damage_taken <= 80 and _fight_time <= 720.0:
		return "B"
	return "C"

func _format_time(time_seconds: float) -> String:
	var seconds: int = maxi(0, int(time_seconds))
	return "%02d:%02d" % [int(seconds / 60.0), seconds % 60]

func _register_victory_once() -> Dictionary:
	if _victory_recorded:
		return _load_record()
	_victory_recorded = true
	var record: Dictionary = _load_record()
	var old_best: float = float(record.get("best", -1.0))
	var new_record: bool = old_best < 0.0 or _fight_time < old_best
	var best: float = _fight_time if new_record else old_best
	var wins: int = int(record.get("wins", 0)) + 1
	var config := ConfigFile.new()
	config.set_value("combate", "mejor_tiempo", best)
	config.set_value("combate", "victorias", wins)
	var error: Error = config.save(RECORD_PATH)
	if error != OK:
		push_warning("No se pudo guardar el récord de combate: %s" % error_string(error))
	return {"best": best, "wins": wins, "new": new_record}

func _load_record() -> Dictionary:
	var config := ConfigFile.new()
	if config.load(RECORD_PATH) != OK:
		return {"best": -1.0, "wins": 0}
	return {"best": float(config.get_value("combate", "mejor_tiempo", -1.0)), "wins": int(config.get_value("combate", "victorias", 0))}

## Suma el daño recibido para la pantalla de resultados.
func register_player_damage(amount: int) -> void:
	_damage_taken += amount

## Abre Ajustes desde la pantalla de fin (el juego ya está en pausa).
func _open_settings() -> void:
	if _settings != null:
		return
	_settings = load("res://scenes/settings_menu.tscn").instantiate()
	add_child(_settings)
	_settings.closed.connect(func(): _settings = null)

func _display_end_screen() -> void:
	end_panel.visible = true
	if _help_hint:
		_help_hint.visible = false
	_style_end_buttons()
	# Pantalla limpia: se oculta todo el HUD de combate.
	if _root:
		for c in _root.get_children():
			if c != end_panel:
				c.visible = false
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

## Botones de fin en estilo texto (sin caja), como en los menús.
func _style_end_buttons() -> void:
	for b in [restart_button, options_button, quit_button]:
		b.custom_minimum_size = Vector2(340, 42)
		b.add_theme_font_size_override("font_size", 17)
		b.add_theme_color_override("font_color", BONE)
		b.add_theme_color_override("font_hover_color", Color("ffbdc0"))
		b.add_theme_color_override("font_pressed_color", Color("ffbdc0"))
		b.add_theme_color_override("font_focus_color", BONE)
		b.alignment = HORIZONTAL_ALIGNMENT_CENTER
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color(0.035, 0.039, 0.071, 0.84)
		normal.border_color = Color("575265")
		normal.border_width_bottom = 1
		normal.content_margin_left = 20.0
		normal.content_margin_right = 20.0
		var hover := normal.duplicate() as StyleBoxFlat
		hover.bg_color = Color(0.23, 0.065, 0.12, 0.95)
		hover.border_color = Color("d76e83")
		hover.border_width_left = 3
		b.add_theme_stylebox_override("normal", normal)
		b.add_theme_stylebox_override("hover", hover)
		b.add_theme_stylebox_override("pressed", hover)
		b.add_theme_stylebox_override("focus", hover)
	restart_button.text = "REINTENTAR    [R]"
	options_button.text = "AJUSTES"
	quit_button.text = "SALIR"

func _build_result_style() -> void:
	# Mantiene intacta la jerarquía de hud.tscn y los tres botones existentes.
	var background := end_panel.get_node_or_null("DeathBg") as TextureRect
	if background:
		background.texture = DEFEAT_ART
		background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_result_veil = ColorRect.new()
	_result_veil.name = "ResultadoVeloTinta"
	_result_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_result_veil.color = Color(0.015, 0.022, 0.047, 0.58)
	_result_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	end_panel.add_child(_result_veil)
	var center := end_panel.get_node("CenterContainer") as CenterContainer
	end_panel.move_child(_result_veil, center.get_index())
	var content := center.get_node("VBoxContainer") as VBoxContainer
	_result_frame = PanelContainer.new()
	_result_frame.name = "MarcoCeremonial"
	_result_frame.custom_minimum_size = Vector2(650, 0)
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0.035, 0.038, 0.068, 0.91)
	frame_style.border_color = Color("875765")
	frame_style.set_border_width_all(1)
	frame_style.content_margin_left = 36.0
	frame_style.content_margin_right = 36.0
	frame_style.content_margin_top = 32.0
	frame_style.content_margin_bottom = 32.0
	_result_frame.add_theme_stylebox_override("panel", frame_style)
	center.remove_child(content)
	center.add_child(_result_frame)
	_result_frame.add_child(content)
	content.add_theme_constant_override("separation", 12)
	title_label.add_theme_font_size_override("font_size", 39)
	title_label.add_theme_color_override("font_shadow_color", Color(0,0,0,0.7))
	rank_label.add_theme_font_size_override("font_size", 16)
	cause_label.add_theme_font_size_override("font_size", 17)
	cause_label.add_theme_color_override("font_color", Color("cfb8bf"))
	stats_label.add_theme_font_size_override("font_size", 17)
	stats_label.add_theme_color_override("font_color", BONE)
	tip_label.add_theme_font_size_override("font_size", 15)
	tip_label.add_theme_color_override("font_color", Color("c6b3bd"))
	tip_label.custom_minimum_size = Vector2(510, 0)

func _apply_result_background(victory: bool) -> void:
	var bg := end_panel.get_node_or_null("DeathBg") as TextureRect
	if bg:
		bg.texture = VICTORY_ART if victory else DEFEAT_ART
	if _result_frame:
		var panel_style := _result_frame.get_theme_stylebox("panel") as StyleBoxFlat
		if panel_style:
			panel_style.border_color = Color("a97c83") if victory else Color("ab4059")
	title_label.add_theme_color_override("font_color", Color("f1ddd6") if victory else Color("f3a1ac"))

func _build_help_hint() -> void:
	_help_hint = Label.new()
	_help_hint.text = "F2  CONTROLES     ·     ESC  PAUSA"
	_help_hint.add_theme_font_size_override("font_size", 12)
	_help_hint.add_theme_color_override("font_color", Color("b4acbf"))
	_help_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_help_hint.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_help_hint.anchor_left = 1.0
	_help_hint.anchor_right = 1.0
	_help_hint.offset_left = -280.0
	_help_hint.offset_right = -18.0
	_help_hint.offset_top = 12.0
	_help_hint.offset_bottom = 38.0
	_help_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	$Control.add_child(_help_hint)

func _unhandled_input(event: InputEvent) -> void:
	if end_panel.visible and event is InputEventKey and event.pressed and event.keycode == KEY_R:
		_on_restart_pressed()

func _on_restart_pressed() -> void:
	# Limpiar cualquier pulso rojo que pudiera persistir durante la recarga.
	if _flash_tween and _flash_tween.is_running():
		_flash_tween.kill()
	damage_flash.color = Color(0, 0, 0, 0)
	if low_health.material is ShaderMaterial:
		(low_health.material as ShaderMaterial).set_shader_parameter("intensity", 0.0)
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().reload_current_scene()

func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().quit()

# ---------------------------------------------------------------------------
# HUD de combate (elementos de la hoja de concepto)
# ---------------------------------------------------------------------------

var _root: Control
var _emblem: TextureRect
var _stamina: ProgressBar
var _charges: Label
var _skill_icons: Array = []
var _state_icon: TextureRect
var _interact: Control
var _reticle: TextureRect
var _subtitle: Label

func _build_combat_hud() -> void:
	_root = get_node_or_null("Control")
	if _root == null:
		return
	# HUD jugador: margen 24 px, emblema 52 px, barra de 236 px.
	_emblem = TextureRect.new()
	_emblem.texture = EMBLEM
	_emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# Emblema anclado a la esquina inferior izquierda.
	_emblem.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_emblem.offset_left = 20.0
	_emblem.offset_top = -116.0
	_emblem.offset_right = 78.0
	_emblem.offset_bottom = -58.0
	_emblem.modulate = Color(0.75, 0.75, 0.85, 0.85)
	_emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_emblem)
	var panel: Control = health_bar.get_parent()
	# Todo el bloque del jugador se coloca abajo a la izquierda.
	# Mantiene sus elementos internos en las mismas posiciones relativas.
	panel.anchor_left = 0.0
	panel.anchor_top = 1.0
	panel.anchor_right = 0.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 88.0
	panel.offset_top = -116.0
	panel.offset_right = 336.0
	panel.offset_bottom = -12.0
	health_bar.offset_left = 0.0
	health_bar.offset_top = 0.0
	health_bar.offset_right = 236.0
	health_bar.offset_bottom = 15.0
	health_label.offset_left = 152.0
	health_label.offset_top = -2.0
	health_label.offset_right = 232.0
	health_label.offset_bottom = 16.0
	dash_label.offset_left = 0.0
	dash_label.offset_top = 48.0
	dash_label.offset_right = 100.0
	dash_label.offset_bottom = 67.0
	combo_label.offset_left = 110.0
	combo_label.offset_top = 48.0
	combo_label.offset_right = 240.0
	combo_label.offset_bottom = 67.0
	_stamina = ProgressBar.new()
	_stamina.max_value = 100.0
	_stamina.value = 100.0
	_stamina.show_percentage = false
	_stamina.offset_top = 24.0
	_stamina.offset_bottom = 30.0
	_stamina.offset_right = 236.0
	_stamina.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_bar(_stamina, Color("729bb0"), Color("10131e"), Color("505d6b"))
	panel.add_child(_stamina)
	_grip_bar = _stamina
	# Solo mostrar la resistencia al trepar; mantener layout estable.
	_stamina.modulate.a = 0.72
	var rune: Texture2D = load("res://assets/generated/ui_skill_rune_2.png")
	if rune == null:
		rune = RING_TEX
	var dash_rune := TextureRect.new()
	dash_rune.texture = rune
	dash_rune.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dash_rune.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dash_rune.position = Vector2(0, 68)
	dash_rune.size = Vector2(24, 24)
	dash_rune.modulate = Color(0.68, 0.75, 0.87, 0.85)
	dash_rune.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(dash_rune)
	_skill_icons.append(dash_rune)
	_charges = Label.new()
	_charges.position = Vector2(31, 69)
	_charges.size = Vector2(150, 24)
	_charges.text = "DASH DISPONIBLE"
	_charges.add_theme_font_size_override("font_size", 11)
	_charges.add_theme_color_override("font_color", Color("cbd4dd"))
	panel.add_child(_charges)
	# Barra del jefe centrada arriba, independiente de la barra del jugador.
	boss_panel.anchor_left = 0.5
	boss_panel.anchor_right = 0.5
	boss_panel.anchor_top = 0.0
	boss_panel.anchor_bottom = 0.0
	boss_panel.offset_left = -240.0
	boss_panel.offset_right = 240.0
	boss_panel.offset_top = 16.0
	boss_panel.offset_bottom = 86.0
	boss_name_label.offset_left = 0.0
	boss_name_label.offset_top = 0.0
	boss_name_label.offset_right = 480.0
	boss_name_label.offset_bottom = 23.0
	boss_health_bar.offset_left = 0.0
	boss_health_bar.offset_top = 30.0
	boss_health_bar.offset_right = 480.0
	boss_health_bar.offset_bottom = 45.0
	_style_boss_bar()
	# Fantasmas heredan el tamaño final (se construyeron antes del layout).
	for pair in [[_health_ghost, health_bar], [_boss_ghost, boss_health_bar]]:
		var ghost: ProgressBar = pair[0]
		var source: ProgressBar = pair[1]
		if ghost:
			ghost.offset_left = source.offset_left
			ghost.offset_top = source.offset_top
			ghost.offset_right = source.offset_right
			ghost.offset_bottom = source.offset_bottom
	_build_phase_markers()
	# Retícula pequeña, sin saturación fuera de lock-on.
	_reticle = TextureRect.new()
	_reticle.texture = CROSSHAIR
	_reticle.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_reticle.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_reticle.anchor_left = 0.5
	_reticle.anchor_top = 0.5
	_reticle.anchor_right = 0.5
	_reticle.anchor_bottom = 0.5
	_reticle.offset_left = -12.0
	_reticle.offset_top = -12.0
	_reticle.offset_right = 12.0
	_reticle.offset_bottom = 12.0
	_reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reticle.modulate = Color(0.9, 0.72, 0.73, 0.3)
	_root.add_child(_reticle)
	_interact = HBoxContainer.new()
	_interact.add_theme_constant_override("separation", 8)
	_interact.anchor_left = 0.5
	_interact.anchor_right = 0.5
	_interact.anchor_top = 1.0
	_interact.anchor_bottom = 1.0
	_interact.offset_left = -95.0
	_interact.offset_right = 95.0
	_interact.offset_top = -90.0
	_interact.offset_bottom = -56.0
	_interact.modulate.a = 0.0
	_interact.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_interact)
	var key := Label.new()
	key.text = "[E]"
	key.add_theme_font_size_override("font_size", 17)
	key.add_theme_color_override("font_color", Color("d2a4a9"))
	_interact.add_child(key)
	var txt := Label.new()
	txt.text = "Interactuar"
	txt.add_theme_font_size_override("font_size", 16)
	txt.add_theme_color_override("font_color", Color("eee6e2"))
	_interact.add_child(txt)
	# Subtítulos: caption de las acciones del jefe (toggle en Ajustes).
	_subtitle = Label.new()
	_subtitle.anchor_left = 0.5
	_subtitle.anchor_right = 0.5
	_subtitle.anchor_top = 1.0
	_subtitle.anchor_bottom = 1.0
	_subtitle.offset_left = -340.0
	_subtitle.offset_right = 340.0
	_subtitle.offset_top = -128.0
	_subtitle.offset_bottom = -96.0
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.add_theme_font_size_override("font_size", 16)
	_subtitle.add_theme_color_override("font_color", Color(0.90, 0.87, 0.82, 0.95))
	_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_subtitle.modulate.a = 0.0
	_root.add_child(_subtitle)
	_build_tutorial()

## Prompts de tutorial (esquina inferior derecha): aparecen al empezar y se desvanecen.
func _build_tutorial() -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.anchor_left = 1.0
	vbox.anchor_top = 1.0
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = -230.0
	vbox.offset_right = -24.0
	vbox.offset_top = -120.0
	vbox.offset_bottom = -32.0
	vbox.alignment = BoxContainer.ALIGNMENT_END
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.modulate.a = 0.0
	_root.add_child(vbox)
	var hints := ["ESPACIO   SALTAR", "SHIFT   ESQUIVAR", "RATÓN   ATACAR"]
	for txt in hints:
		var l := Label.new()
		l.text = txt
		l.add_theme_font_size_override("font_size", 12)
		l.add_theme_color_override("font_color", Color(0.9, 0.87, 0.82, 0.9))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		vbox.add_child(l)
	var t := create_tween()
	t.tween_property(vbox, "modulate:a", 1.0, 0.6)
	t.tween_interval(4.0)
	t.tween_property(vbox, "modulate:a", 0.0, 1.2)

## Caption de subtítulos (respeta el ajuste Subtítulos). Cadena vacía lo oculta.
func show_subtitle(text: String, hold: float = 1.6) -> void:
	if _subtitle == null or text.is_empty():
		return
	var s := get_node_or_null("/root/Settings")
	if s != null and s.get("subtitles") == false:
		return
	_subtitle.text = text
	_subtitle.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(_subtitle, "modulate:a", 1.0, 0.15)
	t.tween_interval(hold)
	t.tween_property(_subtitle, "modulate:a", 0.0, 0.4)

func _style_boss_bar() -> void:
	_style_bar(boss_health_bar, Color("ca5269"), Color("0b111c"), Color("736778"))

func _build_phase_markers() -> void:
	for i in range(3):
		var diamond := ColorRect.new()
		diamond.color = Color("ecb6af")
		diamond.size = Vector2(8, 8)
		diamond.pivot_offset = Vector2(4, 4)
		diamond.rotation = PI / 4.0
		diamond.position = Vector2(114.0 + float(i) * 126.0, 33.0)
		diamond.mouse_filter = Control.MOUSE_FILTER_IGNORE
		boss_health_bar.get_parent().add_child(diamond)
		_eye_indicators.append(diamond)
	update_eyes_broken(_eyes_broken)

func _update_combat_hud() -> void:
	var p := get_parent()
	if p == null:
		return
	# Retícula: resalta con lock-on (bloqueado/sin bloqueo).
	if _reticle:
		var locked: bool = p.get("lock_active") == true
		_reticle.modulate.a = lerp(_reticle.modulate.a, 1.0 if locked else 0.3, 0.15)
		_reticle.modulate.g = 0.4 if locked else 0.7
		_reticle.modulate.b = 0.35 if locked else 0.65
	# Prompt de interacción: aparece al poder trepar.
	if _interact:
		var can_climb: bool = p.get("current_climb_zone") != null
		_interact.modulate.a = lerp(_interact.modulate.a, 1.0 if can_climb else 0.0, 0.2)
	# Barra secundaria = agarre.
	if _stamina and p.get("grip") != null:
		var g: float = p.get("grip")
		var gm: float = maxf(float(p.get("grip_max")), 1.0)
		_stamina.value = clampf(g / gm * 100.0, 0.0, 100.0)
	# Cargas de dash.
	if _charges:
		_charges.text = "DASH DISPONIBLE" if p.get("can_dash") else "RECARGANDO"
		_charges.modulate = BONE if p.get("can_dash") else Color(0.65, 0.55, 0.65, 0.7)
	# Icono de estado: normal / invulnerable / vida baja.
	if _state_icon and p.get("player_health") != null:
		var inv: bool = p.get("is_invulnerable") == true
		var hp: float = float(p.get("player_health"))
		var mx: float = maxf(float(p.get("max_player_health")), 1.0)
		var col := Color(0.9, 0.9, 0.98)
		if inv:
			col = Color(0.55, 0.62, 1.0)
		elif hp / mx < 0.3:
			col = Color(1.0, 0.2, 0.25)
		_state_icon.modulate = col

## Número de daño flotante (rojo para el jugador, dorado para el jefe).
func pop_damage(amount: int, world_pos: Vector3, color: Color) -> void:
	if _root == null:
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null or cam.is_position_behind(world_pos):
		return
	var sp := cam.unproject_position(world_pos)
	var l := Label.new()
	l.text = str(amount)
	l.add_theme_font_size_override("font_size", 29)
	l.add_theme_color_override("font_color", color)
	l.position = sp - Vector2(22, 24)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(l)
	var t := create_tween().set_parallel(true)
	t.tween_property(l, "position:y", l.position.y - 76, 0.85).set_trans(Tween.TRANS_SINE)
	t.tween_property(l, "modulate:a", 0.0, 0.85)
	t.chain().tween_callback(l.queue_free)
