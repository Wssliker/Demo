extends Node3D

@export var projectile_scene: PackedScene # tu Orb.tscn reutilizado
@export var shots_per_eye: int = 1

var boss: CharacterBody3D
var orbit_eyes: Node3D

func _ready():
	boss = get_parent().get_parent()
	orbit_eyes = boss.get_node("BodyPivot/OrbitEyes")

func fire():
	if not orbit_eyes or orbit_eyes.get_child_count() == 0: return
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	Audio.play_sfx("beam_charge", -6.0, 1.5)
	
	# 1. TELEGRAPH - ojos se inflan - Pilar 4
	var t1 = create_tween().set_parallel(true)
	t1.tween_property(orbit_eyes, "scale", Vector3(1.5,1.5,1.5), 0.5).set_trans(Tween.TRANS_SINE)
	
	# Flash magenta en cada ojo - gouache sucio
	for eye in orbit_eyes.get_children():
		var m = _eye_material(eye)
		if m:
			m.emission_enabled = true
			m.emission = Color(2.0, 0.5, 1.5)
	
	await get_tree().create_timer(0.6).timeout
	
	if boss.current_state == boss.State.STAGGERED:
		orbit_eyes.scale = Vector3.ONE
		return
	
	# 2. DISPARO
	for eye in orbit_eyes.get_children():
		if not is_instance_valid(eye): continue
		if boss.current_state == boss.State.STAGGERED: break
		
		for i in range(shots_per_eye):
			if not projectile_scene: continue
			var proj = projectile_scene.instantiate()
			get_tree().current_scene.add_child(proj)
			proj.global_position = eye.global_position
			
			# Si tu proyectil tiene target
			if "target" in proj:
				proj.target = player
			# Si es simple, que mire al player
			else:
				proj.look_at(player.global_position + Vector3(0,1,0), Vector3.UP)
				# Dale velocidad si es Area3D con script de movimiento
				if proj.has_method("launch"):
					proj.launch(player.global_position)
		
		# Animación de ojo disparando
		var tw = create_tween()
		tw.tween_property(eye, "scale", Vector3.ZERO, 0.08)
		tw.tween_property(eye, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK)
		
		await get_tree().create_timer(0.18).timeout
	
	# 2.5 DESTELLO DE BOCA: pequeño fogonazo pintado en cada ojo que dispara.
	# 3. RESET
	var t2 = create_tween()
	t2.tween_property(orbit_eyes, "scale", Vector3.ONE, 0.3)
	# Devolvemos el brillo cálido original de los ojos.
	for eye in orbit_eyes.get_children():
		var m = _eye_material(eye)
		if m:
			m.emission = Color(1.0, 0.95468724, 0.58383155)

func _eye_material(eye: Node) -> StandardMaterial3D:
	if eye is MeshInstance3D:
		return eye.get_active_material(0) as StandardMaterial3D
	return null
