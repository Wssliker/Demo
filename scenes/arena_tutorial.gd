extends Node
## Tutorial contextual. Nunca bloquea controles ni altera las mecánicas.
## Las ayudas se completan en esta partida y se reinician al reiniciar la arena.

@export_group("Tutorial orgánico")
@export var enabled: bool = true
@export_range(0.05, 1.5, 0.05) var fade_in_seconds: float = 0.28
@export_range(0.05, 1.5, 0.05) var fade_out_seconds: float = 0.55
@export_range(0.5, 10.0, 0.5) var movement_hint_seconds: float = 4.0
@export_range(1.0, 10.0, 0.5) var proximity_distance: float = 6.5
@export_range(0.5, 8.0, 0.5) var tip_duration: float = 3.2

const IVORY: Color = Color(0.94, 0.89, 0.82)
const DUSK: Color = Color(0.065, 0.055, 0.11, 0.91)
const RIM: Color = Color(0.56, 0.30, 0.43, 0.9)

var _arena: Node3D
var _player: Node3D
var _boss: Node3D
var _canvas: CanvasLayer
var _frame: PanelContainer
var _label: Label
var _shown_message: String = ""
var _intro_elapsed: float = 0.0
var _display_elapsed: float = 0.0
var _movement_done: bool = false
var _dash_done: bool = false
var _grab_done: bool = false
var _stab_done: bool = false
var _anchor_done: bool = false
var _last_shake_warning: bool = false
var _hint_tween: Tween = null
var _expired_tip: String = ""
var _currently_fading_out: bool = false

func _ready() -> void:
	_arena = get_parent() as Node3D
	_player = _arena.get_node_or_null("Player") as Node3D
	_boss = _arena.get_node_or_null("DummyEnemy") as Node3D
	_build_overlay()

func _process(delta: float) -> void:
	if not enabled or not is_instance_valid(_player) or not is_instance_valid(_boss):
		_hide()
		return
	if not _intro_completed() or get_tree().paused or _game_finished():
		_hide()
		return
	_intro_elapsed += delta
	_update_completed_actions()
	var tip: String = _choose_tip()
	if tip.is_empty():
		_expired_tip = ""
		_hide()
		return
	if tip == _expired_tip:
		return
	if tip != _shown_message:
		_show(tip)
	else:
		_display_elapsed += delta
		if _display_elapsed >= tip_duration and tip != "SACUDIDA INMINENTE · MANTÉN E + SHIFT PARA ANCLARTE":
			_expired_tip = tip
			_hide()

func _intro_completed() -> bool:
	if _arena == null:
		return true
	if "_intro_finished" in _arena:
		return bool(_arena.get("_intro_finished"))
	return true

func _game_finished() -> bool:
	var hud: Node = _player.get_node_or_null("HUD")
	if hud != null:
		var result: CanvasItem = hud.get_node_or_null("Control/EndGamePanel") as CanvasItem
		if result != null and result.visible:
			return true
	return false

func _update_completed_actions() -> void:
	if Input.is_action_pressed("ui_up") or Input.is_action_pressed("ui_down") or Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right"):
		_movement_done = true
	if "is_dashing" in _player and bool(_player.get("is_dashing")):
		_dash_done = true
	if "is_climbing" in _player and bool(_player.get("is_climbing")):
		_grab_done = true
	if _grab_done and not _stab_done and "is_attacking" in _player and bool(_player.get("is_attacking")) and bool(_player.get("is_climbing")):
		_stab_done = true
	if "_shake_warning_active" in _player and bool(_player.get("_shake_warning_active")):
		_last_shake_warning = true
	if _last_shake_warning and "is_climbing" in _player and bool(_player.get("is_climbing")) and Input.is_key_pressed(KEY_SHIFT):
		_anchor_done = true

func _choose_tip() -> String:
	if not _movement_done and _intro_elapsed <= movement_hint_seconds:
		return "WASD · MOVERSE     RATÓN · MIRAR"
	if _intro_elapsed < 1.0:
		return ""
	if "_shake_warning_active" in _player and bool(_player.get("_shake_warning_active")) and not _anchor_done:
		return "SACUDIDA INMINENTE · MANTÉN E + SHIFT PARA ANCLARTE"
	var climbing: bool = "is_climbing" in _player and bool(_player.get("is_climbing"))
	if climbing and not _stab_done:
		return "SOBRE EL COLOSO · CLIC IZQUIERDO / DERECHO PARA ATACAR UN OJO"
	if climbing:
		return ""
	if not _grab_done and _near_climb_zone():
		return "CERCA DEL COLOSO · MANTÉN E PARA AGARRARTE"
	if not _dash_done:
		return "SHIFT · DASH PARA ESQUIVAR LOS ATAQUES"
	return ""

func _near_climb_zone() -> bool:
	if "current_climb_zone" in _player:
		var zone: Object = _player.get("current_climb_zone")
		if is_instance_valid(zone):
			return true
	return _player.global_position.distance_to(_boss.global_position) < proximity_distance

func _build_overlay() -> void:
	_canvas = CanvasLayer.new()
	_canvas.name = "TutorialLayer"
	_canvas.layer = 24
	add_child(_canvas)
	var root: Control = Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(root)
	_frame = PanelContainer.new()
	_frame.name = "TutorialHint"
	_frame.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_frame.offset_left = -320.0
	_frame.offset_right = 320.0
	_frame.offset_top = -135.0
	_frame.offset_bottom = -92.0
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = DUSK
	style.border_color = RIM
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	_frame.add_theme_stylebox_override("panel", style)
	root.add_child(_frame)
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_color_override("font_color", IVORY)
	_label.add_theme_font_size_override("font_size", 14)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_child(_label)
	_frame.visible = false
	_frame.modulate.a = 0.0

func _show(message: String) -> void:
	_shown_message = message
	_display_elapsed = 0.0
	_currently_fading_out = false
	if is_instance_valid(_hint_tween):
		_hint_tween.kill()
	_label.text = message
	_frame.visible = true
	_frame.modulate.a = 0.0
	_hint_tween = create_tween()
	_hint_tween.tween_property(_frame, "modulate:a", 1.0, fade_in_seconds)

func _hide() -> void:
	if not is_instance_valid(_frame) or _currently_fading_out or not _frame.visible:
		return
	_shown_message = ""
	_currently_fading_out = true
	if is_instance_valid(_hint_tween):
		_hint_tween.kill()
	_hint_tween = create_tween()
	_hint_tween.tween_property(_frame, "modulate:a", 0.0, fade_out_seconds)
	_hint_tween.tween_callback(func() -> void:
		if is_instance_valid(_frame) and _currently_fading_out:
			_frame.visible = false
		_currently_fading_out = false
	)
