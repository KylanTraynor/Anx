extends PathFollow2D

class_name Platform

@onready var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

# Movement settings
@export var speed = 200 ## Platform movement speed
@export var ping_pong = false ## Whether platform should reverse direction at endpoints
@export var reverse_direction = false ## Current movement direction

# Collapse settings
@export var is_collapsible := false ## Whether platform collapses when touched
@export var collapse_delay := 0.5 ## Time in seconds before platform starts falling
@export var fall_acceleration := 500.0 ## Acceleration at which platform falls
@export var destroy_on_collapse := true ## Whether to destroy platform after falling
@export var respawn_delay := 3.0 ## Time in seconds before platform respawns
@export var respawn_enabled := true ## Whether platform should respawn after collapsing

# Internal state
var _is_collapsing := false ## Whether platform is currently collapsing
var _original_position := Vector2.ZERO ## Platform's initial position
var _velocity := Vector2.ZERO ## Platform's velocity for collapse
var _default_collision_layer : int ## Collision layer the object is initialized with

## Called when the node enters the scene tree
func _ready() -> void:
	_original_position = position
	var body_node = $Area2D
	if body_node:
		body_node.body_entered.connect(_on_body_entered)
	_default_collision_layer = $AnimatableBody2D.collision_layer
	
## Called every physics frame
## Handles platform movement and collapse behavior
## @param delta Time elapsed since last physics frame
func _physics_process(delta: float) -> void:
	# Always handle movement to keep track of platform position
	_handle_movement(delta)
	# Handle collapse state
	if _is_collapsing:
		_handle_collapse(delta)

## Handles normal platform movement
## @param delta Time elapsed since last physics frame
func _handle_movement(delta: float) -> void:
	var movement = speed if not reverse_direction else -speed
	progress = progress + movement * delta
	if progress_ratio >= 1 or progress_ratio <= 0:
		reverse_direction = not reverse_direction

## Handles platform collapse behavior
## @param delta Time elapsed since last physics frame
func _handle_collapse(delta: float) -> void:
	$AnimatableBody2D.collision_layer = 0
	_velocity.y += gravity * delta * 0.5
	position.y += _velocity.y
	_velocity.y += gravity * delta * 0.5
	
	if position.y > _original_position.y + 1000:
		if destroy_on_collapse and not respawn_enabled:
			queue_free()
		elif respawn_enabled:
			_start_respawn()

## Called when a body enters the platform's collision area
## @param body The body that entered the platform
func _on_body_entered(body: Node2D) -> void:
	if not is_collapsible or _is_collapsing:
		print("Is collapsing")
		return
		
	if body is Player:
		print("Collapsing platform")
		_start_collapse()

## Initiates the platform collapse sequence
func _start_collapse() -> void:
	modulate = Color(1, 0.5, 0.5) # Red tint to indicate collapsing
	await get_tree().create_timer(collapse_delay).timeout
	_is_collapsing = true # Keep this true to start falling

func _start_respawn() -> void:
	visible = false
	await get_tree().create_timer(respawn_delay).timeout
	
	# Reset platform state
	_is_collapsing = false
	_velocity = Vector2.ZERO
	$AnimatableBody2D.collision_layer = _default_collision_layer
	modulate = Color.WHITE
	visible = true
