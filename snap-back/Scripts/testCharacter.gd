extends Node3D

var mesh = self
@export var left = true
@export var speed = 7.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var thumbstick = (
		Input.get_vector("LeftThumbstickLeft", "LeftThumbstickRight", "LeftThumbstickDown", "LeftThumbstickUp")
		if left else 
		Input.get_vector("RightThumbstickLeft", "RightThumbstickRight", "RightThumbstickDown", "RightThumbstickUp",)
		)
	var movement: Vector3 = Vector3(thumbstick.x, 0.0, thumbstick.y)
	mesh.global_position += movement * delta * speed
	pass
