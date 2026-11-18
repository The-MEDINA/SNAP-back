extends Node

@export var object1: Node3D
@export var object2: Node3D
@export var minDistance = 5.0
@export var cameraBounds: MeshInstance3D
var camera
var bounds

# Camera shake values
var maxCameraShakeTimer = 0.0
var cameraShakeTimer = 0.0
var cameraShakeIntensity = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	camera = self
	# Get bounding box
	bounds = cameraBounds.get_aabb()
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Place camera on perpendicular plane to objects
	var direction = (object1.global_position - camera.global_position).normalized() + (object2.global_position - camera.global_position).normalized()
	direction.y = 0;
	direction = direction.normalized()
	camera.look_at(camera.global_position + direction, Vector3.UP)
	var position = ((
		(object1.global_position + object2.global_position) / 2) - direction
		* clampf(object1.global_position.distance_to(object2.global_position), minDistance, 999))
	# Convert position to local space of bounds
	var local_position : Vector3 = cameraBounds.to_local(position);
	local_position.x = clampf(
		local_position.x,
		bounds.position.x,
		bounds.end.x
	)
	local_position.y = clampf(
		local_position.y,
		bounds.position.y,
		bounds.end.y
	)
	local_position.z = clampf(
		local_position.z,
		bounds.position.z,
		bounds.end.z
	)
	# Convert back to world space
	position = cameraBounds.to_global(local_position)
	camera.global_position = position
	
	# Run camera shake function
	if cameraShakeTimer > 0:
		var intensityMultipler = (cameraShakeTimer / maxCameraShakeTimer) * cameraShakeIntensity
		var shake = Vector3(randf_range(-intensityMultipler, intensityMultipler), randf_range(-intensityMultipler, intensityMultipler), 0.0)
		camera.global_position += shake
		cameraShakeTimer -= delta

# Apply numbers to camera shake variables, creating shake
func _startCameraShake(time: float, intensity: float) -> void:
	maxCameraShakeTimer = time
	cameraShakeTimer = time
	cameraShakeIntensity = intensity
