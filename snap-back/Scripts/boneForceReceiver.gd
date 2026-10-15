extends PhysicalBone3D

var parent: Node3D

# Watch contacts for collision
func _ready() -> void:
	parent = get_parent().get_parent().get_parent().get_parent().get_parent()
	PhysicsServer3D.body_set_max_contacts_reported(get_rid(), 3)

# When possible, send force information to character controller
func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	for i in range(state.get_contact_count()):
		var collider = state.get_contact_collider_object(i)
		var force = state.get_contact_impulse(i) / state.step
		if force.length() > 0.0:
			parent._receiveForce(self, force, collider)
