extends Control

const LOCK_COLOR: Color = Color(0.55, 0.45, 0.58)
const KEYHOLE_COLOR: Color = Color(0.1, 0.05, 0.12)

@onready var menu_box: VBoxContainer = $CenterContainer/VBoxContainer
@onready var level_1_button: Button = $CenterContainer/VBoxContainer/LevelButtons/Level1Button
@onready var level_2_button: Button = $CenterContainer/VBoxContainer/LevelButtons/Level2Button
@onready var back_button: Button = $CenterContainer/VBoxContainer/BackButton


func _ready() -> void:
	level_1_button.pressed.connect(_on_level_1_pressed)
	level_2_button.pressed.connect(_on_level_2_pressed)
	back_button.pressed.connect(_on_back_pressed)

	for button in [level_1_button, level_2_button]:
		MenuFx.setup_hover(button, 1.06)
	MenuFx.setup_hover(back_button)

	# Level 1 completion status.
	_setup_card(level_1_button, true,
		"Cleared!" if GameProgress.level_1_cleared else "Ready to fight")

	# Level 2 unlock and completion status.
	level_2_button.disabled = not GameProgress.level_2_unlocked
	_setup_card(level_2_button, GameProgress.level_2_unlocked,
		"Cleared!" if GameProgress.level_2_cleared else
		"Ready to fight" if GameProgress.level_2_unlocked else
		"Beat Level 1 to unlock")
	_play_intro()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back_pressed()


func _on_level_1_pressed() -> void:
	MusicManager.play_music(MusicManager.GAME_MUSIC)
	get_tree().change_scene_to_file("res://Scenes/main.tscn")


func _on_level_2_pressed() -> void:
	MusicManager.play_music(MusicManager.GAME_MUSIC)
	get_tree().change_scene_to_file("res://Scenes/Level2.tscn")


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")


func _setup_card(card: Button, unlocked: bool, status: String) -> void:
	var content: Control = card.get_node("Content")
	var lock_icon: Control = content.get_node("LockIcon")

	content.get_node("NumberLabel").visible = unlocked
	content.get_node("StatusLabel").text = status
	lock_icon.visible = not unlocked
	if not unlocked:
		content.modulate = Color(1, 1, 1, 0.65)
		lock_icon.draw.connect(_draw_lock.bind(lock_icon))


func _draw_lock(icon: Control) -> void:
	var center := Vector2(icon.size.x / 2.0, icon.size.y / 2.0 + 14.0)
	var body := Rect2(center - Vector2(36, 26), Vector2(72, 56))

	icon.draw_arc(center - Vector2(0, 26), 24.0, PI, TAU, 24, LOCK_COLOR, 10.0)
	icon.draw_line(center + Vector2(-24, -26), center + Vector2(-24, -18), LOCK_COLOR, 10.0)
	icon.draw_line(center + Vector2(24, -26), center + Vector2(24, -18), LOCK_COLOR, 10.0)
	icon.draw_rect(body, LOCK_COLOR)
	icon.draw_circle(center - Vector2(0, 6), 8.0, KEYHOLE_COLOR)
	icon.draw_rect(Rect2(center + Vector2(-3.5, -6), Vector2(7, 20)), KEYHOLE_COLOR)


func _play_intro() -> void:
	menu_box.modulate.a = 0.0
	create_tween().tween_property(menu_box, "modulate:a", 1.0, 0.4)

	var delay := 0.1
	for card in [level_1_button, level_2_button]:
		card.scale = Vector2(0.7, 0.7)
		create_tween().tween_property(card, "scale", Vector2.ONE, 0.5) \
			.set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		delay += 0.12
