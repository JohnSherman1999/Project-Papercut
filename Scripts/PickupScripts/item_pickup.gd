extends Area3D

@export var pickup_type = "health"
@export var value = 3
@onready var audio = $AudioStreamPlayer3D

func _ready():
	body_entered.connect(_on_body_entered)
	$AnimationPlayer.play("spin")

func _on_body_entered(body: Node):
	if body.is_in_group("player"):
		if pickup_type == "coin":
			body.add_coins(value)
		elif pickup_type == "health":
			body.add_health(value)
		audio.play()
		$".".hide()
		audio.reparent(get_tree().root, true)#keep playing after deleted
		audio.autoplay = false
		queue_free()

func _on_audio_stream_player_3d_finished() -> void:
	if audio:
		audio.queue_free()
