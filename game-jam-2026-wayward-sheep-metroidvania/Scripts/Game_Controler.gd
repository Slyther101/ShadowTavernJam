extends Node

@onready var hero: CharacterBody2D = $Hero
@onready var shadow: CharacterBody2D = $Shadow
@onready var active_camera: Camera2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hero.is_controled = true
	shadow.is_controled = false
	active_camera = hero.get_child(2)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Summon Shadow") and hero.is_on_floor():
		if hero.is_controled: 
			shadow.global_position = hero.global_position +Vector2(30,0)
		hero.is_controled = not hero.is_controled
		shadow.is_controled = not shadow.is_controled
		if hero.is_controled:
			active_camera.reparent(hero,true)
		else:
			active_camera.reparent(shadow,true)
			
		
