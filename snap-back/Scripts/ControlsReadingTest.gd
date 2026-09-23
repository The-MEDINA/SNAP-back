extends Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var leftThumbstick := Input.get_vector("LeftThumbstickLeft", "LeftThumbstickRight", "LeftThumbstickUp", "LeftThumbstickDown");
	var rightThumbstick := Input.get_vector("RightThumbstickLeft", "RightThumbstickRight", "RightThumbstickUp", "RightThumbstickDown");
	leftThumbstick.y *= -1
	rightThumbstick.y *= -1
	print("Left: ", leftThumbstick)
	print("Right: ", rightThumbstick)
	pass
