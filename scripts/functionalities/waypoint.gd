extends Node

@export var target_scene: PackedScene

## Trigger the scene change.
func switch_scene() -> void:
	print("Switching scene to ", target_scene)
	get_tree().change_scene_to_packed(target_scene)
