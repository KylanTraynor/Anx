extends RigidBody2D

@export var speed = 400 # How far the player will move pixel/sec.
@export var jump = 1000 # How far the player will jump.

var jump_pressed_time = -1
var is_grounded = false
var is_jumping = false
var ground = null

signal grounded_start
signal grounded_end

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since t0he previous frame.
func _process(_delta: float) -> void:
	var is_about_to_jump = jump_pressed_time != -1
	var jump_delta = Time.get_ticks_msec() - jump_pressed_time if is_about_to_jump else 0
	
	# Jump
	if(Input.is_action_just_pressed("action_jump")):
		jump_pressed_time = Time.get_ticks_msec()
		if(is_grounded):
			apply_central_impulse(Vector2.UP * jump)
			is_jumping = true
			print("Legit jump")
		else:
			print("Not grounded")
	
	# Add some tolerance for actually when you hit the ground.
	if(is_about_to_jump and jump_delta < 50 and not is_jumping and is_grounded):
		apply_central_impulse(Vector2.UP * jump)
		is_jumping = true
		print("Tolerance jump (",jump_delta,")")
	
	# Add force to the jump while the button is pressed.
	if(is_about_to_jump and Input.is_action_pressed("action_jump")):
		apply_force(Vector2.UP * jump)
		
	# Reset jump when button is released or after 200ms.
	if(Input.is_action_just_released("action_jump") or jump_delta > 200):
		is_jumping = false
		jump_pressed_time = -1
	
# Called every physic update.
func _integrate_forces(_state: PhysicsDirectBodyState2D) -> void:
	var velocity = Vector2.ZERO
	if(Input.is_action_pressed("move_left")):
		velocity.x -= 1
	if(Input.is_action_pressed("move_right")):
		velocity.x += 1
	if(velocity.length_squared() > 0):
		velocity = velocity.normalized() * speed
		$AnimatedSprite2D.play("walk")
		$AnimatedSprite2D.flip_h = velocity.x > 0
	else:
		$AnimatedSprite2D.play("idle")
	linear_velocity.x = velocity.x

# When the player collides with something.
func _on_body_shape_entered(body_rid: RID, body: Node, body_shape_index: int, local_shape_index: int):
	var body_shape_owner_id = body.shape_find_owner(body_shape_index)
	var body_shape_owner = body.shape_owner_get_owner(body_shape_owner_id)
	var body_shape_2d = body.shape_owner_get_shape(body_shape_owner_id, 0)
	var body_global_transform = body_shape_owner.global_transform

	var local_shape_owner_id = shape_find_owner(local_shape_index)
	var local_shape_owner = shape_owner_get_owner(local_shape_owner_id)
	var local_shape_2d = shape_owner_get_shape(local_shape_owner_id, 0)
	var local_global_transform = local_shape_owner.global_transform
	
	var collision_points = local_shape_2d.collide_and_get_contacts(local_global_transform, body_shape_2d, body_global_transform)
	for point in collision_points:
		var dot_product = (point - position).normalized().dot(Vector2.DOWN)
		var is_below = dot_product > 0.9
		if(is_below):
			ground = body
			if(not is_grounded):
				is_grounded = true
				grounded_start.emit()

# When the player stops colliding with something.
func _on_body_shape_exited(body_rid: RID, body: Node, body_shape_index: int, local_shape_index: int):
	if(body == ground):
		is_grounded = false
		ground = null
		grounded_end.emit()
