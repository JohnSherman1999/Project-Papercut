extends Sprite3D

signal no_hp_left

@export var max_hp := 100.0

func _ready() -> void:
	$SubViewport/ProgressBar.max_value = max_hp
	$SubViewport/ProgressBar.value = max_hp


func take_damage(damage: float):
	$SubViewport/ProgressBar.max_value -= damage
	if $SubViewport/ProgressBar.value <= 0.1:
		no_hp_left.emit()
