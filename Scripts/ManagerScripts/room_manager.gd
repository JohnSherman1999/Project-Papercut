extends Node3D

@export var basic_enemy_scene: PackedScene = preload("res://Scenes/EnemyScenes/basic_enemy.tscn")  # Adjust path
@export var crane_enemy_scene: PackedScene = preload("res://Scenes/EnemyScenes/crane_enemy.tscn")  # Adjust path
@export var dragon_boss_scene: PackedScene = preload("res://Scenes/EnemyScenes/dragon_boss.tscn")
@export var barrier_fade_time: float = 0.5  # Tween duration for seal/unlock

# Room enemy arrays
var bonus_room1_enemies: Array[Node3D] = []
var room1_enemies: Array[Node3D] = []
var room2_enemies: Array[Node3D] = []
var room3_enemies: Array[Node3D] = []

var bonus_room1_remaining: int = 0
var room1_remaining: int = 0
var room2_remaining: int = 0
var room3_remaining: int = 0

@onready var interact_label: Label = $InteractUI/Label  # CanvasLayer/Label child

func _ready():
	interact_label.visible = false
	interact_label.modulate.a = 0.0
	# Seal BonusRoom1 initially
	seal_bonus_room1(true)  # Initial seal, no tween

# BONUSROOM1
func _on_bonus_interact_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		interact_label.visible = true
		var tween = create_tween()
		tween.tween_property(interact_label, "modulate:a", 1.0, 0.2)

func _on_bonus_interact_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		interact_label.visible = false
		var tween = create_tween()
		tween.tween_property(interact_label, "modulate:a", 0.0, 0.2)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and interact_label.visible:
		# Open door (fade barriers out)
		unlock_bonus_room1()
		interact_label.visible = false
		$BonusRoom1/InteractArea/CollisionShape3D.disabled = true
		var tween = create_tween()
		tween.tween_property(interact_label, "modulate:a", 0.0, 0.2)

func _on_bonus_detection_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		seal_bonus_room1()
		spawn_bonus_room1_enemies()

func seal_bonus_room1(_initial_seal: bool = false) -> void:
	var barrier_node = $BonusRoom1.get_node("Barrier")  # The StaticBody3D
	if barrier_node:
		var meshes = barrier_node.find_children("*", "MeshInstance3D", true, false)
		var collisions = barrier_node.find_children("*", "CollisionShape3D", true, false)
		print("Sealing BonusRoom1 - Meshes found: ", meshes.size(), " Collisions found: ", collisions.size())
		for mesh in meshes:
			mesh.visible = true
		for col in collisions:
			col.disabled = false
	else:
		print("Barrier node not found for BonusRoom1")

func spawn_bonus_room1_enemies() -> void:
	var spawn_points = $BonusRoom1/SpawnPoints.get_children()
	bonus_room1_remaining = 0  # Reset counter
	print("Spawning BonusRoom1 enemies - Points found: ", spawn_points.size())
	for spawn_point in spawn_points:
		var enemy_instance: Node3D
		if "F_SpawnPoint" in spawn_point.name:
			enemy_instance = crane_enemy_scene.instantiate()
			print("Spawning crane at ", spawn_point.name)
		elif "G_SpawnPoint" in spawn_point.name:
			enemy_instance = basic_enemy_scene.instantiate()
			print("Spawning basic at ", spawn_point.name)
		else:
			continue
		
		get_parent().add_child(enemy_instance)
		enemy_instance.global_position = spawn_point.global_position
		enemy_instance.tree_exited.connect(_on_bonus_room1_enemy_died)
		bonus_room1_remaining += 1  # Increment counter
		print("BonusRoom1 remaining after spawn: ", bonus_room1_remaining)
	
	$BonusRoom1/DetectionArea/CollisionShape3D.disabled = true
	print("BonusRoom1 DetectionArea disabled")

func _on_bonus_room1_enemy_died() -> void:
	bonus_room1_remaining -= 1
	print("BonusRoom1 enemy died - Remaining: ", bonus_room1_remaining)
	if bonus_room1_remaining <= 0:
		unlock_bonus_room1()

func unlock_bonus_room1() -> void:
	var barrier_node = $BonusRoom1.get_node("Barrier")
	if barrier_node:
		var meshes = barrier_node.find_children("*", "MeshInstance3D", true, false)
		var collisions = barrier_node.find_children("*", "CollisionShape3D", true, false)
		print("Unlocking BonusRoom1 - Meshes found: ", meshes.size(), " Collisions found: ", collisions.size())
		for mesh in meshes:
			mesh.visible = false
		for col in collisions:
			col.disabled = true
	else:
		print("Barrier node not found for BonusRoom1")

# ROOM1
func _on_room1_detection_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		seal_room1()
		spawn_room1_enemies()

func seal_room1() -> void:
	var barrier_node = $Room1.get_node("Barrier")
	if barrier_node:
		var meshes = barrier_node.find_children("*", "MeshInstance3D", true, false)
		var collisions = barrier_node.find_children("*", "CollisionShape3D", true, false)
		print("Sealing Room1 - Meshes found: ", meshes.size(), " Collisions found: ", collisions.size())
		for mesh in meshes:
			mesh.visible = true
		for col in collisions:
			col.disabled = false
	else:
		print("Barrier node not found for Room1")

