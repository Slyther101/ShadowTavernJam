extends CharacterBody2D

@export var speed = 10.0
@export var jump_power = 10.0
@onready var hero_animation: AnimatedSprite2D = $HeroAnimation

var speed_multiplier = 30.0
var jump_multiplier = -30.0
var direction = 0
var attack_step := 0
var attack_queued := false

#const SPEED = 300.0
#const JUMP_VELOCITY = -400.0


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("Attack"):
		if attack_step == 0:
			attack_step = 1
			hero_animation.play("Attack")
		elif attack_step == 1:
			attack_queued = true

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("Jump") and is_on_floor() and not attack_step:
		velocity.y = jump_power * jump_multiplier

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	direction = Input.get_axis("ui_left", "ui_right")
	if attack_step:
		velocity.x = 0
	elif direction:
		velocity.x = direction * speed * speed_multiplier
	else:
		velocity.x = move_toward(velocity.x, 0, speed * speed_multiplier)

	move_and_slide()
	_update_animation()


func _update_animation() -> void:
	if attack_step:
		if not hero_animation.is_playing():
			if attack_queued and attack_step == 1:
				attack_step = 2
				attack_queued = false
				hero_animation.play("Attack 2")
				return
			else:
				attack_step = 0
		else:
			return

	var animation := "Jump" if not is_on_floor() else "Run" if direction else "Idle"
	if hero_animation.animation != animation:
		hero_animation.play(animation)
	if direction:
		hero_animation.flip_h = direction < 0


		
