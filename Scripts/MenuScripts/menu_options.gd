extends Control

@onready var playerCam = $Player/Head/Camera3D
var is_in_menu := false

@onready var game_speed_slider: HSlider = $GameSpeedSlider  # Path in pause menu
@onready var game_speed_label: Label = $GameSpeed

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://aLevels/main_menu.tscn")

func _on_brightness_slider_value_changed(value: float) -> void:
	playerCam.attributes.exposure_multiplier = value

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	game_speed_slider.value = Global.get_game_speed()
	game_speed_label.text = "Game Speed: %.1fx" % Global.get_game_speed()
	game_speed_slider.value_changed.connect(_on_game_speed_changed)

func _on_game_speed_changed(value: float) -> void:
	Global.set_game_speed(value)
	game_speed_label.text = "Game Speed: %.1fx" % value
