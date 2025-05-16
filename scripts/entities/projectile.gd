## Projectile that travels in a straight line and damages the player on collision.
## Used by turrets and other enemies to attack the player.
extends Area2D

class_name Projectile

# Movement properties
var direction := Vector2.ZERO ## Direction vector for projectile movement
var velocity := Vector2.ZERO ## Current velocity vector
var thrower : CharacterBody2D ## The entity that threw the projectile
var target: Node2D ## Target for homing projectiles

# Projectile data
var data: ProjectileData ## Configuration data for this projectile
var _spawn_time: int ## When the projectile was created
var _bounces_remaining: int ## Number of bounces left before destruction
var _default_collision_layer: int ## Default collision layer
var _time_thrown : int ## When the projectile was thrown

signal bounced
signal caught(by_whom: CharacterBody2D)
signal thrown(by_whom: CharacterBody2D)

## Called when the node enters the scene tree
## Initializes the projectile with its data
func _ready() -> void:
	if not data:
		push_error("No projectile data set!")
		queue_free()
		return
		
	_spawn_time = Time.get_ticks_msec()
	_bounces_remaining = data.bounces
	_default_collision_layer = collision_layer
	
	# Setup sprite
	if data.texture:
		$Sprite2D.texture = data.texture
		$Sprite2D.scale = data.scale
		$Sprite2D.modulate = data.modulate
	
	# Play shoot sound
	if data.shoot_sound:
		$AudioStreamPlayer2D.stream = data.shoot_sound
		$AudioStreamPlayer2D.play()
	
	# Setup trail effect
	if data.trail_effect:
		var trail = data.trail_effect.instantiate()
		add_child(trail)
	
	self.body_entered.connect(_on_body_entered)
	
	# Initialize velocity based on direction and speed
	velocity += direction * data.speed

## Called every physics frame
## Moves the projectile in its direction
## @param delta Time elapsed since last physics frame
func _physics_process(delta: float) -> void:
	if Time.get_ticks_msec() - _spawn_time >= data.lifetime * 1000:
		queue_free()
		return
		
	if data.homing and target and is_instance_valid(target):
		var to_target = (target.global_position - global_position).normalized()
		direction = direction.lerp(to_target, data.homing_strength * delta)
		velocity = direction * data.speed
	
	if data.use_gravity:
		velocity.y += gravity * data.gravity_scale * delta

	position += velocity * delta
	rotation = velocity.angle()

## Called when the projectile collides with a body
## Damages the player and destroys the projectile
## @param body The body that was hit
func _on_body_entered(body: Node2D) -> void:
	if body == thrower and Time.get_ticks_msec() < 100 + _time_thrown:
		return
	
	if body is Player:
		PlayerData.damage(data.damage)
	elif body is EnemyController:
		body.damage(data.damage)
	else:  # Wall collision
		_handle_wall_collision(body)
		return
	
	_play_impact_sound()
	
	# Spawn impact effect
	if data.impact_effect:
		var effect = data.impact_effect.instantiate()
		effect.global_position = global_position
		get_parent().add_child(effect)
	
	if not data.pierce_targets:
		queue_free()

## Handles collision with walls and implements bouncing
## @param wall The wall that was hit
func _handle_wall_collision(wall: PhysicsBody2D) -> void:
	if _bounces_remaining <= 0:
		queue_free()
		return
		
	# Calculate collision normal based on relative positions
	var collision_normal = ShapeUtils.get_normal_at_(global_position, wall, wall.global_position)
	print(collision_normal)
	Main.debug_draw_line(global_position, global_position+collision_normal * 300, Color.BLUE)
	
	# Reflect direction based on collision normal
	velocity = velocity.bounce(collision_normal)
	
	# Decrease bounce count
	_bounces_remaining -= 1
	
	# Play bounce sound
	_play_impact_sound()

	# Spawn bounce effect
	if data.bounce_effect:
		var effect = data.bounce_effect.instantiate()
		effect.global_position = global_position
		get_parent().add_child(effect)
	
	# Emit bounced signal
	bounced.emit()

func _draw():
	draw_line(Vector2.ZERO, Vector2.RIGHT*500, Color.RED)

func throw(velocity: Vector2, by_whom: CharacterBody2D = null) -> void:
	self.collision_layer = _default_collision_layer
	if Main.get_projectile_layer():
		reparent(Main.get_projectile_layer())
	else:
		reparent(get_tree().root)
	self.velocity = velocity
	self.position += self.velocity * get_physics_process_delta_time()
	self.thrower = by_whom
	self._time_thrown = Time.get_ticks_msec()
	thrown.emit(by_whom)

func catch(by_whom: CharacterBody2D) -> void:
	collision_layer = 0
	reparent(by_whom)
	velocity = Vector2.ZERO
	caught.emit(by_whom)

func _play_impact_sound() -> void:
	if not data.impact_sound:
		return
	var sound = AudioStreamPlayer2D.new()
	self.get_parent().add_child(sound)
	sound.global_position = self.global_position
	sound.stream = data.impact_sound
	sound.play()
	await sound.finished
	sound.queue_free()
