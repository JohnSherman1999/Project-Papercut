extends Node3D

@export var basic_enemy_scene: PackedScene = preload("res://Scenes/EnemyScenes/basic_enemy.tscn")  # Adjust path
@export var crane_enemy_scene: PackedScene = preload("res://Scenes/EnemyScenes/crane_enemy.tscn")  # Adjust path
@export var barrier_fade_time: float = 0.5  # Tween duration for seal/unlock

# Room enemy arrays
var bonus_room1_enemies: Array[Node3D] = []
var room1_enemies: Array[Node3D] = []
var room2_enemies: Array[Node3D] = []
var room3_enemies: Array[Node3D] = []

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
	bonus_room1_enemies.clear()
	for spawn_point in spawn_points:
		if "F_SpawnPoint" in spawn_point.name:
			var crane = crane_enemy_scene.instantiate()
			get_parent().add_child(crane)
			crane.global_position = spawn_point.global_position
			crane.tree_exited.connect(_on_bonus_room1_enemy_died)
			bonus_room1_enemies.append(crane)
		elif "G_SpawnPoint" in spawn_point.name:
			var enemy = basic_enemy_scene.instantiate()
			get_parent().add_child(enemy)
			enemy.global_position = spawn_point.global_position
			enemy.tree_exited.connect(_on_bonus_room1_enemy_died)
			bonus_room1_enemies.append(enemy)

func _on_bonus_room1_enemy_died() -> void:
	var remaining = 0
	for enemy in bonus_room1_enemies:
		if is_instance_valid(enemy):
			remaining += 1
	if remaining == 0:
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
	room1_enemies.clear()
	for spawn_point in spawn_points:
		if "F_SpawnPoint" in spawn_point.name:
			var crane = crane_enemy_scene.instantiate()
			get_parent().add_child(crane)
			crane.global_position = spawn_point.global_position
			crane.tree_exited.connect(_on_room1_enemy_died)
			room1_enemies.append(crane)
		elif "G_SpawnPoint" in spawn_point.name:
			var enemy = basic_enemy_scene.instantiate()
			get_parent().add_child(enemy)
			enemy.global_position = spawn_point.global_position
			enemy.tree_exited.connect(_on_room1_enemy_died)
			room1_enemies.append(enemy)

func _on_room1_enemy_died() -> void:
	var remaining = 0
	for enemy in room1_enemies:
		if is_instance_valid(enemy):
			remaining += 1
	if remaining == 0:
		unlock_room1()

func unlock_room1() -> void:
	var barriers = $Room1.find_children("*", "*", true, false).filter(func(child): return "Barrier" in child.name)
	for barrier in barriers:
		var tween = create_tween()
		tween.tween_property(barrier, "modulate:a", 0.0, barrier_fade_time)
		tween.tween_callback(func():
			barrier.visible = false
			barrier.get_node("CollisionShape3D").disabled = true)

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
	room2_enemies.clear()
	for spawn_point in spawn_points:
		if "F_SpawnPoint" in spawn_point.name:
			var crane = crane_enemy_scene.instantiate()
			get_parent().add_child(crane)
			crane.global_position = spawn_point.global_position
			crane.tree_exited.connect(_on_room2_enemy_died)
			room2_enemies.append(crane)
		elif "G_SpawnPoint" in spawn_point.name:
			var enemy = basic_enemy_scene.instantiate()
			get_parent().add_child(enemy)
			enemy.global_position = spawn_point.global_position
			enemy.tree_exited.connect(_on_room2_enemy_died)
			room2_enemies.append(enemy)

func _on_room2_enemy_died() -> void:
	var remaining = 0
	for enemy in room2_enemies:
		if is_instance_valid(enemy):
			remaining += 1
	if remaining == 0:
		unlock_room2()

func unlock_room2() -> void:
	var barriers = $Room2.find_children("*", "*", true, false).filter(func(child): return "Barrier" in child.name)
	for barrier in barriers:
		var tween = create_tween()
		tween.tween_property(barrier, "modulate:a", 0.0, barrier_fade_time)
		tween.tween_callback(func():
			barrier.visible = false
			barrier.get_node("CollisionShape3D").disabled = true)

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
	room3_enemies.clear()
	for spawn_point in spawn_points:
		if "F_SpawnPoint" in spawn_point.name:
			var crane = crane_enemy_scene.instantiate()
			get_parent().add_child(crane)
			crane.global_position = spawn_point.global_position
			crane.tree_exited.connect(_on_room3_enemy_died)
			room3_enemies.append(crane)
		elif "G_SpawnPoint" in spawn_point.name:
			var enemy = basic_enemy_scene.instantiate()
			get_parent().add_child(enemy)
			enemy.global_position = spawn_point.global_position
			enemy.tree_exited.connect(_on_room3_enemy_died)
			room3_enemies.append(enemy)

func _on_room3_enemy_died() -> void:
	var remaining = 0
	for enemy in room3_enemies:
		if is_instance_valid(enemy):
			remaining += 1
	if remaining == 0:
		unlock_room3()

func unlock_room3() -> void:
	var barriers = $Room3.find_children("*", "*", true, false).filter(func(child): return "Barrier" in child.name)
	for barrier in barriers:
		var tween = create_tween()
		tween.tween_property(barrier, "modulate:a", 0.0, barrier_fade_time)
		tween.tween_callback(func():
			barrier.visible = false
			barrier.get_node("CollisionShape3D").disabled = true)
