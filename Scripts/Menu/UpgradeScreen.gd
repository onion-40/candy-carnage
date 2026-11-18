extends ColorRect
## Main menu overlay where Sucream (earned by beating levels) buys permanent
## special character upgrades. State lives in the GameProgress autoload.

const SPECIAL_CHARACTER_SCRIPT = preload("res://Scenes/special_characters.gd")
const PINK: Color = Color(1.0, 0.45, 0.75)
const GOLD: Color = Color(1.0, 0.84, 0.25)
const MUTED: Color = Color(0.6, 0.5, 0.62)
const TEXT: Color = Color(0.95, 0.9, 0.95)

var panel: PanelContainer
var sucream_label: Label
var level_label: Label
var row_styles: Array[StyleBoxFlat] = []
var row_status_labels: Array[Label] = []
var upgrade_button: Button
var hint_label: Label


func _ready() -> void:
	color = Color(0.05, 0.02, 0.08, 0.85)
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_build_ui()
	GameProgress.sucream_changed.connect(func(_amount): refresh())
	refresh()
	hide()


func open() -> void:
	refresh()
	show()
	panel.scale = Vector2(0.85, 0.85)
	panel.modulate.a = 0.0
	var tween := create_tween().set_parallel()
	tween.tween_property(panel, "scale", Vector2.ONE, 0.3) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)


func refresh() -> void:
	var level := GameProgress.special_level
	sucream_label.text = "Sucream: %d" % GameProgress.sucream
	level_label.text = "Special character - Level %d / %d" % [level, SPECIAL_CHARACTER_SCRIPT.MAX_LEVEL]

	for i in row_styles.size():
		var row_level := i + 1
		var status := row_status_labels[i]
		if row_level <= level:
			row_styles[i].border_color = PINK
			row_styles[i].bg_color = Color(0.3, 0.06, 0.24, 0.9)
			status.text = "OWNED"
			status.add_theme_color_override("font_color", PINK)
		elif row_level == level + 1:
			row_styles[i].border_color = GOLD
			row_styles[i].bg_color = Color(0.2, 0.08, 0.16, 0.9)
			status.text = "%d Sucream" % SPECIAL_CHARACTER_SCRIPT.upgrade_cost_for(row_level)
			status.add_theme_color_override("font_color", GOLD)
		else:
			row_styles[i].border_color = MUTED.darkened(0.3)
			row_styles[i].bg_color = Color(0.1, 0.05, 0.12, 0.9)
			status.text = "%d Sucream" % SPECIAL_CHARACTER_SCRIPT.upgrade_cost_for(row_level)
			status.add_theme_color_override("font_color", MUTED)

	if GameProgress.is_special_max_level():
		upgrade_button.text = "MAX LEVEL"
		upgrade_button.disabled = true
		hint_label.text = "Your special character is fully upgraded!"
	else:
		var cost := GameProgress.special_upgrade_cost()
		upgrade_button.text = "UPGRADE  -  %d SUCREAM" % cost
		upgrade_button.disabled = not GameProgress.can_upgrade_special()
		if upgrade_button.disabled:
			hint_label.text = "Beat levels to earn Sucream (Level 1: +%d, Level 2: +%d)." % [
				GameProgress.reward_for_level("res://Scenes/main.tscn"),
				GameProgress.reward_for_level("res://Scenes/Level2.tscn"),
			]
		else:
			hint_label.text = "Upgrades are permanent and apply in every level."


func _on_upgrade_pressed() -> void:
	if GameProgress.upgrade_special():
		refresh()
		var bought: Control = row_status_labels[GameProgress.special_level - 1].get_parent().get_parent()
		MenuFx.keep_pivot_centered(bought)
		bought.scale = Vector2(1.06, 1.06)
		create_tween().tween_property(bought, "scale", Vector2.ONE, 0.25) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _build_ui() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.04, 0.14, 0.98)
	style.border_color = PINK
	style.set_border_width_all(3)
	style.set_corner_radius_all(18)
	style.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	MenuFx.keep_pivot_centered(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)

	var title := _label("UPGRADES", 40, GOLD)
	title.add_theme_color_override("font_outline_color", Color(0.45, 0.05, 0.3))
	title.add_theme_constant_override("outline_size", 10)
	box.add_child(title)

	sucream_label = _label("", 26, PINK)
	sucream_label.add_theme_color_override("font_outline_color", Color(0.25, 0.02, 0.15))
	sucream_label.add_theme_constant_override("outline_size", 6)
	box.add_child(sucream_label)

	level_label = _label("", 18, TEXT)
	box.add_child(level_label)

	for row_level in range(1, SPECIAL_CHARACTER_SCRIPT.MAX_LEVEL + 1):
		box.add_child(_build_row(row_level))

	hint_label = _label("", 15, Color(TEXT, 0.8))
	box.add_child(hint_label)

	upgrade_button = Button.new()
	upgrade_button.custom_minimum_size = Vector2(0, 56)
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	box.add_child(upgrade_button)

	var back_button := Button.new()
	back_button.text = "BACK"
	back_button.custom_minimum_size = Vector2(220, 48)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_button.add_theme_font_size_override("font_size", 22)
	back_button.pressed.connect(hide)
	box.add_child(back_button)

	MenuFx.setup_hover(upgrade_button, 1.04)
	MenuFx.setup_hover(back_button)


func _build_row(row_level: int) -> PanelContainer:
	var row := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	row.add_theme_stylebox_override("panel", style)
	row_styles.append(style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	row.add_child(hbox)

	var level_tag := _label("LV %d" % row_level, 22, GOLD)
	level_tag.custom_minimum_size = Vector2(60, 0)
	hbox.add_child(level_tag)

	var description := "Base special character"
	if SPECIAL_CHARACTER_SCRIPT.UPGRADE_SUMMARIES.has(row_level):
		description = SPECIAL_CHARACTER_SCRIPT.UPGRADE_SUMMARIES[row_level]
	var summary := _label(description, 17, TEXT)
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	summary.custom_minimum_size = Vector2(340, 0)
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(summary)

	var status := _label("", 18, GOLD)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status.custom_minimum_size = Vector2(130, 0)
	hbox.add_child(status)
	row_status_labels.append(status)

	return row


func _label(text: String, font_size: int, font_color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	return label
