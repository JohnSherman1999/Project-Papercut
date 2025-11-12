# dragon_boss.gd
extends CharacterBody3D
class_name DragonBoss

signal boss_defeated

@export var max_health: float = 500.0  # High health for boss
@export var speed: float = 4.0  # Slower chase
@export var attack_range: float = 8.0  # General range for attack checks
@export var detection_range: float = 30.0  # Wide detection
@export var gravity: float = 9.5  # Match player

# Attack params
@export var fireball_cooldown: float = 5.0
@export var firebreath_cooldown: float = 3.0
@export var slam_cooldown: float = 7.0
@export var slam_jump_height: float = 10.0
@export var slam_speed: float = 15.0
@export var slam_damage: float = 2.0
@export var slam_knockback: float = 15.0
@export var slam_radius: float = 5.0
@export var firebreath_damage: float = 3.0
@export var firebreath_startup: float = 1.2
@export var firebreath_duration: float = 1.0
@export var fireball_arc_height: float = 20.0
@export var projectile_speed: float = 10.0
@export var global_cooldown: float = 2.5  # Seconds between any attacks (tweak for balance)
@export var turn_speed: float = 2.5

# Pathfinding (from basic_enemy.gd)
@export var path_update_min_frames: int = 7
@export var path_update_max_frames: int = 12
var path_update_counter: int = 0
var path_update_interval: int = 0

enum State {IDLE, CHASING, FIREBALL, FIREBREATH, SLAM, DEATH}
var current_state: State = State.IDLE

var is_dead: bool = false
var health: float
var player: Node3D
var knockback_velocity: Vector3 = Vector3.ZERO
var player_in_range: bool = false

@onready var animation_player: AnimationPlayer = $AnimationPlayer  # Attach to mesh
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var detection_area: Area3D = $detection_area
@onready var fireball_timer: Timer = $FireballTimer
@onready var firebreath_timer: Timer = $FireBreathTimer
@onready var slam_timer: Timer = $SlamTimer
@onready var firebreath_area: Area3D = $FireBreathArea  # Cone for breath
@onready var slam_area: Area3D = $SlamArea  # Sphere for slam
@onready var global_cooldown_timer: Timer = $GlobalCooldownTimer
var projectile_scene = preload("res://Scenes/EnemyScenes/fire_attack_crane.tscn")  # Reuse for fireball

func _ready():
	health = max_health
	player = get_tree().get_first_node_in_group("player")
	path_update_interval = randi_range(path_update_min_frames, path_update_max_frames)
	path_update_counter = randi_range(0, path_update_interval)
	fireball_timer.wait_time = fireball_cooldown
	firebreath_timer.wait_time = firebreath_cooldown
	global_cooldown_timer.wait_time = global_cooldown
	slam_timer.wait_time = slam_cooldown
	fireball_timer.start(randf_range(0, fireball_cooldown))  # Random start
	firebreath_timer.start(randf_range(0, firebreath_cooldown))
	slam_timer.start(randf_range(0, slam_cooldown))
	animation_player.play("Idle")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Detection and chase logic (adapted from basic_enemy.gd)
	if player_in_range and player:
		var dist_to_player = global_position.distance_to(player.global_position)
		path_update_counter += 1
		if path_update_counter >= path_update_interval:
			update_path_to_player()
			path_update_counter = 0
			path_update_interval = randi_range(path_update_min_frames, path_update_max_frames)
		
		# Check for attacks in priority (slam close, breath medium, fireball long)
		if dist_to_player <= 5.0 and slam_timer.is_stopped() and global_cooldown_timer.is_stopped() and is_dead == false:
			current_state = State.SLAM
			animation_player.play("Attack-Slam")
			slam_attack()
			global_cooldown_timer.start()
		elif dist_to_player <= 10.0 and firebreath_timer.is_stopped() and global_cooldown_timer.is_stopped() and is_dead == false:
			current_state = State.FIREBREATH
			animation_player.play("Attack-FireBreath")
			firebreath_attack()
			global_cooldown_timer.start()
		elif dist_to_player <= 20.0 and fireball_timer.is_stopped() and global_cooldown_timer.is_stopped() and is_dead == false:
			current_state = State.FIREBALL
			animation_player.play("Attack-FireBall")
			fireball_attack()
			global_cooldown_timer.start()
		else:
			current_state = State.CHASING
			var next_pos = nav_agent.get_next_path_position()
			if global_position.distance_to(next_pos) > 0.1:
				var direction = (next_pos - global_position).normalized()
				velocity.x = direction.x * speed
				velocity.z = direction.z * speed
			var target_y_rot = atan2(player.global_position.x - global_position.x, player.global_position.z - global_position.z)
			rotation.y = lerp_angle(rotation.y, target_y_rot, delta * turn_speed)
	else:
		current_state = State.IDLE
		velocity.x = 0
		velocity.z = 0

	# Knockback logic (from basic_enemy.gd)
	if knockback_velocity.length() > 0.1:
		velocity += knockback_velocity
		knockback_velocity *= 0.9
	else:
		knockback_velocity = Vector3.ZERO
	
	move_and_slide()

