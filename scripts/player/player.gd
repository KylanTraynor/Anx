## Player character controller that handles movement, jumping, and combat mechanics.
## Extends CharacterBody2D to provide physics-based movement and collision detection.
extends CharacterBody2D

class_name Player

# ===============================================================================
# ==========================  CONSTANT UPDATING  ===============================
# ===============================================================================

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
@export var catch_tolerance = 0.5 ## Time in seconds of tolerance for catching projectiles
@export var throw_strength = 2000 ## Strength of the projectiles thrown
@export var melee_effect : PackedScene ## Effect for melee attacks

@export_subgroup("Dash settings")
@export var dash_speed := 4000.0  # How fast the dash is
@export var dash_distance := 1000.0  # How far the dash goes
@export var dash_cooldown := 0.1  # Cooldown in seconds

# Internal state variables
var jump_pressed_time = -1 ## Timestamp of when jump was pressed (-1 if not pressed)
var jump_counter = 0 ## Current number of jumps performed
var is_jumping = false ## Whether player is currently in a jump
var hook: Hook = null
var _is_dashing := false
var _dash_time_left := 0.0
var _interactable_objects : Array[Area2D] = []

# Node references
var animated_sprite : AnimatedSprite2D ## Reference to the sprite animation component
var collision_shape : CollisionShape2D ## Reference to the collision shape component
var animation_player : AnimationPlayer ## Reference to the animation player component

# Combat state
var _attack_direction := Vector2.ZERO ## Direction the player is facing for attacks
var _ready_to_catch_time := 0 ## Timestamp of when the player is ready to catch a projectile
var _caught_projectile : Projectile ## Projectile that the player is currently catching
var _aiming_direction := Vector2.ZERO ## Direction the player is aiming for projectiles

# Physics state tracking
var _was_grounded : bool = false ## Previous frame's ground contact state
var _was_walled : bool = false ## Previous frame's wall contact state
var _was_ceiled : bool = false ## Previous frame's ceiling contact state
var _last_ground_velocity = Vector2.ZERO ## Velocity of the platform player is standing on
var _last_attack = 0 ## Timestamp of the last attack
var _start_falling_time = 0 ## Timestamp of the time falling started
var _last_dash_time := -1000.0

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

## Called every frame
## Handles jump and attack input processing
## @param delta Time elapsed since last frame
func _process(delta: float) -> void:
	if Main.instance.is_in_ui(): 
		return
	_process_attack(delta)
	_process_projectiles_interaction()

## Called every physics frame
## Handles movement, gravity, and collision detection
## @param delta Time elapsed since last physics frame
func _physics_process(delta) -> void:
	_try_dash()
	
	var hooking = hook and Input.is_action_pressed(&"action_hook")
	if hooking:
		$Rope.set_point_position(1, hook.global_position - self.global_position)
		var direction = (hook.global_position - self.global_position).normalized()
		velocity = direction * 4000
		move_and_slide()
		return
	else:
		$Rope.set_point_position(1, Vector2.ZERO)

	if _is_dashing:
		_dash_time_left -= delta
		if _dash_time_left <= 0.0:
			_is_dashing = false
		else:
			# Optionally, disable gravity and input during dash
			move_and_slide()
			return  # Skip normal movement while dashing

	# Normal movement code below
	_handle_events()
	_handle_movement(delta)
	_update_animation()
	_process_jump(delta)
	_apply_gravity(delta)
	_update_physics_state()
	move_and_slide()
	
	_process_procedural_animation()
	_process_time_scale(delta)

## Handles jump and attack input processing
## @param _delta Time elapsed since last frame
func _process_jump(_delta: float) -> void:
	_handle_jump_input()
	_handle_jump_hold()
	_handle_jump_release()

## Handles attack input and triggers attack logic
## @param _delta Time elapsed since last frame
func _process_attack(_delta: float) -> void:
	if not _can_attack():
		return
	print("Player attacks!")
	_last_attack = Time.get_ticks_msec()
	play_animation(&"attack")
	Main.play_local_effect(melee_effect, $Visuals, Vector2(0,0), Vector2(2,2))
	_apply_attack_damage()

## Handles catch input
func _process_projectiles_interaction() -> void:
	if _caught_projectile:
		$Aim.visible = true
		$Aim.rotation = get_aiming_direction().angle()
		_caught_projectile.global_position = self.global_position + _attack_direction * get_size().x
	else:
		$Aim.visible = false
	if Input.is_action_just_pressed(&"action_catch") and not _caught_projectile:
		_ready_to_catch_time = Time.get_ticks_msec()
		for o in _interactable_objects:
			if o is Projectile:
				catch_projectile(o)
				_interactable_objects.remove_at(_interactable_objects.find(o))
				break
	elif Input.is_action_just_released(&"action_catch") and _caught_projectile:
		throw_projectile(_caught_projectile)

