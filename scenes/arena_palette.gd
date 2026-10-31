extends Node
class_name ArenaPalette
## Las 5 variantes visuales del coloso (hoja de concepto).
## Recolorea ambiente, niebla y luz para reencuadrar la pelea.

const PRESETS := {
	1: {"name": "01. El Que Sostiene", "bg": Color(0.09, 0.05, 0.16), "bg_energy": 1.0,
		"ambient": Color(0.55, 0.42, 0.66), "fog": Color(0.32, 0.2, 0.4), "light": Color(0.99, 0.92, 0.73)},
	2: {"name": "02. El Que Arde", "bg": Color(0.13, 0.03, 0.02), "bg_energy": 1.1,
		"ambient": Color(0.7, 0.28, 0.14), "fog": Color(0.5, 0.14, 0.06), "light": Color(1.0, 0.6, 0.3)},
	3: {"name": "03. El Que Se Pudre", "bg": Color(0.05, 0.09, 0.05), "bg_energy": 1.0,
		"ambient": Color(0.45, 0.6, 0.28), "fog": Color(0.28, 0.36, 0.12), "light": Color(0.8, 0.95, 0.5)},
	4: {"name": "04. El Que Flota", "bg": Color(0.08, 0.11, 0.15), "bg_energy": 1.2,
		"ambient": Color(0.7, 0.85, 0.95), "fog": Color(0.6, 0.78, 0.88), "light": Color(0.85, 0.95, 1.0)},
	5: {"name": "05. El Que Despierta", "bg": Color(0.14, 0.06, 0.18), "bg_energy": 1.1,
		"ambient": Color(0.8, 0.4, 0.8), "fog": Color(0.5, 0.2, 0.5), "light": Color(1.0, 0.7, 0.95)},
}

const SKY_PATH := "res://assets/generated/arena_sostiene_sky.png"

var index: int = 1

func _ready() -> void:
	_setup_sky()
	# Se difiere para que el HUD ya exista cuando escribamos su etiqueta.
	call_deferred("apply", index)

## Monta el cielo pintado (gouache) como fondo del ambiente.
func _setup_sky() -> void:
	var host := get_parent()
	if host == null:
		return
	var env := host.find_child("WorldEnvironment", true, false) as WorldEnvironment
	if env == null or env.environment == null:
		return
	var tex := load(SKY_PATH) as Texture2D
	if tex == null:
		return
	var mat := PanoramaSkyMaterial.new()
	mat.panorama = tex
	var sky := Sky.new()
	sky.sky_material = mat
	env.environment.sky = sky
	env.environment.background_mode = Environment.BG_SKY

func apply(i: int) -> void:
	index = clampi(i, 1, PRESETS.size())
	var p: Dictionary = PRESETS[index]
	var host := get_parent()
	if host == null:
		return
	var env := host.find_child("WorldEnvironment", true, false) as WorldEnvironment
	if env and env.environment:
		var e := env.environment
		e.background_color = p["bg"]
		e.background_energy_multiplier = p["bg_energy"]
		e.ambient_light_color = p["ambient"]
		e.fog_light_color = p["fog"]
		e.volumetric_fog_emission = p["fog"]
	var light := host.find_child("DirectionalLight3D", true, false) as DirectionalLight3D
	if light:
		light.light_color = p["light"]
	var hud := get_tree().get_first_node_in_group("hud")
	if not hud:
		hud = get_tree().get_first_node_in_group("HUD")
	if hud and hud.has_method("set_palette_name"):
		hud.set_palette_name(p["name"])

func next() -> void:
	apply(index + 1 if index < PRESETS.size() else 1)

func name_of(i: int) -> String:
	return PRESETS[clampi(i, 1, PRESETS.size())]["name"]