extends Node3D

@export var bob_amount: float = 0.018
@export var bob_speed: float = 2.1
@export var cloak_follow_speed: float = 6.0
@export var walk_sway: float = 7.0

@onready var _player: CharacterBody3D = get_parent().get_parent() as CharacterBody3D
@onready var _body_root: Node3D = $BodyRoot
@onready var _cloak_root: Node3D = $BodyRoot/CloakRoot
@onready var _weapon_root: Node3D = $BodyRoot/WeaponRoot
@onready var _arm_left: Node3D = $BodyRoot/ArmLeft
@onready var _arm_right: Node3D = $BodyRoot/ArmRight

var _time: float = 0.0

func _process(delta: float) -> void:
	_time += delta
	if _player == null:
		return

	var horiz_speed: float = Vector2(_player.velocity.x, _player.velocity.z).length()
	var move_factor: float = clamp(horiz_speed / 8.0, 0.0, 1.0)
	var bob: float = sin(_time * bob_speed) * bob_amount * (0.4 + move_factor)
	_body_root.position.y = bob

	var cloak_target_x: float = deg_to_rad(-5.0 - move_factor * walk_sway - max(_player.velocity.y, 0.0) * 0.03)
	var cloak_target_z: float = deg_to_rad(sin(_time * 1.9) * (1.5 + move_factor * 3.0))
	_cloak_root.rotation.x = lerp_angle(_cloak_root.rotation.x, cloak_target_x, delta * cloak_follow_speed)
	_cloak_root.rotation.z = lerp_angle(_cloak_root.rotation.z, cloak_target_z, delta * cloak_follow_speed)

	var arm_swing: float = sin(_time * 4.5) * deg_to_rad(6.0) * move_factor
	_arm_left.rotation.x = arm_swing
	_arm_right.rotation.x = -arm_swing

	_weapon_root.rotation.y = deg_to_rad(12.0 + sin(_time * 1.7) * 2.0)
