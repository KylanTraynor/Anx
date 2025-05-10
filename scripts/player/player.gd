## Player character controller that handles movement, jumping, and combat mechanics.
## Extends CharacterBody2D to provide physics-based movement and collision detection.
extends CharacterBody2D

class_name Player

# Constants
const DAMAGE_FLASH_DURATION := 0.1
const DEATH_FADE_DURATION := 0.11
const DEATH_CLEANUP_DELAY := 2.0
const JUMP_BUFFER_TIME := 200.0
const MIN_MOVEMENT_THRESHOLD := 0.1
const MIN_FALL_TIME := 0.2

# Movement properties
@export var speed = 400 ## Base movement speed in pixels per second
@export var acceleration = 10.0 ## Movement smoothing factor (1 = instant acceleration, higher = smoother)

# Audio feedback
@export var damaged_sound: AudioStream ## Sound effect played when player takes damage

@export_subgroup("Jump settings")
@export var jump_strength = 1500 ## Initial upward force applied when jumping
@export var jump_boost = 2 ## Multiplier for sustained jump force while button is held
@export var jump_limit = 1 ## Maximum number of consecutive jumps allowed (1 = single jump only)
@export var jump_tolerance = 50 ## Buffer time in milliseconds for jump input before landing
@export var jump_sound: AudioStream ## Sound effect played when jumping
@export var landing_sound: AudioStream ## Sound effect played when landing on ground

@export_subgroup("Combat settings")
@export var melee_range = 5 ## Attack range in units of player width
@export var attack_cooldown = 0.5 ## Minimum time between attacks in seconds

# Internal state variables
var jump_pressed_time = -1 ## Timestamp of when jump was pressed (-1 if not pressed)
var jump_counter = 0 ## Current number of jumps performed
var is_jumping = false ## Whether player is currently in a jump

# Node references
var animated_sprite : AnimatedSprite2D ## Reference to the sprite animation component
var collision_shape : CollisionShape2D ## Reference to the collision shape component
var animation_player : AnimationPlayer ## Reference to the animation player component

# Combat state
var attack_direction := Vector2.ZERO ## Direction the player is facing for attacks

# Physics state tracking
var _was_grounded : bool = false ## Previous frame's ground contact state
var _was_walled : bool = false ## Previous frame's wall contact state
var _was_ceiled : bool = false ## Previous frame's ceiling contact state
var _last_ground_velocity = Vector2.ZERO ## Velocity of the platform player is standing on
var _last_attack = 0 ## Timestamp of the last attack
var _start_falling_time = 0 ## Timestamp of the time falling started

# Signals for state changes
signal grounded_start ## Emitted when player first touches ground
signal grounded_end ## Emitted when player leaves ground
signal walled_start ## Emitted when player first touches wall
signal walled_end ## Emitted when player leaves wall
signal ceiled_start ## Emitted when player first touches ceiling
signal ceiled_end ## Emitted when player leaves ceiling

## Called when the node enters the scene tree
## Initializes node references and connects signals
func _ready() -> void:
	_setup_node_references()
	_connect_signals()

## Sets up references to required nodes
func _setup_node_references() -> void:
	var sprite_nodes = find_children("*", "AnimatedSprite2D")
	var collision_nodes = find_children("*", "CollisionShape2D")
	var animation_nodes = find_children("*", "AnimationPlayer")
	
	if sprite_nodes.is_empty():
		push_error("No AnimatedSprite2D found for player")
		queue_free()
		return
	if collision_nodes.is_empty():
		push_error("No CollisionShape2D found for player")
		queue_free()
		return
	if animation_nodes.is_empty():
		push_error("No AnimationPlayer found for player")
		queue_free()
		return
		
	animated_sprite = sprite_nodes[0]
	collision_shape = collision_nodes[0]
	animation_player = animation_nodes[0]

## Connects all required signals
func _connect_signals() -> void:
	var player_data = PlayerData.get_instance()
	if not player_data:
		push_error("PlayerData singleton not found")
		queue_free()
		return
		
	player_data.damaged.connect(_on_damaged)
	player_data.die.connect(_on_die)

## Called every frame
## Handles jump and attack input processing
## @param delta Time elapsed since last frame
func _process(delta: float) -> void:
	if Main.instance.is_in_ui(): 
		return
	
	_process_attack(delta)

## Processes jump input and state
## Handles jump button press, hold, and release
## @param _delta Time elapsed since last frame
func _process_jump(_delta: float) -> void:
	_handle_jump_input()
	_handle_jump_hold()
	_handle_jump_release()

