extends CharacterBody2D

class_name Player

@export var speed = 400 ## How far the player will move pixel/sec.
@export var damaged_sound: AudioStream ## Sound made when receiving damage.
@export_subgroup("Jump settings")
@export var jump_strength = 1500 ## How far the player will jump.
@export var jump_boost = 2 ## The jump multiplier for sustained jumps.
@export var jump_limit = 1 ## If 1, only single jumps allowed. More allows double or triple jumps.
@export var jump_tolerance = 50 ## Time in milliseconds before hitting the ground that will still trigger a jump.
@export var jump_sound: AudioStream ## Sound made when jumping.
@export var landing_sound: AudioStream ## Sound made when landing.

var jump_pressed_time = -1
var jump_counter = 0
var is_jumping = false

var animated_sprite : AnimatedSprite2D
var collision_shape : CollisionShape2D

var _last_successful_ground_raycast_origin : Vector2 = Vector2.ZERO
var _was_grounded : bool = false
var _was_walled : bool = false
var _was_ceiled : bool = false
var _last_ground_velocity = Vector2.ZERO

signal grounded_start
signal grounded_end
signal walled_start
signal walled_end
signal ceiled_start
signal ceiled_end

## Play the given sound at the player location.
func play_sound(sound: AudioStream, restart: bool = false):
	if(sound != null):
		if($PlayerAudio.stream != sound or restart):
			$PlayerAudio.stream = sound
			$PlayerAudio.play()
	else:
		push_warning("Sound was null.")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animated_sprite = find_children("*", "AnimatedSprite2D")[0]
	collision_shape = find_children("*", "CollisionShape2D")[0]
	PlayerData.get_instance().damaged.connect(_on_damaged)
	pass

# Called every frame. 'delta' is the elapsed time since t0he previous frame.
func _process(delta: float) -> void:
	if Main.instance.is_in_ui(): return
	_process_jump(delta)

# Called every frame to handle jumping functionality.
func _process_jump(delta: float) -> void:
	var is_about_to_jump = jump_pressed_time != -1
	var jump_delta = Time.get_ticks_msec() - jump_pressed_time if is_about_to_jump else 0
	# Jump
	if(Input.is_action_just_pressed("action_jump")):
		jump_pressed_time = Time.get_ticks_msec()
		register_jump(jump_tolerance)
	# Add force to the jump while the button is pressed.
	if(is_jumping and Input.is_action_pressed("action_jump")):
		velocity.y = -jump_strength
	# Reset jump when button is released or after 200ms.
	if(Input.is_action_just_released("action_jump") or jump_delta > 200):
		is_jumping = false
		jump_pressed_time = -1
	
func register_jump(tolerance: float = jump_tolerance):
	jump_pressed_time = Time.get_ticks_msec()
	if(is_on_floor()):
		print("Legit Jump!")
		jump()
	else:
		if(jump_counter < jump_limit):
			jump()
			return
		# Wait for ground collision.
		await grounded_start
		print("Grounded")
		# Wait a frame to ensure velocity is back to 0.
		await get_tree().physics_frame
		# If already jumping, then skip.
		if(is_jumping):
			return
		if(Time.get_ticks_msec() < jump_pressed_time + tolerance):
			print("Tolerance jump (",Time.get_ticks_msec() - jump_pressed_time,")")
			jump()
		else:
			jump_pressed_time = -1
			print("Grounded too late, no jumping.")

func jump() -> void:
	velocity.y = -jump_strength
	is_jumping = true
	jump_counter += 1
	play_sound(jump_sound, true)

func _physics_process(delta) -> void:
	_handle_events()
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	#if _wants_to_jump and is_on_floor(): jump()

	var move_direction = Input.get_axis("move_left", "move_right")
	if move_direction ** 2 >= 0.1:
		velocity.x = move_direction * speed
		animated_sprite.play("walk")
	else:
		if is_on_floor(): velocity.x = move_toward(velocity.x, 0, speed)
		else: velocity.x = move_toward(velocity.x, _last_ground_velocity.x, speed)
		animated_sprite.play("idle")
	
	$AnimatedSprite2D.flip_h = $AnimatedSprite2D.flip_h if move_direction == 0 else move_direction > 0

	_was_grounded = is_on_floor()
	_was_walled = is_on_wall()
	_was_ceiled = is_on_ceiling()
	if is_on_floor() : _last_ground_velocity = get_platform_velocity()
	move_and_slide()

func _handle_events() -> void:
	if not is_on_floor():
		if _was_grounded : grounded_end.emit()
	else:
		jump_counter = 0
		is_jumping = false
		if not _was_grounded : grounded_start.emit()
	
	if not is_on_wall():
		if _was_walled : walled_end.emit()
	else:
		if not _was_walled : walled_start.emit()
	
	if not is_on_ceiling():
		if _was_ceiled : ceiled_end.emit()
	else:
		if not _was_ceiled : ceiled_start.emit()

func _on_damaged(_amount: int) -> void:
	play_sound(damaged_sound)
	Main.shake_screen(100)
