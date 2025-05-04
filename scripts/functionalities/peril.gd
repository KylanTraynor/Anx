extends Area2D

@export var damage_amount: int = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if(body == Main.get_player()):
		print("Damaging player!")
		PlayerData.damage(damage_amount)
