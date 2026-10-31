extends Node3D
# En OrbitEyes.gd (ponlo en el Node3D OrbitEyes)
func _process(delta):
	rotate_y(2.5 * delta)
	for child in get_children():
		child.position.y += sin(Time.get_ticks_msec() * 0.002 + child.get_index()) * 0.01
