extends Area3D
## Mancha independiente. El dano depende exclusivamente de la superposicion fisica.

@export_range(0.5, 8.0, 0.1) var radius: float = 2.2
@export_range(1, 100, 1) var damage: int = 10
@export_range(0.2, 15.0, 0.1) var lifetime: float = 3.5
@export_range(0.15, 3.0, 0.05) var damage_interval: float = 0.6

@onready var _shape_node: CollisionShape3D = $CollisionShape3D
@onready var _visual: MeshInstance3D = $Visual

var _material: ShaderMaterial
var _life_elapsed: float = 0.0
var _damage_elapsed: float = 0.0
var _closing: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = false
	var source_material: ShaderMaterial = _visual.material_override as ShaderMaterial
	if source_material != null:
		_material = source_material.duplicate() as ShaderMaterial
		_visual.material_override = _material
	_apply_radius()
	body_entered.connect(_on_body_entered)

func configure(new_radius: float, new_damage: int, new_lifetime: float, new_interval: float) -> void:
	radius = maxf(0.5, new_radius)
	damage = maxi(1, new_damage)
	lifetime = maxf(0.2, new_lifetime)
	damage_interval = maxf(0.15, new_interval)
	if is_node_ready():
		_apply_radius()

func _apply_radius() -> void:
	var shape: CylinderShape3D = _shape_node.shape.duplicate() as CylinderShape3D
	shape.radius = radius
	shape.height = 0.55
	_shape_node.shape = shape
	_visual.scale = Vector3(radius, 1.0, radius)

func _on_body_entered(body: Node3D) -> void:
	if _closing:
		return
	if body.is_in_group("player"):
		_hit_player(body)
		_damage_elapsed = 0.0

func _physics_process(delta: float) -> void:
	if _closing:
		return
	_life_elapsed += delta
	if _life_elapsed >= lifetime:
		_expire()
		return
	var players: Array[Node3D] = []
	for body in get_overlapping_bodies():
		if body is Node3D and body.is_in_group("player"):
			players.append(body)
	if players.is_empty():
		_damage_elapsed = 0.0
		return
	_damage_elapsed += delta
	if _damage_elapsed >= damage_interval:
		_damage_elapsed = 0.0
		for body in players:
			_hit_player(body)

func _hit_player(body: Node3D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage, "Marca oscura")

func _expire() -> void:
	_closing = true
	monitoring = false
	_shape_node.set_deferred("disabled", true)
	if _material != null:
		var tween: Tween = create_tween()
		tween.tween_method(_set_fade, 1.0, 0.0, 0.35)
		tween.tween_callback(queue_free)
	else:
		queue_free()

func _set_fade(value: float) -> void:
	if _material != null:
		_material.set_shader_parameter("fade", value)
