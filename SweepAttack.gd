extends Node3D
## Barrido horizontal: telegrafía un gran aro y barre la zona frontal del coloso.

const TELEGRAPH: PackedScene = preload("res://telegraph_decal.tscn")

@export var damage: int = 24
@export var swing_range: float = 7.5
@export var arc_degrees: float = 150.0

func _boss() -> Node3D:
	return get_parent().get_parent() as Node3D

func fire() -> void:
	var boss := _boss()
	if boss == null:
		return
	Audio.play_sfx("heavy_swing", -2.0)
	var forward := -boss.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var center := boss.global_position + forward * (swing_range * 0.5)
	var ground := TelegraphDecal.find_ground(get_tree(), center + Vector3(0, 5, 0))
	var decal := TELEGRAPH.instantiate() as TelegraphDecal
	get_tree().current_scene.add_child(decal)
	decal.place(ground)
	decal.show_ring(swing_range * 0.72)
	decal.grow_to(swing_range * 0.72, 0.45)
	var pivot := boss.get_node_or_null("BodyPivot") as Node3D
	if pivot:
		create_tween().tween_property(pivot, "rotation:y", deg_to_rad(-45), 0.45).set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(0.45, false).timeout
	if not is_inside_tree():
		return
	if is_instance_valid(decal):
		decal.flash_and_free()
	Audio.play_sfx("swing", 0.0)
	_apply_damage(boss, forward)
	if pivot:
		var sw := create_tween()
		sw.tween_property(pivot, "rotation:y", deg_to_rad(70), 0.16).set_trans(Tween.TRANS_QUAD)
		sw.tween_property(pivot, "rotation:y", 0.0, 0.3)

func _apply_damage(boss: Node3D, forward: Vector3) -> void:
	var cos_half := cos(deg_to_rad(arc_degrees * 0.5))
	for p in get_tree().get_nodes_in_group("player"):
		var to: Vector3 = p.global_position - boss.global_position
		to.y = 0.0
		if to.length() <= swing_range and forward.dot(to.normalized()) >= cos_half:
			if p.has_method("take_damage"):
				p.take_damage(damage, "Barrido")