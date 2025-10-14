#LINE 83 IS HIDING PLAYER MODEL AS IT CLIPS WITH SCREEN
extends CharacterBody3D

var speed
const WALK_SPEED = 6.0
const CROUCH_SPEED = 1.0
const SPRINT_SPEED = 10.0
const SLIDE_SPEED = 20.0  # Proto's value for great feel
@export var JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.003
var knockback_velocity: Vector3 = Vector3.ZERO

# Health (from John's)
var health: float = 100.0
@export var max_health: float = 100.0


# Slide playground (integrated from John's with tweaks)
var is_sliding = false
var SLIDE_FRICTION = 1.0  # Lower friction (adjusted in downhill)
const MIN_SLIDE_SPEED = 6.0  # Proto's value
const SLIDE_SLOPE_THRESHOLD = 0.05  # Floor normal Y for downhill detection

# Bob variables
const BOB_FREQ = 1.75
const BOB_AMP = 0.08
var t_bob = 0.0

const BASE_FOV = 75.0
const FOV_CHANGE = 1.5

@export var gravity = 9.5
var direction = Vector3.ZERO

# Wall-run variables
var wall_running = false
var wall_normal = Vector3.ZERO
@export var WALL_RUN_UP_BOOST = 2.0  # Initial upward velocity on wall-run entry
@export var WALL_RUN_GRAVITY = 4.0  # Reduced gravity for gradual descent during wall-run
@export var WALL_STICK_FORCE = 100.0  # Force to push player into the wall to "stick"
@export var JUMP_BOOST = 8.0  # Horizontal boost away from wall when jumping off

# Dash variables
@export var DASH_SPEED = 20.0  # Forward boost speed for dash
@export var DASH_DURATION = 1.0  # Max safety duration (prevent infinite dash)
@export var DASH_END_THRESHOLD = 1.0  # Distance to target to end dash
var dash_timer = 0.0
var is_dashing = false
@export var DASH_DAMAGE = 30.0  # Damage on hit
@export var DASH_TARGET_OFFSET = Vector3(0, 0, -2.0)  # Go "through" enemy (adjust based on direction)
@export var DASH_VERTICAL_OFFSET = 1.0  # Vertical adjustment to aim above enemy's base
var dash_target: Vector3 = Vector3.ZERO  # For targeted dash
var dash_direction: Vector3 = Vector3.ZERO

# Ground-pound variables
var is_pounding = false
@export var POUND_SPEED = 15.0  # Downward boost speed
@export var POUND_DAMAGE = 20.0  # AOE damage (less than dash)
@export var POUND_RADIUS = 3.0  # AOE area (set on pound_area shape)
@export var POUND_KNOCKBACK = 80.0  # Radial push force
@export var POUND_JUMP_BUFFER = 0.4  # Seconds for boosted jump window
@export var POUND_JUMP_BOOST = 3.0  # Extra jump height during buffer
var pound_buffer_timer = 0.0

# Juice variables (for dash hit)
@export var HIT_STOP_DURATION = 0.07  # Time scale slowdown time
@export var SHAKE_INTENSITY = 0.2  # Camera shake amount
@export var SHAKE_DURATION = 0.06  # Shake time
var shake_timer = 0.0
var hit_stop_timer = 0.0

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var dash_area = $dash_area
@onready var target_ray = $Head/Camera3D/target_ray
@onready var pound_area = $pound_area  # New Area3D for AOE

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	health = max_health  # Initialize health
	$Player_Model.hide() #PLACE HOLD FOR NOW (PLAYER MODEL WAS CLIPPING CAMERA)

# Health function (from John's)
func add_health(value: float) -> void:
	health = clamp(health + value, 0.0, max_health)
	print("Health increased to: ", health)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		self.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))

func _process(delta: float) -> void:
	# Handle hit-stop
	if hit_stop_timer > 0:
		hit_stop_timer -= delta
		if hit_stop_timer <= 0:
			Engine.time_scale = 1.0

	# Handle screenshake
	if shake_timer > 0:
		shake_timer -= delta
		camera.h_offset = randf_range(-SHAKE_INTENSITY, SHAKE_INTENSITY) * (shake_timer / SHAKE_DURATION)
		camera.v_offset = randf_range(-SHAKE_INTENSITY, SHAKE_INTENSITY) * (shake_timer / SHAKE_DURATION)


