extends Resource
class_name AttackData

@export var id: String
@export var damage: int = 10
@export var charge_time: float = 1.2
@export var recover_time: float = 1.0
@export var telegraph_color: Color = Color.MAGENTA
@export var sound_charge: AudioStream
@export var sound_fire: AudioStream
