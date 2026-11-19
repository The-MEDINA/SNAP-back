extends Node3D
@export var height: float 

func _ready() -> void:
	# starts tha ragdoll simulation
	$ArmatureBottom/Skeleton3D/PhysicalBoneSimulator3D.physical_bones_start_simulation()
