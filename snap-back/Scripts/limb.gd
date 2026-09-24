extends Node

# Variables
var mesh = self
@export var left = true
@export var startingMeshHeight = 0.5
var origin: Vector3
@export var baseDirection = Vector3(0, -1.01, 0)
@export var lowBase = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	origin = mesh.global_position
	baseDirection = baseDirection / 1000 if lowBase else baseDirection
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var thumbstick = (
		Input.get_vector("LeftThumbstickLeft", "LeftThumbstickRight", "LeftThumbstickDown", "LeftThumbstickUp")
		if left else 
		Input.get_vector("RightThumbstickLeft", "RightThumbstickRight", "RightThumbstickDown", "RightThumbstickUp",)
		)
	# Make it look like a fake limb!
	mesh.scale.y = startingMeshHeight
	var meshHeight = mesh.scale.y
	var trigger = Input.get_action_strength("LeftTrigger") if left else Input.get_action_strength("RightTrigger")
	meshHeight = mesh.scale.y - (mesh.scale.y / 2 * trigger)
	mesh.scale.y = meshHeight;
	var actualDirection: Vector3 = (Vector3(thumbstick.x, thumbstick.y, 0) + baseDirection).normalized()
	mesh.look_at(mesh.global_position + actualDirection, Vector3.UP)
	mesh.global_position = origin + meshHeight / 2 * actualDirection
	mesh.rotate_z(PI / 2)
	pass
