extends CharacterBody2D

@export var speed = 10.0
@export var jump_power = 10.0
@onready var shadow_animation: AnimatedSprite2D = $ShadowAnimation
@export var is_controled = false

const DASH_DURATION := 0.15
const SHADOW_DASH_DURATION := 0.20
const SLIDE_DURATION := 0.25

var speed_multiplier = 30.0
var jump_multiplier = -30.0
var direction := 0.0
var action_name: StringName
var action_time := 0.0
var action_multiplier := 0.0
var action_direction := 1.0
var attack_queued := false


func _physics_process(delta: float) -> void:
	print(action_name)
	if is_controled:
		visible = true
		if not is_on_floor():
			velocity += get_gravity() * delta
		direction = Input.get_axis("Move Left", "Move Right")
		if direction:
			shadow_animation.flip_h = direction < 0

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
	elif not shadow_animation.is_playing():
		visible = false
		action_name = ""
	


func _try_start_action() -> void:
	if Input.is_action_just_pressed("Test Die"):
		_start_action(&"Die")
	elif Input.is_action_just_pressed("Test Damage"):
		_start_action(&"Damage")
	elif Input.is_action_just_pressed("Test Push"):
		_start_action(&"Push")
	elif Input.is_action_just_pressed("Summon Shadow"):
		_start_action(&"Disolve",0.6)
	elif Input.is_action_just_pressed("Shadow Strike"):
		_start_action(&"ShadowStrike")
	elif Input.is_action_just_pressed("Attack"):
		_start_action(&"Attack" if is_on_floor() else &"AirStrike",0.5)
	elif Input.is_action_just_pressed("Dash") and is_on_floor():
		_start_action(&"Dash", DASH_DURATION, 2.0)
	elif Input.is_action_just_pressed("Shadow Dash") and is_on_floor():
		_start_action(&"ShadowDash", SHADOW_DASH_DURATION, 3.0)
	elif Input.is_action_just_pressed("Slide") and is_on_floor():
		_start_action(&"Slide", SLIDE_DURATION, 1.0)
	elif Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = jump_power * jump_multiplier


func _start_action(animation: StringName, duration := 0.01, multiplier := 0.0) -> void:
	action_name = animation
	action_time = duration
	action_multiplier = multiplier
	action_direction = direction if direction else -1.0 if shadow_animation.flip_h else 1.0
	shadow_animation.play(animation)


func _update_action(delta: float) -> void:
	if action_time > 0.0:
		action_time -= delta
		velocity.x = action_direction * speed * speed_multiplier * action_multiplier
		if action_time <= 0.0:
			action_name = &""
			velocity.x = 0.0
			shadow_animation.stop()
		return

	velocity.x = 0.0
	if shadow_animation.is_playing():
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
	if shadow_animation.animation != animation:
		shadow_animation.play(animation)


		
