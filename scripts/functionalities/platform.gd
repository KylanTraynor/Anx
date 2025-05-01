extends PathFollow2D

@export var speed = 200

func _physics_process(delta: float) -> void:
	progress = progress + speed * delta
