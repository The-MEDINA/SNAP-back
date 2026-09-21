extends Node3D


func _ready() -> void:
	# starts tha ragdoll simulation
	$Bottom1/ArmatureBottom/Skeleton3D/PhysicalBoneSimulator3D.physical_bones_start_simulation()
