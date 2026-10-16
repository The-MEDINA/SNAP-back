extends Skeleton3D 

@export_enum("char1", "char2") var character_key: String = "char1"

@onready var top_mesh_instance: MeshInstance3D = $TopMesh
@onready var bottom_mesh_instance: MeshInstance3D = $BottomMesh

var top_player_id: int
var bottom_player_id: int

func _ready() -> void:
	load_character_data()

func load_character_data() -> void:
	if not PlayerData:
		return
		
	var data = PlayerData.character_selections[character_key]
	
	if data["top_mesh"]:
		top_mesh_instance.mesh = data["top_mesh"]
		top_mesh_instance.skeleton = top_mesh_instance.get_path_to(self)
		
	if data["bottom_mesh"]:
		bottom_mesh_instance.mesh = data["bottom_mesh"]
		bottom_mesh_instance.skeleton = bottom_mesh_instance.get_path_to(self)
		
	top_player_id = data["top_player_id"]
	bottom_player_id = data["bottom_player_id"]
