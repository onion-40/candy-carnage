extends PathFollow2D

const BODY_PART_SCRIPT = preload("res://Scripts/Scenes/BodyPart.gd")

signal defeated(reward: int)
signal reached_base(damage: int)

@export var max_health: int = 50
@export var move_speed: float = 100.0
@export var reward: int = 5
@export var base_damage: int = 1

var health: int

func _ready() -> void:
	health = max_health
	add_to_group("enemies")

	loop = false
	rotates = false

func _process(delta: float) -> void:
	progress += move_speed * delta

	if progress_ratio >= 1.0:
		reached_base.emit(base_damage)
		queue_free()


func take_damage(amount: int) -> void:
	if health <= 0:
		return

	health -= amount

	if health <= 0:
		drop_random_resource()
		_spawn_death_burst()
		defeated.emit(reward)
		queue_free()
	else:
		_flash_hit()
		queue_redraw()


# =====================================
# VISUAL FEEDBACK
# =====================================

const HEALTH_BAR_SIZE: Vector2 = Vector2(28, 4)
const HEALTH_BAR_OFFSET: float = -18.0
const DEATH_BURST_COLOR: Color = Color(0.85, 0.05, 0.1)


# Small health bar above the enemy, only once it has been hit.
func _draw() -> void:
	if health >= max_health:
		return

	var top_left = Vector2(-HEALTH_BAR_SIZE.x / 2.0, HEALTH_BAR_OFFSET)
	var ratio = clampf(float(health) / float(max_health), 0.0, 1.0)

	draw_rect(Rect2(top_left, HEALTH_BAR_SIZE), Color(0.1, 0.1, 0.1, 0.8))
	draw_rect(
		Rect2(top_left, Vector2(HEALTH_BAR_SIZE.x * ratio, HEALTH_BAR_SIZE.y)),
		Color(0.2, 0.9, 0.3).lerp(Color(0.95, 0.2, 0.1), 1.0 - ratio)
	)


# Briefly turns the body white when it takes a hit.
func _flash_hit() -> void:
	var body: Polygon2D = $Body
	var base_color = body.get_meta("base_color", body.color)
	body.set_meta("base_color", base_color)

	body.color = Color.WHITE
	var tween = body.create_tween()
	tween.tween_property(body, "color", base_color, 0.12)


# A few shards fly out and fade where the enemy died.
func _spawn_death_burst() -> void:
	var scene = get_tree().current_scene
	var origin = scene.to_local(global_position)

	for i in range(6):
		var shard = Polygon2D.new()
		shard.polygon = PackedVector2Array([
			Vector2(-3, -3), Vector2(3, -3), Vector2(3, 3), Vector2(-3, 3)
		])
		shard.color = DEATH_BURST_COLOR
		shard.position = origin
		shard.rotation = randf() * TAU
		shard.z_index = 4
		scene.add_child.call_deferred(shard)

		var direction = Vector2.RIGHT.rotated(TAU * i / 6.0 + randf_range(-0.3, 0.3))
		var distance = randf_range(18.0, 34.0)

		# The tween must start once the shard is in the tree.
		shard.ready.connect(func() -> void:
			var tween = shard.create_tween()
			tween.set_parallel(true)
			tween.tween_property(shard, "position", origin + direction * distance, 0.35) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(shard, "scale", Vector2(0.3, 0.3), 0.35)
			tween.tween_property(shard, "modulate:a", 0.0, 0.35)
			tween.chain().tween_callback(shard.queue_free)
		, CONNECT_ONE_SHOT)


func drop_random_resource() -> void:
	var roll = randi_range(1, 100)

	if roll <= 60:
		var bone_amount = randi_range(3, 8)
		_spawn_body_part(bone_amount, 0, 0)

	elif roll <= 95:
		var organ_amount = randi_range(1, 4)
		_spawn_body_part(0, organ_amount, 0)

	else:
		var eyeball_amount = randi_range(1, 2)
		_spawn_body_part(0, 0, eyeball_amount)


# The loot drops on the ground; the player clicks it to collect (BodyPart.gd).
func _spawn_body_part(
	bone_amount: int,
	organ_amount: int,
	eyeball_amount: int
) -> void:
	var part = BODY_PART_SCRIPT.new()
	part.bones = bone_amount
	part.organs = organ_amount
	part.eyeballs = eyeball_amount

	# The Body polygon is drawn offset from the node origin, so drop the
	# part where the enemy is actually visible.
	var body: Polygon2D = $Body
	var center = Vector2.ZERO

	for point in body.polygon:
		center += point

	center /= body.polygon.size()

	var scene = get_tree().current_scene
	part.position = scene.to_local(body.to_global(center))
	scene.add_child.call_deferred(part)
