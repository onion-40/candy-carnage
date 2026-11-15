extends Control

# How to Play popup. It opens once when the game first launches (not after a
# restart) and can be reopened with the "?" button in the top-right corner.
# The game is paused while it is open.

const CANDY_PINK: Color = Color(1.0, 0.45, 0.75)
const GOLD: Color = Color(1.0, 0.84, 0.25)
const BACKDROP_COLOR: Color = Color(0.05, 0.02, 0.08, 0.7)
const TEXT_WIDTH: float = 620.0

# Static vars survive reload_current_scene(), so Restart skips the popup.
static var shown_on_launch: bool = false

var map: Node
var help_button: Button
var overlay: Control
var close_button: Button


func _ready() -> void:
	# Keeps working while the tree is paused (by this popup or by game over).
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	map = owner.get_node_or_null("Map")

	_build_help_button()
	_build_popup()
	overlay.hide()

	if map:
		map.game_over.connect(_on_game_ended)
		map.victory.connect(_on_game_ended)

	if not shown_on_launch:
		shown_on_launch = true
		open_popup()


func _unhandled_input(event: InputEvent) -> void:
	if overlay.visible and event.is_action_pressed("ui_cancel"):
		close_popup()
		get_viewport().set_input_as_handled()


func open_popup() -> void:
	if _game_has_ended():
		return

	get_tree().paused = true
	overlay.show()
	help_button.hide()
	close_button.grab_focus.call_deferred()


func close_popup() -> void:
	overlay.hide()

	if _game_has_ended():
		return

	help_button.show()
	get_tree().paused = false


func _on_game_ended() -> void:
	# The end screens own the pause from here on.
	overlay.hide()
	help_button.hide()


func _game_has_ended() -> bool:
	return map != null and (map.is_game_over or map.is_victory)


# =====================================
# UI (built in code)
# =====================================

func _build_help_button() -> void:
	help_button = Button.new()
	help_button.text = "?"
	help_button.tooltip_text = "How to Play"
	help_button.custom_minimum_size = Vector2(44, 44)
	# Top-right corner, 16 px from the edges.
	help_button.anchor_left = 1.0
	help_button.anchor_right = 1.0
	help_button.offset_left = -60.0
	help_button.offset_right = -16.0
	help_button.offset_top = 16.0
	help_button.offset_bottom = 60.0
	help_button.add_theme_font_size_override("font_size", 22)
	help_button.add_theme_stylebox_override("normal", _round_style(Color(0.6, 0.48, 0.75)))
	help_button.add_theme_stylebox_override("hover", _round_style(Color(0.72, 0.6, 0.88)))
	help_button.add_theme_stylebox_override("pressed", _round_style(Color(0.45, 0.35, 0.6)))
	help_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	help_button.add_theme_color_override("font_color", Color.WHITE)
	help_button.add_theme_color_override("font_hover_color", Color.WHITE)
	help_button.pressed.connect(open_popup)
	add_child(help_button)


func _build_popup() -> void:
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	# Full-screen backdrop; it also blocks clicks on the map.
	var backdrop = ColorRect.new()
	backdrop.color = BACKDROP_COLOR
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(backdrop)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)

	var panel = PanelContainer.new()
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.04, 0.14, 0.96)
	panel_style.border_color = CANDY_PINK
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(12)
	panel_style.set_content_margin_all(26)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	var title = Label.new()
	title.text = "HOW TO PLAY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", GOLD)
	title.add_theme_color_override("font_outline_color", Color(0.45, 0.05, 0.3))
	title.add_theme_constant_override("outline_size", 8)
	box.add_child(title)

	var waves = map.total_waves if map else 6

	_add_section(box, "Goal",
		"Survive all %d waves. Every enemy that reaches the end of the path damages your base. At 0 HP, it's game over." % waves)
	_add_section(box, "Build towers",
		"Click an empty build spot, then press Laser Tower or Heavy Cannon in the bottom bar. Costs are shown on the buttons. The Laser hits fast from far away; the Heavy Cannon is slower but hits much harder.")
	_add_section(box, "Collect loot",
		"Defeated enemies drop body parts. Click them to collect bones, organs and eyeballs (they collect themselves after a few seconds).")
	_add_section(box, "Upgrade or sell",
		"Click a tower to open its panel. Upgrade it up to level 3, or sell it to get back half of its build cost.")
	_add_section(box, "Special character",
		"When it is ready, press Special Character and left-click on the map to deploy it (right-click cancels). It attacks nearby enemies for a while, then needs time to recharge.")

	close_button = Button.new()
	close_button.text = "LET'S GO!"
	close_button.custom_minimum_size = Vector2(0, 46)
	close_button.add_theme_font_size_override("font_size", 20)
	close_button.add_theme_stylebox_override("normal", _button_style(Color(0.6, 0.15, 0.45)))
	close_button.add_theme_stylebox_override("hover", _button_style(Color(0.8, 0.25, 0.6)))
	close_button.add_theme_stylebox_override("pressed", _button_style(Color(0.4, 0.08, 0.3)))
	close_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	close_button.add_theme_color_override("font_color", Color.WHITE)
	close_button.add_theme_color_override("font_hover_color", Color.WHITE)
	close_button.pressed.connect(close_popup)
	box.add_child(close_button)


func _add_section(box: VBoxContainer, heading: String, body: String) -> void:
	var heading_label = Label.new()
	heading_label.text = heading
	heading_label.add_theme_font_size_override("font_size", 18)
	heading_label.add_theme_color_override("font_color", CANDY_PINK)
	box.add_child(heading_label)

	var body_label = Label.new()
	body_label.text = body
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.custom_minimum_size = Vector2(TEXT_WIDTH, 0)
	body_label.add_theme_font_size_override("font_size", 15)
	body_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.95))
	box.add_child(body_label)


func _button_style(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = GOLD
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	return style


func _round_style(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color.WHITE
	style.set_border_width_all(2)
	style.set_corner_radius_all(22)
	return style
