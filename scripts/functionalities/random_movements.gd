extends Node2D

func _process(delta: float) -> void:
	position.x = position.x + randf_range(-500, +500) * delta
	position.y = position.y + randf_range(-500, +500) * delta
