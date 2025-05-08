## Enemy controller that handles AI behavior, movement, and combat mechanics.
## Extends CharacterBody2D to provide physics-based movement and collision detection.
extends CharacterBody2D

class_name EnemyController

# Constants
const DAMAGE_FLASH_DURATION := 0.1
const DEATH_FADE_DURATION := 0.11
const DEATH_CLEANUP_DELAY := 2.0
const MIN_MOVEMENT_THRESHOLD := 0.1
const DESTINATION_REACHED_THRESHOLD := 2.0

# Configuration
@export var enemy_data : EnemyData ## Enemy type configuration data

# Movement and targeting
var destination : Vector2 = self.global_position ## Current movement target position
var target : Node2D = null ## Current target to chase/attack
var move_direction : Vector2 = Vector2.ZERO ## Normalized direction of movement

# Combat state
var _wants_to_jump = false ## Flag for jump request
var _wants_to_attack = false ## Flag for attack request
var _attack_cooldown = 0.0 ## Time remaining before next attack
var _health : int ## Current health points

# UI and feedback
var _health_indicator : ProgressBar ## UI element showing health
var _audio_player: AudioStreamPlayer2D ## Audio component for sound effects

# Signals for state changes
signal destination_changed(new_destination: Vector2) ## Emitted when movement target changes
signal target_changed(new_target: Node2D) ## Emitted when target changes
signal damaged(amount: int) ## Emitted when taking damage
signal died ## Emitted when health reaches zero

## Called when the node enters the scene tree
## Initializes health, audio, and UI components
func _ready() -> void:
	if not enemy_data:
		push_error("Enemy data not set for enemy: %s" % name)
		queue_free()
		return
		
	_health = enemy_data.health
	_setup_audio()
	_setup_health_indicator()
	_connect_signals()

## Sets up the audio player component
func _setup_audio() -> void:
	if not _audio_player:
		var nodes = find_children('*', "AudioStreamPlayer2D")
		if len(nodes) > 0:
			_audio_player = nodes[0]
		else:
			push_warning("No audio player found for enemy: %s" % name)

## Sets up the health indicator UI
func _setup_health_indicator() -> void:
	if not _health_indicator:
		var nodes = find_children("*", "ProgressBar")
		if len(nodes) > 0:
			_health_indicator = nodes[0]
		else:
			push_warning("No health indicator found for enemy: %s" % name)
	if _health_indicator:
		_health_indicator.visible = false

## Connects all required signals
func _connect_signals() -> void:
	damaged.connect(_on_damaged)
	died.connect(_on_die)

## Called every frame
## Updates AI behavior and handles attack cooldown
## @param delta Time elapsed since last frame
func _process(delta: float) -> void:
	_brain_process(delta)
	_update_attack_state(delta)

## Updates attack state and cooldown
## @param delta Time elapsed since last frame
func _update_attack_state(delta: float) -> void:
	if _wants_to_attack and _attack_cooldown <= 0.0:
		attack()
	_attack_cooldown -= delta

## Processes AI behavior including target selection and movement
## @param _delta Time elapsed since last frame
func _brain_process(_delta: float) -> void:
	_update_target()
	_update_movement()
	_check_attack_conditions()

## Updates the current target
func _update_target() -> void:
	if target: 
		set_destination(target.global_position, true)
	else: 
		set_target(Main.get_player())

## Updates movement direction based on destination
func _update_movement() -> void:
	if global_position.distance_squared_to(destination) >= DESTINATION_REACHED_THRESHOLD:
		move_direction = (destination - global_position).normalized()

## Checks if attack conditions are met
func _check_attack_conditions() -> void:
	if target and is_in_melee_range(target.global_position):
		_wants_to_attack = true

## Called every physics frame
## Handles movement, gravity, and collision detection
## @param delta Time elapsed since last physics frame
func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_jump()
	_update_horizontal_movement()
	_update_sprite_direction()
	move_and_slide()

## Applies gravity when in air
## @param delta Time elapsed since last physics frame
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

## Handles jump execution
func _handle_jump() -> void:
	if _wants_to_jump and is_on_floor(): 
		jump()

## Updates horizontal movement based on direction
func _update_horizontal_movement() -> void:
	if move_direction.length_squared() >= MIN_MOVEMENT_THRESHOLD:
		velocity.x = move_direction.x * enemy_data.speed
	else:
		velocity.x = move_toward(velocity.x, 0, enemy_data.speed)

