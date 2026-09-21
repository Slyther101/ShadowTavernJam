extends Node2D

func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed():
		get_tree().change_scene_to_file("res://main.tscn")
		
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
