extends RigidBody2D

@export var speed = 400 # How far the player will move pixel/sec.
@export var jump = 500 # How far the player will jump.

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since t0he previous frame.
func _process(_delta: float) -> void:
	if(Input.is_action_just_released("action_jump")):
		apply_central_impulse(Vector2.UP * jump)
	pass
	
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
