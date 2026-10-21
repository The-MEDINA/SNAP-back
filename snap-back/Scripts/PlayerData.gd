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
