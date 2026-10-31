extends Node3D

func _ready() -> void:
	var core: MeshInstance3D = get_node_or_null("Core") as MeshInstance3D
	if core != null and core.material_override != null:
		core.material_override = core.material_override.duplicate()
