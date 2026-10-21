extends Node

# This dictionary holds all match data and stays alive when scenes change.
var match_data: Dictionary = {
	# Controller IDs (-1 is Keyboard/Mouse, 0 to 3 are gamepads)
	"p1_device": 0, # Fighter 1 Arms
	"p2_device": 1, # Fighter 1 Legs
	"p3_device": 2, # Fighter 2 Arms
	"p4_device": 3, # Fighter 2 Legs
	
	# Mesh/Part selections for Fighter 1
	"f1_top_index": 0,
	"f1_bottom_index": 0,
	
	# Mesh/Part selections for Fighter 2
	"f2_top_index": 0,
	"f2_bottom_index": 0
}

# Simple helper function to update choices from the menu
func save_choices(p1_dev: int, p2_dev: int, f1_top: int, f1_bot: int, p3_dev: int = 2, p4_dev: int = 3, f2_top: int = 0, f2_bot: int = 0) -> void:
	match_data["p1_device"] = p1_dev
	match_data["p2_device"] = p2_dev
	match_data["f1_top_index"] = f1_top
	match_data["f1_bottom_index"] = f1_bot
	
	match_data["p3_device"] = p3_dev
	match_data["p4_device"] = p4_dev
	match_data["f2_top_index"] = f2_top
	match_data["f2_bottom_index"] = f2_bot
	
	print("GameManager saved choices: ", match_data)
