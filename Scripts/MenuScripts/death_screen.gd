# res://Scenes/UI/death_screen.tscn → death_screen.gd
extends Node2D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_exit_pressed() -> void:
	get_tree().change_scene_to_file("res://aLevels/main_menu.tscn")

func _on_restart_pressed() -> void:
	var level = Global.get_current_level()
	if level.is_empty():
		# Fallback – should never happen if you set the level before entering
		push_warning("Global.current_level_path is empty! Restarting to test_forest.")
		level = "res://aLevels/test_forest.tscn"
	
	get_tree().change_scene_to_file(level)
