
extends Area2D

# A body part dropped by a dead enemy. Click it to collect it;
# it collects itself after AUTO_COLLECT_TIME so loot is never lost.

const AUTO_COLLECT_TIME: float = 5.0
# The first drops of a session say they can be clicked: players missed it.
static var click_hints_left: int = 3
const PICK_RADIUS: float = 18.0

var bones: int = 0
var organs: int = 0
var eyeballs: int = 0

var collected: bool = false


func _ready() -> void:
	add_to_group("body_parts")
	z_index = 5

	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = PICK_RADIUS
	shape.shape = circle
	add_child(shape)

	_create_visual()

	input_event.connect(_on_input_event)

	# false: the timer stops while the game is paused (game over).
	get_tree().create_timer(AUTO_COLLECT_TIME, false).timeout.connect(collect)

	# Small pop when it drops.
	scale = Vector2(0.2, 0.2)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	_start_pulse()

	if click_hints_left > 0:
		click_hints_left -= 1
		_show_click_hint()


# The sprite keeps pulsing so the loot catches the eye.
func _start_pulse() -> void:
	var sprite: Sprite2D = $Sprite
	var pulse = sprite.create_tween().set_loops()
	pulse.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.4).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(sprite, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_SINE)


func _show_click_hint() -> void:
	var label = Label.new()
	label.name = "ClickHint"
	label.text = "CLICK!"
	label.position = Vector2(-26, -44)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(1, 0.84, 0.25))
	label.add_theme_color_override("font_outline_color", Color(0.12, 0.04, 0.14))
	label.add_theme_constant_override("outline_size", 5)
	add_child(label)


func _create_visual() -> void:
	var sprite = Sprite2D.new()
	sprite.name = "Sprite"

	if eyeballs > 0:
		sprite.texture = preload("res://Assets/Sprites/tissue_resource.png")
	elif organs > 0:
		sprite.texture = preload("res://Assets/Sprites/muscle_resource.png")
	else:
		sprite.texture = preload("res://Assets/Sprites/bone_resource.png")

	add_child(sprite)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		collect()
		get_viewport().set_input_as_handled()


func collect() -> void:
	if collected:
		return

	collected = true
	input_pickable = false

	if has_node("ClickHint"):
		$ClickHint.queue_free()
	ResourceManager.add_resources(bones, organs, eyeballs)

	_show_gain_text()

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 40.0, 0.6)
	tween.tween_property(self, "modulate:a", 0.0, 0.6)
	tween.chain().tween_callback(queue_free)


func _show_gain_text() -> void:
	var parts = []

	if bones > 0:
		parts.append("+%d bones" % bones)
	if organs > 0:
		parts.append("+%d organs" % organs)
	if eyeballs > 0:
		parts.append("+%d eyeballs" % eyeballs)

	var label = Label.new()
	label.text = ", ".join(parts)
	label.position = Vector2(-40, -42)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	add_child(label)
