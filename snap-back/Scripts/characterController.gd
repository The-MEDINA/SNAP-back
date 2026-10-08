extends Node3D

# Physics values
@export var heightToRunMaintenance = 0.75
@export var heightToMaintain = 0.65
@export var heightMaintenanceStrength = 100.0
@export var uprightMaintenanceStrength = 30.0

# Joints
var joint: Generic6DOFJoint3D
var topBoneSim: PhysicalBoneSimulator3D
var bottomBoneSim: PhysicalBoneSimulator3D
var topJoint: PhysicalBone3D
var bottomJoint: PhysicalBone3D
var rightThigh: PhysicalBone3D
var leftThigh: PhysicalBone3D
var rightUpperArm: PhysicalBone3D
var leftUpperArm: PhysicalBone3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Assign variables
	joint = $Joint
	topBoneSim = $Top/ArmatureTop/Skeleton3D/PhysicalBoneSimulator3D
	bottomBoneSim = $Bottom/ArmatureBottom/Skeleton3D/PhysicalBoneSimulator3D
	# Get joints to connect
	topJoint = topBoneSim.get_node('Physical Bone RootTorso') as PhysicalBone3D
	bottomJoint = bottomBoneSim.get_node('Physical Bone RootHip') as PhysicalBone3D
	# Connect bodies
	joint.node_a = topJoint.get_path()
	joint.node_b = bottomJoint.get_path()
	# Assign variables
	rightThigh = bottomBoneSim.get_node('Physical Bone ThighR') as PhysicalBone3D
	leftThigh = bottomBoneSim.get_node('Physical Bone ThighL') as PhysicalBone3D
	rightUpperArm = topBoneSim.get_node('Physical Bone UpperArmR') as PhysicalBone3D
	leftUpperArm = topBoneSim.get_node('Physical Bone UpperArmL') as PhysicalBone3D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# Runs on physics tick
func _physics_process(delta: float) -> void:
	var leftThumbstick = Input.get_vector("LeftThumbstickLeft", "LeftThumbstickRight", "LeftThumbstickDown", "LeftThumbstickUp")
	var rightThumbstick = Input.get_vector("RightThumbstickLeft", "RightThumbstickRight", "RightThumbstickDown", "RightThumbstickUp")
	leftThigh.global_position = leftThigh.global_position + Vector3(leftThumbstick.x, leftThumbstick.y, 0.0) * delta * 3
	print(bottomJoint.global_position)
	# Check to see if body should be upright (only if body is close to ground), Character and Joint never actually move
	var query = PhysicsRayQueryParameters3D.create(bottomJoint.global_position, bottomJoint.global_position + Vector3.DOWN * heightToRunMaintenance)
	# Hit only layer 4 (4th bit position for 4th layer, 1000 in binary == 8 in decimal)
	query.collision_mask = 8
	var space = get_world_3d().direct_space_state
	var result = space.intersect_ray(query)
	if result:
		_keepUpright(delta)
		_keepHeight(delta, result.position.y)
	pass

# Keep the body upright
func _keepUpright(delta: float) -> void:
	# Get up direction (direction from bottomJoint to topJoint)
	var bodyUpDirection = (topJoint.global_position - bottomJoint.global_position).normalized()
	# Get rotation axis (direction perpendicular to up direction and Vector3.UP)
	var axis = bodyUpDirection.cross(Vector3.UP)
	# How far to rotate
	var angle = bodyUpDirection.angle_to(Vector3.UP)
	# length_squared runs faster than length, avoid rotating when length == 0 (which occurs when up direction and Vector3.UP are parallel)
	if axis.length_squared() == 0.0:
		return
	axis = axis.normalized()
	# Rotation direction * angle to rotate (stronger rotation when angle is higher) * additional strength
	var correction = axis * angle * uprightMaintenanceStrength
	# Rotate torso, apply oppsoite rotation to pelvis to avoid spinning forever
	topJoint.angular_velocity += correction
	bottomJoint.angular_velocity -= correction

# Keep the body (somewhat) off of the floor
func _keepHeight(delta: float, floor: float) -> void:
	# Get ideal height and see if the pelvis is below that height
	var desired_height = floor + heightToMaintain
	if bottomJoint.global_position.y < desired_height:
		# If below that height, apply velocity to correct for difference in height
		var error = desired_height - bottomJoint.global_position.y
		bottomJoint.linear_velocity.y += error * heightMaintenanceStrength