func update_path_to_player() -> void:
	if nav_agent and player:
		nav_agent.target_position = player.global_position

func fireball_attack() -> void:
	# Launch fireball in lob arc to initial player pos
	var projectile = projectile_scene.instantiate() as RigidBody3D
	get_parent().add_child(projectile)
	projectile.global_position = global_position + Vector3(0, 2.0, 0)  # Mouth height
	var target = player.global_position
	var dist = global_position.distance_to(target)
	var time = dist / projectile_speed
	var horiz_dir = (target - global_position).normalized()
	horiz_dir.y = 0
	var horiz_vel = horiz_dir * projectile_speed
	var vert_vel = (target.y - global_position.y + 0.5 * gravity * time * time) / time  # Arc formula
	projectile.linear_velocity = horiz_vel + Vector3(0, vert_vel, 0)
	fireball_timer.start()
	current_state = State.CHASING

func firebreath_attack() -> void:
	# Activate cone for duration
	await get_tree().create_timer(firebreath_startup).timeout
	$FireBreathArea/Flame.emitting = true
	firebreath_area.monitoring = true
	await get_tree().create_timer(firebreath_duration).timeout
	firebreath_area.monitoring = false
	firebreath_timer.start()
	current_state = State.CHASING


func slam_attack() -> void:
# Jump up
	velocity.y = sqrt(2 * gravity * slam_jump_height)
	await get_tree().create_timer(1.0).timeout  # Peak time
	# Slam down
	velocity.y = -slam_speed
	slam_area.monitoring = true  # Damage on descent
	while not is_on_floor():
		await get_tree().physics_frame

	# Impact AOE (capture while monitoring is on)
	var bodies = slam_area.get_overlapping_bodies()
	slam_area.monitoring = false
	for body in bodies:
		print(bodies.size())
		if body != self && body is CharacterBody3D:
			body.take_damage(slam_damage)
			var knock_dir = (body.global_position - global_position).normalized()
			body.apply_knockback(knock_dir, slam_knockback)
	slam_timer.start()
	current_state = State.CHASING

func _on_firebreath_area_body_entered(body: Node3D) -> void:
	if body.has_method("take_damage") and body.global_position.y - global_position.y < 1.0:  # Grounded check
		body.take_damage(firebreath_damage)

func _on_slam_area_body_entered(body: Node3D) -> void:
	if body != self and body.has_method("take_damage"):
		body.take_damage(slam_damage)
		var knock_dir = (body.global_position - global_position).normalized()
		body.apply_knockback(knock_dir, slam_knockback)

func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0 and not is_dead:
		is_dead = true
		self.collision_layer = 1
		player.apply_knockback((player.global_position - global_position), 5.0)
		current_state = State.DEATH
		animation_player.play("Death")
		await animation_player.animation_finished
		die()

func apply_knockback(dir: Vector3, force: float) -> void:
	if not is_dead:
		knockback_velocity = dir * force * 0.2

func die() -> void:
	boss_defeated.emit()
	queue_free()

# Detection (from basic_enemy.gd)
func _on_detection_area_body_entered(body: Node3D) -> void:
	if body == player:
		player_in_range = true
		await get_tree().physics_frame
		update_path_to_player()

func _on_detection_area_body_exited(body: Node3D) -> void:
	if body == player:
		player_in_range = false
