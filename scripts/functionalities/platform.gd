extends PathFollow2D

@export var speed = 200
@export var ping_pong = false
@export var reverse_direction = false

func _physics_process(delta: float) -> void:
	var movement = speed if not reverse_direction else -speed
	progress = progress + movement * delta
	if progress_ratio >= 1 or progress_ratio <= 0:
		reverse_direction = not reverse_direction
