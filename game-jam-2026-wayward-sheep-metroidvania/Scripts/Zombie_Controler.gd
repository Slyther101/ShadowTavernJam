extends CharacterBody2D

@export var patrol_speed := 22.0
@export var chase_speed := 42.0
@export var patrol_distance := 64.0
@export var detection_range := 150.0
@export var attack_range := 34.0
@export var max_health := 3

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hero: CharacterBody2D = get_parent().get_node("Hero")

var health: int
var home_x: float
var facing := -1.0
var state := &"Idle"
var pause_time := 0.6
var attack_cooldown := 0.0
var attack_landed := false
var dead := false


func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	home_x = global_position.x
	# Each instance owns its playback settings.
	sprite.sprite_frames = sprite.sprite_frames.duplicate()
	sprite.sprite_frames.set_animation_loop(&"Attack", false)
	sprite.sprite_frames.set_animation_loop(&"Damage", false)
	sprite.sprite_frames.set_animation_speed(&"Attack", 14.0)
	sprite.sprite_frames.set_animation_speed(&"Damage", 12.0)
	sprite.sprite_frames.set_animation_speed(&"Walk", 10.0)
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.frame_changed.connect(_on_frame_changed)
	sprite.play(&"Idle")


func _physics_process(delta: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	if not is_on_floor():
		velocity += get_gravity() * delta
	if state == &"Damage":
		velocity.x = move_toward(velocity.x, 0.0, 250.0 * delta)
	elif state == &"Attack" or dead:
		velocity.x = 0.0
	else:
		_update_behavior(delta)
	move_and_slide()


func _update_behavior(delta: float) -> void:
	var offset: Vector2 = hero.hero_animation.global_position - sprite.global_position
	var sees_hero: bool = hero.health > 0 and offset.length() <= detection_range and absf(offset.y) < 45.0 and _clear_path(sprite.global_position, hero.hero_animation.global_position)
	velocity.x = 0.0
	if sees_hero:
		if absf(offset.x) > 1.0:
			facing = signf(offset.x)
		if absf(offset.x) <= attack_range and absf(offset.y) < 26.0:
			if attack_cooldown <= 0.0:
				attack_landed = false
				_play(&"Attack")
			else:
				_play(&"Idle")
		elif _can_walk(facing):
			velocity.x = facing * chase_speed
			_play(&"Walk")
		else:
			_play(&"Idle")
	elif pause_time > 0.0:
		pause_time -= delta
		_play(&"Idle")
	else:
		if absf(global_position.x - home_x) >= patrol_distance:
			facing = signf(home_x - global_position.x)
		if is_on_floor() and (is_on_wall() or not _can_walk(facing)):
			facing *= -1.0
			pause_time = 0.7
			_play(&"Idle")
		else:
			velocity.x = facing * patrol_speed
			_play(&"Walk")
	sprite.flip_h = facing < 0.0


func _can_walk(direction: float) -> bool:
	var ahead := global_position + Vector2(direction * 16.0, 0.0)
	var floor_ray := PhysicsRayQueryParameters2D.create(ahead, ahead + Vector2(0, 28), 1)
	return not get_world_2d().direct_space_state.intersect_ray(floor_ray).is_empty() and _clear_path(global_position, ahead)


func _clear_path(from: Vector2, to: Vector2) -> bool:
	var ray := PhysicsRayQueryParameters2D.create(from, to, 1)
	return get_world_2d().direct_space_state.intersect_ray(ray).is_empty()


func _play(animation: StringName) -> void:
	state = animation
	if sprite.animation != animation or not sprite.is_playing():
		sprite.play(animation)


func _on_frame_changed() -> void:
	# Wind up before the bite; one hit per attack, with range checked at impact.
	if state != &"Attack" or sprite.frame < 7 or attack_landed:
		return
	attack_landed = true
	var offset: Vector2 = hero.hero_animation.global_position - sprite.global_position
	if absf(offset.x) <= attack_range + 6.0 and absf(offset.y) < 26.0 and offset.x * facing >= -4.0 and _clear_path(sprite.global_position, hero.hero_animation.global_position):
		hero.take_damage(1)


func take_damage(amount: int, source_position: Vector2) -> void:
	if dead or state == &"Damage":
		return
	health = maxi(0, health - amount)
	dead = health == 0
	velocity.x = signf(global_position.x - source_position.x) * 90.0
	_play(&"Damage")


func _on_animation_finished() -> void:
	if dead:
		# There is no zombie death sheet; fade after the final damage reaction.
		set_physics_process(false)
		var fade := create_tween()
		fade.tween_property(sprite, "modulate:a", 0.0, 0.3)
		fade.tween_callback(queue_free)
	else:
		attack_cooldown = 0.7
		pause_time = 0.3
		_play(&"Idle")
