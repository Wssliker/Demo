extends Node3D

@export var sway_strength: float = 0.05
@export var sway_speed: float = 3.2
@export var cloak_lag: float = 7.0
@export var idle_breath: float = 0.012

@onready var _player: CharacterBody3D = get_parent().get_parent() as CharacterBody3D
@onready var _hood: Node3D = $Hood
@onready var _mask: Node3D = $Mask
@onready var _cloak_root: Node3D = $CloakRoot
@onready var _weapon_root: Node3D = $WeaponRoot

var _t: float = 0.0
var _cloak_rot: Vector3 = Vector3.ZERO

func _process(delta: float) -> void:
	_t += delta
	if _player == null:
		return

	var horizontal_speed: float = Vector2(_player.velocity.x, _player.velocity.z).length()
	var move_factor: float = clamp(horizontal_speed / 9.0, 0.0, 1.0)
	var pulse: float = sin(_t * sway_speed)
	var breath: float = sin(_t * 1.8) * idle_breath

	_hood.position.y = 0.72 + breath
	_mask.rotation.x = deg_to_rad(4.0 + pulse * 1.5 + move_factor * 2.0)

	var target_z: float = deg_to_rad(-5.0 - move_factor * 12.0 - max(_player.velocity.y, 0.0) * 0.04)
	var target_x: float = deg_to_rad(pulse * 2.0)
	_cloak_rot.x = lerp_angle(_cloak_rot.x, target_x, delta * cloak_lag)
	_cloak_rot.z = lerp_angle(_cloak_rot.z, target_z, delta * cloak_lag)
	_cloak_root.rotation = _cloak_rot

	_weapon_root.rotation.y = deg_to_rad(18.0 + pulse * 1.5)
	_weapon_root.rotation.z = deg_to_rad(14.0 + move_factor * 4.0)
