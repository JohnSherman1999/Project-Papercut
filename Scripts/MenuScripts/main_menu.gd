extends Node2D

func _on_play_pressed() -> void:
	Global.set_current_level("res://aLevels/test_forest.tscn", 1)
	get_tree().change_scene_to_file("res://aLevels/test_forest.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
	
func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Settings/menu_options.tscn")
