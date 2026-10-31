extends Node3D
## Marca oscura: siembra zonas corruptas en el suelo que dañan al pisarlas.
## "Deja zonas que te hacen daño si las tocas." — hoja de concepto (Fase 1).

const TELEGRAPH: PackedScene = preload("res://telegraph_decal.tscn")
const DARK_ZONE: PackedScene = preload("res://scenes/dark_mark_zone.tscn")

@export var mark_count: int = 4
@export var damage: int = 10
@export var duration: float = 3.5
@export var mark_radius: float = 2.2
@export var tick: float = 0.6
@export var spread: float = 6.0

func _boss() -> Node3D:
	return get_parent().get_parent() as Node3D

func fire() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var boss := _boss()
	var center: Vector3 = boss.global_position if boss else Vector3.ZERO
	Audio.play_sfx("beam_charge", -6.0, 1.4)
	for i in mark_count:
		if not is_inside_tree():
			return
		var base: Vector3 = player.global_position if player else center
		var target := base + Vector3(randf_range(-spread, spread), 0, randf_range(-spread, spread))
		_spawn_mark(target)
		await get_tree().create_timer(0.15, false).timeout

func _spawn_mark(target: Vector3) -> void:
	var scene: Node = get_tree().current_scene
	if not is_instance_valid(scene):
		return
	var ground: Vector3 = TelegraphDecal.find_ground(get_tree(), target + Vector3.UP * 5.0)
	var decal: TelegraphDecal = TELEGRAPH.instantiate() as TelegraphDecal
	scene.add_child(decal)
	decal.place(ground)
	decal.show_ring(mark_radius, Color(0.72, 0.05, 0.35, 0.95))
	decal.grow_to(mark_radius, 0.5)
	Audio.play_sfx("beam_charge", -9.0, 1.6)
	await get_tree().create_timer(0.5, false).timeout
	if not is_inside_tree() or not is_instance_valid(scene):
		if is_instance_valid(decal):
			decal.queue_free()
		return
	if is_instance_valid(decal):
		decal.flash_and_free(Color(0.5, 0.02, 0.25, 0.95))
	var zone: Area3D = DARK_ZONE.instantiate() as Area3D
	scene.add_child(zone)
	zone.global_position = ground
	zone.configure(mark_radius, damage, duration, tick)
