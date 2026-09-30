extends Node

@export var object1: Node
@export var object2: Node
@export var minDistance = 5.0
@export var cameraBounds: MeshInstance3D
var camera
var bounds

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	camera = self
	# Get bounding box
	bounds = cameraBounds.global_transform * cameraBounds.get_aabb()
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var direction = (object1.global_position - camera.global_position).normalized() + (object2.global_position - camera.global_position).normalized()
	direction.y = 0;
	direction = direction.normalized()
	camera.look_at(camera.global_position + direction, Vector3.UP)
	# Need to bind camera position to be within bounds
	var position = ((
		(object1.global_position + object2.global_position) / 2) - direction
		* clampf(object1.global_position.distance_to(object2.global_position), minDistance, 999))
	camera.global_position = position
	pass
