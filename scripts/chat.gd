extends Control

class_name Chat

static var instance: Chat

@export var animation_player: AnimationPlayer
@export var text_container: RichTextLabel
@export var choices_container: VBoxContainer
@export var typing_sound: AudioStream

signal input_received
signal message_ended
signal choice_selected(choice: int)

var audio_player : AudioStreamPlayer

func _ready() -> void:
	instance = self
	audio_player = find_children("*", "AudioStreamPlayer")[0]
	
func _process(delta: float) -> void:
	if(visible and Input.is_action_just_pressed("ui_accept")):
		input_received.emit()

static func show_message(text: String, choices: Array[String]= []) -> void:
	instance.visible = true
	instance.choices_container.visible = false
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
	if(len(choices) > 0):
		show_choices(choices)
	await instance.input_received
	instance.animation_player.play("Close")
	await instance.animation_player.animation_finished
	instance.visible = false
	instance.message_ended.emit()

static func show_choices(choices: Array[String])-> void:
	for n in instance.choices_container.get_children():
		n.free()
	
	var i = 0
	for choice in choices:
		var btn := Button.new()
		btn.text = choice
		instance.choices_container.add_child(btn)
		btn.pressed.connect(select_choice.bind(i))
		i += 1
	instance.choices_container.visible = true

static func select_choice(choice: int) -> void:
	print("Clicked on choice #", choice)
	instance.choice_selected.emit(choice)
