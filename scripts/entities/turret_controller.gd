@tool
## Turret enemy that detects the player and shoots projectiles.
## Rotates to face the player and fires at regular intervals when in range.
extends Node2D

# Shooting properties
@export var shoot_delay := 1.0 ## Time between shots in seconds
@export var projectile_scene: PackedScene ## Scene to instantiate for projectiles
@export var projectile_data: ProjectileData ## Data for the projectiles this turret fires
@export var detection_range: float = 5000
@export var detection_start_angle: float = -PI
@export var detection_end_angle: float = PI
@export var detection_relative: bool = false

# Internal state
var _shoot_timer := 0.0 ## Timer for controlling shot frequency
var _player: Node2D ## Reference to the player when in range

## Called when the node enters the scene tree
## Connects signals for player detection
func _ready() -> void:
	if not projectile_data:
		push_error("No projectile data set for turret!")
		queue_free()
		return

## Called every frame
## Handles rotation and shooting when player is in range
## @param delta Time elapsed since last frame
func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()
	else:
		if _check_player_in_range():
			_rotate_towards_player()
			_shoot_timer -= delta
			if _shoot_timer <= 0:
				_shoot()
				_shoot_timer = shoot_delay

func _is_angle_between(angle, min, max) -> bool:
	while angle < min :
		angle += PI * 2
	while angle > max :
		angle -= PI * 2
	if angle < max and angle > min:
		return true
	return false

func _check_player_in_range() -> bool:
	var player = Main.get_player()
	if Geometry2D.is_point_in_circle(player.global_position, self.global_position, detection_range):
		var angle = (player.global_position - self.global_position).angle()
		if _is_angle_between(angle, detection_start_angle, detection_end_angle):
			return true
	return false

## Rotates the turret to face the player
## Calculates angle between turret and player position
func _rotate_towards_player() -> void:
	var direction = (Main.get_player().global_position - global_position).normalized()
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


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_arc(Vector2.ZERO, detection_range, detection_start_angle, detection_end_angle, 100, Color.RED, 10)
		for i in range(0, detection_range, 100):
			draw_arc(Vector2.ZERO, i, detection_start_angle, detection_end_angle, 100, Color.RED, 1)
