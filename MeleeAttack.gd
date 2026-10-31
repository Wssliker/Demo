extends Node3D
class_name MeleeAttack

const TELEGRAPH: PackedScene = preload("res://telegraph_decal.tscn")

@onready var hitbox: Area3D = _find_hitbox()

func _find_hitbox() -> Area3D:
	var a = get_node_or_null("Hitbox") as Area3D
	if a != null: return a
	a = get_node_or_null("Area3D") as Area3D
	if a != null: return a
	return find_child("Area3D", true, false) as Area3D

var boss: CharacterBody3D
var body_pivot: Node3D
var mesh: MeshInstance3D
var base_scale: Vector3

func _ready():
	boss = get_parent().get_parent() as CharacterBody3D
	if boss:
		# El jefe puede exponer su pivote como "Model" o "BodyPivot".
		body_pivot = boss.get_node_or_null("Model") as Node3D
		if body_pivot == null:
			body_pivot = boss.get_node_or_null("BodyPivot") as Node3D
		if body_pivot:
			mesh = body_pivot.find_child("MeshInstance3D", true, false) as MeshInstance3D
			if mesh: base_scale = mesh.scale
	
	if hitbox:
		# reconecta seguro
		if hitbox.body_entered.is_connected(_on_hit):
			hitbox.body_entered.disconnect(_on_hit)
		hitbox.body_entered.connect(_on_hit)
		hitbox.monitoring = false
		hitbox.monitorable = false
		print("Melee hitbox lista: ", hitbox.get_path())
	else:
		print("ERROR Melee: no hay Area3D")

func _spawn_telegraph() -> TelegraphDecal:
	if boss == null:
		return null
	var forward := -boss.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var center := boss.global_position + forward * 3.0
	var ground := TelegraphDecal.find_ground(get_tree(), center + Vector3(0, 5, 0))
	var decal := TELEGRAPH.instantiate() as TelegraphDecal
	get_tree().current_scene.add_child(decal)
	decal.place(ground)
	decal.show_ring(3.0)
	decal.grow_to(3.0, 0.35)
	return decal

func fire():
	if not hitbox:
		return
	Audio.play_sfx("heavy_swing", -3.0)
	var decal := _spawn_telegraph()

	# Si el jefe no usa una malla localizable, el golpe igual ocurre mediante el hitbox.
	if not mesh:
		await get_tree().create_timer(0.35, false).timeout
		hitbox.monitoring = true
		Audio.play_sfx("swing", -1.0)
		if decal: decal.flash_and_free()
		await get_tree().create_timer(0.4, false).timeout
		hitbox.monitoring = false
		return

	# Anticipación (Telegraph)
	var t1 = create_tween()
	t1.tween_property(mesh, "scale", base_scale * Vector3(1.8, 0.4, 1.8), 0.35).set_trans(Tween.TRANS_BACK)
	await t1.finished

	if boss and "current_state" in boss and boss.current_state == 3: # State.STAGGERED
		mesh.scale = base_scale
		if decal: decal.flash_and_free()
		return

	# Golpe Melee
	Audio.play_sfx("swing", -1.0)
	var t2 = create_tween()
	t2.tween_property(mesh, "scale", base_scale * Vector3(0.7, 2.0, 0.7), 0.08)
	
	# Activar la zona de daño
	hitbox.monitoring = true
	if decal: decal.flash_and_free()
	
	# Mantenemos activo el hitbox el tiempo suficiente para impactar
	await get_tree().create_timer(0.4, false).timeout
	hitbox.monitoring = false

	var t3 = create_tween()
	t3.tween_property(mesh, "scale", base_scale, 0.25).set_trans(Tween.TRANS_ELASTIC)
	await t3.finished

func _on_hit(body: Node3D):
	# Detectar al jugador tanto por grupo como por nombre de nodo
	if body.is_in_group("player") or body.is_in_group("Player") or body.name.to_lower() == "player":
		if body.has_method("take_damage"):
			body.take_damage(20, "Melee")
			Audio.play_sfx("hit", 0.0)
			hitbox.set_deferred("monitoring", false)
