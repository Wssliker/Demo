extends Area3D

@export var speed: float = 9.0
@export var damage: int = 12
@export var homing_time: float = 2.0 # Tiempo durante el cual persigue al jugador
@export var lifetime: float = 4.0    # Autodestrucción si falla

var target: Node3D = null
var direction: Vector3 = Vector3.FORWARD
var time_alive: float = 0.0
var _active: bool = true

const IMPACT_SCENE: PackedScene = preload("res://scenes/ink_impact_effect.tscn")
const ORB_TEX: Texture2D = preload("res://assets/generated/fx_orb.png")

var _sprite: Sprite3D
var _glow: OmniLight3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	add_to_group("projectiles")
	# El proyectil se ve como un orbe cósmico pintado (no un mesh plano).
	for c in get_children():
		if c is MeshInstance3D:
			c.visible = false
	_sprite = Sprite3D.new()
	_sprite.texture = ORB_TEX
	_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sprite.pixel_size = 0.012
	_sprite.shaded = false
	_sprite.transparent = true
	add_child(_sprite)
	# Halo de luz que tiñe el entorno a su paso.
	_glow = OmniLight3D.new()
	_glow.light_color = Color(1.0, 0.32, 0.45, 1)
	_glow.omni_range = 7.0
	_glow.light_energy = 2.2
	add_child(_glow)

func _physics_process(delta: float) -> void:
	if not _active:
		return
	time_alive += delta
	
	# Durante el tiempo de 'homing', corrige suavemente la trayectoria hacia el jugador
	if target and is_instance_valid(target) and time_alive < homing_time:
		var target_dir = (target.global_position + Vector3(0, 1.0, 0) - global_position).normalized()
		direction = direction.lerp(target_dir, 4.0 * delta).normalized()
	
	# Movimiento en la dirección actual
	global_position += direction * speed * delta

	# Latido del orbe.
	if _sprite:
		_sprite.scale = Vector3.ONE * (1.0 + sin(time_alive * 16.0) * 0.13)

	if time_alive >= lifetime:
		_pop()

func _on_body_entered(body: Node3D) -> void:
	if body == self:
		return
	# El jugador está en el grupo "player" (minúscula). Aceptamos variantes por nombre.
	if body.is_in_group("player") or body.is_in_group("Player") or body.name.to_lower() == "player":
		if body.has_method("take_damage"):
			body.take_damage(damage)
		_pop()
		return
	# Ignoramos al propio jefe y sus partes móviles.
	if body.is_in_group("boss") or body.is_in_group("Boss") or body.is_in_group("weak_point") or body.is_in_group("climbable"):
		return
	# Cualquier otra superficie (suelo, paredes) consume el proyectil.
	_pop()

func _pop() -> void:
	if not _active:
		return
	_active = false
	if is_inside_tree():
		var fx = IMPACT_SCENE.instantiate()
		get_tree().current_scene.add_child(fx)
		fx.global_position = global_position
	queue_free()
