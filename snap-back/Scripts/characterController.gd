extends Node3D

# Physics values
@export var upperArmMovementStrength = 1.5
@export var calfMovementStrength = 5.0
@export var heightToRunMaintenance = 0.95
@export var uprightMaintenanceStrength = 65.0
@export var rotationSpeed = 10.0
@export var rotationDamping = 300.0
@export var bodyDamping = 0.7

# Movement values
@export var upwardCalfMovementMultiplier = 1.5
@export var upwardCalfSplitMovementMultiplier = 0.5
@export var calfMovementMultiplier = 250.0
@export var calfSplitMovementMultiplier = 25.0
@export var upperArmSplitMovementMultiplier = 10.0
@export var distanceForMaxSplitDiagonalMovement = 3.0

# Force length required to split
@export var worldForceThreshold = 1500.0
@export var playerTopForceThreshold = 35.0
@export var playerBottomForceThreshold = 350.0

# Controls values
@export var maxUpperArmControlDistance = 0.3
@export var maxCalfControlDistance = 0.3
@export var triggerMaxReduction = 0.5
var alternateArms: bool
var alternateLegs: bool
var lastBottomB: bool
var lastBottomX: bool

# Controllers (0 is controller 1, 1 is controller 2, so on)
@export var topController = 0
@export var bottomController = 0
# If true, player's controller is initially bottomController
@export var singlePlayer = true
var bumperPrevious: bool

# Game variables
@export var otherPlayer: Node3D
@export var splitPlayers = false

# Reconnection values
@export var reconnectionDistance = 1.0
@export var reconnectionTimerMax = 1.0
var reconnectionTimer = reconnectionTimerMax
@export var safetyTimerAfterReconnection = 1.0
var safetyTimer = safetyTimerAfterReconnection

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
var jointOffset: Transform3D

# Target positions for each limb
var rightUpperArmTarget: Vector3
var leftUpperArmTarget: Vector3
var rightCalfTarget: Vector3
var leftCalfTarget: Vector3

# Last relative inputs for movement (arms for movement when split)
var lastLeftCalfInput: Vector3
var lastRightCalfInput: Vector3
var lastLeftUpperArmInput: Vector3
var lastRightUpperArmInput: Vector3

# Camera for making input relative
var camera: Camera3D

# Misc
var grounded: bool
var groundedRayResult

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Assign variables
	joint = $Joint
	topBoneSim = $Top/ArmatureTop/Skeleton3D/PhysicalBoneSimulator3D
	bottomBoneSim = $Bottom/ArmatureBottom/Skeleton3D/PhysicalBoneSimulator3D
	# Start bone simulation
	topBoneSim.physical_bones_start_simulation()
	bottomBoneSim.physical_bones_start_simulation()
	# Get joints to connect
	topJoint = topBoneSim.get_node('Physical Bone RootTorso') as PhysicalBone3D
	bottomJoint = bottomBoneSim.get_node('Physical Bone RootHip') as PhysicalBone3D
	# Connect bodies
	joint.node_a = bottomJoint.get_path()
	joint.node_b = topJoint.get_path()
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
	jointOffset = bottomJoint.global_transform.affine_inverse() * topJoint.global_transform
	# Assign camera
	camera = get_viewport().get_camera_3d()
	# Singleplayer setup
	if singlePlayer:
		topController = 999
		print('Controlling bottom')

# Runs on physics tick
func _physics_process(delta: float) -> void:
	# Check to see if body should be upright (only if body is close to ground), Character and Joint never actually move
	var query = PhysicsRayQueryParameters3D.create(bottomJoint.global_position, bottomJoint.global_position + Vector3.DOWN * heightToRunMaintenance)
	# Hit only layer 4 (4th bit position for 4th layer, 1000 in binary == 8 in decimal)
	query.collision_mask = 8
	var space = get_world_3d().direct_space_state
	groundedRayResult = space.intersect_ray(query)
	grounded = groundedRayResult.size() > 0
	# Series of function calls for handling physics and input
	if grounded && !splitPlayers:
		_keepUpright()
		_reduceMovement()
		_rotateTowardTarget(otherPlayer.global_position, delta)
		_setTopTransform()
	if splitPlayers:
		_tryReconnect(delta)
	_handlePlayerInput(delta)
	# Update safety timer if need be
	if safetyTimer > 0.0:
		safetyTimer -= delta
		if safetyTimer < 0.0:
			safetyTimer = 0.0
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
	var correction = axis * angle * uprightMaintenanceStrength # * (0.1 if angle < 10.0 else 1.0)
	# Rotate torso, apply oppsoite rotation to pelvis to avoid spinning forever
	topJoint.angular_velocity += correction
	bottomJoint.angular_velocity -= correction
	# If angle is close enough to being upright, keep character standing up
	#if angle < 5.0:
		#if groundedRayResult.position.y + 0.75 > bottomJoint.global_position.y:
			#topJoint.linear_velocity += Vector3.UP * abs(groundedRayResult.position.y - bottomJoint.global_position.y)
	

