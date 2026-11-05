# PlayerData.gd
extends Node

# Dictionary holding selections for each character
# Character 1: Player 1 (Top) & Player 2 (Bottom)
# Character 2: Player 3 (Top) & Player 4 (Bottom)
var character_selections = {
	"char1": {
		"top_mesh": null,
		"bottom_mesh": null,
		"top_player_id": 0,    # P1
		"bottom_player_id": 1  # P2
	},
	"char2": {
		"top_mesh": null,
		"bottom_mesh": null,
		"top_player_id": 2,    # P3
		"bottom_player_id": 3  # P4
	}
}

func save_selections(c1_top: Mesh, c1_bottom: Mesh, c2_top: Mesh, c2_bottom: Mesh) -> void:
	character_selections["char1"]["top_mesh"] = c1_top
	character_selections["char1"]["bottom_mesh"] = c1_bottom
	
	character_selections["char2"]["top_mesh"] = c2_top
	character_selections["char2"]["bottom_mesh"] = c2_bottom
	
	print("Player choices saved to Autoload!")

func change_controllers(device_to_player: Array[int]):
	character_selections["char1"]["top_player_id"] = device_to_player[0];
	character_selections["char1"]["bottom_player_id"] = device_to_player[1];
	character_selections["char2"]["top_player_id"] = device_to_player[2];
	character_selections["char2"]["bottom_player_id"] = device_to_player[3];
	return

# Take the mesh's INDEX from the CharacterSelect node, and converts it to a scene path.
# The character needs the scene path as a string to load the correct body.
func mesh_index_to_tscn_path(p1_selection: int, p2_selection: int, p3_selection: int, p4_selection: int):
	var char;
	var mesh;
	# set the correct option for each player
	for i in 4:
		match i:
			0:
				char = "char1"
				mesh = "top_mesh"
				set_top(char, mesh, p1_selection)
				pass
			1:
				char = "char1"
				mesh = "bottom_mesh"
				set_bottom(char, mesh, p2_selection)
				pass
			2:
				char = "char2"
				mesh = "top_mesh"
				set_top(char, mesh, p3_selection)
				pass
			3:
				char = "char2"
				mesh = "bottom_mesh"
				set_bottom(char, mesh, p4_selection)
				pass

	pass

func set_top(char, mesh, index):
	match index:
		# Mech
		0:
			character_selections[char][mesh] = "res://Character/mech_top.tscn"
		# Debug model
		_:
			character_selections[char][mesh] = "res://Character/top.tscn"
	pass
	
func set_bottom(char, mesh, index):
	match index:
		# Mech
		0:
			character_selections[char][mesh] = "res://Character/mech_bottom.tscn"
		# Debug model
		_:
			character_selections[char][mesh] = "res://Character/bottom_1.tscn"
	pass
