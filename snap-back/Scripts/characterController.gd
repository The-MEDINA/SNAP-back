extends Node

var boneSim: PhysicalBoneSimulator3D
var leftThigh: PhysicalBone3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var boneSim = get_node(self.name + "/ArmatureBottom/Skeleton3D/PhysicalBoneSimulator3D")
	leftThigh = boneSim.get_node('Physical Bone ThighL') as PhysicalBone3D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# Runs on physics tick
func _physics_process(delta: float) -> void:
	var leftThumbstick = Input.get_vector("LeftThumbstickLeft", "LeftThumbstickRight", "LeftThumbstickDown", "LeftThumbstickUp")
	var rightThumbstick = Input.get_vector("RightThumbstickLeft", "RightThumbstickRight", "RightThumbstickDown", "RightThumbstickUp")
	leftThigh.global_position = leftThigh.global_position + Vector3(leftThumbstick.x, leftThumbstick.y, 0.0) * delta
	pass
