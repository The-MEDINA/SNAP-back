extends Node3D

# Physics values
@export var upperArmMovementStrength = 1.5
@export var calfMovementStrength = 5.0
@export var heightToRunMaintenance = 0.83
@export var uprightMaintenanceStrength = 25.0
@export var rotationSpeed = 2.5
@export var rotationDamping = 50.0
@export var bodyDamping = 0.7

# Controls values
@export var maxUpperArmControlDistance = 0.3
@export var maxCalfControlDistance = 0.3
@export var triggerMaxReduction = 0.5

# Controllers (0 is controller 1, 1 is controller 2, so on)
@export var topController = 0
@export var bottomController = 0
# If true, player's controller is initially bottomController
@export var singlePlayer = true
var bumperPrevious: bool

# Game variables
@export var otherPlayer: Node3D

# Joints
var joint: Generic6DOFJoint3D
var topBoneSim: PhysicalBoneSimulator3D
var bottomBoneSim: PhysicalBoneSimulator3D
var topJoint: PhysicalBone3D
var bottomJoint: PhysicalBone3D
var rightCalf: PhysicalBone3D
var leftCalf: PhysicalBone3D
var rightUpperArm: PhysicalBone3D
var leftUpperArm: PhysicalBone3D

# Offsets used for base bone positions
var rightUpperArmOffset: Vector3
var leftUpperArmOffset: Vector3
var rightCalfOffset: Vector3
var leftCalfOffset: Vector3

# Target positions for each limb
var rightUpperArmTarget: Vector3
var leftUpperArmTarget: Vector3
var rightCalfTarget: Vector3
var leftCalfTarget: Vector3

# Camera for making input relative
var camera: Camera3D

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
	rightCalf = bottomBoneSim.get_node('Physical Bone CalfR') as PhysicalBone3D
	leftCalf = bottomBoneSim.get_node('Physical Bone CalfL') as PhysicalBone3D
	rightUpperArm = topBoneSim.get_node('Physical Bone UpperArmR') as PhysicalBone3D
	leftUpperArm = topBoneSim.get_node('Physical Bone UpperArmL') as PhysicalBone3D
	# Get offsets for limbs (in local space of base joints)
	rightUpperArmOffset = topJoint.global_transform.basis.inverse() * (rightUpperArm.global_position - topJoint.global_position)
	leftUpperArmOffset = topJoint.global_transform.basis.inverse() * (leftUpperArm.global_position - topJoint.global_position)
	rightCalfOffset = bottomJoint.global_transform.basis.inverse() * (rightCalf.global_position - bottomJoint.global_position)
	leftCalfOffset = bottomJoint.global_transform.basis.inverse() * (leftCalf.global_position - bottomJoint.global_position)
	# Assign camera
	camera = get_viewport().get_camera_3d()
	# Singleplayer setup
	if singlePlayer:
		topController = 999
		print('Controlling bottom')

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# Runs on physics tick
func _physics_process(delta: float) -> void:
	# Check to see if body should be upright (only if body is close to ground), Character and Joint never actually move
	var query = PhysicsRayQueryParameters3D.create(bottomJoint.global_position, bottomJoint.global_position + Vector3.DOWN * heightToRunMaintenance)
	# Hit only layer 4 (4th bit position for 4th layer, 1000 in binary == 8 in decimal)
	query.collision_mask = 8
	var space = get_world_3d().direct_space_state
	var result = space.intersect_ray(query)
	if result:
		_keepUpright()
		_reduceMovement()
		_handlePlayerInput(delta, true)
		_rotateTowardTarget(otherPlayer.global_position, delta)
	else:
		_handlePlayerInput(delta, false)
	# Update parent
	global_position = (bottomJoint.global_position + topJoint.global_position) / 2.0

# Keep the body upright
func _keepUpright() -> void:
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

# Reduce movement to make player slide less
func _reduceMovement() -> void:
	topJoint.linear_velocity *= bodyDamping
	bottomJoint.linear_velocity *= bodyDamping

# Rotate parent toward the target Vector3
func _rotateTowardTarget(target: Vector3, delta: float) -> void:
	# Get target direction
	var targetDirection = target - global_position
	targetDirection.y = 0
	if targetDirection.length_squared() == 0.0:
		return
	targetDirection = targetDirection.normalized()
	# Forward direction, axis and angle
	var forward = bottomJoint.global_transform.basis.z.normalized()
	forward.y = 0
	var axis = Vector3.UP
	var angle = atan2(forward.cross(targetDirection).y, forward.dot(targetDirection))
	var correction = angle * rotationSpeed
	# Rotate torso, apply oppsoite rotation to pelvis to avoid spinning forever
	# Add rotational velocity
	topJoint.angular_velocity += axis * correction
	# Remove rotational velocity to prevent too much spinning
	topJoint.angular_velocity -= axis * topJoint.angular_velocity.y * rotationDamping * delta

