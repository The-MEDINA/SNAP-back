extends Node

@export var object1: Node
@export var object2: Node
var camera

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	camera = self
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var direction = (object1.global_position - camera.global_position).normalized() + (object2.global_position - camera.global_position).normalized()
	direction.y = 0;
	direction = direction.normalized()
	camera.look_at(camera.global_position + direction, Vector3.UP)
	var position = ((object1.global_position + object2.global_position) / 2) - direction * object1.global_position.distance_to(object2.global_position)
	camera.global_position = position
	pass