## Handles initial jump input
func _handle_jump_input() -> void:
	if Input.is_action_just_pressed("action_jump"):
		jump_pressed_time = Time.get_ticks_msec()
		register_jump(jump_tolerance)

## Handles sustained jump force while button is held
func _handle_jump_hold() -> void:
	if is_jumping and Input.is_action_pressed("action_jump"):
		velocity.y = -jump_strength

## Handles jump button release
## @param jump_delta Time since jump was initiated
func _handle_jump_release() -> void:
	var is_about_to_jump = jump_pressed_time != -1
	var jump_delta = Time.get_ticks_msec() - jump_pressed_time if is_about_to_jump else 0
	if Input.is_action_just_released("action_jump") or jump_delta > JUMP_BUFFER_TIME:
		is_jumping = false
		jump_pressed_time = -1

## Processes attack input and performs melee attacks
## Checks for enemies in range and applies damage
## @param _delta Time elapsed since last frame
func _process_attack(_delta: float) -> void:
	if not _can_attack():
		return
		
	print("Player attacks!")
	_last_attack = Time.get_ticks_msec()
	_apply_attack_damage()

## Checks if player can attack
## @return bool True if attack can be performed
func _can_attack() -> bool:
	if not Input.is_action_just_pressed("action_attack"):
		return false
	if Time.get_ticks_msec() <= _last_attack + attack_cooldown * 1000:
		return false
	return true

## Applies damage to enemies in range
func _apply_attack_damage() -> void:
	var enemies = Main.instance.find_children("*", "EnemyController")
	for enemy in enemies:
		if not enemy.is_on_screen():
			continue
		var attack_pos = self.global_position - self.attack_direction * self.get_size().x
		var to_enemy = enemy.global_position - attack_pos
		if to_enemy.dot(self.attack_direction) > 0 and abs(to_enemy.x) < (melee_range * get_size().x) and abs(to_enemy.y) < (melee_range * get_size().x):
			enemy.damage(1)

## Registers a jump attempt and handles jump buffering
## @param tolerance Time window in milliseconds to buffer the jump input
func register_jump(tolerance: float = jump_tolerance) -> void:
	jump_pressed_time = Time.get_ticks_msec()
	if is_on_floor():
		print("Legit Jump!")
		jump()
	else:
		_handle_air_jump(tolerance)

## Handles jump attempt while in air
## @param tolerance Time window in milliseconds to buffer the jump input
func _handle_air_jump(tolerance: float) -> void:
	if jump_counter < jump_limit:
		jump()
		return
		
	# Wait for ground collision
	await grounded_start
	print("Grounded")
	
	# Wait a frame to ensure velocity is back to 0
	await get_tree().physics_frame
	
	# Check if we can still jump
	if is_jumping:
		return
		
	if Time.get_ticks_msec() < jump_pressed_time + tolerance:
		print("Tolerance jump (", Time.get_ticks_msec() - jump_pressed_time, ")")
		jump()
	else:
		jump_pressed_time = -1
		print("Grounded too late, no jumping.")

## Executes a jump by applying upward force and updating state
func jump() -> void:
	velocity.y = -jump_strength
	is_jumping = true
	jump_counter += 1
	print("Jump counter: ", jump_counter)
	play_animation(&"jump", 1)
	play_sound(jump_sound, true)

## Called every physics frame
## Handles movement, gravity, and collision detection
## @param delta Time elapsed since last physics frame
func _physics_process(delta) -> void:
	_handle_events()
	_handle_movement(delta)
	_update_animation()
	_process_jump(delta)
	
	_apply_gravity(delta)
	
	_update_physics_state()
	
	move_and_slide()

## Applies gravity when in air
## @param delta Time elapsed since last physics frame
func _apply_gravity(delta: float) -> void:
	#if not is_on_floor():
	velocity += get_gravity() * delta

