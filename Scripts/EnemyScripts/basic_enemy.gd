extends CharacterBody3D
class_name Enemy

@export var max_health: float = 50.0
@export var speed: float = 5.0
@export var attack_range: float = 2.0  # Close range for bite (tweak to match Area3D shape)
@export var detection_range: float = 20.0
@export var gravity: float = 9.5
@export var damage: float = 1.0
@export var attack_delay: float = 0.5  # Windup before damage (during "Bite" anim)
@export var attack_cooldown: float = 1.5  # Time before next attack (after damage)

# Pathfinding variables
@export var path_update_min_frames: int = 7
@export var path_update_max_frames: int = 12
var path_update_counter: int = 0
var path_update_interval: int = 0

var health: float
var player: Node3D
var knockback_velocity: Vector3 = Vector3.ZERO
var player_in_range: bool = false  # Flag for detection
var attack_timer: float = 0.0  # Cooldown counter
var health_scene = preload("res://Scenes/Pickups/pickup.tscn")

enum State {IDLE, CHASING, ATTACKING}
var current_state: State = State.IDLE

@onready var attack_area: Area3D = $Area3D
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var detection_area: Area3D = $detection_area
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	health = max_health
	player = get_tree().get_first_node_in_group("player")
	path_update_interval = randi_range(path_update_min_frames, path_update_max_frames)
	path_update_counter = randi_range(0, path_update_interval)
	attack_timer = 0.0  # Ready to attack

func _physics_process(delta: float) -> void:
	attack_timer = max(0, attack_timer - delta)  # Cooldown tick

	if not is_on_floor():
		velocity.y -= gravity * delta

	if player_in_range and player:
		var dist_to_player = global_position.distance_to(player.global_position)
		path_update_counter += 1
		if path_update_counter >= path_update_interval:
			update_path_to_player()
			path_update_counter = 0
			path_update_interval = randi_range(path_update_min_frames, path_update_max_frames)
		
		var next_pos = nav_agent.get_next_path_position()
		if current_state != State.ATTACKING:
			if dist_to_player <= attack_range and attack_timer <= 0:
				current_state = State.ATTACKING
				_perform_attack()
			else:
				current_state = State.CHASING
				if global_position.distance_to(next_pos) > 0.1:
					var direction = (next_pos - global_position).normalized()
					velocity.x = direction.x * speed
					velocity.z = direction.z * speed
					look_at(player.global_position, Vector3.UP)
					animation_player.play("Run")
					$"Wolf walk".play()
				else:
					velocity.x = 0
					velocity.z = 0
					animation_player.play("Idle")
	else:
		current_state = State.IDLE
		velocity.x = 0
		velocity.z = 0
		animation_player.play("Idle")

	if knockback_velocity.length() > 0.1:
		velocity += knockback_velocity
		knockback_velocity *= 0.9
	else:
		knockback_velocity = Vector3.ZERO
	move_and_slide()

func _perform_attack() -> void:
	animation_player.play("Bite")
	$"Wolf Attack".play()
	await get_tree().create_timer(attack_delay).timeout
	var hit_player = false
	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(damage)
			hit_player = true
			break
	attack_timer = attack_cooldown
	current_state = State.CHASING  # Back to chase (or IDLE if out of range)

func update_path_to_player() -> void:
	if nav_agent and player:
		nav_agent.target_position = player.global_position

func take_damage(amount: float) -> void:
	$"Wolf Hurt".play()
	health -= amount
	if health <= 0:
		die()

func die() -> void:
	queue_free()
	await get_tree().physics_frame
	spawn_health()

func apply_knockback(dir: Vector3, force: float) -> void:
	knockback_velocity = dir * force

# Detection signals (connect in editor)
func _on_detection_area_body_entered(body: Node3D) -> void:
	if body == player:
		player_in_range = true
		await get_tree().physics_frame
		update_path_to_player()
		$"Wolf Growl".play()  # Initial aggro sound

func _on_detection_area_body_exited(body: Node3D) -> void:
	if body == player:
		player_in_range = false

func spawn_health():
	var health_pickup = health_scene.instantiate()
	var root_node = get_tree().root
	root_node.add_child(health_pickup)
	health_pickup.global_position = global_position
