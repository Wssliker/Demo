extends Control

const VISUAL := preload("res://menu_visuals.gd")

@onready var resume_button: Button = $ColorRect/CenterContainer/VBoxContainer/ResumeButton
@onready var ajustes_button: Button = $ColorRect/CenterContainer/VBoxContainer/AjustesButton
@onready var restart_button: Button = $ColorRect/CenterContainer/VBoxContainer/RestartButton
@onready var quit_button: Button = $ColorRect/CenterContainer/VBoxContainer/QuitToMenuButton
var _settings: Control = null

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    visible = false
    _style_menu()
    _apply_language()
    resume_button.pressed.connect(unpause_game)
    ajustes_button.pressed.connect(_open_settings)
    restart_button.pressed.connect(_on_restart_pressed)
    quit_button.pressed.connect(_on_quit_to_menu_pressed)

## Aplica el idioma elegido en Ajustes a los botones del menú de pausa.
func _apply_language() -> void:
    var s := get_node_or_null("/root/Settings")
    if s == null:
        return
    var title := get_node_or_null("ColorRect/CenterContainer/VBoxContainer/TittleLabel")
    if title:
        title.text = s.t("pausa")
    resume_button.text = s.t("reanudar")
    ajustes_button.text = s.t("opciones")
    restart_button.text = s.t("reiniciar")
    quit_button.text = s.t("menu")

func _style_menu() -> void:
    var panel: ColorRect = $ColorRect
    panel.color = Color(0.02, 0.02, 0.035, 0.82)
    $BgImage.modulate = Color(0.75, 0.73, 0.84, 0.55)
    var box: VBoxContainer = $ColorRect/CenterContainer/VBoxContainer
    box.add_theme_constant_override("separation", 10)
    var label: Label = $ColorRect/CenterContainer/VBoxContainer/TittleLabel
    VISUAL.style_title(label, 42)
    for button in [resume_button, ajustes_button, restart_button, quit_button]:
        button.custom_minimum_size = Vector2(310, 43)
        VISUAL.style_button(button, button == resume_button, 19)

func _open_settings() -> void:
    if _settings != null:
        return
    _settings = load("res://scenes/settings_menu.tscn").instantiate()
    add_child(_settings)
    _settings.closed.connect(func():
        _settings = null
        _apply_language())

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.echo:
        return
    if _settings != null:
        return
    if event.is_action_pressed("pausar") or event.is_action_pressed("ui_cancel"):
        if get_tree().paused:
            unpause_game()
        else:
            pause_game()
        get_viewport().set_input_as_handled()

func pause_game() -> void:
    visible = true
    _set_hud_visible(false)
    get_tree().paused = true
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func unpause_game() -> void:
    visible = false
    _set_hud_visible(true)
    get_tree().paused = false
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _set_hud_visible(shown: bool) -> void:
    var hud := get_tree().get_first_node_in_group("hud")
    if hud:
        hud.visible = shown

func _on_restart_pressed() -> void:
    get_tree().paused = false
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    get_tree().reload_current_scene()

func _on_quit_to_menu_pressed() -> void:
    get_tree().paused = false
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
