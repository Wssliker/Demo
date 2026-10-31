extends Area3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	# Si el jugador cae al vacío, muere/reinicia
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			# Inflige daño letal
			body.take_damage(999)
			
	# Si un enemigo o proyectil cae al vacío, se elimina
	elif body.has_method("die"):
		body.die()
	else:
		body.queue_free()
