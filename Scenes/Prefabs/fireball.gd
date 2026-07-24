extends RigidBody2D

var direction : Vector2 = Vector2.ZERO
var speed : float = 500


func _ready() -> void:
	gravity_scale = 0
	linear_velocity = direction * speed
	rotation = direction.angle()


func _physics_process(_delta: float) -> void:
	linear_velocity = direction * speed


func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D:
		get_tree().reload_current_scene()
	else:
		call_deferred("queue_free")
