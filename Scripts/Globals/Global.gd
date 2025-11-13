# res://Scripts/Global.gd
extends Node

# The path of the level that is currently playing
var current_level_path: String = ""

# Call this right before you change scene to a level
func set_current_level(path: String, level_id: int = 1) -> void:
	current_level_path = path
	current_level_id = level_id
	print("[Global] Level ", level_id, " (", path, ") set")

# Helper to get the path (used by death screen)
func get_current_level() -> String:
	return current_level_path

# Add to Global.gd (with current_level_path)
var current_level_id: int = 1  # 1=Forest, 2=City, etc.

# Helper getter
func get_current_level_id() -> int:
	return current_level_id

var game_speed: float = 1.0  # 0.1 = slow-mo, 1.0 = normal, 2.0 = fast

func set_game_speed(speed: float) -> void:
	game_speed = clamp(speed, 0.1, 2.0)
	Engine.time_scale = game_speed
	print("[Global] Game speed set to: ", game_speed, "x")

func get_game_speed() -> float:
	return game_speed
