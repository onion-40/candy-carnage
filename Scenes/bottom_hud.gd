
extends PanelContainer

@onready var bones_label: Label = $HBoxContainer/ResourceList/BonesLabel
@onready var organs_label: Label = $HBoxContainer/ResourceList/OrgansLabel
@onready var eyeballs_label: Label = $HBoxContainer/ResourceList/EyeballsLabel
@onready var special_character_button: Button = $HBoxContainer/SpecialCharButton

func _ready() -> void:
	ResourceManager.inventory_changed.connect(update_resources)
	update_resources(
		ResourceManager.bones,
		ResourceManager.organs,
		ResourceManager.eyeballs
	)
	
	special_character_button.pressed.connect(_on_special_character_button_pressed)

func update_resources(
	bone_amount: int,
	organ_amount: int,
	eyeball_amount: int
) -> void:
	bones_label.text = "Bones: %d" % bone_amount
	organs_label.text = "Organs: %d" % organ_amount
	eyeballs_label.text = "Eyeballs: %d" % eyeball_amount

func _on_special_character_button_pressed() -> void:
	var map = get_tree().current_scene.get_node("Map")
	map.begin_special_placement()
