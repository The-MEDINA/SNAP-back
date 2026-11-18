extends Skeleton3D 

@export_enum("char1", "char2") var character_key: String = "char1"

@onready var top_mesh_instance: Node3D = $TopMesh
@onready var bottom_mesh_instance: Node3D = $BottomMesh
func _ready() -> void:
	load_character_selections()

func load_character_selections() -> void:
	if not PlayerData or not PlayerData.character_selections.has(character_key):
		print("No PlayerData found for key: ", character_key)
		return

	var data = PlayerData.character_selections[character_key]

	# Instantiate saved PackedScene GLB into Top mount
	if data.get("top_mesh") and top_mesh_instance:
		_apply_part_scene(top_mesh_instance, data["top_mesh"])

	# Instantiate saved PackedScene GLB into Bottom mount
	if data.get("bottom_mesh") and bottom_mesh_instance:
		_apply_part_scene(bottom_mesh_instance, data["bottom_mesh"])

# Clears default placeholder parts and spawns the new PackedScene GLB
func _apply_part_scene(mount_node: Node3D, part_scene: PackedScene) -> void:
	# Clear out placeholder mannequin nodes
	for child in mount_node.get_children():
		child.queue_free()

	if part_scene:
		var instance = part_scene.instantiate()
		mount_node.add_child(instance)
		
		var inner_mesh = _find_mesh_instance(instance)
		if inner_mesh:
			inner_mesh.skeleton = inner_mesh.get_path_to(self)

func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var found = _find_mesh_instance(child)
		if found:
			return found
	return null