## Handles the time scale changes depending on context
func _process_time_scale(delta : float) -> void:
	if(_caught_projectile):
		Engine.time_scale = lerpf(Engine.time_scale, 0.5, delta * 5)
	else:
		Engine.time_scale = lerpf(Engine.time_scale, 1, delta * 5)

## Handles procedural animation effects (e.g., squash/stretch)
func _process_procedural_animation() -> void:
	if not animated_sprite: return
	var max_y_velocity = 1000.0
	var scale_x = lerp(1.0, 0.25, clamp(abs(velocity.y) / max_y_velocity, 0.0, 1.0))
	animated_sprite.scale = lerp(animated_sprite.scale, Vector2(scale_x, 1), get_physics_process_delta_time())

# ===============================================================================
# ============================  MOVEMENT GROUP  ================================
# ===============================================================================

## Handles initial jump input
func _handle_jump_input() -> void:
	if Input.is_action_just_pressed(&"action_jump"):
		jump_pressed_time = Time.get_ticks_msec()
		register_jump(jump_tolerance)

## Handles sustained jump force while button is held
func _handle_jump_hold() -> void:
	if is_jumping and Input.is_action_pressed(&"action_jump"):
		velocity.y = -jump_strength

## Handles jump button release
func _handle_jump_release() -> void:
	var is_about_to_jump = jump_pressed_time != -1
	var jump_delta = Time.get_ticks_msec() - jump_pressed_time if is_about_to_jump else 0
	if Input.is_action_just_released(&"action_jump") or jump_delta > JUMP_BUFFER_TIME:
		is_jumping = false
		jump_pressed_time = -1

## Handles dash input and triggers dash logic
func _try_dash():
	if _is_dashing:
		return
	if not Input.is_action_just_pressed(&"action_dash"):
		return
	if (Time.get_ticks_msec() < _last_dash_time + int(dash_cooldown * 1000)):
		return

	var dash_dir: Vector2
	if is_on_floor():
		# Dash along the ground tangent, always oriented rightward
		var floor_normal = get_floor_normal()
		var tangent = Vector2(-floor_normal.y, floor_normal.x).normalized()  # Rightward tangent for Godot's coordinate system
		var move_dir = Input.get_axis(&"move_left", &"move_right")
		if move_dir == 0:
			# Default to facing direction if no input
			tangent = -tangent if $Visuals.scale.x < 0 else tangent
		else:
			tangent = tangent * sign(move_dir)
		dash_dir = tangent
	else:
		# Dash horizontally in air
		dash_dir = Vector2(Input.get_axis(&"move_left", &"move_right"), 0)
		if dash_dir == Vector2.ZERO:
			dash_dir.x = (-1 if $Visuals.scale.x < 0 else 1) if animated_sprite else 1  # Default to facing direction
		dash_dir = dash_dir.normalized()
		if dash_dir == Vector2.ZERO:
			dash_dir = Vector2.RIGHT  # Fallback

	_is_dashing = true
	_dash_time_left = dash_distance / dash_speed  # Duration = distance / speed
	velocity = dash_dir * dash_speed
	_last_dash_time = Time.get_ticks_msec()

## Applies gravity to the player
## @param delta Time elapsed since last physics frame
func _apply_gravity(delta: float) -> void:
	velocity += get_gravity() * delta

## Handles horizontal and vertical movement
## @param delta Time elapsed since last physics frame
func _handle_movement(delta: float) -> void:
	var move_direction = Input.get_axis(&"move_left", &"move_right")
	if move_direction ** 2 >= MIN_MOVEMENT_THRESHOLD:
		_attack_direction.x = move_direction
		_attack_direction = _attack_direction.normalized() # IMPORTANT FOR JOYSTICKS OTHERWISE IT BREAKS PROJECTILES
		if is_on_floor():
			var tangent = get_floor_normal().orthogonal()
			if tangent.x < 0:
				tangent = -tangent
			velocity.x = move_toward(velocity.x, (move_direction) * speed, speed/acceleration)
			animated_sprite.skew = lerp(animated_sprite.skew, abs(velocity.x) / (speed*8), delta*5)
		else:
			velocity.x = move_toward(velocity.x, move_direction * speed, speed/acceleration)
			animated_sprite.skew = lerp(animated_sprite.skew, abs(velocity.x) / (speed*4), delta*5)
		play_animation(&"walk")
	else:
		animated_sprite.skew = lerpf(animated_sprite.skew, 0.0, delta*5)
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0, speed/acceleration)
		else:
			velocity.x = move_toward(velocity.x, _last_ground_velocity.x, speed/(acceleration*5))
		play_animation(&"idle")

