# bull.gd (Full standalone script - attach to Bull.tscn root: CharacterBody3D)
extends CharacterBody3D
class_name Bull

@export var charge_speed: float = 12.0  # Faster than player sprint (tweak in Inspector)
@export var acceleration: float = 40.0   # How fast it ramps to full speed
@export var jump_force: float = 8.0      # Vault over piles/cars
@export var turn_speed: float = 3.0      # Quick facing (radians/sec)
@export var detection_range: float = 50.0 # Wide aggro
@export var gravity: float = 9.5

# Jumping exports
@export var path_update_interval: int = 10  # Frames between path updates (perf)
@export var jump_cooldown_min: float = 0.3  # Min time between jumps
@export var jump_cooldown_max: float = 1.0  # Max time (random for variety)
@export var random_jump_chance: float = 0.005  # ~1 jump/sec manic chaos (tune 0.01-0.03)

# Dash Exports
@export var speed_burst_distance: float = 30.0  # Distance from player to trigger burst chance
@export var speed_burst_multiplier: float = 3.0  # How much faster (2x = double-time)
@export var speed_burst_duration: float = 1.0   # Burst length
@export var speed_burst_chance: float = 0.02    # ~2% chance/frame when far (~1 burst every 8-10s)

# Components (match your scene setup)
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var detection_area: Area3D = $DetectionArea  # Sphere CollisionShape3D (r=50)
@onready var damage_area: Area3D = $DamageArea       # Sphere r=2-3u for game over trigger
@onready var smoke_particles: GPUParticles3D = $SmokeHeavy  # Optional trail FX
@onready var spike_particles: GPUParticles3D = $Spikes  # Optional trail FX
@onready var spark_particles: GPUParticles3D = $Sparks  # Optional trail FX

var player: Node3D
var player_in_range: bool = false
var knockback_velocity: Vector3 = Vector3.ZERO
var current_velocity: Vector3 = Vector3.ZERO  # For smooth accel

# Jump state
var path_update_counter: int = 0
var jump_cooldown: float = 0.0

# Dash state
var speed_burst_timer: float = 0.0
var is_speed_bursting: bool = false

func _ready():
	player = get_tree().get_first_node_in_group("player")
	animation_player.play("Charge")
	animation_player.speed_scale = randf_range(0.9, 1.1)
	damage_area.monitoring = true
	path_update_counter = randi() % path_update_interval  # Stagger updates

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Knockback decay
	if knockback_velocity.length() > 0.1:
		velocity += knockback_velocity
		knockback_velocity *= 0.9
	else:
		knockback_velocity = Vector3.ZERO

	# Jump cooldown tick
	jump_cooldown = maxf(0.0, jump_cooldown - delta)

	if player_in_range and player:
		# Pathfinding: PERIODIC UPDATE (fixes "stuck on trees/buildings")
		path_update_counter += 1
		if path_update_counter >= path_update_interval:
			update_path_to_player()
			path_update_counter = 0

		# Movement
		var next_pos = nav_agent.get_next_path_position()
		if global_position.distance_to(next_pos) > 1.0:
			var direction = (next_pos - global_position).normalized()
			
			# SPEED BURST LOGIC
			var current_burst_mult = 1.0
			if speed_burst_timer > 0.0:
				speed_burst_timer -= delta
				current_burst_mult = speed_burst_multiplier
				is_speed_bursting = true
			else:
				is_speed_bursting = false
				# Check for new burst (only if far from player)
				if global_position.distance_to(player.global_position) > speed_burst_distance:
					if randf() < speed_burst_chance:
						speed_burst_timer = speed_burst_duration
						print("Bull SPEED BURST! 🐂⚡")  # Debug
			
			# Apply accelerated speed
			var target_speed = charge_speed * current_burst_mult
			current_velocity = current_velocity.move_toward(direction * target_speed, acceleration * delta * 1.5)  # Extra accel during burst
			velocity.x = current_velocity.x
			velocity.z = current_velocity.z

			# Smooth turning
			var target_y_rot = atan2(direction.x, direction.z)
			rotation.y = lerp_angle(rotation.y, target_y_rot, delta * turn_speed)
			
			# JUMPING: Manic wave only (bridges handle holes/obstacles)
			if jump_cooldown <= 0.0 and is_on_floor():  # Your ground check - no space cowboys
				if randf() < random_jump_chance:  # Random chaos (over each other)
					velocity.y = jump_force
					jump_cooldown = randf_range(jump_cooldown_min, jump_cooldown_max)
					print("Bull JUMP! 🐂💥")  # Debug (remove later)
			
			# Anim speed
			animation_player.speed_scale = current_velocity.length() / charge_speed
		else:
			velocity.x = 0
			velocity.z = 0
			animation_player.speed_scale = 0.5  # Idle trot
	else:
		# Idle slowdown
		current_velocity = current_velocity.move_toward(Vector3.ZERO, acceleration * delta * 2.0)
		velocity.x = current_velocity.x
		velocity.z = current_velocity.z
		animation_player.speed_scale = 0.3

	# Hooves (if on ground & moving)
	if smoke_particles and is_on_floor() and velocity.length() > 2.0:
		smoke_particles.emitting = true
		spike_particles.emitting = true
		spark_particles.emitting = true
	else:
		smoke_particles.emitting = false
		spike_particles.emitting = false
		spark_particles.emitting = false

	move_and_slide()

func update_path_to_player() -> void:
	if nav_agent and player:
		nav_agent.target_position = player.global_position

# Detection Signals (connect in editor: DetectionArea body_entered/exited)
func _on_detection_area_body_entered(body: Node3D) -> void:
	if body == player:
		$moo.play()
		player_in_range = true
		print("Bull aggro'd! 🐂")

func _on_detection_area_body_exited(body: Node3D) -> void:
	if body == player:
		player_in_range = false

# Damage Area (connect: DamageArea body_entered)
func _on_damage_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		# GAME OVER - deferred for physics safety
		get_tree().call_deferred("change_scene_to_file", "res://Scenes/Settings/sample_death.tscn")
		print("Bull gotcha! 💥")

# Optional: One-shot kill (for testing/powerups)
func die() -> void:
	queue_free()
