extends Node3D

@export var orb_scene: PackedScene # asigna una escena de orbe pequeña
@export var rain_count: int = 8
@export var rain_height: float = 15.0
@export var rain_radius: float = 5.0
@export var damage: int = 12
@export var impact_radius: float = 1.3

const IMPACT_SCENE: PackedScene = preload("res://scenes/ink_impact_effect.tscn")
const TELEGRAPH: PackedScene = preload("res://telegraph_decal.tscn")

var boss: Node3D

func _ready():
	boss = get_parent().get_parent() # Attacks -> Boss01

func fire():
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	
	# Pilar 4 - Lenguaje: cielo oscurece
	var env = get_tree().current_scene.find_child("WorldEnvironment", true, false)
	if env: env.environment.background_energy_multiplier = 0.3
	
	for i in range(rain_count):
		if not is_inside_tree(): return
		drop_one(player)
		await get_tree().create_timer(0.12, false).timeout
	
	await get_tree().create_timer(1.0, false).timeout
	if env: env.environment.background_energy_multiplier = 1.0

func drop_one(player: Node3D):
	var spawn_x = player.global_position.x + randf_range(-rain_radius, rain_radius)
	var spawn_z = player.global_position.z + randf_range(-rain_radius, rain_radius)
	var target = Vector3(spawn_x, player.global_position.y + 0.1, spawn_z)
	
	# 1. TelegraphDecal reutilizable: aro rojo en el suelo + relleno creciente.
	var ground := TelegraphDecal.find_ground(get_tree(), Vector3(target.x, target.y + 5.0, target.z))
	var decal := TELEGRAPH.instantiate()
	get_tree().current_scene.add_child(decal)
	decal.place(ground)
	decal.show_ring(impact_radius)
	decal.grow_to(impact_radius, 0.6)
	Audio.play_sfx("beam_charge", -8.0, 1.7)
	await get_tree().create_timer(0.6, false).timeout
	decal.flash_and_free()
	
	# 2. Caída
	if not orb_scene: return
	var orb = orb_scene.instantiate()
	get_tree().current_scene.add_child(orb)
	orb.global_position = target + Vector3(0, rain_height, 0)
	# El orbe sólo debe seguir el tween de caída, no su propio movimiento.
	if "direction" in orb:
		orb.direction = Vector3.ZERO
	if "homing_time" in orb:
		orb.homing_time = 0.0
	
	var fall = create_tween()
	fall.tween_property(orb, "global_position", target, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fall.tween_callback(func():
		_on_orb_land(target)
		if is_instance_valid(orb): orb.queue_free())

func _on_orb_land(target: Vector3) -> void:
	var player = get_tree().get_first_node_in_group("player") as Node3D
	if player and player.has_method("take_damage"):
		var flat = player.global_position
		flat.y = target.y
		if flat.distance_to(target) <= impact_radius:
			player.take_damage(damage, "Rain")
	Audio.play_sfx("rain_impact", -4.0, randf_range(0.9, 1.1))
	_spawn_impact(target)

func _spawn_impact(target: Vector3) -> void:
	if not is_inside_tree(): return
	var fx = IMPACT_SCENE.instantiate()
	get_tree().current_scene.add_child(fx)
	fx.global_position = target
