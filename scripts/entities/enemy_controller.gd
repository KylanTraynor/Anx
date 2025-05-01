extends CharacterBody2D

@export var speed = 300.0
@export var jump_velocity = 400.0
@export var melee_cooldown = 2.0 ## Number of seconds of cooldown between basic attacks.
@export var melee_range = 2.0 ## Melee range measured in number of widths of the enemy.

var destination : Vector2 = self.position
var target : Node2D = null
var move_direction : Vector2 = Vector2.ZERO
var _wants_to_jump = false
var _wants_to_attack = false
var _attack_cooldown = 0.0

signal destination_changed(new_destination: Vector2)
signal target_changed(new_target: Node2D)

func _process(delta: float) -> void:
	_brain_process(delta)
	if _wants_to_attack and _attack_cooldown <= 0.0:
		attack()
	_attack_cooldown -= delta

func _brain_process(_delta: float) -> void:
	if target: set_destination(target.global_position, true)
	else: set_target(Main.get_player())
	if global_position.distance_squared_to(destination) >= 2 :
		move_direction = (destination - global_position).normalized()
	if is_in_melee_range(target.global_position):
		_wants_to_attack = true

func get_size() -> Vector2:
	var shape = $CollisionShape2D.shape
	if shape is CapsuleShape2D:
		return Vector2(shape.radius * 2, shape.height)
	elif shape is RectangleShape2D:
		return shape.size
	else:
		push_warning("Unrecognized enemy shape.")
		return Vector2.ZERO
	
func is_in_melee_range(point : Vector2) -> bool:
	return point.distance_squared_to(global_position) < (get_size().x * melee_range) ** 2
	
func set_destination(new_destination : Vector2, silent = false) -> void:
	destination = new_destination
	if not silent: destination_changed.emit(new_destination)

func set_target(new_target : Node2D) -> void:
	target = new_target
	_wants_to_jump = true
	target_changed.emit(new_target)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
	#	velocity.y = JUMP_VELOCITY
	if _wants_to_jump and is_on_floor(): jump()

	if move_direction.length_squared() >= 0.1:
		velocity.x = move_direction.x * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
	
	if move_direction.x > 0:
		$Sprite2D.scale.x = -1
	else:
		$Sprite2D.scale.x = 1

	move_and_slide()

func jump() -> void:
	_wants_to_jump = false
	velocity.y = -jump_velocity

func attack() -> void:
	_wants_to_attack = false
	if not target : return
	if not is_in_melee_range(target.global_position) : return
	print("Enemy attacks!")
	_attack_cooldown = melee_cooldown
	if target == Main.get_player():
		PlayerData.damage(1)