# Reduce movement to make player slide less
func _reduceMovement() -> void:
	topJoint.linear_velocity *= bodyDamping
	bottomJoint.linear_velocity *= bodyDamping

# Rotate parent toward the target Vector3
# THIS IS CAUSING THE CHARACTER TO FLY WHEN MID-AIR
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
	# Add rotational velocity, remove some rotational velocity to prevent too much spinning
	var rotationChange = (axis * correction) - (axis * topJoint.angular_velocity.y * rotationDamping * delta)
	topJoint.angular_velocity += rotationChange
	bottomJoint.angular_velocity -= rotationChange

# Get inputs and apply to limbs
func _handlePlayerInput(delta: float) -> void:
	# Read button inputs
	var bottomA = Input.is_joy_button_pressed(bottomController, JOY_BUTTON_A)
	var bottomB = Input.is_joy_button_pressed(bottomController, JOY_BUTTON_B)
	var bottomX = Input.is_joy_button_pressed(bottomController, JOY_BUTTON_X)
	var bottomY = Input.is_joy_button_pressed(bottomController, JOY_BUTTON_Y)
	# Read thumbstick inputs, use buttons if they're being pressed
	var topRightThumbstick = Vector2(Input.get_joy_axis(topController, JOY_AXIS_RIGHT_X),-Input.get_joy_axis(topController, JOY_AXIS_RIGHT_Y))
	var topLeftThumbstick = Vector2(Input.get_joy_axis(topController, JOY_AXIS_LEFT_X),-Input.get_joy_axis(topController, JOY_AXIS_LEFT_Y))
	var bottomRightThumbstick = (Vector2(Input.get_joy_axis(bottomController, JOY_AXIS_RIGHT_X),-Input.get_joy_axis(bottomController, JOY_AXIS_RIGHT_Y))
		if !((bottomB || bottomX) && !alternateLegs) && !bottomY else Vector2((1.0 if bottomB else 0.0) + (-1.0 if bottomX else 0.0), (1.0 if bottomY else 0.0)))
	var bottomLeftThumbstick = (Vector2(Input.get_joy_axis(bottomController, JOY_AXIS_LEFT_X),-Input.get_joy_axis(bottomController, JOY_AXIS_LEFT_Y))
		if !((bottomB || bottomX) && alternateLegs) && !bottomY else Vector2((1.0 if bottomB else 0.0) + (-1.0 if bottomX else 0.0), (1.0 if bottomY else 0.0)))
	# If button released, swap alternate variable
	if (!bottomX && lastBottomX) || (!bottomB && lastBottomB):
		alternateLegs = !alternateLegs
	# Save last button values
	lastBottomX = bottomX
	lastBottomB = bottomB
	# Turn thumbsticks into relative Vector3s to use on body
	var rightUpperArmInput = _makeRelativeToCamera(topRightThumbstick) if !splitPlayers else _makeRelativeForSplit(topRightThumbstick, rightUpperArm)
	var leftUpperArmInput = _makeRelativeToCamera(topLeftThumbstick) if !splitPlayers else _makeRelativeForSplit(topLeftThumbstick, leftUpperArm)
	var rightCalfInput = _makeRelativeToCamera(bottomRightThumbstick) if !splitPlayers else _makeRelativeForSplit(bottomRightThumbstick, rightCalf)
	var leftCalfInput = _makeRelativeToCamera(bottomLeftThumbstick) if !splitPlayers else _makeRelativeForSplit(bottomLeftThumbstick, leftCalf)
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
	# Get target positions for limbs, accounting for base joint rotation
	var relativeRightUpperArm = _makeRelativeToBase(topJoint, rightUpperArmOffset)
	var relativeLeftUpperArm = _makeRelativeToBase(topJoint, leftUpperArmOffset)
	var relativeRightCalf = _makeRelativeToBase(bottomJoint, rightCalfOffset)
	var relativeLeftCalf = _makeRelativeToBase(bottomJoint, leftCalfOffset)
	rightUpperArmTarget = relativeRightUpperArm + rightUpperArmInput * maxUpperArmControlDistance
	leftUpperArmTarget = relativeLeftUpperArm + leftUpperArmInput * maxUpperArmControlDistance
	rightCalfTarget = relativeRightCalf + rightCalfInput * maxCalfControlDistance
	leftCalfTarget = relativeLeftCalf + leftCalfInput * maxCalfControlDistance
	# Apply velocity to get limbs to target positions
	var splitArmModifier = 0.5 if splitPlayers else 1.0
	var splitCalfModifier = 0.15 if splitPlayers else 1.0
	var rightCalfVelocity = _getVelocityToTarget(rightCalf.global_position, rightCalfTarget, calfMovementStrength)
	var leftCalfVelocity = _getVelocityToTarget(leftCalf.global_position, leftCalfTarget, calfMovementStrength)
	rightUpperArm.linear_velocity += _getVelocityToTarget(rightUpperArm.global_position, rightUpperArmTarget, upperArmMovementStrength) * splitArmModifier
	leftUpperArm.linear_velocity += _getVelocityToTarget(leftUpperArm.global_position, leftUpperArmTarget, upperArmMovementStrength) * splitArmModifier
	rightCalf.linear_velocity += rightCalfVelocity * splitCalfModifier
	leftCalf.linear_velocity += leftCalfVelocity * splitCalfModifier
	# If grounded, apply opposite of calf velocity average multipled by movement strength
	if grounded && !splitPlayers:
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
	# Move the player along the ground with movement (seperately between arms and legs if split)
	# Declared outside of if-statement for use later
	var rightCalfInputChange
	var leftCalfInputChange
	if grounded || splitPlayers:
		var calfMultiplier = calfSplitMovementMultiplier if splitPlayers else calfMovementMultiplier
		var calfVectorMultiplier = Vector3(1,upwardCalfSplitMovementMultiplier if splitPlayers else upwardCalfMovementMultiplier,1) if grounded else Vector3(1,0,1)
		leftCalfInputChange = (leftCalfInput - lastLeftCalfInput) * calfVectorMultiplier
		# Y shouldn't be allowed to be greater than 0, also no Y when airborne
		if leftCalfInputChange.y > 0:
			leftCalfInputChange.y = 0
		if leftCalfInput.length() < lastLeftCalfInput.length():
			bottomJoint.linear_velocity -= leftCalfInputChange * maxCalfControlDistance * calfMultiplier
		rightCalfInputChange = (rightCalfInput - lastRightCalfInput) * calfVectorMultiplier
		if rightCalfInputChange.y > 0:
			rightCalfInputChange.y = 0
		if rightCalfInput.length() < lastRightCalfInput.length():
			bottomJoint.linear_velocity -= rightCalfInputChange * maxCalfControlDistance * calfMultiplier
	if splitPlayers:
		# Arms have no grounded value, cannot move vertically
		var leftUpperArmInputChange = (leftUpperArmInput - lastLeftUpperArmInput) * Vector3(1,0,1)
		if leftUpperArmInput.length() < lastLeftUpperArmInput.length():
			topJoint.linear_velocity -= leftUpperArmInputChange * maxUpperArmControlDistance * upperArmSplitMovementMultiplier
		var rightUpperArmInputChange = (rightUpperArmInput - lastRightUpperArmInput) * Vector3(1,0,1)
		if rightUpperArmInput.length() < lastRightUpperArmInput.length():
			topJoint.linear_velocity -= rightUpperArmInputChange * maxUpperArmControlDistance * upperArmSplitMovementMultiplier
	# If any form of leg input change is present, raise character up to prevent impact on floor
	if !splitPlayers && grounded:
		var inputChange = abs(rightCalfInputChange.length()) + abs(leftCalfInputChange.length())
		if (inputChange > 0):
			bottomJoint.linear_velocity += Vector3.UP * inputChange * 9.81 / 2.0
	# Save thumbstick positions for use on next tick
	lastLeftCalfInput = leftCalfInput
	lastRightCalfInput = rightCalfInput
	lastLeftUpperArmInput = leftUpperArmInput
	lastRightUpperArmInput = rightUpperArmInput

