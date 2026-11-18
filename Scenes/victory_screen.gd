extends Control

# Victory screen: shown when Map emits `victory` after the last wave is cleared.
# Like the game over screen it pauses the tree; Play Again resets and reloads.

const CANDY_PINK: Color = Color(1.0, 0.45, 0.75)
const GOLD: Color = Color(1.0, 0.84, 0.25)
const BACKDROP_COLOR: Color = Color(0.1, 0.02, 0.12, 0.75)
const FADE_TIME: float = 0.4

var map: Node
var backdrop: ColorRect
var panel: PanelContainer
var stats_label: Label
var reward_label: Label
var play_again_button: Button
var main_menu_button: Button


func _ready() -> void:
	hide()

	# The tree is paused on victory; this screen must keep handling clicks.
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_build_ui()

	map = owner.get_node_or_null("Map")

	if map:
		map.victory.connect(_on_victory)


func _on_victory() -> void:
	get_tree().paused = true
	
	#Once player won level 1, level 2 will be unlocked.
	GameProgress.unlock_level_2()

	# Sucream is spent on special character upgrades in the main menu.
	var reward = GameProgress.award_level_reward(get_tree().current_scene.scene_file_path)
	reward_label.text = "+%d Sucream   (total: %d)" % [reward, GameProgress.sucream]

	stats_label.text = "Waves cleared: %d / %d\nBase HP left: %d / %d" % [
		map.current_wave,
		map.total_waves,
		map.player_hp,
		map.max_player_hp
	]

	# Draw above every other UI element (health bar, HUD, wave info).
	move_to_front()
	show()
	play_again_button.grab_focus.call_deferred()

	backdrop.color.a = 0.0
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.8, 0.8)

	var tween = create_tween().set_parallel(true)
	tween.tween_property(backdrop, "color:a", BACKDROP_COLOR.a, FADE_TIME)
	tween.tween_property(panel, "modulate:a", 1.0, FADE_TIME)
	tween.tween_property(panel, "scale", Vector2.ONE, FADE_TIME) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_play_again_pressed() -> void:
	get_tree().paused = false
	ResourceManager.reset()
	get_tree().reload_current_scene()
	
func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	ResourceManager.reset()
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")


# =====================================
# UI (built in code)
# =====================================

func _build_ui() -> void:
	# Full-screen backdrop; it also blocks clicks on the map.
	backdrop = ColorRect.new()
	backdrop.color = BACKDROP_COLOR
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	panel = PanelContainer.new()
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.04, 0.14, 0.95)
	panel_style.border_color = CANDY_PINK
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(12)
	panel_style.set_content_margin_all(32)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)
	# Scale from the middle for the pop-in animation.
	panel.resized.connect(func(): panel.pivot_offset = panel.size / 2.0)

	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)

	var title = Label.new()
	title.text = "VICTORY!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", GOLD)
	title.add_theme_color_override("font_outline_color", Color(0.45, 0.05, 0.3))
	title.add_theme_constant_override("outline_size", 10)
	box.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "Your base survived the carnage"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(0.95, 0.85, 0.92))
	box.add_child(subtitle)

	stats_label = Label.new()
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.add_theme_font_size_override("font_size", 20)
	stats_label.add_theme_color_override("font_color", Color.WHITE)
	box.add_child(stats_label)

	reward_label = Label.new()
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_label.add_theme_font_size_override("font_size", 26)
	reward_label.add_theme_color_override("font_color", CANDY_PINK)
	reward_label.add_theme_color_override("font_outline_color", Color(0.25, 0.02, 0.15))
	reward_label.add_theme_constant_override("outline_size", 6)
	box.add_child(reward_label)

	var reward_hint = Label.new()
	reward_hint.text = "Spend it in Upgrades on the main menu"
	reward_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_hint.add_theme_font_size_override("font_size", 14)
	reward_hint.add_theme_color_override("font_color", Color(0.95, 0.85, 0.92, 0.8))
	box.add_child(reward_hint)

	
	# Button container
	var button_container = HBoxContainer.new()
	button_container.add_theme_constant_override("separation", 12)
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(button_container)

	# Play Again button
	play_again_button = Button.new()
	play_again_button.text = "PLAY AGAIN"
	play_again_button.custom_minimum_size = Vector2(180, 50)
	play_again_button.add_theme_font_size_override("font_size", 18)
	play_again_button.add_theme_stylebox_override("normal", _button_style(Color(0.6, 0.15, 0.45)))
	play_again_button.add_theme_stylebox_override("hover", _button_style(Color(0.8, 0.25, 0.6)))
	play_again_button.add_theme_stylebox_override("pressed", _button_style(Color(0.4, 0.08, 0.3)))
	play_again_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	play_again_button.add_theme_color_override("font_color", Color.WHITE)
	play_again_button.add_theme_color_override("font_hover_color", Color.WHITE)
	play_again_button.pressed.connect(_on_play_again_pressed)
	button_container.add_child(play_again_button)

	# Main Menu button
	main_menu_button = Button.new()
	main_menu_button.text = "MAIN MENU"
	main_menu_button.custom_minimum_size = Vector2(180, 50)
	main_menu_button.add_theme_font_size_override("font_size", 18)
	main_menu_button.add_theme_stylebox_override("normal", _button_style(Color(0.25, 0.12, 0.35)))
	main_menu_button.add_theme_stylebox_override("hover", _button_style(Color(0.4, 0.2, 0.5)))
	main_menu_button.add_theme_stylebox_override("pressed", _button_style(Color(0.15, 0.06, 0.25)))
	main_menu_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	main_menu_button.add_theme_color_override("font_color", Color.WHITE)
	main_menu_button.add_theme_color_override("font_hover_color", Color.WHITE)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	button_container.add_child(main_menu_button)



func _button_style(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = GOLD
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	return style
