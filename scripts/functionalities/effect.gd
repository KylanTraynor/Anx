extends Node2D

class_name Effect

@export var random_rotation_amplitude := 0.0 ## Amount of random rotation to apply each time the effect is spawned

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AnimationPlayer.animation_finished.connect(_on_finished)
	$AnimationPlayer.play(&"play")
	$Node2D.rotation_degrees = randf_range(
		-random_rotation_amplitude/2,
		random_rotation_amplitude/2
	)

func _on_finished(_anim_name) -> void:
	queue_free()
