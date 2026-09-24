extends Control

# Character Data Structure
class CharacterData:
	var name: String
	var role: String
	var texture: Texture2D

	func _init(p_name: String, p_role: String, p_texture: Texture2D) -> void:
		name = p_name
		texture = p_texture

@onready var avatar_texture: TextureRect = $CardPanel/VBoxContainer/CarouselHBox/DisplayVBox/AvatarTexture
@onready var name_label: Label = $CardPanel/VBoxContainer/CarouselHBox/DisplayVBox/NameLabel
@onready var prev_button: Button = $CardPanel/VBoxContainer/CarouselHBox/PrevButton
@onready var next_button: Button = $CardPanel/VBoxContainer/CarouselHBox/NextButton
@onready var lock_button: Button = $CardPanel/VBoxContainer/LockInButton
@onready var status_label: Label = $CardPanel/VBoxContainer/StatusLabel

signal character_selected(character_data: CharacterData)

var characters: Array[CharacterData] = []
var current_index: int = 0
var is_locked: bool = false


func _ready() -> void:
	# Load sample character data
	characters = [
		CharacterData.new("Valerie", "Vanguard / Tank", preload("res://icon.svg")),
		CharacterData.new("Jax", "Duelist / Speed", preload("res://icon.svg")),
		CharacterData.new("Aura", "Support / Healer", preload("res://icon.svg")),
		CharacterData.new("Kael", "Mage / Crowd Control", preload("res://icon.svg"))
	]
