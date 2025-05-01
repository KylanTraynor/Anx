extends Resource

class_name EnemyData

@export var name: String = "Enemy"
@export var health: int = 5
@export var speed: float = 400.0
@export var jump_strength: float = 1200.0

@export var base_damage: int = 1
@export var attacks: Array[ActionData] = []
