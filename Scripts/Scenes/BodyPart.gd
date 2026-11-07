
extends Area2D

# A body part dropped by a dead enemy. Click it to collect it;
# it collects itself after AUTO_COLLECT_TIME so loot is never lost.

const AUTO_COLLECT_TIME: float = 8.0
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


func _create_visual() -> void:
	if eyeballs > 0:
		add_child(_circle_polygon(11.0, Color(0.97, 0.97, 0.95)))
		add_child(_circle_polygon(5.0, Color(0.15, 0.45, 0.9)))
		add_child(_circle_polygon(2.5, Color.BLACK))

	elif organs > 0:
		var organ = _circle_polygon(12.0, Color(0.85, 0.2, 0.35))
		organ.scale = Vector2(1.0, 0.8)
		add_child(organ)

	else:
		var bone = Polygon2D.new()
		bone.polygon = PackedVector2Array([
			Vector2(-14, -3), Vector2(14, -3), Vector2(14, 3), Vector2(-14, 3)
		])
		bone.color = Color(0.95, 0.93, 0.85)
		add_child(bone)

		for x in [-14.0, 14.0]:
			for y in [-4.0, 4.0]:
				var knob = _circle_polygon(4.5, bone.color)
				knob.position = Vector2(x, y)
				add_child(knob)


func _circle_polygon(radius: float, color: Color) -> Polygon2D:
	var points = PackedVector2Array()
	var segments = 20

	for i in range(segments):
		var angle = TAU * float(i) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)

	var polygon = Polygon2D.new()
	polygon.polygon = points
	polygon.color = color

	return polygon


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		collect()
		get_viewport().set_input_as_handled()


func collect() -> void:
	if collected:
		return

	collected = true
	input_pickable = false
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
