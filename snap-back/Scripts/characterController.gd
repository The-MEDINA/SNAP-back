extends Node3D

# Physics values
@export var forearmMovementStrength = 200.0
@export var calfMovementStrength = 200.0
@export var heightToRunMaintenance = 0.75
@export var minHeightToMaintain = 0.35
@export var heightMaintenanceStrength = 100.0
@export var uprightMaintenanceStrength = 30.0
@export var rotationSpeedToOtherPlayer = 0.75

# Controllers (0 is controller 1, 1 is controller 2, so on)
@export var topController = 0
@export var bottomController = 0
# If true, player's controller is initially bottomController
@export var singlePlayer = true
var bumperPrevious: bool

# Controller settings
@export var triggerMaxReduction = 0.5

# Game variables
@export var otherPlayerTop: Node3D
@export var otherPlayerBottom: Node3D

# Joints
var joint: Generic6DOFJoint3D
var topBoneSim: PhysicalBoneSimulator3D
var bottomBoneSim: PhysicalBoneSimulator3D
var topJoint: PhysicalBone3D
var bottomJoint: PhysicalBone3D
var rightCalf: PhysicalBone3D
var leftCalf: PhysicalBone3D
var rightForearm: PhysicalBone3D
var leftForearm: PhysicalBone3D

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
	rightForearm = topBoneSim.get_node('Physical Bone ForearmR') as PhysicalBone3D
	leftForearm = topBoneSim.get_node('Physical Bone ForearmL') as PhysicalBone3D
	# Assign camera
	camera = get_viewport().get_camera_3d()
	# Singleplayer setup
	if singlePlayer:
		topController = 999

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
		_keepHeight(result.position.y)
		_rotateTowardTarget((otherPlayerTop.global_position + otherPlayerBottom.global_position) / 2.0)
	_handlePlayerInput(delta)

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

# Keep the body (somewhat) off of the floor
func _keepHeight(floor: float) -> void:
	# Get height to maintain
	var heightToMaintain = ((bottomJoint.global_position.y - leftCalf.global_position.y) + (bottomJoint.global_position.y - rightCalf.global_position.y)) / 2.0
	heightToMaintain = clamp(heightToMaintain, minHeightToMaintain, heightToRunMaintenance)
	# Get ideal height and see if the pelvis is below that height
	var desired_height = floor + heightToMaintain
	if bottomJoint.global_position.y < desired_height:
		# If below that height, apply velocity to correct for difference in height
		var error = desired_height - bottomJoint.global_position.y
		bottomJoint.linear_velocity.y += error * heightMaintenanceStrength

# Rotate toward the target Vector3
func _rotateTowardTarget(target: Vector3) -> void:
	# Get direction to target, ensure it isn't length 0 when Y is removed
	var direction = target - global_position
	direction.y = 0.0
	if direction.length_squared() == 0.0:
		return
	direction = direction.normalized()
	# Get forward, same check
	var forward = topJoint.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() == 0.0:
		return
	forward = forward.normalized()
	# Signed angle around Y
	var angle = atan2(forward.cross(direction).y, forward.dot(direction))
	var axis = Vector3.UP
	var correction = axis * angle * rotationSpeedToOtherPlayer
	topJoint.angular_velocity += correction
	bottomJoint.angular_velocity -= correction

func _handlePlayerInput(delta: float) -> void:
	# Read thumbstick inputs
	var topRightThumbstick = Vector2(Input.get_joy_axis(topController, JOY_AXIS_RIGHT_X),-Input.get_joy_axis(topController, JOY_AXIS_RIGHT_Y))
	var topLeftThumbstick = Vector2(Input.get_joy_axis(topController, JOY_AXIS_LEFT_X),-Input.get_joy_axis(topController, JOY_AXIS_LEFT_Y))
	var bottomRightThumbstick = Vector2(Input.get_joy_axis(bottomController, JOY_AXIS_RIGHT_X),-Input.get_joy_axis(topController, JOY_AXIS_RIGHT_Y))
	var bottomLeftThumbstick = Vector2(Input.get_joy_axis(bottomController, JOY_AXIS_LEFT_X),-Input.get_joy_axis(topController, JOY_AXIS_LEFT_Y))
	# Turn thumbsticks into relative Vector3s to use on body
	var rightForearmInput = _makeRelativeToCamera(topRightThumbstick)
	var leftForearmInput = _makeRelativeToCamera(topLeftThumbstick)
	var rightCalfInput = _makeRelativeToCamera(bottomRightThumbstick)
	var leftCalfInput = _makeRelativeToCamera(bottomLeftThumbstick)
	# Read trigger values
	var topLeftTrigger = Input.get_joy_axis(topController, JOY_AXIS_TRIGGER_LEFT)
	var topRightTrigger = Input.get_joy_axis(topController, JOY_AXIS_TRIGGER_RIGHT)
	var bottomLeftTrigger = Input.get_joy_axis(bottomController, JOY_AXIS_TRIGGER_LEFT)
	var bottomRightTrigger = Input.get_joy_axis(bottomController, JOY_AXIS_TRIGGER_RIGHT)
	# Apply triggers to weaken inputs
	rightForearmInput -= rightForearmInput * topRightTrigger * triggerMaxReduction
	leftForearmInput -= leftForearmInput * topLeftTrigger * triggerMaxReduction
	rightCalfInput -= rightCalfInput * bottomRightTrigger * triggerMaxReduction
	leftCalfInput -= leftCalfInput * bottomLeftTrigger * triggerMaxReduction
	# Move limbs
	rightForearm.angular_velocity += rightForearmInput * forearmMovementStrength
	leftForearm.angular_velocity += leftForearmInput * forearmMovementStrength
	rightCalf.angular_velocity += rightCalfInput * calfMovementStrength
	leftCalf.angular_velocity += leftCalfInput * calfMovementStrength
	# If single player and button pressed, swap controlled half of body
	if singlePlayer:
		var bumper = Input.is_joy_button_pressed(bottomController if bottomController != 999 else topController, JOY_BUTTON_RIGHT_SHOULDER)
		if bumper && !bumperPrevious:
			if bottomController == 999:
				bottomController = topController
				topController = 999
			else:
				topController = bottomController
				bottomController = 999
		bumperPrevious = bumper 
		
# Make a Vector2 thumbstick input relative to the camera in world space
func _makeRelativeToCamera(input: Vector2) -> Vector3:
	# Get right direction of camera (basis is a 3x3 matrix containing local axes)
	var cameraRight = camera.global_transform.basis.z
	# Camera looking up or down has no impact on input
	cameraRight.y = 0
	cameraRight = cameraRight.normalized()
	# Multiply right direction by X input, maintain Y as up
	return cameraRight * input.x + Vector3.UP * input.y
