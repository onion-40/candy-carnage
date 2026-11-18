class_name MenuBackground
extends Control
## Animated menu backdrop: dark gradient, blood dripping from the top an
## candies (plus the odd eyeball) slowly raining down.

const GRADIENT_TOP: Color = Color(0.07, 0.02, 0.1)
const GRADIENT_MID: Color = Color(0.2, 0.03, 0.17)
const GRADIENT_BOTTOM: Color = Color(0.38, 0.03, 0.1)
const GRADIENT_MID_AT: float = 0.55
const BLOOD: Color = Color(0.55, 0.02, 0.08)
const CANDY_COLORS: Array[Color] = [
	Color(1.0, 0.45, 0.75),
	Color(0.45, 1.0, 0.8),
	Color(1.0, 0.88, 0.3),
	Color(0.65, 0.45, 1.0),
	Color(0.9, 0.12, 0.2),
]

enum CandyKind { WRAPPED, LOLLIPOP, EYEBALL, CANDY_CORN }

@export var candy_count: int = 26

var rng := RandomNumberGenerator.new()
var time: float = 0.0
var candies: Array[Dictionary] = []
var drips: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	rng.randomize()
	_spawn_candies()
	_spawn_drips()


func _process(delta: float) -> void:
	time += delta
	_update_candies(delta)
	_update_drips(delta)
	queue_redraw()


func _draw() -> void:
	_draw_gradient()

	for candy in candies:
		draw_set_transform(candy.pos, candy.rot, Vector2.ONE * candy.scale)
		match candy.kind:
			CandyKind.WRAPPED:
				_draw_wrapped_candy(candy.color, candy.alpha)
			CandyKind.LOLLIPOP:
				_draw_lollipop(candy.color, candy.alpha)
			CandyKind.EYEBALL:
				_draw_eyeball(candy.color, candy.alpha)
			CandyKind.CANDY_CORN:
				_draw_candy_corn(candy.alpha)
	draw_set_transform(Vector2.ZERO)

	_draw_blood_top()


func _screen_size() -> Vector2:
	return size if size != Vector2.ZERO else get_viewport_rect().size


# --- Candies ----------------------------------------------------------------

func _spawn_candies() -> void:
	var screen := _screen_size()
	for i in candy_count:
		var candy := _new_candy(screen)
		candy.pos = Vector2(candy.pos.x, rng.randf_range(-60.0, screen.y))
		candies.append(candy)


func _new_candy(screen: Vector2) -> Dictionary:
	# Depth drives size, speed and opacity so the rain has some parallax.
	var depth := rng.randf_range(0.35, 1.0)
	return {
		"pos": Vector2(rng.randf_range(0.0, screen.x), -60.0),
		"speed": lerpf(14.0, 46.0, depth),
		"sway_phase": rng.randf_range(0.0, TAU),
		"rot": rng.randf_range(0.0, TAU),
		"spin": rng.randf_range(-1.2, 1.2),
		"scale": lerpf(0.55, 1.35, depth),
		"alpha": lerpf(0.25, 0.75, depth),
		"kind": rng.randi_range(0, CandyKind.size() - 1),
		"color": CANDY_COLORS[rng.randi_range(0, CANDY_COLORS.size() - 1)],
	}


func _update_candies(delta: float) -> void:
	var screen := _screen_size()
	for i in candies.size():
		var candy: Dictionary = candies[i]
		var pos: Vector2 = candy.pos
		pos.y += candy.speed * delta
		pos.x += sin(time * 0.8 + candy.sway_phase) * 12.0 * delta
		candy.pos = pos
		candy.rot += candy.spin * delta
		if pos.y > screen.y + 60.0:
			candies[i] = _new_candy(screen)


# --- Blood drips ------------------------------------------------------------

func _spawn_drips() -> void:
	var screen := _screen_size()
	var x := rng.randf_range(10.0, 40.0)
	while x < screen.x:
		var drip_len := rng.randf_range(18.0, 95.0)
		drips.append({
			"x": x,
			"width": rng.randf_range(6.0, 14.0),
			"length": drip_len,
			"phase": rng.randf_range(0.0, TAU),
			"drop_y": drip_len,
			"drop_speed": 0.0,
			"drop_wait": rng.randf_range(0.5, 6.0),
		})
		x += rng.randf_range(38.0, 110.0)


func _drip_tip(drip: Dictionary) -> float:
	return drip.length + sin(time * 0.7 + drip.phase) * 8.0


func _update_drips(delta: float) -> void:
	var screen := _screen_size()
	for drip in drips:
		if drip.drop_wait > 0.0:
			drip.drop_wait -= delta
			drip.drop_y = _drip_tip(drip)
			continue
		drip.drop_speed += 600.0 * delta
		drip.drop_y += drip.drop_speed * delta
		if drip.drop_y > screen.y + 20.0:
			drip.drop_speed = 0.0
			drip.drop_wait = rng.randf_range(2.0, 7.0)


