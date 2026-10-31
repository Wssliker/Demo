extends GPUParticles3D

func _ready() -> void:
	emitting = true
	# Espera a que termine la emisión y tiempo de vida antes de borrar el nodo
	await get_tree().create_timer(lifetime + 0.1).timeout
	queue_free()
