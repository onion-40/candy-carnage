extends PathFollow2D

const BODY_PART_SCRIPT = preload("res://Scripts/Scenes/BodyPart.gd")
const BLOOD_SPLATTERS = [
	preload("res://Assets/Sprites/blood_splatter_1.png"),
	preload("res://Assets/Sprites/blood_splatter_2.png"),
	preload("res://Assets/Sprites/blood_splatter_3.png"),
]

enum EnemyType {
	REGULAR,
	MAGE,
	TANK,
	HEALER
}

signal defeated(reward: int)
signal reached_base(damage: int)

@export var enemy_type: EnemyType = EnemyType.REGULAR

@export var max_health: int = 35
@export var move_speed: float = 100.0
@export var reward: int = 5
@export var base_damage: int = 2

@export var mage_attack_range: float = 180.0
@export var mage_attack_interval: float = 4.0
@export var mage_lifetime_reduction: float = 3.5

@export var healer_range: float = 160.0
@export var healer_interval: float = 3.0
@export var healer_amount: float = 0.05

var health: int
var mage_attack_timer: Timer
var mage_cooldown_left: float = 0.0
var healer_timer: Timer


func _ready() -> void:
	add_to_group("enemies")

	loop = false
	rotates = false
	rotation = 0.0 # undo the tilt the path gave before rotates was turned off
	$Body.texture = preload("res://Assets/Sprites/enemy_bunny.png")

	match enemy_type:
		EnemyType.MAGE:
			max_health = maxi(1, roundi(max_health * 0.6))
			$Body.texture = preload("res://Assets/Sprites/enemy_skunk.png")
			_create_mage_timer()

		EnemyType.TANK:
			max_health = maxi(1, roundi(max_health * 2.5))
			move_speed *= 0.5
			$Body.texture = preload("res://Assets/Sprites/enemy_bear.png")

		EnemyType.HEALER:
			$Body.texture = preload("res://Assets/Sprites/enemy_dog.png")
			_create_healer_timer()

	health = max_health

func _process(delta: float) -> void:
	progress += move_speed * delta
	$Body.rotation = sin(progress * 0.08) * 0.12 # waddle while walking

	if progress_ratio >= 1.0:
		reached_base.emit(base_damage)
		queue_free()


func take_damage(
	amount: int,
	source_tower_type: int = -1
) -> void:
	if health <= 0:
		return

	var final_damage = amount

	# Tank receives 5% less damage from Heavy Cannon towers.
	if enemy_type == EnemyType.TANK and source_tower_type == 1:
		final_damage = maxi(1, roundi(amount * 0.95))

	health -= final_damage

	if health <= 0:
		health = 0

		if mage_attack_timer:
			mage_attack_timer.stop()

		if healer_timer:
			healer_timer.stop()

		drop_random_resource()
		_spawn_death_burst()
		defeated.emit(reward)
		queue_free()
	else:
		_flash_hit()
		queue_redraw()

# =====================================
# MAGE ABILITY
# =====================================

# The timer only polls: a mage attacks as soon as a tower is in range, then
# waits mage_attack_interval. A plain 4 s timer fired too late, since mages
# usually die within 3-5 s, so they almost never attacked.
const MAGE_POLL_INTERVAL: float = 0.25


func _create_mage_timer() -> void:
	mage_attack_timer = Timer.new()
	mage_attack_timer.wait_time = MAGE_POLL_INTERVAL
	mage_attack_timer.one_shot = false
	add_child(mage_attack_timer)
	mage_attack_timer.timeout.connect(_on_mage_attack_timeout)
	mage_attack_timer.start()


func _on_mage_attack_timeout() -> void:
	if health <= 0:
		return

	mage_cooldown_left -= MAGE_POLL_INTERVAL

	if mage_cooldown_left > 0.0:
		return

	var target = find_nearest_tower()

	if target != null:
		mage_cooldown_left = mage_attack_interval
		target.reduce_lifetime(mage_lifetime_reduction)
		_show_drain_beam(target.global_position)
		_show_cast_pop()


