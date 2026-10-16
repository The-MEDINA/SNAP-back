extends Control

# Resources for Top and Bottom meshes
@export var top_options: Array[PartOption] = []
@export var bottom_options: Array[PartOption] = []

# --- Character 1 Node References (P1 = Top, P2 = Bottom) ---
@onready var c1_top_mesh: MeshInstance3D = $MainHBoxContainer/SubViewportContainer/SubViewport/Node3D/Character1/TopMesh
@onready var c1_bottom_mesh: MeshInstance3D = $MainHBoxContainer/SubViewportContainer/SubViewport/Node3D/Character1/BottomMesh

@onready var p1_name_label: Label = $MainHBoxContainer/PanelContainer/MarginContainer/VBoxContainer/VBoxContainer2/HBoxContainer/VBoxContainer/TopNameLabel1
@onready var p1_role_label: Label = $MainHBoxContainer/PanelContainer/MarginContainer/VBoxContainer/VBoxContainer2/HBoxContainer/VBoxContainer/TopRoleLabel1

@onready var p2_name_label: Label = $MainHBoxContainer/PanelContainer/MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer2/VBoxContainer/BottomNameLabel1
@onready var p2_role_label: Label = $MainHBoxContainer/PanelContainer/MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer2/VBoxContainer/BottomRoleLabel1

# --- Character 2 Node References (P3 = Top, P4 = Bottom) ---
@onready var c2_top_mesh: MeshInstance3D = $MainHBoxContainer2/SubViewportContainer/SubViewport/Node3D/Character2/TopMesh
@onready var c2_bottom_mesh: MeshInstance3D = $MainHBoxContainer2/SubViewportContainer/SubViewport/Node3D/Character2/BottomMesh

@onready var p3_name_label: Label = $MainHBoxContainer2/PanelContainer/MarginContainer/VBoxContainer/VBoxContainer2/HBoxContainer/VBoxContainer/TopNameLabel
@onready var p3_role_label: Label = $MainHBoxContainer2/PanelContainer/MarginContainer/VBoxContainer/VBoxContainer2/HBoxContainer/VBoxContainer/TopRoleLabel

@onready var p4_name_label: Label = $MainHBoxContainer2/PanelContainer/MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer2/VBoxContainer/BottomNameLabel
@onready var p4_role_label: Label = $MainHBoxContainer2/PanelContainer/MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer2/VBoxContainer/BottomRoleLabel

# --- Button Connections (Character 1) ---
@onready var p1_prev_btn: Button = $MainHBoxContainer/PanelContainer/MarginContainer/VBoxContainer/VBoxContainer2/HBoxContainer/TopPrevBtn1
@onready var p1_next_btn: Button = $MainHBoxContainer/PanelContainer/MarginContainer/VBoxContainer/VBoxContainer2/HBoxContainer/TopNextBtn1
@onready var p1_lock_btn: Button = $MainHBoxContainer/PanelContainer/MarginContainer/VBoxContainer/VBoxContainer2/TopLockInButton1

@onready var p2_prev_btn: Button = $MainHBoxContainer/PanelContainer/MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer2/BottomPrevBtn1
@onready var p2_next_btn: Button = $MainHBoxContainer/PanelContainer/MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer2/BottomNextBtn1
@onready var p2_lock_btn: Button = $MainHBoxContainer/PanelContainer/MarginContainer/VBoxContainer/VBoxContainer/BottomLockInButton1

# --- Button Connections (Character 2) ---
@onready var p3_prev_btn: Button = $MainHBoxContainer2/PanelContainer/MarginContainer/VBoxContainer/VBoxContainer2/HBoxContainer/TopPrevBtn
@onready var p3_next_btn: Button = $MainHBoxContainer2/PanelContainer/MarginContainer/VBoxContainer/VBoxContainer2/HBoxContainer/TopNextBtn
@onready var p3_lock_btn: Button = $MainHBoxContainer2/PanelContainer/MarginContainer/VBoxContainer/VBoxContainer2/TopLockInButton

@onready var p4_prev_btn: Button = $MainHBoxContainer2/PanelContainer/MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer2/BottomPrevBtn
@onready var p4_next_btn: Button = $MainHBoxContainer2/PanelContainer/MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer2/BottomNextBtn
@onready var p4_lock_btn: Button = $MainHBoxContainer2/PanelContainer/MarginContainer/VBoxContainer/VBoxContainer/BottomLockInButton

# Tracker variables
var selected_indices: Array[int] = [0, 0, 0, 0] # [P1, P2, P3, P4]
var player_ready: Array[bool] = [false, false, false, false]

