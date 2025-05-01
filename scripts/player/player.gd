extends RigidBody2D

class_name Player

@export var speed = 400 ## How far the player will move pixel/sec.
@export var damaged_sound: AudioStream ## Sound made when receiving damage.
@export_subgroup("Jump settings")
@export var jump_strength = 1000 ## How far the player will jump.
@export var jump_boost = 2 ## The jump multiplier for sustained jumps.
@export var jump_limit = 1 ## If 1, only single jumps allowed. More allows double or triple jumps.
@export var jump_tolerance = 50 ## Time in milliseconds before hitting the ground that will still trigger a jump.
@export var jump_sound: AudioStream ## Sound made when jumping.
@export var landing_sound: AudioStream ## Sound made when landing.

var jump_pressed_time = -1
var jump_counter = 0
var is_grounded = false
var is_jumping = false
var ground = null

var animated_sprite : AnimatedSprite2D
var collision_shape : CollisionShape2D

var _last_successful_ground_raycast_origin : Vector2 = Vector2.ZERO

signal grounded_start
signal grounded_end

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
func _process_jump(_delta: float) -> void:
	var is_about_to_jump = jump_pressed_time != -1
	var jump_delta = Time.get_ticks_msec() - jump_pressed_time if is_about_to_jump else 0
	# Jump
	if(Input.is_action_just_pressed("action_jump")):
		jump_pressed_time = Time.get_ticks_msec()
		register_jump(jump_tolerance)
	# Add force to the jump while the button is pressed.
	if(is_jumping and Input.is_action_pressed("action_jump")):
		apply_central_force(Vector2.UP * jump_strength * jump_boost)	
	# Reset jump when button is released or after 200ms.
	if(Input.is_action_just_released("action_jump") or jump_delta > 200):
		is_jumping = false
		jump_pressed_time = -1
	
func register_jump(tolerance: float = jump_tolerance):
	jump_pressed_time = Time.get_ticks_msec()
	if(is_grounded):
		print("Legit Jump!")
		jump()
	else:
		if(jump_counter < jump_limit):
			jump()
			return
		# Wait for ground collision.
		await grounded_start
		# Wait a frame to ensure velocity is back to 0.
		await get_tree().process_frame
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
	apply_central_impulse(Vector2.UP * jump_strength)
	is_jumping = true
	jump_counter += 1
	play_sound(jump_sound, true)
	
# Called every physic update.
func _integrate_forces(_state: PhysicsDirectBodyState2D) -> void:
	var velocity = Vector2.ZERO
	if(Input.is_action_pressed("move_left")):
		velocity.x -= 1
	if(Input.is_action_pressed("move_right")):
		velocity.x += 1
	if(velocity.length_squared() > 0):
		velocity = velocity.normalized() * speed
		animated_sprite.play("walk")
		animated_sprite.flip_h = velocity.x > 0
	else:
		animated_sprite.play("idle")
	linear_velocity.x = velocity.x

func _physics_process(_delta) -> void:
	_process_ground_check()

# Checks if the player is colliding with something under their feet.
func _process_ground_check():
	var shapeowners = self.get_shape_owners()[0]
	var shape = self.shape_owner_get_shape(shapeowners, 0)
	var width = shape.get_rect().size.x
	var height = shape.get_rect().size.y
	var origin = collision_shape.global_position
	var space_state = get_world_2d().direct_space_state
	
	
	var query = PhysicsRayQueryParameters2D.create(origin, origin + Vector2.DOWN * (height/2 + 3), 1)
	query.exclude = [self]
	var result = space_state.intersect_ray(query)
	if(result):
		_last_successful_ground_raycast_origin = Vector2.ZERO
	
	if(len(result) == 0):
		query.from = origin + _last_successful_ground_raycast_origin
		query.to = query.from + Vector2.DOWN * (height/2 + 3)
		result = space_state.intersect_ray(query)
	
	if(len(result) == 0):
		var offset = Vector2(randf_range(-width/2, width/2), 0)
		query.from = origin + offset
		query.to = query.from + Vector2.DOWN * (height/2 + 3)
		result = space_state.intersect_ray(query)
		if(result):
			_last_successful_ground_raycast_origin = offset
	
	if(result):
		if(not is_grounded):
			is_grounded = true
			ground = result["collider"]
			jump_counter = 0
			grounded_start.emit()
	else:
		if(is_grounded):
			is_grounded = false
			ground = null
			grounded_end.emit()

func _on_damaged(_amount: int) -> void:
	play_sound(damaged_sound)
	Main.shake_screen(100)
