# crane_enemy.gd
extends Enemy
class_name CraneEnemy

@export var min_height: float = 2.0  # Extra height above player if higher
@export var base_tether_length: float = 3.0  # Base tether length from root
@export var stop_distance: float = 10.0  # Distance to stop and prepare attack
@export var projectile_speed: float = 10.0  # Horizontal speed for arc
@export var projectile_gravity: float = 9.5  # Match world gravity for arc
@export var disable_attacks_in_level: int = 2  # Disable attacks in level 2+

enum State {IDLE, CHASING, ATTACKING}
var current_state: State = State.IDLE

@onready var crane: Node3D = $Crane  # Crane model child
@onready var attack_timer: Timer = $AttackTimer  # Add Timer, wait_time=1.0
var projectile_scene = preload("res://Scenes/EnemyScenes/fire_attack_crane.tscn")  # Your particle FX scene
var tether_length = 0
var current_level: int = 1  # Default to level 1

func _ready():
	super._ready()
	attack_timer.start()
	if not animation_player.is_playing():
		animation_player.play("Flying")  # Default flying anim
	crane.global_position = global_position + Vector3(0, base_tether_length, 0)
	
	# NEW: Get current level from Global
	if Global.has_method("get_current_level_id"):
		current_level = Global.get_current_level_id()
		print("using global level")
	else:
		current_level = 2  # Fallback
		print("using default")
	print("Crane level: ", current_level, " | Attacks disabled: ", _attacks_disabled())

func _attacks_disabled() -> bool:
	return current_level >= disable_attacks_in_level

func _physics_process(delta: float) -> void:
	# Grounded movement (capsule handles nav)
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
		
		if dist_to_player <= stop_distance and attack_timer.is_stopped():
			current_state = State.ATTACKING
		elif dist_to_player > stop_distance:
			current_state = State.CHASING
		
		if current_state == State.CHASING and global_position.distance_to(next_pos) > 0.1:
			var direction = (next_pos - global_position).normalized()
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
			look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
		elif current_state == State.ATTACKING:
			velocity.x = 0
			velocity.z = 0
			look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
		else:
			velocity.x = 0
			velocity.z = 0

	else:
		current_state = State.IDLE
		velocity.x = 0
		velocity.z = 0
	
	if knockback_velocity.length() > 0.1:
		velocity += knockback_velocity
		knockback_velocity *= 0.9
	else:
		knockback_velocity = Vector3.ZERO
	
	move_and_slide()

	# Tether crane to root (adjust height if player higher)
	tether_length = base_tether_length
	if player and player.global_position.y + min_height > base_tether_length:
		tether_length = player.global_position.y + min_height
	crane.global_position = global_position + Vector3(0, tether_length, 0)
	
	# Animation control
	if velocity.length() > 0.1 and current_state != State.ATTACKING:
		if not animation_player.is_playing():
			animation_player.play("Flying")
	else:
		animation_player.stop()

func update_path_to_player() -> void:
	if nav_agent and player:
		nav_agent.target_position = player.global_position

func start_attack() -> void:
	# Instantiate and launch projectile
	var projectile = projectile_scene.instantiate() as RigidBody3D
	get_parent().add_child(projectile)
	projectile.global_position = global_position + Vector3(0, tether_length, 0)

	# Calculate parabolic initial velocity (arc to player's feet)
	var target = player.global_position
	var dist = global_position.distance_to(target)
	var time = dist / projectile_speed
	var horiz_dir = (target - global_position).normalized()
	horiz_dir.y = 0
	var horiz_vel = horiz_dir * projectile_speed
	var vert_vel = (target.y - global_position.y * projectile_gravity * time * time) / time
	projectile.linear_velocity = horiz_vel + Vector3(0, vert_vel, 0)

	attack_timer.start()  # Restart cooldown

func _on_attack_timer_timeout() -> void:
	if player_in_range and global_position.distance_to(player.global_position) <= stop_distance:
		if _attacks_disabled():
			# Still face player but NO attack (stepping stone mode)
			look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
			return  # Silent - no projectile, no anim, no sound
		
		# Original attack behavior
		start_attack()
		animation_player.play("Attack")
		$"crane attack".play()

func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0:
		die()

func _on_detection_area_body_entered(body: Node3D) -> void:
	if body == player:
		player_in_range = true
		await get_tree().physics_frame
		update_path_to_player()

func _on_detection_area_body_exited(body: Node3D) -> void:
	if body == player:
		player_in_range = false