# --- Drawing ----------------------------------------------------------------

func _draw_gradient() -> void:
	var screen := _screen_size()
	var mid_y := screen.y * GRADIENT_MID_AT
	draw_polygon(
		PackedVector2Array([Vector2(0, 0), Vector2(screen.x, 0), Vector2(screen.x, mid_y), Vector2(0, mid_y)]),
		PackedColorArray([GRADIENT_TOP, GRADIENT_TOP, GRADIENT_MID, GRADIENT_MID]))
	draw_polygon(
		PackedVector2Array([Vector2(0, mid_y), Vector2(screen.x, mid_y), Vector2(screen.x, screen.y), Vector2(0, screen.y)]),
		PackedColorArray([GRADIENT_MID, GRADIENT_MID, GRADIENT_BOTTOM, GRADIENT_BOTTOM]))


func _draw_wrapped_candy(color: Color, alpha: float) -> void:
	var wrapper := Color(color.lightened(0.25), alpha)
	draw_colored_polygon(PackedVector2Array([Vector2(-12, 0), Vector2(-28, -12), Vector2(-24, 0), Vector2(-28, 12)]), wrapper)
	draw_colored_polygon(PackedVector2Array([Vector2(12, 0), Vector2(28, -12), Vector2(24, 0), Vector2(28, 12)]), wrapper)
	draw_circle(Vector2.ZERO, 14.0, Color(color, alpha))
	draw_arc(Vector2.ZERO, 9.0, -0.6, 1.4, 12, Color(1, 1, 1, alpha * 0.6), 3.0)
	draw_circle(Vector2(-5, -5), 3.5, Color(1, 1, 1, alpha * 0.7))


func _draw_lollipop(color: Color, alpha: float) -> void:
	draw_line(Vector2.ZERO, Vector2(0, 46), Color(0.96, 0.93, 0.86, alpha), 4.0)
	draw_circle(Vector2.ZERO, 19.0, Color(color, alpha))
	draw_arc(Vector2.ZERO, 13.0, 0.0, TAU * 0.8, 24, Color(1, 1, 1, alpha * 0.75), 3.5)
	draw_arc(Vector2.ZERO, 6.5, PI, PI + TAU * 0.7, 16, Color(1, 1, 1, alpha * 0.75), 3.0)


func _draw_eyeball(iris: Color, alpha: float) -> void:
	draw_circle(Vector2.ZERO, 15.0, Color(0.97, 0.94, 0.9, alpha))
	var vein := Color(0.8, 0.05, 0.1, alpha * 0.8)
	draw_polyline(PackedVector2Array([Vector2(-14, -3), Vector2(-9, -2), Vector2(-6, -6)]), vein, 1.5)
	draw_polyline(PackedVector2Array([Vector2(-13, 6), Vector2(-8, 4), Vector2(-5, 8)]), vein, 1.5)
	draw_polyline(PackedVector2Array([Vector2(2, 14), Vector2(4, 9), Vector2(9, 8)]), vein, 1.5)
	draw_circle(Vector2(4, 0), 7.5, Color(iris, alpha))
	draw_circle(Vector2(5, 0), 3.8, Color(0.05, 0.0, 0.05, alpha))
	draw_circle(Vector2(2, -3), 2.0, Color(1, 1, 1, alpha))


func _draw_candy_corn(alpha: float) -> void:
	var apex := Vector2(0, -20)
	var left := Vector2(-14, 16)
	var right := Vector2(14, 16)
	var bands: Array[Color] = [Color(1.0, 0.85, 0.2), Color(1.0, 0.5, 0.1), Color(0.98, 0.96, 0.9)]
	var cuts: Array[float] = [1.0, 0.66, 0.33, 0.0]
	for i in bands.size():
		var a := cuts[i]
		var b := cuts[i + 1]
		draw_colored_polygon(PackedVector2Array([
			apex.lerp(left, a), apex.lerp(right, a), apex.lerp(right, b), apex.lerp(left, b),
		]), Color(bands[i], alpha))


func _draw_blood_top() -> void:
	var screen := _screen_size()
	var dark := BLOOD.darkened(0.25)

	draw_rect(Rect2(0, 0, screen.x, 12), dark)
	var x := 0.0
	var bump := 0
	while x < screen.x + 16.0:
		draw_circle(Vector2(x, 12), 7.0 + float(bump % 3) * 2.0, dark)
		x += 15.0
		bump += 1

	for drip in drips:
		var tip := _drip_tip(drip)
		var half: float = drip.width / 2.0
		draw_rect(Rect2(drip.x - half, 0, drip.width, tip), BLOOD)
		draw_circle(Vector2(drip.x, tip), half + 1.5, BLOOD)
		draw_circle(Vector2(drip.x - half * 0.35, tip - 2.0), half * 0.35, Color(1, 0.5, 0.55, 0.35))
		if drip.drop_wait <= 0.0:
			draw_circle(Vector2(drip.x, drip.drop_y), half * 0.7, BLOOD)
