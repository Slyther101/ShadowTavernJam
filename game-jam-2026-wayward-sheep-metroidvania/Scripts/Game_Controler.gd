extends Node

@onready var hero: CharacterBody2D = $Hero
@onready var shadow: CharacterBody2D = $Shadow

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hero.is_controled = true
	shadow.is_controled = false
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Summon Shadow"):
		if hero.is_controled: 
			shadow.global_position = hero.global_position 
		hero.is_controled = not hero.is_controled
		shadow.is_controled = not shadow.is_controled
		