# Apply a saved offset, accounting for rotation
func _makeRelativeToBase(baseJoint: PhysicalBone3D, offset: Vector3) -> Vector3:
	return baseJoint.global_position + (baseJoint.global_transform.basis * offset)

func _getVelocityToTarget(currentPosition: Vector3, targetPosition: Vector3, movementStrength: float) -> Vector3:
	return (targetPosition - currentPosition) * movementStrength

# Make a Vector2 thumbstick input relative to the camera in world space
func _makeRelativeToCamera(input: Vector2) -> Vector3:
	# Get right direction of camera (basis is a 3x3 matrix containing local axes)
	var rightVector = camera.global_transform.basis.x
	# Camera looking up or down has no impact on input
	rightVector.y = 0
	rightVector = rightVector.normalized()
	# Multiply right direction by X input, maintain Y as up
	return rightVector * input.x + Vector3.UP * input.y

# Make a Vector2 thumbstick input relative to the camera in world space
func _makeRelativeForSplit(input: Vector2, joint: PhysicalBone3D) -> Vector3:
	# First, make movement relative to current camera position
	var movement = _makeRelativeToCamera(input)
	# Calculation is pointless if not moving
	if movement.length() < 0.05:
		return movement
	# Midpoint between players, this point is on the players' plane
	var playerMidpoint = (global_position + otherPlayer.global_position) / 2.0
	# Need forward vector for distance calculation, no Y component to get horizontal distance
	var forwardVector = -camera.global_transform.basis.z
	forwardVector.y = 0
	forwardVector = forwardVector.normalized()
	# Distance to the plane (direction is joint position relative to midpoint, dot gives signed distance in direction)
	var distanceToPlane = abs((joint.global_position - playerMidpoint).dot(forwardVector))
	# Create multiplier based on distance (further away means more diagonal movement)
	var multiplier = clampf(distanceToPlane / distanceForMaxSplitDiagonalMovement, 0.0, 1.0)
	# Movement toward the plane
	var diagonalMovement = forwardVector * input.x + Vector3.UP * input.y
	# Lerp to get actual movement output
	return movement.lerp(diagonalMovement, multiplier)