func _ready() -> void:
	# Connect Button Signals
	p1_prev_btn.pressed.connect(func(): cycle_selection(0, -1))
	p1_next_btn.pressed.connect(func(): cycle_selection(0, 1))
	p1_lock_btn.pressed.connect(func(): toggle_ready(0))

	p2_prev_btn.pressed.connect(func(): cycle_selection(1, -1))
	p2_next_btn.pressed.connect(func(): cycle_selection(1, 1))
	p2_lock_btn.pressed.connect(func(): toggle_ready(1))

	p3_prev_btn.pressed.connect(func(): cycle_selection(2, -1))
	p3_next_btn.pressed.connect(func(): cycle_selection(2, 1))
	p3_lock_btn.pressed.connect(func(): toggle_ready(2))

	p4_prev_btn.pressed.connect(func(): cycle_selection(3, -1))
	p4_next_btn.pressed.connect(func(): cycle_selection(3, 1))
	p4_lock_btn.pressed.connect(func(): toggle_ready(3))

	# Initialize UI
	for i in range(4):
		update_player_ui(i)

func cycle_selection(player_id: int, direction: int) -> void:
	print("Cycle triggered for player: ", player_id, " Direction: ", direction)
	if player_ready[player_id]:
		return


	var is_top: bool = (player_id == 0 or player_id == 2)
	var options_count: int = top_options.size() if is_top else bottom_options.size()

	if options_count == 0:
		return

	selected_indices[player_id] = (selected_indices[player_id] + direction + options_count) % options_count
	update_player_ui(player_id)

func update_player_ui(player_id: int) -> void:
	var index: int = selected_indices[player_id]

	match player_id:
		0: # Player 1 (Char 1 Top)
			print("P1 Array Size: ", top_options.size(), " | Selected Index: ", index)
			if top_options.size() > index and c1_top_mesh:
				c1_top_mesh.mesh = top_options[index].mesh
				p1_name_label.text = top_options[index].name
				p1_role_label.text = top_options[index].role
		1: # Player 2 (Char 1 Bottom)
			if bottom_options.size() > index and c1_bottom_mesh:
				c1_bottom_mesh.mesh = bottom_options[index].mesh
				p2_name_label.text = bottom_options[index].name
				p2_role_label.text = bottom_options[index].role
		2: # Player 3 (Char 2 Top)
			if top_options.size() > index and c2_top_mesh:
				c2_top_mesh.mesh = top_options[index].mesh
				p3_name_label.text = top_options[index].name
				p3_role_label.text = top_options[index].role
		3: # Player 4 (Char 2 Bottom)
			if bottom_options.size() > index and c2_bottom_mesh:
				c2_bottom_mesh.mesh = bottom_options[index].mesh
				p4_name_label.text = bottom_options[index].name
				p4_role_label.text = bottom_options[index].role

func toggle_ready(player_id: int) -> void:
	player_ready[player_id] = !player_ready[player_id]
	
	var lock_buttons = [p1_lock_btn, p2_lock_btn, p3_lock_btn, p4_lock_btn]
	lock_buttons[player_id].text = "Locked!" if player_ready[player_id] else "Lock In"

	if not player_ready.has(false):
		print("All players locked in! Saving data...")
		
		# Retrieve selected meshes
		var c1_top = top_options[selected_indices[0]].mesh
		var c1_bottom = bottom_options[selected_indices[1]].mesh
		var c2_top = top_options[selected_indices[2]].mesh
		var c2_bottom = bottom_options[selected_indices[3]].mesh
		
		# Store in global singletons
		PlayerData.save_selections(c1_top, c1_bottom, c2_top, c2_bottom)
		
		# Change to gameplay scene
		get_tree().change_scene_to_file("res://Scenes/controlsTesting.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("p1_left"): cycle_selection(0, -1)
	elif event.is_action_pressed("p1_right"): cycle_selection(0, 1)
	elif event.is_action_pressed("p1_select"): toggle_ready(0)

	if event.is_action_pressed("p2_left"): cycle_selection(1, -1)
	elif event.is_action_pressed("p2_right"): cycle_selection(1, 1)
	elif event.is_action_pressed("p2_select"): toggle_ready(1)

	if event.is_action_pressed("p3_left"): cycle_selection(2, -1)
	elif event.is_action_pressed("p3_right"): cycle_selection(2, 1)
	elif event.is_action_pressed("p3_select"): toggle_ready(2)

	if event.is_action_pressed("p4_left"): cycle_selection(3, -1)
	elif event.is_action_pressed("p4_right"): cycle_selection(3, 1)
	elif event.is_action_pressed("p4_select"): toggle_ready(3)