func _handlePlayerInput(delta: float, grounded: bool) -> void:
	# Read thumbstick inputs
	var topRightThumbstick = Vector2(Input.get_joy_axis(topController, JOY_AXIS_RIGHT_X),-Input.get_joy_axis(topController, JOY_AXIS_RIGHT_Y))
	var topLeftThumbstick = Vector2(Input.get_joy_axis(topController, JOY_AXIS_LEFT_X),-Input.get_joy_axis(topController, JOY_AXIS_LEFT_Y))
	var bottomRightThumbstick = Vector2(Input.get_joy_axis(bottomController, JOY_AXIS_RIGHT_X),-Input.get_joy_axis(bottomController, JOY_AXIS_RIGHT_Y))
	var bottomLeftThumbstick = Vector2(Input.get_joy_axis(bottomController, JOY_AXIS_LEFT_X),-Input.get_joy_axis(bottomController, JOY_AXIS_LEFT_Y))
	# Turn thumbsticks into relative Vector3s to use on body
	var rightUpperArmInput = _makeRelativeToCamera(topRightThumbstick)
	var leftUpperArmInput = _makeRelativeToCamera(topLeftThumbstick)
	var rightCalfInput = _makeRelativeToCamera(bottomRightThumbstick)
	var leftCalfInput = _makeRelativeToCamera(bottomLeftThumbstick)
	# Read trigger values
	var topRightTrigger = Input.get_joy_axis(topController, JOY_AXIS_TRIGGER_RIGHT)
	var topLeftTrigger = Input.get_joy_axis(topController, JOY_AXIS_TRIGGER_LEFT)
	var bottomRightTrigger = Input.get_joy_axis(bottomController, JOY_AXIS_TRIGGER_RIGHT)
	var bottomLeftTrigger = Input.get_joy_axis(bottomController, JOY_AXIS_TRIGGER_LEFT)
	# Apply triggers to weaken inputs
	rightUpperArmInput -= rightUpperArmInput * topRightTrigger * triggerMaxReduction
	leftUpperArmInput -= leftUpperArmInput * topLeftTrigger * triggerMaxReduction
	rightCalfInput -= rightCalfInput * bottomRightTrigger * triggerMaxReduction
	leftCalfInput -= leftCalfInput * bottomLeftTrigger * triggerMaxReduction
	# Get target positions for limbs
	rightUpperArmTarget = _makeRelativeToBase(topJoint, rightUpperArmOffset) + rightUpperArmInput * maxUpperArmControlDistance
	leftUpperArmTarget = _makeRelativeToBase(topJoint, leftUpperArmOffset) + leftUpperArmInput * maxUpperArmControlDistance
	rightCalfTarget = _makeRelativeToBase(bottomJoint, rightCalfOffset) + rightCalfInput * maxUpperArmControlDistance
	leftCalfTarget = _makeRelativeToBase(bottomJoint, leftCalfOffset) + leftCalfInput * maxUpperArmControlDistance
	# Apply velocity to get limbs to target positions
	rightUpperArm.linear_velocity += _getVelocityToTarget(rightUpperArm.global_position, rightUpperArmTarget, upperArmMovementStrength)
	leftUpperArm.linear_velocity += _getVelocityToTarget(leftUpperArm.global_position, leftUpperArmTarget, upperArmMovementStrength)
	var rightCalfVelocity = _getVelocityToTarget(rightCalf.global_position, rightCalfTarget, calfMovementStrength)
	rightCalf.linear_velocity += rightCalfVelocity
	var leftCalfVelocity = _getVelocityToTarget(leftCalf.global_position, leftCalfTarget, calfMovementStrength)
	leftCalf.linear_velocity += leftCalfVelocity
	# If grounded, apply opposite of calf velocity average multipled by movement strength
	if grounded:
		bottomJoint.linear_velocity -= (rightCalfVelocity + leftCalfVelocity) / 2 * calfMovementStrength
	# If single player and button pressed, swap controlled half of body
	if singlePlayer:
		var bumper = Input.is_joy_button_pressed(bottomController if bottomController != 999 else topController, JOY_BUTTON_RIGHT_SHOULDER)
		if bumper && !bumperPrevious:
			if bottomController == 999:
				bottomController = topController
				topController = 999
				print('Controlling bottom')
			else:
				topController = bottomController
				bottomController = 999
				print('Controlling top')
		bumperPrevious = bumper 

# Apply a saved offset, accounting for rotation
func _makeRelativeToBase(baseJoint: PhysicalBone3D, offset: Vector3) -> Vector3:
	return baseJoint.global_position + (baseJoint.global_transform.basis * offset)

func _getVelocityToTarget(currentPosition: Vector3, targetPosition: Vector3, movementStrength: float) -> Vector3:
	return (targetPosition - currentPosition) * movementStrength

# Make a Vector2 thumbstick input relative to the camera in world space
func _makeRelativeToCamera(input: Vector2) -> Vector3:
	# Get right direction of camera (basis is a 3x3 matrix containing local axes)
	var cameraRight = camera.global_transform.basis.x
	# Camera looking up or down has no impact on input
	cameraRight.y = 0
	cameraRight = cameraRight.normalized()
	# Multiply right direction by X input, maintain Y as up
	return cameraRight * input.x + Vector3.UP * input.y
