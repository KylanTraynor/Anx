extends Control

class_name Chat

static var instance: Chat

@export var animation_player: AnimationPlayer
@export var text_container: RichTextLabel
@export var typing_sound: AudioStream

signal input_received
signal message_ended

var audio_player : AudioStreamPlayer

func _ready() -> void:
	instance = self
	audio_player = find_children("*", "AudioStreamPlayer")[0]
	
func _process(delta: float) -> void:
	if(visible and Input.is_action_just_pressed("ui_accept")):
		input_received.emit()

static func show_message(text: String) -> void:
	instance.visible = true
	instance.animation_player.play("Open")
	instance.text_container.clear()
	instance.text_container.add_text(text)
	instance.text_container.visible_characters = 0
	await instance.animation_player.animation_finished
	instance.audio_player.stream = instance.typing_sound
	while(instance.text_container.visible_characters < len(text)):
		await instance.get_tree().create_timer(0.01).timeout
		instance.text_container.visible_characters += 1
		instance.audio_player.play()
	await instance.input_received
	instance.animation_player.play("Close")
	await instance.animation_player.animation_finished
	instance.visible = false
	instance.message_ended.emit()
