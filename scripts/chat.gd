extends Control

class_name Chat

static var instance: Chat

@export var animation_player: AnimationPlayer
@export var text_container: RichTextLabel

signal input_received

func _ready() -> void:
	instance = self
	
func _process(delta: float) -> void:
	if(visible and Input.is_action_just_pressed("ui_accept")):
		input_received.emit()

static func show_message(text: String) -> void:
	instance.visible = true
	instance.animation_player.play("Open")
	instance.text_container.clear()
	instance.text_container.add_text(text)
	await instance.input_received
	instance.animation_player.play("Close")
	await instance.get_tree().create_timer(1.0).timeout
	instance.visible = false