## Updates sprite direction based on movement
func _update_sprite_direction() -> void:
	$Sprite2D.flip_h = move_direction.x > 0

## Handles damage feedback
## Plays damage sound and visual effect
## @param _amount Amount of damage taken
func _on_damaged(_amount: int) -> void:
	play_sound(enemy_data.damaged_sound)
	_flash_damage()

## Flashes the enemy red when taking damage
func _flash_damage() -> void:
	self.modulate = Color.CRIMSON
	await get_tree().create_timer(DAMAGE_FLASH_DURATION).timeout
	self.modulate = Color.WHITE

## Handles death sequence
## Disables collisions and removes enemy after death animation
func _on_die() -> void:
	await get_tree().create_timer(DEATH_FADE_DURATION).timeout
	_fade_out()
	await get_tree().create_timer(DEATH_CLEANUP_DELAY).timeout
	queue_free()

## Fades out the enemy sprite
func _fade_out() -> void:
	self.modulate = Color.from_rgba8(0, 0, 0, 50)
	self.collision_mask = 0 # Disable all collisions

## Executes jump movement
## Applies upward force and updates state
func jump() -> void:
	_wants_to_jump = false
	velocity.y = -enemy_data.jump_strength

## Handles taking damage and updates health UI
## @param amount Amount of damage to take
func damage(amount : int):
	if amount <= 0:
		push_warning("Attempted to damage enemy with non-positive amount: %d" % amount)
		return
		
	_health -= amount
	_update_health_ui()
	damaged.emit(amount)
	if _health <= 0:
		died.emit()

## Updates the health UI elements
func _update_health_ui() -> void:
	if _health_indicator:
		_health_indicator.visible = true
		_health_indicator.value = (100.0 * _health) / enemy_data.health
		BossBar.set_max(enemy_data.health)
		BossBar.set_health(_health)

## Executes melee attack if conditions are met
## Checks target validity and range before attacking
func attack() -> void:
	_wants_to_attack = false
	if not _can_attack():
		return
		
	print("Enemy attacks!")
	_attack_cooldown = enemy_data.melee_cooldown
	if target == Main.get_player():
		PlayerData.damage(1)

## Checks if attack conditions are met
## @return bool True if attack can be performed
func _can_attack() -> bool:
	if not target:
		return false
	if not is_instance_valid(target):
		target = null
		return false
	return is_in_melee_range(target.global_position)

## Checks if enemy is currently visible in the viewport
## @return bool True if enemy is on screen
func is_on_screen() -> bool:
	return $VisibleOnScreenNotifier2D.is_on_screen()

## Plays a sound effect at the enemy's position
## @param sound The audio stream to play
## @param restart Whether to restart the sound if it's already playing
func play_sound(sound: AudioStream, restart: bool = false):
	if(sound != null):
		if(not _audio_player):
			push_warning("No audio player found for ", self)
			return
		if(_audio_player.stream != sound or restart):
			_audio_player.stream = sound
			_audio_player.play()
	else:
		push_warning("Sound was null.")

## Returns the enemy's collision shape size
## @return Vector2 representing the width and height of the collision shape
func get_size() -> Vector2:
	var shape = $CollisionShape2D.shape
	if shape is CapsuleShape2D:
		return Vector2(shape.radius * 2, shape.height)
	elif shape is RectangleShape2D:
		return shape.size
	else:
		push_warning("Unrecognized enemy shape.")
		return Vector2.ZERO
	
## Checks if a point is within melee attack range
## @param point The position to check
## @return bool True if point is within attack range
func is_in_melee_range(point : Vector2) -> bool:
	return point.distance_squared_to(global_position) < (get_size().x * enemy_data.melee_range + get_size().x) ** 2
	
## Updates movement destination and emits signal
## @param new_destination New target position
## @param silent Whether to suppress the destination_changed signal
func set_destination(new_destination : Vector2, silent = false) -> void:
	destination = new_destination
	if not silent: destination_changed.emit(new_destination)

## Updates current target and requests jump
## @param new_target New target to chase/attack
func set_target(new_target : Node2D) -> void:
	target = new_target
	_wants_to_jump = true
	target_changed.emit(new_target)
