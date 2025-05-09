extends PathFollow2D

class_name Platform

# Movement settings
@export var speed = 200 ## Platform movement speed
@export var ping_pong = false ## Whether platform should reverse direction at endpoints
@export var reverse_direction = false ## Current movement direction

# Collapse settings
@export var is_collapsible := false ## Whether platform collapses when touched
@export var collapse_delay := 0.5 ## Time in seconds before platform starts falling
@export var fall_acceleration := 500.0 ## Acceleration at which platform falls
@export var destroy_on_collapse := true ## Whether to destroy platform after falling

# Internal state
var _is_collapsing := false ## Whether platform is currently collapsing
var _collapse_timer := 0.0 ## Timer for collapse delay
var _original_position := Vector2.ZERO ## Platform's initial position
var _velocity := Vector2.ZERO ## Platform's velocity for collapse

## Called when the node enters the scene tree
func _ready() -> void:
	_original_position = position
	var body_node = $Area2D
	if body_node:
		body_node.body_entered.connect(_on_body_entered)

## Called every physics frame
## Handles platform movement and collapse behavior
## @param delta Time elapsed since last physics frame
func _physics_process(delta: float) -> void:
	if _is_collapsing:
		_handle_collapse(delta)
	else:
		_handle_movement(delta)

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
	if _collapse_timer > 0:
		_collapse_timer -= delta
		return
		
	_velocity.y += fall_acceleration*0.5 * delta
	position.y += _velocity.y
	_velocity.y += fall_acceleration*0.5 * delta
	
	if destroy_on_collapse and position.y > _original_position.y + 1000:
		queue_free()

## Called when a body enters the platform's collision area
## @param body The body that entered the platform
func _on_body_entered(body: Node2D) -> void:
	if not is_collapsible or _is_collapsing:
		return
		
	if body is Player:
		print("Collapsing platform")
		_start_collapse()

## Initiates the platform collapse sequence
func _start_collapse() -> void:
	_is_collapsing = true
	_collapse_timer = collapse_delay
	# Add visual feedback like shaking or color change
	modulate = Color(1, 0.5, 0.5) # Red tint to indicate collapsing
