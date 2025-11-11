extends Node2D


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_exit_pressed() -> void:
	get_tree().change_scene_to_file("res://aLevels/main_menu.tscn")


func _on_restart_pressed() -> void:
	get_tree().change_scene_to_file("res://aLevels/test_forest.tscn")
	#use a get tree and change the scene to the last stored scene in the database to restart level. (ABOVE IS A SIMPLE GAME RESTART)
