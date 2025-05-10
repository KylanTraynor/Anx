## Turret enemy that detects the player and shoots projectiles.
## Rotates to face the player and fires at regular intervals when in range.
extends Node2D

# Shooting properties
@export var shoot_delay := 1.0 ## Time between shots in seconds
@export var projectile_scene: PackedScene ## Scene to instantiate for projectiles
@export var projectile_data: ProjectileData ## Data for the projectiles this turret fires
@export var detection_area: Area2D ## Area used to detect the player

# Internal state
var _shoot_timer := 0.0 ## Timer for controlling shot frequency
var _player: Node2D ## Reference to the player when in range

## Called when the node enters the scene tree
## Connects signals for player detection
func _ready() -> void:
	if not detection_area:
		push_error("No detection area set for turret!")
		queue_free()
		return
		
	if not projectile_data:
		push_error("No projectile data set for turret!")
		queue_free()
		return
		
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)

## Called every frame
## Handles rotation and shooting when player is in range
## @param delta Time elapsed since last frame
func _process(delta: float) -> void:
	if _player:
		_rotate_towards_player()
		_shoot_timer -= delta
		if _shoot_timer <= 0:
			_shoot()
			_shoot_timer = shoot_delay

## Rotates the turret to face the player
## Calculates angle between turret and player position
func _rotate_towards_player() -> void:
	var direction = (_player.global_position - global_position).normalized()
	rotation = direction.angle()

## Creates and fires a projectile in the current direction
## Instantiates the projectile scene and sets its direction
func _shoot() -> void:
	var projectile = projectile_scene.instantiate()
	projectile.global_position = global_position
	projectile.direction = Vector2(cos(rotation), sin(rotation))
	if(self.get_parent() is PhysicsBody2D):
		projectile.velocity = self.get_parent().velocity
	projectile.data = projectile_data
	if projectile_data.homing:
		projectile.target = _player
	if(Main.get_projectile_layer()):
		Main.get_projectile_layer().add_child(projectile)
	else:
		get_tree().root.add_child(projectile)

## Called when a body enters the detection area
## Stores reference to player if detected
## @param body The body that entered the area
func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player = body

## Called when a body exits the detection area
## Clears player reference if player left
## @param body The body that exited the area
func _on_body_exited(body: Node2D) -> void:
	if body == _player:
		_player = null
