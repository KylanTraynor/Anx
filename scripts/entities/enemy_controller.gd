extends CharacterBody2D

class_name EnemyController

@export var enemy_data : EnemyData

var destination : Vector2 = self.global_position
var target : Node2D = null
var move_direction : Vector2 = Vector2.ZERO
var _wants_to_jump = false
var _wants_to_attack = false
var _attack_cooldown = 0.0
var _health : int
var _health_indicator : ProgressBar

var _audio_player: AudioStreamPlayer2D

signal destination_changed(new_destination: Vector2)
signal target_changed(new_target: Node2D)
signal damaged(amount: int)
signal died

func _ready() -> void:
	_health = enemy_data.health
	if(not _audio_player):
		var nodes = find_children('*', "AudioStreamPlayer2D")
		if(len(nodes)>0):
			_audio_player = nodes[0]
	damaged.connect(_on_damaged)
	died.connect(_on_die)
	if(not _health_indicator):
		var nodes = find_children("*", "ProgressBar")
		if(len(nodes)>0):
			_health_indicator = nodes[0]
	if(_health_indicator):
		_health_indicator.visible = false

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
	if target and is_in_melee_range(target.global_position):
		_wants_to_attack = true

## Play the given sound at the player location.
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
	return point.distance_squared_to(global_position) < (get_size().x * enemy_data.melee_range + get_size().x) ** 2
	
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
		velocity.x = move_direction.x * enemy_data.speed
	else:
		velocity.x = move_toward(velocity.x, 0, enemy_data.speed)
	
	$Sprite2D.flip_h = move_direction.x > 0

	move_and_slide()

func _on_damaged(_amount: int) -> void:
	play_sound(enemy_data.damaged_sound)
	self.modulate = Color.CRIMSON
	await get_tree().create_timer(0.1).timeout
	self.modulate = Color.WHITE

func _on_die() -> void:
	await get_tree().create_timer(0.11).timeout
	self.modulate = Color.from_rgba8(0, 0, 0, 50)
	self.collision_mask = 0 # Disable all collisions
	await get_tree().create_timer(2).timeout
	queue_free()

func jump() -> void:
	_wants_to_jump = false
	velocity.y = -enemy_data.jump_strength
	
func damage(amount : int):
	_health -= amount
	_health_indicator.visible = true
	_health_indicator.value = (100.0 * _health) / enemy_data.health
	BossBar.set_max(enemy_data.health)
	BossBar.set_health(_health)
	damaged.emit(amount)
	if(_health <= 0):
		died.emit()

func attack() -> void:
	_wants_to_attack = false
	if not target : return
	if not is_in_melee_range(target.global_position) : return
	print("Enemy attacks!")
	_attack_cooldown = enemy_data.melee_cooldown
	if target == Main.get_player():
		PlayerData.damage(1)
