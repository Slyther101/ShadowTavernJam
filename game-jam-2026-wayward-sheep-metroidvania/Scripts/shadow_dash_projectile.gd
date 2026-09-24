extends AnimatedSprite2D

signal finished(end_position: Vector2)

@export var speed := 300.0
var direction := 1.0


func _ready() -> void:
	flip_h = direction < 0.0
	play(&"Projectile")
	animation_finished.connect(_finish)


func _finish() -> void:
	finished.emit(global_position)
	queue_free()


func _physics_process(delta: float) -> void:
	var start := global_position
	var end := start + Vector2(direction * speed * delta, 0.0)
	var wall_ray := PhysicsRayQueryParameters2D.create(start, end, 1)
	var wall_hit := get_world_2d().direct_space_state.intersect_ray(wall_ray)
	if not wall_hit.is_empty():
		global_position = wall_hit.position
		_finish()
		return
	global_position = end
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var offset: Vector2 = enemy.sprite.global_position - global_position
		if absf(offset.x) > 22.0 or absf(offset.y) > 30.0:
			continue
		enemy.take_damage(1, global_position)
		_finish()
		return
