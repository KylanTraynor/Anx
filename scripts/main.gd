extends Node

class_name Main

@export var background_music: AudioStream
@export var background_sound: AudioStream
@export var base_layer: Node
@export var player: Node2D
@export var play_area: Area2D
@export var camera: Camera2D
@export var start_position: Node2D

signal interactable_changed
signal game_input
signal ui_input

var current_interactable: Interactable

static var instance : Main

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	instance = self
	player = try_find_children_if_null(player, "*", "Player")
	if(not player):
		push_error("No Player node found!")
	play_area = try_find_children_if_null(play_area, "PlayArea", "Area2D")
	if(not play_area):
		push_warning("No PlayArea node found. Camera will not be restricted.")
	camera = try_find_children_if_null(camera, "*", "Camera2D")
	if(not camera):
		push_error("No Camera node found!")
	start_position = try_find_children_if_null(start_position, "StartPosition", "Node2D")
	if(not start_position):
		push_warning("No StartPosition node found. Player will spawn where initially placed.")
	new_game()

func try_find_children_if_null(variable, namepattern: String, type: String):
	if variable:
		return variable
	else:
		return try_find_children(namepattern, type)

func try_find_children(namepattern: String, type: String):
	var nodes = find_children(namepattern, type)
	if(!nodes.is_empty()):
		return nodes[0]
	else:
		return null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	_process_camera_position()
	if(Chat.instance and Chat.instance.visible):
		pass
	else:
		if(current_interactable != null and Input.is_action_just_released("action_interact")):
			current_interactable.interact()
	if(Input.is_anything_pressed()):
		if is_in_ui() == true:
			ui_input.emit()
		else:
			game_input.emit()
	pass

func _process_camera_position() -> void:
	if(camera and player):
		camera.position = player.position
		ensure_camera_is_in_bounds()

func is_in_ui() -> bool:
	return(Chat.instance and Chat.instance.visible)

func new_game() -> void:
	if(start_position):
		player.position = start_position.position
	Chat.show_message("", "Game starting!")

func ensure_camera_is_in_bounds() -> void:
	if(not play_area):
		return
	var scene_rect = play_area.get_rect()
	if(scene_rect):
		camera.limit_left = scene_rect.position.x
		camera.limit_top = scene_rect.position.y
		camera.limit_right = (scene_rect.position + Vector2(scene_rect.size)).x
		camera.limit_bottom = (scene_rect.position + Vector2(scene_rect.size)).y
	
	
static func set_interactable(interactable: Interactable) -> void:
	instance.current_interactable = interactable
	print("Press E to interact with ", interactable)
	instance.interactable_changed.emit()

static func unset_interactable(interactable: Interactable) -> void:
	if(instance.current_interactable == interactable):
		instance.current_interactable = null
		instance.interactable_changed.emit()

static func shake_screen(amount = 100, frequency = 400, time = 200):
	if(not instance.camera):
		push_error("Can't shake the screen, no camera found!")
		return
	var noisex = FastNoiseLite.new()
	var noisey = FastNoiseLite.new()
	noisex.seed = 0
	noisey.seed = 0
	noisex.frequency = frequency
	noisey.frequency = frequency
	noisey.offset = Vector3(500,0 ,0)
	var start_time = Time.get_ticks_msec()
	while Time.get_ticks_msec() < start_time + time:
		instance.camera.offset = Vector2(
			noisex.get_noise_1d(Time.get_ticks_msec()-start_time) * amount,
			noisey.get_noise_1d(Time.get_ticks_msec()-start_time) * amount
		)
		await instance.get_tree().process_frame
	instance.camera.offset = Vector2.ZERO

static func get_player() -> Player:
	if not instance:
		push_error("No main node found !")
		return null
	return instance.player

static func reset_current_scene() -> void:
	PlayerData.reset()
	instance.get_tree().reload_current_scene()
