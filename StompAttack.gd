extends Node3D
## Pisotón: levanta el cuerpo, golpea el suelo y produce una onda expansiva en área.

const TELEGRAPH: PackedScene = preload("res://telegraph_decal.tscn")

@export var damage: int = 30
@export var radius: float = 7.5

func _boss() -> Node3D:
	return get_parent().get_parent() as Node3D

func fire() -> void:
	var boss := _boss()
	if boss == null:
		return
	Audio.play_sfx("heavy_swing", -3.0)
	var ground := TelegraphDecal.find_ground(get_tree(), boss.global_position + Vector3(0, 2, 0))
	var decal := TELEGRAPH.instantiate() as TelegraphDecal
	get_tree().current_scene.add_child(decal)
	decal.place(ground)
	decal.show_ring(radius)
	decal.grow_to(radius, 0.65)
	var pivot := boss.get_node_or_null("BodyPivot") as Node3D
	if pivot:
		var up := create_tween()
		up.tween_property(pivot, "position:y", 2.2, 0.35).set_trans(Tween.TRANS_SINE)
		await up.finished
		var down := create_tween()
		down.tween_property(pivot, "position:y", 0.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await down.finished
	else:
		await get_tree().create_timer(0.65, false).timeout
	if not is_inside_tree():
		return
	if is_instance_valid(decal):
		decal.flash_and_free()
	Audio.play_sfx("heavy_hit", 0.0)
	# Onda expansiva visual.
	var wave := TELEGRAPH.instantiate() as TelegraphDecal
	get_tree().current_scene.add_child(wave)
	wave.place(ground)
	wave.show_ring(radius * 0.4, Color(1.0, 0.5, 0.2, 0.9))
	wave.grow_to(radius * 1.25, 0.3)
	wave.flash_and_free(Color(1.0, 0.5, 0.2, 0.9))
	_apply_damage(boss)

func _apply_damage(boss: Node3D) -> void:
	for p in get_tree().get_nodes_in_group("player"):
		var to: Vector3 = p.global_position - boss.global_position
		to.y = 0.0
		if to.length() <= radius and p.has_method("take_damage"):
			p.take_damage(damage, "Pisotón")