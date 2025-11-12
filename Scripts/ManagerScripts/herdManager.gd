# BullManager.gd
extends Node

@export var bull_scene: PackedScene = preload("res://Scenes/EnemyScenes/bull.tscn") # Drag Bull.tscn here in the Inspector
@export var bull_count: int = 30 # How many bulls in the wave
@export var spawn_delay_min: float = 0.05
@export var spawn_delay_max: float = 0.1
@export var spawn_spread: float = 3.0 # Random X/Z offset around the spawn point

@onready var spawn_zone: Node3D = $SpawnZone # <-- Marker3D (or any Node3D) placed behind the player

func _ready() -> void:
	if not bull_scene:
		push_error("BullManager: bull_scene is not assigned!")
		return
	if not spawn_zone:
		push_error("BullManager: spawn_zone ($SpawnZone) not found!")
		return
	
	spawn_herd_wave()


func spawn_herd_wave() -> void:
	for i in bull_count:
		# Stagger the spawns so they come in a wave
		await get_tree().create_timer(randf_range(spawn_delay_min, spawn_delay_max)).timeout
		
		var bull: Bull = bull_scene.instantiate() as Bull
		if not bull:
			push_error("Failed to instantiate bull!")
			continue
		
		# Add the bull as a child of the manager (or the scene root – both work)
		add_child(bull)
		
		# Random position around the spawn point
		var offset := Vector3(
			randf_range(-spawn_spread, spawn_spread),
			0,
			randf_range(-spawn_spread, spawn_spread)
		)
		bull.global_position = spawn_zone.global_position + offset
