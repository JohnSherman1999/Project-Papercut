extends Node3D

@export var damage: float = 20.0  # Damage in AOE
@export var knockback_force: float = 10.0  # Small knockback
@export var lifespan: float = 0.5  # Time before destroy (for FX)

@onready var aoe_area: Area3D = $Area3D  # Add Area3D child with shape
@onready var timer: Timer = $Timer  # Add Timer node, one_shot=true, wait_time=lifespan

func _ready():
	timer.timeout.connect(queue_free)
	timer.start()
	explosion()


func explosion() -> void:
	$Fire.restart()
	$Sparks.restart()
	$Smoke.restart()
	$Audio.play()


func _on_area_3d_body_entered(body: Node3D) -> void:
	# Immediate AOE check (after frame for sync)
	await get_tree().physics_frame
	if body.has_method("take_damage"):  # For player/enemies
		body.take_damage(damage)
		# Knockback
		var knock_dir = (body.global_position - global_position).normalized()
		if body.has_method("apply_knockback"):
			body.apply_knockback(knock_dir, knockback_force)