## Handles horizontal movement
func _handle_movement(delta: float) -> void:
	var move_direction = Input.get_axis(&"move_left", &"move_right")
	if move_direction ** 2 >= MIN_MOVEMENT_THRESHOLD:
		attack_direction.x = move_direction
		if is_on_floor():
			var tangent = get_floor_normal().orthogonal()
			if tangent.x < 0:
				tangent = -tangent
			#print("Normal: ", get_floor_normal(), "; Tangent: ", get_floor_normal().orthogonal())
			#print("Adjusted:", tangent)
			velocity.x = move_toward(velocity.x, (move_direction * tangent.x) * speed, speed/acceleration)
			velocity.y = move_toward(velocity.y, (move_direction * tangent.y) * 5 * speed, speed/acceleration)
			animated_sprite.skew = lerp(animated_sprite.skew, velocity.x / (speed*12), delta*5)
		else:
			velocity.x = move_toward(velocity.x, move_direction * speed, speed/acceleration)
			animated_sprite.skew = lerp(animated_sprite.skew, velocity.x / (speed*4), delta*5)
		play_animation(&"walk")
	else:
		animated_sprite.skew = lerpf(animated_sprite.skew, 0.0, delta*5)
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0, speed/acceleration)
		else:
			velocity.x = move_toward(velocity.x, _last_ground_velocity.x, speed/(acceleration*5))
		play_animation(&"idle")
	#print("Velocity: ", velocity)

## Updates animation based on movement
func _update_animation() -> void:
	var move_direction = Input.get_axis("move_left", "move_right")
	animated_sprite.flip_h = animated_sprite.flip_h if move_direction == 0 else move_direction > 0

## Updates physics state tracking
func _update_physics_state() -> void:
	_was_grounded = is_on_floor()
	_was_walled = is_on_wall()
	_was_ceiled = is_on_ceiling()
	if is_on_floor():
		_last_ground_velocity = get_platform_velocity()

## Handles state change events and emits appropriate signals
## Manages ground, wall, and ceiling contact state changes
func _handle_events() -> void:
	_handle_ground_events()
	_handle_wall_events()
	_handle_ceiling_events()

## Handles ground contact state changes
func _handle_ground_events() -> void:
	if not is_on_floor():
		if _was_grounded:
			grounded_end.emit()
			_start_falling_time = Time.get_ticks_msec()
	else:
		jump_counter = 0
		is_jumping = false
		if not _was_grounded:
			if(Time.get_ticks_msec() > _start_falling_time + 1000*MIN_FALL_TIME):
				print("Landed")
				grounded_start.emit()
				play_animation(&"land")

## Handles wall contact state changes
func _handle_wall_events() -> void:
	if not is_on_wall():
		if _was_walled:
			walled_end.emit()
	else:
		if not _was_walled:
			walled_start.emit()

## Handles ceiling contact state changes
func _handle_ceiling_events() -> void:
	if not is_on_ceiling():
		if _was_ceiled:
			ceiled_end.emit()
	else:
		if not _was_ceiled:
			ceiled_start.emit()

## Handles player damage feedback
## Plays damage sound and visual effect
## @param _amount Amount of damage taken
func _on_damaged(_amount: int) -> void:
	play_sound(damaged_sound)
	_flash_damage()
	Main.shake_screen(100)

## Flashes the player red when taking damage
func _flash_damage() -> void:
	self.modulate = Color.CRIMSON
	await get_tree().create_timer(DAMAGE_FLASH_DURATION).timeout
	self.modulate = Color.WHITE

## Handles player death sequence
## Disables collisions and resets the scene after death animation
func _on_die() -> void:
	await get_tree().create_timer(DEATH_FADE_DURATION).timeout
	_fade_out()
	await get_tree().create_timer(DEATH_CLEANUP_DELAY).timeout
	Main.reset_current_scene()

## Fades out the player sprite
func _fade_out() -> void:
	self.modulate = Color.from_rgba8(0, 0, 0, 50)
	self.collision_mask = 1 # Disable all collisions

## Plays a sound effect at the player's position
## @param sound The audio stream to play
## @param restart Whether to restart the sound if it's already playing
func play_sound(sound: AudioStream, restart: bool = false):
	if sound == null:
		push_warning("Sound was null.")
		return
		
	if $PlayerAudio.stream != sound or restart:
		$PlayerAudio.stream = sound
		$PlayerAudio.play()

## Plays the specified animation on the player's sprite
## @param animation_name Name of the animation to play
func play_animation(animation_name : StringName, blend = -1.0, speed = 1.0) -> void:
	if animation_name in [&"idle", &"walk"]:
		animated_sprite.play(animation_name, speed)
	if animation_player.has_animation(animation_name):
		animation_player.play(animation_name, blend, speed)

## Returns the player's collision shape size
## @return Vector2 representing the width and height of the collision shape
func get_size() -> Vector2:
	var shape = $CollisionShape2D.shape
	if shape is CapsuleShape2D:
		return Vector2(shape.radius * 2, shape.height)
	elif shape is RectangleShape2D:
		return shape.size
	else:
		push_warning("Unrecognized player shape.")
		return Vector2.ZERO
