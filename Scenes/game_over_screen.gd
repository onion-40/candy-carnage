
extends PanelContainer

const BLOOD_RED: Color = Color(0.9, 0.08, 0.08)
const DARK_RED: Color = Color(0.45, 0.02, 0.02)
const BACKDROP_COLOR: Color = Color(0.12, 0.0, 0.0, 0.75)
const FADE_TIME: float = 0.4

@onready var title_label: Label = $VBoxContainer/Title
@onready var restart_button: Button = $VBoxContainer/RestartButton

var backdrop: ColorRect


func _ready() -> void:
	hide()

	# The tree is paused on game over; this panel must keep handling clicks.
	process_mode = Node.PROCESS_MODE_ALWAYS
	restart_button.pressed.connect(_on_restart_pressed)

	_apply_red_style()

	var map = owner.get_node_or_null("Map")

	if map:
		map.game_over.connect(_on_game_over)


func _on_game_over() -> void:
	get_tree().paused = true

	# Draw above every other UI element (health bar, HUD, wave info).
	backdrop.move_to_front()
	move_to_front()

	backdrop.show()
	show()

	backdrop.color.a = 0.0
	modulate.a = 0.0

	var tween = create_tween().set_parallel(true)
	tween.tween_property(backdrop, "color:a", BACKDROP_COLOR.a, FADE_TIME)
	tween.tween_property(self, "modulate:a", 1.0, FADE_TIME)


func _on_restart_pressed() -> void:
	get_tree().paused = false
	ResourceManager.reset()
	get_tree().reload_current_scene()


# =====================================
# RED "GAME OVER" LOOK (built in code, the scene keeps its layout)
# =====================================

func _apply_red_style() -> void:
	# Dark red full-screen backdrop behind the panel; it also blocks clicks on the map.
	backdrop = ColorRect.new()
	backdrop.color = BACKDROP_COLOR
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.hide()
	get_parent().add_child.call_deferred(backdrop)

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.01, 0.01, 0.95)
	panel_style.border_color = BLOOD_RED
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(12)
	panel_style.set_content_margin_all(32)
	add_theme_stylebox_override("panel", panel_style)

	title_label.add_theme_font_size_override("font_size", 64)
	title_label.add_theme_color_override("font_color", BLOOD_RED)
	title_label.add_theme_color_override("font_outline_color", Color.BLACK)
	title_label.add_theme_constant_override("outline_size", 10)

	var subtitle = Label.new()
	subtitle.text = "Your base has been destroyed"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(0.85, 0.75, 0.75))
	title_label.add_sibling(subtitle)

	restart_button.add_theme_stylebox_override("normal", _button_style(DARK_RED))
	restart_button.add_theme_stylebox_override("hover", _button_style(Color(0.65, 0.05, 0.05)))
	restart_button.add_theme_stylebox_override("pressed", _button_style(Color(0.3, 0.0, 0.0)))
	restart_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	restart_button.add_theme_color_override("font_color", Color.WHITE)
	restart_button.add_theme_color_override("font_hover_color", Color.WHITE)


func _button_style(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = BLOOD_RED
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	return style