# The mage swells and glows purple as it casts, so players see who attacks.
func _show_cast_pop() -> void:
	var body: Sprite2D = $Body
	body.modulate = Color(1.3, 0.7, 1.6)
	body.scale = Vector2(1.35, 1.35)
	var tween = body.create_tween().set_parallel(true)
	tween.tween_property(body, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(body, "modulate", Color.WHITE, 0.35)


# A purple beam from the mage to the tower it drains, so players see why
# their tower is losing lifetime.
func _show_drain_beam(tower_position: Vector2) -> void:
	var beam = Line2D.new()
	beam.top_level = true # points are in world coordinates
	beam.z_index = 10
	beam.width = 5.0
	beam.default_color = Color(0.75, 0.35, 1.0, 0.9)
	beam.begin_cap_mode = Line2D.LINE_CAP_ROUND
	beam.end_cap_mode = Line2D.LINE_CAP_ROUND
	beam.points = PackedVector2Array([global_position, tower_position])
	add_child(beam)

	var tween = beam.create_tween()
	tween.tween_property(beam, "modulate:a", 0.0, 0.5)
	tween.tween_callback(beam.queue_free)


func find_nearest_tower() -> Node2D:
	var nearest_tower: Node2D = null
	var nearest_distance = mage_attack_range

	for tower in get_tree().get_nodes_in_group("towers"):
		if not is_instance_valid(tower):
			continue

		if tower.is_sold:
			continue

		var distance = global_position.distance_to(
			tower.global_position
		)

		if distance <= nearest_distance:
			nearest_distance = distance
			nearest_tower = tower

	return nearest_tower


# =====================================
# HEALER ABILITY
# =====================================

func _create_healer_timer() -> void:
	healer_timer = Timer.new()
	healer_timer.wait_time = healer_interval
	healer_timer.one_shot = false
	add_child(healer_timer)
	healer_timer.timeout.connect(_on_healer_timer_timeout)
	healer_timer.start()


func _on_healer_timer_timeout() -> void:
	if health <= 0:
		return

	# Heal the Healer itself.
	_heal_enemy(self)

	# Heal nearby living allied enemies.
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue

		if enemy == self:
			continue

		if enemy.health <= 0 or enemy.is_queued_for_deletion():
			continue

		var distance = global_position.distance_to(
			enemy.global_position
		)

		if distance <= healer_range:
			_heal_enemy(enemy)


func _heal_enemy(target: Node) -> void:
	if not is_instance_valid(target):
		return

	if target.health <= 0 or target.is_queued_for_deletion():
		return

	var healing = maxi(
		1,
		roundi(target.max_health * healer_amount)
	)

	target.health = mini(
		target.max_health,
		target.health + healing
	)

	target.queue_redraw()
	
# =====================================
# VISUAL FEEDBACK
# =====================================

const HEALTH_BAR_SIZE: Vector2 = Vector2(40, 6)
const HEALTH_BAR_OFFSET: float = -40.0
const DEATH_BURST_COLOR: Color = Color(0.85, 0.05, 0.1)


# A soft shadow under the feet (drawn below the Body sprite), and a health
# bar above the enemy once it has been hit.
func _draw() -> void:
	var feet = $Body.texture.get_height() * 0.45
	draw_set_transform(Vector2(0, feet), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 22.0, Color(0, 0, 0, 0.22))
	draw_set_transform(Vector2.ZERO)

	if health >= max_health:
		return

	var top_left = Vector2(-HEALTH_BAR_SIZE.x / 2.0, HEALTH_BAR_OFFSET)
	var ratio = clampf(float(health) / float(max_health), 0.0, 1.0)

	draw_rect(Rect2(top_left, HEALTH_BAR_SIZE).grow(1.5), Color(0.12, 0.04, 0.14, 0.9))
	draw_rect(
		Rect2(top_left, Vector2(HEALTH_BAR_SIZE.x * ratio, HEALTH_BAR_SIZE.y)),
		Color(0.2, 0.9, 0.3).lerp(Color(0.95, 0.2, 0.1), 1.0 - ratio)
	)


# Briefly turns the body red when it takes a hit.
func _flash_hit() -> void:
	var body: Sprite2D = $Body
	body.modulate = Color(1.0, 0.35, 0.35)
	var tween = body.create_tween()
	tween.tween_property(body, "modulate", Color.WHITE, 0.12)


# A few shards fly out and fade where the enemy died.
func _spawn_death_burst() -> void:
	var scene = get_tree().current_scene
	var origin = scene.to_local(global_position)

	# A blood stain stays on the road for a few seconds.
	var stain = Sprite2D.new()
	stain.texture = BLOOD_SPLATTERS.pick_random()
	stain.position = position
	stain.rotation = randf_range(-0.4, 0.4)
	# On the path, right above the road, so walking enemies stay on top of it.
	get_parent().add_child.call_deferred(stain)
	get_parent().move_child.call_deferred(stain, 1)
	stain.ready.connect(func() -> void:
		var fade = stain.create_tween()
		fade.tween_interval(4.0)
		fade.tween_property(stain, "modulate:a", 0.0, 1.0)
		fade.tween_callback(stain.queue_free)
	, CONNECT_ONE_SHOT)

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
		var bone_amount = randi_range(5, 10)
		_spawn_body_part(bone_amount, 0, 0)

	elif roll <= 95:
		var organ_amount = randi_range(2, 5)
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

	var scene = get_tree().current_scene
	part.position = scene.to_local(global_position)
	scene.add_child.call_deferred(part)
