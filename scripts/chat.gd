## Chat UI controller that handles dialogue display and choice selection.
## Manages text animation, sound effects, and user interaction.
extends Control

class_name Chat

# Constants
const TYPING_SPEED := 0.01
const DEFAULT_CHOICE := [""]

# Static instance
static var instance: Chat

# Exported nodes
@export var animation_player: AnimationPlayer ## Controls chat window animations
@export var text_container: RichTextLabel ## Displays the dialogue text
@export var choices_container: VBoxContainer ## Container for choice buttons
@export var name_container: RichTextLabel ## Displays the speaker's name
@export var typing_sound: AudioStream ## Sound played during text animation

# Signals
signal input_received ## Emitted when user confirms dialogue
signal message_ended(text: String) ## Emitted when dialogue is complete
signal choice_selected(choice: int) ## Emitted when a choice is made

# Internal state
var audio_player : AudioStreamPlayer ## Audio player for typing sound
var _is_typing := false ## Whether text is currently being animated

## Called when the node enters the scene tree
## Initializes the chat system
func _ready() -> void:
	instance = self
	_setup_audio_player()
	hide() # Start hidden

## Sets up the audio player component
func _setup_audio_player() -> void:
	var audio_nodes = find_children("*", "AudioStreamPlayer")
	if audio_nodes.is_empty():
		push_error("No AudioStreamPlayer found for chat!")
		queue_free()
		return
	audio_player = audio_nodes[0]

## Called every frame
## Handles user input for dialogue progression
## @param _delta Time elapsed since last frame
func _process(_delta: float) -> void:
	if not visible or choices_container.visible:
		return
		
	if Input.is_action_just_pressed("ui_accept"):
		input_received.emit()

## Shows a dialogue message with optional choices
## @param speaker Name of the speaker
## @param text The dialogue text to display
## @param choices Array of choice options
static func show_message(speaker: String, text: String, choices: Array = DEFAULT_CHOICE) -> void:
	if not instance:
		push_error("No chat instance found!")
		return
		
	instance._show_message_internal(speaker, text, choices)

## Internal implementation of show_message
## @param speaker Name of the speaker
## @param text The dialogue text to display
## @param choices Array of choice options
func _show_message_internal(speaker: String, text: String, choices: Array[String]) -> void:
	visible = true
	choices_container.visible = false
	
	# Setup speaker name
	var name_parent = name_container.get_parent_control()
	name_parent.visible = speaker != ""
	name_container.text = speaker
	
	# Animate window opening
	animation_player.play("Open")
	await animation_player.animation_finished
	
	# Setup and animate text
	text_container.clear()
	text_container.add_text(text)
	text_container.visible_characters = 0
	
	# Play typing animation
	await _play_typing_animation(text)
	
	# Show choices if any
	if _should_show_choices(choices):
		show_choices(choices)
		
	input_received.connect(close_message)

## Plays the typing animation for the text
## @param text The text to animate
func _play_typing_animation(text: String) -> void:
	_is_typing = true
	audio_player.stream = typing_sound
	
	while text_container.visible_characters < len(text):
		await get_tree().create_timer(TYPING_SPEED).timeout
		text_container.visible_characters += 1
		audio_player.play()
		
		if Input.is_action_just_pressed("ui_accept"):
			text_container.visible_characters = len(text)
			break
			
	_is_typing = false

## Checks if choices should be displayed
## @param choices Array of choice options
## @return bool True if choices should be shown
func _should_show_choices(choices: Array[String]) -> bool:
	return not choices.is_empty() and not (choices[0] == "" and choices.size() == 1)

## Closes the current dialogue
static func close_message() -> void:
	if not instance:
		return
		
	instance.input_received.disconnect(close_message)
	instance.animation_player.play("Close")
	await instance.animation_player.animation_finished
	instance.visible = false
	instance.message_ended.emit(instance.text_container.text)

## Shows choice buttons for the dialogue
## @param choices Array of choice options
static func show_choices(choices: Array[String]) -> void:
	if not instance:
		return
		
	instance._clear_choices()
	instance._create_choice_buttons(choices)
	instance.choices_container.visible = true

## Clears all existing choice buttons
func _clear_choices() -> void:
	for child in choices_container.get_children():
		child.free()

## Creates buttons for each choice
## @param choices Array of choice options
func _create_choice_buttons(choices: Array[String]) -> void:
	for i in range(choices.size()):
		var btn := Button.new()
		btn.text = choices[i]
		choices_container.add_child(btn)
		btn.pressed.connect(close_message)
		btn.pressed.connect(select_choice.bind(i))
		
		# Focus first button
		if i == 0:
			btn.grab_focus()

## Handles choice selection
## @param choice Index of the selected choice
static func select_choice(choice: int) -> void:
	if not instance:
		return
		
	instance.choice_selected.emit(choice)
