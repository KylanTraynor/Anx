## Main game controller that manages core game systems and global state.
## Handles camera control, player management, and game initialization.
extends Node2D

class_name Main

# Constants
const SCREEN_SHAKE_DEFAULT_AMOUNT := 100
const SCREEN_SHAKE_DEFAULT_FREQUENCY := 400
const SCREEN_SHAKE_DEFAULT_TIME := 200
const NOISE_SEED_OFFSET := 500

# Exported nodes
@export var background_music: AudioStream ## Background music track
@export var background_sound: AudioStream ## Ambient background sound
@export var base_layer: Node ## Base layer for game elements
@export var projectile_layer: Node ## Layer projectiles will be initialized into
@export var player: Node2D ## Player character reference
@export var play_area: Area2D ## Area that restricts camera movement
@export var camera: Camera2D ## Main game camera
@export var start_position: Node2D ## Player spawn position

# Signals
signal interactable_changed ## Emitted when current interactable changes
signal game_input ## Emitted when game input is detected
signal ui_input ## Emitted when UI input is detected

# State
var current_interactable: Interactable ## Currently focused interactable object
static var instance : Main ## Singleton instance

var debug_points_to_draw : Array[Vector2] = []
var debug_lines_to_draw: Array[Array] = []

## Called when the node enters the scene tree
## Initializes game systems and finds required nodes
func _ready() -> void:
	instance = self
	_initialize_required_nodes()
	new_game()

## Initializes all required nodes with validation
func _initialize_required_nodes() -> void:
	player = _find_node_if_null(player, "*", "Player", true)
	play_area = _find_node_if_null(play_area, "PlayArea", "Area2D", false)
	camera = _find_node_if_null(camera, "*", "Camera2D", true)
	start_position = _find_node_if_null(start_position, "StartPosition", "Node2D", false)

## Finds a node of specified type if the provided reference is null
## @param variable Current node reference
## @param namepattern Pattern to match node name
## @param type Type of node to find
## @param required Whether this node is required for game operation
## @return Node2D Found node or null
func _find_node_if_null(variable: Node2D, namepattern: String, type: String, required: bool) -> Node2D:
	if variable:
		return variable
		
	var nodes = find_children(namepattern, type)
	if nodes.is_empty():
		if required:
			push_error("No %s node found!" % type)
		else:
			push_warning("No %s node found. Some features may be limited." % type)
		return null
	return nodes[0]

## Called every frame
## Handles input processing and camera updates
## @param _delta Time elapsed since last frame
func _process(_delta: float) -> void:
	_process_camera_position()
	_process_interaction()
	_process_input()

## Processes player interaction with interactable objects
func _process_interaction() -> void:
	if Chat.instance and Chat.instance.visible:
		return
		
	if current_interactable and Input.is_action_just_released("action_interact"):
		current_interactable.interact()

## Processes game input and emits appropriate signals
func _process_input() -> void:
	if Input.is_anything_pressed():
		if is_in_ui():
			ui_input.emit()
		else:
			game_input.emit()

## Updates camera position and ensures it stays within bounds
func _process_camera_position() -> void:
	if not camera or not player:
		return
		
	camera.position = player.position
	ensure_camera_is_in_bounds()

## Checks if the game is currently in a UI state
## @return bool True if UI is active
func is_in_ui() -> bool:
	return Chat.instance and Chat.instance.visible

## Initializes a new game session
func new_game() -> void:
	if start_position:
		player.position = start_position.position
	Chat.show_message("", "Game starting!")

## Ensures camera stays within the play area bounds
func ensure_camera_is_in_bounds() -> void:
	if not play_area:
		return
		
	var scene_rect = play_area.get_rect()
	if not scene_rect:
		return
		
	var rect_end = scene_rect.position + Vector2(scene_rect.size)
	camera.limit_left = scene_rect.position.x
	camera.limit_top = scene_rect.position.y
	camera.limit_right = rect_end.x
	camera.limit_bottom = rect_end.y

## Sets the current interactable object
## @param interactable The interactable object to set
static func set_interactable(interactable: Interactable) -> void:
	if not instance:
		push_error("No main instance found!")
		return
		
	instance.current_interactable = interactable
	print("Press E to interact with ", interactable)
	instance.interactable_changed.emit()

## Clears the current interactable object
## @param interactable The interactable object to unset
static func unset_interactable(interactable: Interactable) -> void:
	if not instance:
		return
		
	if instance.current_interactable == interactable:
		instance.current_interactable = null
		instance.interactable_changed.emit()

## Applies screen shake effect to the camera
## @param amount Intensity of the shake
## @param frequency Frequency of the shake
## @param time Duration of the shake in milliseconds
static func shake_screen(amount := SCREEN_SHAKE_DEFAULT_AMOUNT, 
						frequency := SCREEN_SHAKE_DEFAULT_FREQUENCY, 
						time := SCREEN_SHAKE_DEFAULT_TIME) -> void:
	if not instance or not instance.camera:
		push_error("Can't shake the screen, no camera found!")
		return
		
	var noise = _setup_screen_shake_noise(frequency)
	var start_time = Time.get_ticks_msec()
	
	while Time.get_ticks_msec() < start_time + time:
		instance.camera.offset = _calculate_shake_offset(noise, start_time, amount)
		await instance.get_tree().process_frame
		
	instance.camera.offset = Vector2.ZERO

## Sets up noise generators for screen shake
## @param frequency Frequency of the noise
## @return Array containing noise generators
static func _setup_screen_shake_noise(frequency: float) -> Array:
	var noisex = FastNoiseLite.new()
	var noisey = FastNoiseLite.new()
	
	noisex.seed = 0
	noisey.seed = 0
	noisex.frequency = frequency
	noisey.frequency = frequency
	noisex.offset = Vector3(NOISE_SEED_OFFSET, 0, 0)
	
	return [noisex, noisey]

## Calculates camera offset for screen shake
## @param noise Array of noise generators
## @param start_time When the shake started
## @param amount Intensity of the shake
## @return Vector2 Camera offset
static func _calculate_shake_offset(noise: Array, start_time: int, amount: float) -> Vector2:
	var current_time = Time.get_ticks_msec() - start_time
	return Vector2(
		noise[0].get_noise_1d(current_time) * amount,
		noise[1].get_noise_1d(current_time) * amount
	)

## Gets the player instance
## @return Player The player instance or null if not found
static func get_player() -> Player:
	if not instance:
		push_error("No main instance found!")
		return null
	return instance.player
	
static func get_projectile_layer() -> Node:
	if(not instance):
		push_error("No main instance found!")
		return null
	return instance.projectile_layer

## Resets the current scene and player data
static func reset_current_scene() -> void:
	PlayerData.reset()
	if instance:
		instance.get_tree().reload_current_scene()
	else:
		push_error("No main instance found!")

static func debug_draw_point(point: Vector2):
	instance.debug_points_to_draw.append(point)
	instance.queue_redraw()

static func debug_draw_line(point_a: Vector2, point_b: Vector2, color: Color):
	instance.debug_lines_to_draw.append([point_a, point_b, color])
	instance.queue_redraw()

func _draw() :
	for p in debug_points_to_draw:
		draw_circle(p, 10, Color.BLUE)
	for l in debug_lines_to_draw:
		draw_line(l[0], l[1], l[2])
