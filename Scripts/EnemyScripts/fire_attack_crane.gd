extends RigidBody3D

@export var explosion_scene: PackedScene = preload("res://Scenes/EnemyScenes/explosion_crane.tscn")  # Your explosion scene

func _ready():
	# Optional: Set gravity for arc if not in Inspector
	gravity_scale = 1.0

func _on_body_entered(body: Node3D):
	# Spawn explosion on hit (any body)
	if body:
		var explosion = explosion_scene.instantiate()
		get_parent().add_child(explosion)
		explosion.global_position = global_position  # At hit point
	# Destroy projectile
		queue_free()