func _physics_process(delta: float) -> void:
	# Input at top (proto style)
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Handle gravity (modified for wall-run, dash, pound)
	if not is_on_floor() and not is_dashing:
		if wall_running:
			velocity.y -= WALL_RUN_GRAVITY * delta
		elif is_pounding:
			velocity.y = -POUND_SPEED  # Lock downward speed
		else:
			velocity.y -= gravity * delta

	# Handle pound buffer timer
	if pound_buffer_timer > 0:
		pound_buffer_timer -= delta

	# Handle jump (modified for wall-jump and pound buffer, with audio from John)
	if Input.is_action_just_pressed("jump"):
		var jump_vel = JUMP_VELOCITY
		if pound_buffer_timer > 0:
			jump_vel += POUND_JUMP_BOOST  # Boosted jump
		if is_on_floor() and not is_sliding:
			velocity.y = jump_vel
			$jump.play()  # Audio from John
			$walking.stop()  # Stop walking sound
		elif wall_running:
			velocity.y = jump_vel
			velocity += wall_normal * JUMP_BOOST
			wall_running = false
			$jump.play()  # Audio for wall jump

	# Handle ground-pound activation
	if not is_on_floor() and Input.is_action_just_pressed("crouch") and not is_pounding and not is_dashing:
		is_pounding = true
		velocity.y = -POUND_SPEED  # Initial downward boost
		$GroundPound.play() # Ground Pound audio

	# On land: Check for pound impact
	if is_on_floor() and is_pounding:
		is_pounding = false
		pound_buffer_timer = POUND_JUMP_BUFFER
		pound_area.monitoring = true
		await get_tree().physics_frame
		for body in pound_area.get_overlapping_bodies():
			if body is Enemy:
				body.take_damage(POUND_DAMAGE)
				var knock_dir = (body.global_position - global_position).normalized()
				body.apply_knockback(knock_dir, POUND_KNOCKBACK)
		pound_area.monitoring = false

	# Handle downhill detection (from John, used in slide)
	var is_downhill = false
	if is_on_floor():
		var floor_normal = get_floor_normal()
		is_downhill = floor_normal.y < (1.0 - SLIDE_SLOPE_THRESHOLD)

	# Handle sprint (proto style, no forward condition)
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
		if Input.is_action_just_pressed("crouch") and not is_sliding and is_on_floor():  # Slide start (from John, removed forward condition for omni)
			is_sliding = true
			$Slide.play()  # Audio from John
			var slide_dir = direction if direction else -camera.global_transform.basis.z.normalized()  # Use input or forward
			velocity.x = slide_dir.x * SLIDE_SPEED
			velocity.z = slide_dir.z * SLIDE_SPEED
	else:
		speed = WALK_SPEED

	# Handle Crouch (ground only)
	if Input.is_action_pressed("crouch") and not is_sliding and is_on_floor():
		speed = CROUCH_SPEED

	# Slide logic (integrated from John with tweaks for proto feel)
	if is_sliding:
		$walking.stop()  # Stop walking sound
		var slide_vel = Vector3(velocity.x, 0, velocity.z)  # From John, fixed no +delta
		# Strafe (from John)
		var strafe_dir = (transform.basis * Vector3(input_dir.x, 0, 0)).normalized()
		var slide_dir = slide_vel.normalized()
		if input_dir.x != 0:
			slide_dir = slide_dir.lerp(strafe_dir, 0.01).normalized()  # Gentle strafe

		# Downhill adjustment (from John)
		var downhill_dir = Vector3.ZERO
		var target_speed = SLIDE_SPEED
		if is_downhill:
			SLIDE_FRICTION = 0.05  # Low friction downhill
			downhill_dir = (Vector3.DOWN - get_floor_normal() * get_floor_normal().dot(Vector3.DOWN)).normalized()
			slide_dir = slide_dir.lerp(downhill_dir, 0.05).normalized()
			var slope_angle = acos(get_floor_normal().dot(Vector3.UP))
			var slope_angle_degrees = rad_to_deg(slope_angle)
			var interpol = clamp((slope_angle_degrees - 5.0) / (10.0 - 5.0), 0.0, 1.0)
			target_speed = lerp(10.0, 20.0, interpol)  # John's interp, keeps proto max
		else:
			SLIDE_FRICTION = 1.0  # Normal friction flat

		# Apply friction and dir
		var current_speed = slide_vel.length()
		slide_vel = slide_dir * current_speed * (1.0 - SLIDE_FRICTION * delta)
		velocity.x = slide_vel.x
		velocity.z = slide_vel.z

		# Stop condition (proto with John's jump from slide)
		var horizontal_speed = Vector2(velocity.x, velocity.z).length()
		if Input.is_action_pressed("jump") && not is_on_wall():
			slide_dir = Vector3(velocity.x, 0, velocity.z).normalized()
			velocity = slide_dir * JUMP_BOOST * speed
			velocity.y = JUMP_VELOCITY
			is_sliding = false
			$Slide.stop()
		elif horizontal_speed < MIN_SLIDE_SPEED and not is_downhill:
			is_sliding = false
			$Slide.stop()
			if Input.is_action_pressed("crouch"):
				speed = CROUCH_SPEED
	else:
		is_sliding = false
	$Slide.stop()

	# Handle camera offset
	if is_sliding or (Input.is_action_pressed("crouch") and is_on_floor()):
		camera.v_offset = lerp(camera.v_offset, -0.75, delta * 10.0)
	else:
		camera.v_offset = lerp(camera.v_offset, 0.0, delta * 10.0)

	# Movement lerp (proto style, after slide for no override)
	if (is_on_floor() or wall_running) and not is_sliding and not is_dashing:
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
			if is_on_floor() and not $walking.playing:
				$walking.play()  # Audio from John
				animation_player.play("Run")
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
			$walking.stop()
			animation_player.play("Idle")
	elif not is_on_floor() and not is_sliding and not is_dashing:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 4.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 4.0)

	# Wall stick force
	if wall_running:
		velocity += -wall_normal * WALL_STICK_FORCE * delta

	# Handle dash (with audio from John)
	if Input.is_action_just_pressed("dash") and not is_dashing:
		if target_ray.is_colliding():
			var collider = target_ray.get_collider()
			if collider and collider is Enemy:
				$slice.play()  # Audio from John
				is_dashing = true
				dash_timer = DASH_DURATION
				dash_area.monitoring = true
				dash_target = collider.global_position + Vector3(0, DASH_VERTICAL_OFFSET, 0) + DASH_TARGET_OFFSET.rotated(Vector3.UP, rotation.y)
				dash_direction = (dash_target - global_position).normalized()
				velocity = dash_direction * DASH_SPEED

	if is_dashing:
		velocity.x = dash_direction.x * DASH_SPEED
		velocity.z = dash_direction.z * DASH_SPEED
		velocity.y = dash_direction.y * DASH_SPEED
		var dist_to_target = global_position.distance_to(dash_target)
		if dist_to_target < DASH_END_THRESHOLD:
			is_dashing = false
			dash_area.set_deferred("monitoring", false)
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			dash_area.set_deferred("monitoring", false)

	# Head bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)

	# FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	# KNOCKBACK HANDLING
	if knockback_velocity.length() > 0.1:
		velocity += knockback_velocity
		knockback_velocity *= 0.9
	else:
		knockback_velocity = Vector3.ZERO

	# Move and slide
	move_and_slide()

	# Wall-run entry/exit
	if wall_running:
		if not is_on_wall():
			wall_running = false
	else:
		if not is_on_floor() and get_slide_collision_count() > 0:
			for i in range(get_slide_collision_count()):
				var col = get_slide_collision(i)
				var norm = col.get_normal()
				if abs(norm.y) < 0.1:
					if velocity.dot(norm) < 0:
						wall_running = true
						wall_normal = norm
						velocity.y += WALL_RUN_UP_BOOST
						velocity -= norm * velocity.dot(norm)
						break

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos

func _on_dash_area_body_entered(body: Node3D) -> void:
	if body is Enemy:
		body.take_damage(DASH_DAMAGE)
		is_dashing = false
		dash_area.set_deferred("monitoring", false)
		Engine.time_scale = 0.1
		hit_stop_timer = HIT_STOP_DURATION
		shake_timer = SHAKE_DURATION

# In movement.gd (add at bottom)
func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0:
		# Death logic (e.g., respawn)
		print("Player died")
	print("Player health: ", health)

func apply_knockback(dir: Vector3, force: float) -> void:
	knockback_velocity += dir * force  # Simple add to current vel
	print("Player knocked back")
