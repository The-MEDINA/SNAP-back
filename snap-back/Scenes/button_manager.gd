extends Control

# Character Data
class CharacterPart:
	var name: String
	var role: String
	var mesh: Mesh
	
	func _init(p_name: String, p_role: String,p_mesh: Mesh) -> void:
		name = p_name
		role = p_role
		mesh = p_mesh
		
		
#UI References
#Top References
@onready var top_name_label: Label = $MainHBoxContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/TopNameLabel
@onready var top_role_label: Label = $MainHBoxContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/TopRoleLabel
@onready var top_prev_btn: Button = $MainHBoxContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/TopPrevBtn
@onready var top_next_btn: Button = $MainHBoxContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/TopNextBtn
@onready var top_lock_btn: Button = $MainHBoxContainer/PanelContainer/MarginContainer/VBoxContainer/TopLockInButton
#Bottom References
@onready var bottom_name_label: Label = $MainHBoxContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/VBoxContainer/BottomNameLabel
@onready var bottom_role_label: Label = $MainHBoxContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/VBoxContainer/BottomRoleLabel
@onready var bottom_prev_btn: Button = $MainHBoxContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/BottomPrevBtn
@onready var bottom_next_btn: Button = $MainHBoxContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/BottomNextBtn
@onready var bottom_lock_btn: Button = $MainHBoxContainer/PanelContainer/MarginContainer/VBoxContainer/BottomLockInButton

#3D Mesh Instance References
@export var top_mesh_node: MeshInstance3D
@export var bottom_mesh_node: MeshInstance3D

#Character Part State Tracking
#Array of character parts
var top_parts: Array[CharacterPart] = []
var bottom_parts: Array[CharacterPart] = []

#Tracking current character shown
var current_top_index: int = 0
var current_bottom_index: int = 0

#Check if locked in top and bottom
var p1_locked: bool = false
var p2_locked: bool = false

#Start 
func _ready() -> void:
	#Initalize parts
	_setup_character_parts()
	
	#Connect buttons 
	top_prev_btn.pressed.connect(func(): _cycle_top(-1))
	top_next_btn.pressed.connect(func(): _cycle_top(1))
	top_lock_btn.pressed.connect(_on_top_lock_pressed)
	
	bottom_prev_btn.pressed.connect(func(): _cycle_bottom(-1))
	bottom_next_btn.pressed.connect(func(): _cycle_bottom(1))
	bottom_lock_btn.pressed.connect(_on_bottom_lock_pressed)
	
	_update_display()


#Update the meshes with names and roles
func _update_display() -> void:
	# Update Top Selection
	if not top_parts.is_empty():
		var top_item = top_parts[current_top_index]
		top_name_label.text = top_item.name
		top_role_label.text = top_item.role
		if top_mesh_node:
			top_mesh_node.mesh = top_item.mesh

	# Update Bottom Selection
	if not bottom_parts.is_empty():
		var bottom_item = bottom_parts[current_bottom_index]
		bottom_name_label.text = bottom_item.name
		bottom_role_label.text = bottom_item.role
		if bottom_mesh_node:
			bottom_mesh_node.mesh = bottom_item.mesh

#Initalizing the parts
func _setup_character_parts() -> void:
	#==================================
	# FOR TESTING BEFORE REAL MESHES
	#==================================
	var red_cube = BoxMesh.new()
	red_cube.size = Vector3(0.8, 0.8, 0.8)
	var red_mat = StandardMaterial3D.new()
	red_mat.albedo_color = Color.RED
	red_cube.material = red_mat

	var blue_sphere = SphereMesh.new()
	blue_sphere.radius = 0.4
	blue_sphere.height = 0.8
	var blue_mat = StandardMaterial3D.new()
	blue_mat.albedo_color = Color.DODGER_BLUE
	blue_sphere.material = blue_mat
	
	top_parts = [
		CharacterPart.new("Red Top", "Melee", red_cube),
		CharacterPart.new("Blue Top", "Ranged", blue_sphere)
	]
	bottom_parts = [
		CharacterPart.new("Red Bottom", "Speed", red_cube),
		CharacterPart.new("Blue Bottom", "Stability", blue_sphere)
	]
	#==================================
	# WHEN 3D MESHES ARE READY (Examples)
	#==================================
	#top_parts = [
	# 	CharacterPart.new("Scarecrow", "Light", preload("res://Assets/3D/Armor/top_knight.tres")),
	# ]
	#
	# bottom_parts = [
	# 	CharacterPart.new("Scarecrow", "Light", preload("res://Assets/3D/Armor/bottom_knight.tres")),
	# ]

#Function to cycle through the tops, and update
func _cycle_top(dir: int) -> void:
	#make sure there is a 
	if p1_locked or top_parts.is_empty():
		return
	current_top_index = (current_top_index + dir + top_parts.size()) % top_parts.size()
	_update_display()	

#Function to cycle through the bottoms and update
# -1 = previous index
# 1 = next index 
func _cycle_bottom(dir: int) -> void:
	if p2_locked or bottom_parts.is_empty():
		return
	#Change index based on number passed in
	current_bottom_index = (current_bottom_index + dir + bottom_parts.size()) % bottom_parts.size()
	_update_display()

#Player 1 is ready 
func _on_top_lock_pressed() -> void:
	p1_locked = true
	top_prev_btn.disabled = true
	top_next_btn.disabled = true
	top_lock_btn.disabled = true
	top_lock_btn.text = "READY"
	_check_both_ready()

#Player 2 is ready
func _on_bottom_lock_pressed() -> void:
	p2_locked = true
	bottom_prev_btn.disabled = true
	bottom_next_btn.disabled = true
	bottom_lock_btn.disabled = true
	bottom_lock_btn.text = "READY"
	_check_both_ready()

#Both players are ready to start
func _check_both_ready() -> void:
	if p1_locked and p2_locked:
		print("Both players locked in their meshes!")
		# Transition to gameplay scene
