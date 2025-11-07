extends Control

@onready var playerCam = $Player/Head/Camera3D
var is_in_menu := false

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://aLevels/main_menu.tscn")

func _on_brightness_slider_value_changed(value: float) -> void:
	playerCam.attributes.exposure_multiplier = value

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
