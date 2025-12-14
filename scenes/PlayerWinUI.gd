extends Control

@onready var win_panel = $PanelContainer
@onready var menu_button = $PanelContainer/VBoxContainer/MenuButton
@onready var time_label = $PanelContainer/VBoxContainer/TimeLabel  # Add this label



func show_win_screen():
	# Get the elapsed time from GameTimer
	var game_timer = get_tree().root.find_child("GameTimer", true, false)
	if game_timer and game_timer.has_method("get_time_string"):
		var time_string = game_timer.get_time_string()
		if time_label:
			time_label.text = "Time: " + time_string


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/title_scene.tscn")

	pass # Replace with function body.