# Set the top transform to match that of the bottom
func _setTopTransform() -> void:
	var reconnectTransform: Transform3D = bottomJoint.global_transform * jointOffset
	topJoint.global_transform = reconnectTransform

# Depending on splitPlayers, either split the bodies or reconnect them
func _splitPlayers(split: bool) -> void:
	# Split >> not split, reconnect
	if !split:
		bottomJoint.angular_velocity = Vector3.ZERO
		bottomJoint.linear_velocity = Vector3.ZERO
		topJoint.angular_velocity = Vector3.ZERO
		topJoint.linear_velocity = Vector3.ZERO
		await get_tree().physics_frame
		_setTopTransform()
		joint.node_a = bottomJoint.get_path()
		joint.node_b = topJoint.get_path()
		splitPlayers = false
		safetyTimer = safetyTimerAfterReconnection
		return
	# Not split >> split, disconnect the bodies
	joint.node_a = NodePath("")
	joint.node_b = NodePath("")
	splitPlayers = true

# Force was applied to a bone, split if high enough
func _receiveForce(bone: PhysicalBone3D, force: Vector3, collider: Object) -> void:
	var usedForceThreshold = worldForceThreshold
	# Forces mean nothing if split or if safety timer is up
	if splitPlayers || safetyTimer > 0:
		return
	# If force is from other bone, ensure force isn't from self and other player is the acting player
	if collider is PhysicalBone3D:
		# If colliding with self, do nothing
		if bone.parent.is_ancestor_of(collider):
			return
		# If other player is down, do nothing
		if bone.parent.splitPlayers:
			return
		# If bone velocity is greater than other player's velocity, ignore collision
		if bone.linear_velocity.length() > collider.linear_velocity.length():
			return
		# Set threshold depending on the section of bones that was hit
		if bone.subParent.name == "Top":
			usedForceThreshold = playerTopForceThreshold
		else:
			usedForceThreshold = playerBottomForceThreshold
	# Check force
	print('force: ', force.length())
	print('required: ', usedForceThreshold)
	if force.length() > usedForceThreshold && !splitPlayers:
		_splitPlayers(true)

# Run timer that prevents reconnection, then try to reconnect players
func _tryReconnect(delta: float) -> void:
	if reconnectionTimer > 0:
		reconnectionTimer -= delta
		if reconnectionTimer <= 0:
			reconnectionTimer = 0
		else:
			return
	if bottomJoint.global_position.distance_to(topJoint.global_position) < reconnectionDistance:
		_splitPlayers(false)
		reconnectionTimer = reconnectionTimerMax
