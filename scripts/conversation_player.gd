extends Node

@export var dialogue_data: DialogueData

var processor: DialogueParser = DialogueParser.new()

var waiting_for_choice: bool = false

func trigger() -> void:
	processor.data = dialogue_data
	processor.dialogue_processed.connect(show_dialogue)
	processor.start("0")
	_process_dialog()

func _process_dialog() -> void:
	while(processor.is_running()):
		if(waiting_for_choice):
			var choice = await Chat.instance.choice_selected
			print("Made choice: #", choice)
			processor.select_option(choice)
		else:
			await Chat.instance.message_ended
			processor.select_option(0)
	
func show_dialogue(speaker: Variant, dialogue: String, options: Array[String]) -> void:
	print(dialogue)
	if(len(options) > 0):
		waiting_for_choice = true
	else:
		waiting_for_choice = false
	Chat.show_message(dialogue, options)
