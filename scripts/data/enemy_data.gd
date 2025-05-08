extends Resource

class_name EnemyData

@export var name: String = "Enemy"
@export var speed: float = 400.0
@export var jump_strength: float = 1200.0

@export_category("Combat")
@export var health: int = 5
@export var base_damage: int = 1
@export var melee_cooldown: float = 2.0 ## Base cooldown between actions.
@export var melee_range: float = 2.0 ## Range for melee attacks (collider width based).
@export var melee_attacks: Array[ActionData] = [] ## The list of melee attacks available.
@export var ranged_attacks: Array[ActionData] = [] ## The list of ranged attacks available.
@export var damaged_sound: AudioStream ## Sound played when damaged.
