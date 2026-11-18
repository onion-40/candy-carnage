extends Control

const PINK: Color = Color(1.0, 0.45, 0.75)
const GOLD: Color = Color(1.0, 0.84, 0.25)
const UPGRADE_SCREEN_SCRIPT = preload("res://Scripts/Menu/UpgradeScreen.gd")

@onready var menu_box: VBoxContainer = $CenterContainer/VBoxContainer
@onready var title_box: VBoxContainer = $CenterContainer/VBoxContainer/TitleBox
@onready var candy_label: Label = $CenterContainer/VBoxContainer/TitleBox/CandyLabel
@onready var carnage_label: Label = $CenterContainer/VBoxContainer/TitleBox/CarnageLabel
@onready var play_button: Button = $CenterContainer/VBoxContainer/PlayButton
@onready var upgrades_button: Button = $CenterContainer/VBoxContainer/UpgradesButton
@onready var how_to_play_button: Button = $CenterContainer/VBoxContainer/HowToPlayButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitButton

var tutorial_overlay: ColorRect
var upgrade_screen: ColorRect


func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	upgrades_button.pressed.connect(_on_upgrades_pressed)
	how_to_play_button.pressed.connect(_on_how_to_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	for button in [play_button, upgrades_button, how_to_play_button, quit_button]:
		MenuFx.setup_hover(button)

	for control in [title_box, candy_label, carnage_label]:
		MenuFx.keep_pivot_centered(control)

	_create_tutorial_popup()
	upgrade_screen = UPGRADE_SCREEN_SCRIPT.new()
	add_child(upgrade_screen)
	_play_intro()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	for overlay in [tutorial_overlay, upgrade_screen]:
		if overlay.visible:
			overlay.hide()
			get_viewport().set_input_as_handled()


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/LevelSelect.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_upgrades_pressed() -> void:
	upgrade_screen.open()


func _on_how_to_play_pressed() -> void:
	tutorial_overlay.show()


func _play_intro() -> void:
	menu_box.modulate.a = 0.0
	title_box.scale = Vector2(0.6, 0.6)

	var intro := create_tween().set_parallel()
	intro.tween_property(menu_box, "modulate:a", 1.0, 0.5)
	intro.tween_property(title_box, "scale", Vector2.ONE, 0.7) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# "CANDY" wobbles gently, "CARNAGE" beats like a heart.
	var wobble := create_tween().set_loops()
	wobble.tween_property(candy_label, "rotation_degrees", 2.0, 1.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	wobble.tween_property(candy_label, "rotation_degrees", -2.0, 1.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var heartbeat := create_tween().set_loops()
	heartbeat.tween_property(carnage_label, "scale", Vector2(1.05, 1.05), 0.12)
	heartbeat.tween_property(carnage_label, "scale", Vector2.ONE, 0.16)
	heartbeat.tween_property(carnage_label, "scale", Vector2(1.03, 1.03), 0.1)
	heartbeat.tween_property(carnage_label, "scale", Vector2.ONE, 0.2)
	heartbeat.tween_interval(1.0)


# --- How to play popup ------------------------------------------------------

func _create_tutorial_popup() -> void:
	tutorial_overlay = ColorRect.new()
	tutorial_overlay.color = Color(0.05, 0.02, 0.08, 0.85)
	tutorial_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tutorial_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(tutorial_overlay)

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tutorial_overlay.add_child(center)

	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.04, 0.14, 0.98)
	style.border_color = PINK
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(26)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)

	var title = Label.new()
	title.text = "HOW TO PLAY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", GOLD)
	box.add_child(title)

	_add_tutorial_section(box, "Goal",
		"Survive all waves. Enemies that reach your base will damage its HP.")

	_add_tutorial_section(box, "Build Towers",
		"Select an empty tower spot, then choose Laser Tower or Heavy Cannon.")

	_add_tutorial_section(box, "Collect Loot",
		"Defeated enemies drop bones, organs and eyeballs. Collect them to earn resources.")

	_add_tutorial_section(box, "Upgrade or Sell",
		"Select a tower to upgrade, repair or sell it.")

	_add_tutorial_section(box, "Special Character",
		"Wait for the ability to become available, then select a location to deploy your special character.")

	_add_tutorial_section(box, "Sucream & Upgrades",
		"Beat a level to earn Sucream. Spend it in Upgrades to make your special character stronger in every level.")

	var close_button = Button.new()
	close_button.text = "BACK TO MENU"
	close_button.custom_minimum_size = Vector2(0, 50)
	close_button.add_theme_font_size_override("font_size", 22)
	close_button.pressed.connect(func(): tutorial_overlay.hide())
	box.add_child(close_button)

	tutorial_overlay.hide()


func _add_tutorial_section(box: VBoxContainer, heading: String, description: String) -> void:
	var heading_label = Label.new()
	heading_label.text = heading
	heading_label.add_theme_color_override("font_color", PINK)
	heading_label.add_theme_font_size_override("font_size", 18)
	box.add_child(heading_label)

	var body_label = Label.new()
	body_label.text = description
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.custom_minimum_size = Vector2(500, 0)
	body_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.95))
	box.add_child(body_label)