func spawn_room1_enemies() -> void:
	var spawn_points = $Room1/SpawnPoints.get_children()
	room1_remaining = 0  # Reset counter
	print("Spawning Room1 enemies - Points found: ", spawn_points.size())
	for spawn_point in spawn_points:
		var enemy_instance: Node3D
		if "F_SpawnPoint" in spawn_point.name:
			enemy_instance = crane_enemy_scene.instantiate()
			print("Spawning crane at ", spawn_point.name)
		elif "G_SpawnPoint" in spawn_point.name:
			enemy_instance = basic_enemy_scene.instantiate()
			print("Spawning basic at ", spawn_point.name)
		else:
			continue
		
		get_parent().add_child(enemy_instance)
		enemy_instance.global_position = spawn_point.global_position
		enemy_instance.tree_exited.connect(_on_room1_enemy_died)
		room1_remaining += 1  # Increment counter
		print("Room1 remaining after spawn: ", room1_remaining)
	
	$Room1/DetectionArea/CollisionShape3D.disabled = true
	print("Room1 DetectionArea disabled")

func _on_room1_enemy_died() -> void:
	room1_remaining -= 1
	print("Room1 enemy died - Remaining: ", room1_remaining)
	if room1_remaining <= 0:
		unlock_room1()

func unlock_room1() -> void:
	var barrier_node = $Room1.get_node("Barrier")
	if barrier_node:
		var meshes = barrier_node.find_children("*", "MeshInstance3D", true, false)
		var collisions = barrier_node.find_children("*", "CollisionShape3D", true, false)
		print("Unlocking Room1 - Meshes found: ", meshes.size(), " Collisions found: ", collisions.size())
		for mesh in meshes:
			mesh.visible = false
		for col in collisions:
			col.disabled = true
	else:
		print("Barrier node not found for Room1")

# ROOM2
func _on_room2_detection_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		seal_room2()
		spawn_room2_enemies()

func seal_room2() -> void:
	var barrier_node = $Room2.get_node("Barrier")
	if barrier_node:
		var meshes = barrier_node.find_children("*", "MeshInstance3D", true, false)
		var collisions = barrier_node.find_children("*", "CollisionShape3D", true, false)
		print("Sealing Room2 - Meshes found: ", meshes.size(), " Collisions found: ", collisions.size())
		for mesh in meshes:
			mesh.visible = true
		for col in collisions:
			col.disabled = false
	else:
		print("Barrier node not found for Room2")

func spawn_room2_enemies() -> void:
	var spawn_points = $Room2/SpawnPoints.get_children()
	room2_remaining = 0  # Reset counter
	print("Spawning Room2 enemies - Points found: ", spawn_points.size())
	for spawn_point in spawn_points:
		var enemy_instance: Node3D
		if "F_SpawnPoint" in spawn_point.name:
			enemy_instance = crane_enemy_scene.instantiate()
			print("Spawning crane at ", spawn_point.name)
		elif "G_SpawnPoint" in spawn_point.name:
			enemy_instance = basic_enemy_scene.instantiate()
			print("Spawning basic at ", spawn_point.name)
		else:
			continue
		
		get_parent().add_child(enemy_instance)
		enemy_instance.global_position = spawn_point.global_position
		enemy_instance.tree_exited.connect(_on_room2_enemy_died)
		room2_remaining += 1  # Increment counter
		print("Room2 remaining after spawn: ", room2_remaining)
	
	$Room2/DetectionArea/CollisionShape3D.disabled = true
	print("Room2 DetectionArea disabled")

func _on_room2_enemy_died() -> void:
	room2_remaining -= 1
	print("Room2 enemy died - Remaining: ", room2_remaining)
	if room2_remaining <= 0:
		unlock_room2()

func unlock_room2() -> void:
	var barrier_node = $Room2.get_node("Barrier")
	if barrier_node:
		var meshes = barrier_node.find_children("*", "MeshInstance3D", true, false)
		var collisions = barrier_node.find_children("*", "CollisionShape3D", true, false)
		print("Unlocking Room2 - Meshes found: ", meshes.size(), " Collisions found: ", collisions.size())
		for mesh in meshes:
			mesh.visible = false
		for col in collisions:
			col.disabled = true
	else:
		print("Barrier node not found for Room2")

# ROOM3
func _on_room3_detection_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		seal_room3()
		spawn_room3_enemies()

func seal_room3() -> void:
	var barrier_node = $Room3.get_node("Barrier")
	if barrier_node:
		var meshes = barrier_node.find_children("*", "MeshInstance3D", true, false)
		var collisions = barrier_node.find_children("*", "CollisionShape3D", true, false)
		print("Sealing Room3 - Meshes found: ", meshes.size(), " Collisions found: ", collisions.size())
		for mesh in meshes:
			mesh.visible = true
		for col in collisions:
			col.disabled = false
	else:
		print("Barrier node not found for Room3")

func spawn_room3_enemies() -> void:
	var spawn_points = $Room3/SpawnPoints.get_children()
	room3_remaining = 0  # Reset counter
	print("Spawning Room3 boss - Points found: ", spawn_points.size())
	for spawn_point in spawn_points:
		var boss_instance = dragon_boss_scene.instantiate()
		get_parent().add_child(boss_instance)
		boss_instance.global_position = spawn_point.global_position
		boss_instance.boss_defeated.connect(_on_room3_enemy_died)
		room3_remaining += 1  # Increment (1 per spawn point; use 1 point for single boss)
		print("Room3 boss spawned at ", spawn_point.name, " - Remaining: ", room3_remaining)
	
	$Room3/DetectionArea/CollisionShape3D.disabled = true
	print("Room3 DetectionArea disabled")

func _on_room3_enemy_died() -> void:
	room3_remaining -= 1
	print("Room3 enemy died - Remaining: ", room3_remaining)
	if room3_remaining <= 0:
		Global.set_current_level("res://aLevels/City.tscn", 2)
		get_tree().call_deferred("change_scene_to_file", "res://aLevels/City.tscn")
