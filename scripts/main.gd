extends Node

class_name Main

@export var background_music: AudioStream
@export var background_sound: AudioStream
@export var base_layer: Node
@export var player: Node2D

signal interactable_changed
signal game_input
signal ui_input

var current_interactable: Interactable

static var instance : Main

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	instance = self
	new_game()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$Camera.position = player.position
	ensure_camera_is_in_bounds()
	if(Chat.instance.visible):
		pass
	else:
		if(current_interactable != null and Input.is_action_just_released("ui_accept")):
			current_interactable.interact()
	if(Input.is_anything_pressed()):
		if is_in_ui() == true:
			ui_input.emit()
		else:
			game_input.emit()
	pass

func is_in_ui() -> bool:
	return(Chat.instance.visible)

func new_game() -> void:
	player.position = $StartPosition.position
	Chat.show_message("Game starting!")

func ensure_camera_is_in_bounds() -> void:
	var scene_rect = $PlayArea.get_rect()
	$Camera.limit_left = scene_rect.position.x
	$Camera.limit_top = scene_rect.position.y
	$Camera.limit_right = (scene_rect.position + Vector2(scene_rect.size)).x
	$Camera.limit_bottom = (scene_rect.position + Vector2(scene_rect.size)).y
	
	
static func set_interactable(interactable: Interactable) -> void:
	instance.current_interactable = interactable
	instance.interactable_changed.emit()

static func unset_interactable(interactable: Interactable) -> void:
	if(instance.current_interactable == interactable):
		instance.current_interactable = null
		instance.interactable_changed.emit()
