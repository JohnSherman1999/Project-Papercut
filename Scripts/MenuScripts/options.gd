extends Control

@onready var playerCam = $"../Head/Camera3D"
var is_in_menu := false

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://aLevels/main_menu.tscn")

func _on_brightness_slider_value_changed(value: float) -> void:
	playerCam.attributes.exposure_multiplier = value

func _ready():
	if playerCam:
		print("cam ready")
	else:
		print("no cam")
	if get_tree().current_scene.name == "options":
		visible = true
	else:
		visible = false

func _input(event):
	if event.is_action_pressed("pause"):
		toggle_options()

func toggle_options():
	if visible == true:
		visible = false
	else:
		visible = true
	if visible:
		get_tree().paused = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		get_tree().paused = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
