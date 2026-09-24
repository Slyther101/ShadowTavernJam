extends CharacterBody2D

@export var speed = 10.0
@export var jump_power = 10.0
@onready var hero_animation: AnimatedSprite2D = $HeroAnimation
@onready var hero_camera: Camera2D = $Camera2D
const SHADOW_DASH_PROJECTILE = preload("res://shadow_dash_projectile.tscn")
@export var is_controled = true

const DASH_DURATION := 0.15
const SLIDE_DURATION := 0.25

var speed_multiplier = 30.0
var jump_multiplier = -30.0
var direction := 0.0
var action_name: StringName
var action_time := 0.0
var action_multiplier := 0.0
var action_direction := 1.0
var attack_queued := false
@export var max_health := 5
var health := 5
var hurt_cooldown := 0.0
var swing_hit := false
@onready var health_bar: TextureProgressBar = $"../HUD/HealthBar&Housing"


func _ready() -> void:
	health = max_health
	hero_animation.frame_changed.connect(_on_combat_frame)
	_update_health_display()


func _update_health_display() -> void:
	health_bar.max_value = max_health
	health_bar.value = health


func take_damage(amount: int) -> void:
	if health <= 0 or hurt_cooldown > 0.0:
		return
	health = maxi(0, health - amount)
	hurt_cooldown = 1.2
	attack_queued = false
	_start_action(&"Die" if health == 0 else &"Damage")
	_update_health_display()


func _on_combat_frame() -> void:
	if swing_hit or action_name not in [&"Attack", &"Attack 2", &"AirStrike", &"ShadowStrike", &"ShadowDash"] or hero_animation.frame < 2:
		return
	swing_hit = true
	if action_name == &"ShadowDash":
		var projectile := SHADOW_DASH_PROJECTILE.instantiate() as AnimatedSprite2D
		projectile.set("direction", action_direction)
		projectile.connect("finished", _on_shadow_dash_projectile_finished)
		get_tree().current_scene.add_child(projectile)
		projectile.global_position = hero_animation.global_position + Vector2(action_direction * 20.0, 0.0)
		return
	var reach := 54.0 if action_name == &"ShadowStrike" else 40.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var offset: Vector2 = enemy.sprite.global_position - hero_animation.global_position
		if absf(offset.x) > reach or absf(offset.y) > 30.0 or offset.x * action_direction < -5.0:
			continue
		var ray := PhysicsRayQueryParameters2D.create(hero_animation.global_position, enemy.sprite.global_position, 1)
		if get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
			enemy.take_damage(1, global_position)


func _on_shadow_dash_projectile_finished(end_position: Vector2) -> void:
	if action_name != &"ShadowDash":
		return
	var travel := Vector2(end_position.x - global_position.x, 0.0)
	var collision := move_and_collide(travel, true)
	if collision:
		travel = collision.get_travel()
	var camera_offset := hero_camera.offset
	hero_camera.offset -= travel
	global_position += travel
	create_tween().tween_property(hero_camera, "offset", camera_offset, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	velocity.x = 0.0


func _physics_process(delta: float) -> void:
	hurt_cooldown = maxf(0.0, hurt_cooldown - delta)
	hero_animation.modulate.a = 0.5 if hurt_cooldown > 0.0 and int(hurt_cooldown * 12.0) % 2 == 0 else 1.0
	if not is_on_floor():
		velocity += get_gravity() * delta
	# Damage and death must finish even while the shadow is controlled.
	if action_name in [&"Damage", &"Die"]:
		_update_action(delta)
		move_and_slide()
		if not action_name:
			_update_animation()
		return

	if is_controled:
		direction = Input.get_axis("Move Left", "Move Right")
		if direction:
			hero_animation.flip_h = direction < 0

		if action_name == &"Attack" and Input.is_action_just_pressed("Attack"):
			attack_queued = true

		if action_name:
			_update_action(delta)
		else:
			_try_start_action()
			if action_name:
				_update_action(delta)
			else:
				_update_movement()
	
		move_and_slide()
		if not action_name:
			_update_animation()
	elif action_name == &"SummonShadow" and hero_animation.is_playing() == false:
		action_name = ""
		_update_animation()
		_update_movement()
		


func _try_start_action() -> void:
	if Input.is_action_just_pressed("Test Die"):
		_start_action(&"Die")
	elif Input.is_action_just_pressed("Test Damage"):
		_start_action(&"Damage")
	elif Input.is_action_just_pressed("Test Push"):
		_start_action(&"Push")
	elif Input.is_action_just_pressed("Summon Shadow"):
		_start_action(&"SummonShadow")
	elif Input.is_action_just_pressed("Shadow Strike"):
		_start_action(&"ShadowStrike")
	elif Input.is_action_just_pressed("Attack"):
		_start_action(&"Attack" if is_on_floor() else &"AirStrike")
	elif Input.is_action_just_pressed("Dash") and is_on_floor():
		_start_action(&"Dash", DASH_DURATION, 2.0)
	elif Input.is_action_just_pressed("Shadow Dash") and is_on_floor():
		_start_action(&"ShadowDash")
	elif Input.is_action_just_pressed("Slide") and is_on_floor():
		_start_action(&"Slide", SLIDE_DURATION, 1.0)
	elif Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = jump_power * jump_multiplier


func _start_action(animation: StringName, duration := 0.0, multiplier := 0.0) -> void:
	swing_hit = false
	action_name = animation
	action_time = duration
	action_multiplier = multiplier
	action_direction = direction if direction else -1.0 if hero_animation.flip_h else 1.0
	hero_animation.play(animation)


func _update_action(delta: float) -> void:
	if action_time > 0.0:
		action_time -= delta
		velocity.x = action_direction * speed * speed_multiplier * action_multiplier
		if action_time <= 0.0:
			action_name = &""
			velocity.x = 0.0
			hero_animation.stop()
		return

	velocity.x = 0.0
	if hero_animation.is_playing():
		return
	if action_name == &"Die":
		get_tree().reload_current_scene()
		return
	if action_name == &"Attack" and attack_queued:
		attack_queued = false
		_start_action(&"Attack 2")
		return
	action_name = &""


func _update_movement() -> void:
	if direction:
		velocity.x = direction * speed * speed_multiplier
	else:
		velocity.x = move_toward(velocity.x, 0, speed * speed_multiplier)


func _update_animation() -> void:
	var animation := "Jump" if not is_on_floor() else "Run" if direction else "Idle"
	if hero_animation.animation != animation:
		hero_animation.play(animation)


		
