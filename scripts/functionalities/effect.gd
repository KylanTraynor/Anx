extends Node2D

class_name Effect

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AnimationPlayer.animation_finished.connect(_on_finished)
	$AnimationPlayer.play(&"play")

func _on_finished() -> void:
	queue_free()
