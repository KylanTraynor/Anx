extends Node

@export var dialogue_data: DialogueData

var processor: DialogueParser = DialogueParser.new()

func trigger() -> void:
	print("Test")
	processor.data = dialogue_data
	processor.start("0")
	processor.dialogue_processed.connect(show_dialogue)
	_process_dialog()

func _process_dialog() -> void:
	while(processor.is_running()):
		await get_tree().process_frame
		if(Input.is_action_just_released("ui_accept")):
			processor.select_option(0)
	
func show_dialogue(speaker: Variant, dialogue: String, options: Array[String]) -> void:
	print(dialogue)
	Chat.show_message(dialogue)