## Executes a jump by applying upward force and updating state
func jump() -> void:
	velocity.y = -jump_strength
	is_jumping = true
	jump_counter += 1
	if(jump_counter == 1):
		play_animation(&"jump", 1)
	else:
		#var side = "l" if animated_sprite.flip_h else "r"
		play_animation(&"spin_f", 1)
	play_sound(jump_sound, true)

## Registers a jump attempt and handles jump buffering
## @param tolerance Time window in milliseconds to buffer the jump input
func register_jump(tolerance: float = jump_tolerance) -> void:
	jump_pressed_time = Time.get_ticks_msec()
	if is_on_floor():
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

# ===============================================================================
# =============================  COMBAT GROUP  =================================
# ===============================================================================

## Checks if player can attack
## @return bool True if attack can be performed
func _can_attack() -> bool:
	if not Input.is_action_just_pressed(&"action_attack"):
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
		var attack_pos = self.global_position - _attack_direction * self.get_size().x
		var to_enemy = enemy.global_position - attack_pos
		if to_enemy.dot(_attack_direction) > 0 and abs(to_enemy.x) < (melee_range * get_size().x) and abs(to_enemy.y) < (melee_range * get_size().x):
			enemy.damage(1)

## Did the player press catch within the tolerance?
func is_ready_to_catch() -> bool:
	return Time.get_ticks_msec() >= _ready_to_catch_time and Time.get_ticks_msec() < _ready_to_catch_time + 1000.0 * catch_tolerance

## Catches a projectile
## @param projectile The projectile to catch
func catch_projectile(projectile: Projectile) -> void:
	_ready_to_catch_time = -1
	_caught_projectile = projectile
	projectile.catch(self)
	print("Projectile caught!")
	
## Throws a projectile
## @param projectile The projectile to throw
func throw_projectile(projectile: Projectile) -> void:
	var direction = get_aiming_direction()
	projectile.global_position = self.global_position + direction * get_size().x
	if(projectile == _caught_projectile):
		_caught_projectile = null
	projectile.throw(direction * throw_strength, self)
	if not is_on_floor():
		velocity -= direction * throw_strength

## Get the direction the player is aiming for
func get_aiming_direction() -> Vector2:
	var direction = Input.get_vector(&"aim_neg_x", &"aim_pos_x", &"aim_neg_y", &"aim_pos_y")
	if direction.length_squared() < 0.1 and _aiming_direction != Vector2.ZERO:
		return _aiming_direction
	if direction.length_squared() < 0.1:
		_aiming_direction = _attack_direction
		return _aiming_direction
	_aiming_direction = direction.normalized()
	return _aiming_direction

# ===============================================================================
# ==========================  GENERAL / SIGNALS  ===============================
# ===============================================================================
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
	
## When something enters the interaction area
func _on_interaction_area_entered(area : Area2D) -> void:
	_interactable_objects.append(area)

## When something leaves the interaction area
func _on_interaction_area_exited(area: Area2D) -> void:
	var i = _interactable_objects.find(area)
	if i >= 0:
		_interactable_objects.remove_at(i)

## Updates animation based on movement
func _update_animation() -> void:
	var move_direction = Input.get_axis(&"move_left", &"move_right")
	$Visuals.scale.x = $Visuals.scale.x if move_direction == 0 else (
		-1 if move_direction < 0 else 1
	)

## Updates physics state tracking
func _update_physics_state() -> void:
	_was_grounded = is_on_floor()
	_was_walled = is_on_wall()
	_was_ceiled = is_on_ceiling()
	if is_on_floor():
		_last_ground_velocity = get_platform_velocity()

## Handles state change events and emits appropriate signals
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
			grounded_start.emit()
			if(Time.get_ticks_msec() > _start_falling_time + 1000*MIN_FALL_TIME):
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
		return
	if $PlayerAudio.stream != sound or restart:
		$PlayerAudio.stream = sound
		$PlayerAudio.play()

## Plays the specified animation on the player's sprite
## @param animation_name Name of the animation to play
## @param blend Animation blend time
## @param animation_speed Playback speed
func play_animation(animation_name : StringName, blend = -1.0, animation_speed = 1.0) -> void:
	if animation_name in [&"idle", &"walk"]:
		animated_sprite.play(animation_name, animation_speed)
	if animation_player.has_animation(animation_name):
		animation_player.play(animation_name, blend, animation_speed)

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
