extends Control

const VISUAL := preload("res://menu_visuals.gd")

@onready var play_button: Button = $MarginContainer/VBoxContainer/PlayButton
@onready var new_game_button: Button = $MarginContainer/VBoxContainer/NewGameButton
@onready var options_button: Button = $MarginContainer/VBoxContainer/OptionsButton
@onready var exit_button: Button = $MarginContainer/VBoxContainer/ExitButton
var _settings: Control = null

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Audio.play_music("menu")
	VISUAL.add_veil(self, 0.82, 0.54)
	_style_menu()
	_add_controls_access()
	_apply_language()
	play_button.pressed.connect(_on_play_pressed)
	new_game_button.pressed.connect(_on_play_pressed)
	options_button.pressed.connect(_open_settings)
	exit_button.pressed.connect(_on_exit_pressed)

## Aplica el idioma elegido en Ajustes a los botones del menú.
func _apply_language() -> void:
	var s := get_node_or_null("/root/Settings")
	if s == null:
		return
	play_button.text = s.t("continuar")
	new_game_button.text = s.t("nueva")
	options_button.text = s.t("opciones")
	exit_button.text = s.t("salir")

func _style_menu() -> void:
	var panel: MarginContainer = $MarginContainer
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.anchor_right = 0.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 64.0
	panel.offset_right = 525.0
	panel.offset_top = 0.0
	panel.offset_bottom = 0.0
	panel.add_theme_constant_override("margin_left", 8)
	panel.add_theme_constant_override("margin_top", 65)
	panel.add_theme_constant_override("margin_right", 30)
	panel.add_theme_constant_override("margin_bottom", 20)
	var vbox: VBoxContainer = $MarginContainer/VBoxContainer
	vbox.add_theme_constant_override("separation", 9)
	VISUAL.style_title($MarginContainer/VBoxContainer/GameTitle, 48)
	var title: Label = $MarginContainer/VBoxContainer/GameTitle
	title.text = "Demo 0.5"
	var subtitle: Label = $MarginContainer/VBoxContainer/Subtitle
	subtitle.text = "I  —  El que sostiene"
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.80, 0.67, 0.72))
	for button in [play_button, new_game_button, options_button, exit_button]:
		button.custom_minimum_size = Vector2(310, 42)
		VISUAL.style_button(button, button == play_button, 19)
	VISUAL.make_caption(self, "Version a testear", Vector2(72, 585), Vector2(410, 24))

func _open_settings() -> void:
	if _settings != null:
		return
	var menu := get_node_or_null("MarginContainer")
	if menu:
		menu.visible = false
	_settings = load("res://scenes/settings_menu.tscn").instantiate()
	add_child(_settings)
	_settings.closed.connect(func():
		_settings = null
		if menu:
			menu.visible = true
		_apply_language())

var _opening_combat: bool = false

func _on_play_pressed() -> void:
	if _opening_combat:
		return
	_opening_combat = true
	play_button.disabled = true
	new_game_button.disabled = true
	Audio.stop_music()
	await get_tree().create_timer(0.55).timeout
	get_tree().change_scene_to_file("res://scenes/arena.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()

# Acceso explícito y visible en la demo: no requiere saber que existe F2.
func _add_controls_access() -> void:
	var buttons: VBoxContainer = $MarginContainer/VBoxContainer
	var guide := Button.new()
	guide.name = "ControlsHelpButton"
	guide.text = "CONTROLES    [F2]"
	guide.custom_minimum_size = Vector2(310, 42)
	VISUAL.style_button(guide, false, 19)
	buttons.add_child(guide)
	buttons.move_child(guide, options_button.get_index())
	guide.pressed.connect(func():
		var debug_ui := get_node_or_null("/root/Debug")
		if debug_ui and debug_ui.has_method("show_controls"):
			debug_ui.show_controls()
	)
