extends Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	new_game()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$Camera.position = $Player.position
	ensure_camera_is_in_bounds()
	pass

func new_game() -> void:
	$Player.position = $StartPosition.position

func ensure_camera_is_in_bounds() -> void:
	var scene_rect = $PlayArea.get_rect()
	$Camera.limit_left = scene_rect.position.x
	$Camera.limit_top = scene_rect.position.y
	$Camera.limit_right = (scene_rect.position + Vector2(scene_rect.size)).x
	$Camera.limit_bottom = (scene_rect.position + Vector2(scene_rect.size)).y
	
