extends CharacterBody3D
class_name Enemy

@export var max_health: float = 50.0
@export var speed: float = 5.0
@export var attack_range: float = 0.2
@export var detection_range: float = 20.0
@export var gravity = 9.5  # Match player's gravity

# Pathfinding variables
@export var path_update_min_frames: int = 7  # Min frames between path updates (scalable)
@export var path_update_max_frames: int = 12  # Max frames for randomization
var path_update_counter: int = 0
var path_update_interval: int = 0  # Randomized per enemy

var health: float
var player: Node3D
var knockback_velocity: Vector3 = Vector3.ZERO
var player_in_range: bool = false  # Flag for detection

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var detection_area: Area3D = $detection_area  # Add in scene with CollisionShape3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	health = max_health
	player = get_tree().get_first_node_in_group("player")
	path_update_interval = randi_range(path_update_min_frames, path_update_max_frames)
	path_update_counter = randi_range(0, path_update_interval)
	# Initial path update if in range, with delay for nav sync
	if player_in_range == true:
		await get_tree().physics_frame
		update_path_to_player()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if player_in_range and player:
		var _dist_to_player = global_position.distance_to(player.global_position)
		path_update_counter += 1
		if path_update_counter >= path_update_interval:
			update_path_to_player()
			path_update_counter = 0
			path_update_interval = randi_range(path_update_min_frames, path_update_max_frames)
		   
			# Use agent's next position for movement (avoids manual index issues)
		var next_pos = nav_agent.get_next_path_position()
		if global_position.distance_to(next_pos) > 0.1:  # Threshold to move
			var direction = (next_pos - global_position).normalized()
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
			look_at(player.global_position, Vector3.UP)  # Smooth facing every frame
		else:
			velocity.x = 0
			velocity.z = 0
	else:
		velocity.x = 0
		velocity.z = 0
   
	if knockback_velocity.length() > 0.1:
		velocity += knockback_velocity
		knockback_velocity *= 0.9
	else:
		knockback_velocity = Vector3.ZERO
   
	move_and_slide()

func update_path_to_player() -> void:
	if nav_agent and player:
		nav_agent.target_position = player.global_position

func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0:
		die()

func die() -> void:
	queue_free()

func apply_knockback(dir: Vector3, force: float) -> void:
	knockback_velocity = dir * force

# Detection signals (connect in editor)
func _on_detection_area_body_entered(body: Node3D) -> void:
	if body == player:
		player_in_range = true
		await get_tree().physics_frame  # Ensure physics/nav sync
		update_path_to_player()
		animation_player.play("Run")

func _on_detection_area_body_exited(body: Node3D) -> void:
	if body == player:
		player_in_range = false
		animation_player.play("Idle")
