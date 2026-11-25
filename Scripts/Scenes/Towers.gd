
extends Node2D

enum TowerType {
	LASER,
	HEAVY_CANNON
}

@export var tower_type: TowerType = TowerType.LASER

const LASER_COLOR: Color = Color(0.4, 0.9, 1.0)
const CANNON_FLASH_COLOR: Color = Color(1.0, 0.75, 0.2)
const CANNON_PROJECTILE = preload("res://Assets/Sprites/fibroxy_artillery_tower_projectile.png")
const DRAINED_COLOR: Color = Color(0.75, 0.35, 1.0)
# [new, decay] sprite per tower type.
const SPRITES = {
	TowerType.LASER: [
		preload("res://Assets/Sprites/amblin_ranged_tower_new.png"),
		preload("res://Assets/Sprites/amblin_ranged_tower_decay.png"),
	],
	TowerType.HEAVY_CANNON: [
		preload("res://Assets/Sprites/fibroxy_artillery_tower_new.png"),
		preload("res://Assets/Sprites/fibroxy_artillery_tower_decay.png"),
	],
}

var level: int = 1
var attack_range: float
var damage: int
var attack_interval: float
var is_sold: bool = false
var build_spot: Area2D

@onready var attack_timer: Timer = $AttackTimer
@onready var body: Sprite2D = $Body
@onready var lifetime_bar: ProgressBar = $LifetimeBar
# TOWER LIFETIME
@export var starting_lifetime: float = 90.0
@export var lifetime_per_upgrade: float = 30.0
@export var decay_warning_time: float = 15.0

var max_lifetime: float = 90.0
var time_left: float = 90.0

# REPAIR SYSTEM
var is_repairing: bool = false
var repair_held_time: float = 0.0
var repair_duration: float = 6.0
var repair_decay_multiplier: float = 0.5

signal dissolved(spot: Area2D)


func _ready() -> void:
	add_to_group("towers")
	apply_stats()
	max_lifetime = starting_lifetime
	lifetime_bar.max_value = max_lifetime
	lifetime_bar.value = time_left
	time_left = max_lifetime

	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_timer.start()

func _process(delta: float) -> void:
	if is_sold:
		return

	var decay_speed = 1.0

	if is_repairing:
		decay_speed = repair_decay_multiplier
		repair_held_time += delta

		if repair_held_time >= repair_duration:
			_finish_repair()

	time_left -= delta * decay_speed
	time_left = max(0.0, time_left)
	lifetime_bar.max_value = max_lifetime
	lifetime_bar.value = time_left
	
	# The tower looks rotten once half its lifetime is gone.
	body.texture = SPRITES[tower_type][1 if time_left <= max_lifetime * 0.5 else 0]

	# Show a warning when the tower is close to dissolving.
	if time_left <= decay_warning_time:
		body.modulate = Color(1.0, 0.4, 0.4)
		lifetime_bar.modulate = Color(1.0, 0.3, 0.3)
	else:
		body.modulate = Color.WHITE
		lifetime_bar.modulate = Color.WHITE

	# Dissolve the tower when its lifetime expires.
	if time_left <= 0.0:
		_dissolve()
		

func _dissolve() -> void:
	if is_sold:
		return

	is_sold = true
	attack_timer.stop()

	dissolved.emit(build_spot)
	queue_free()

func get_build_cost() -> Dictionary:
	return build_cost_for(tower_type)


# Static so the HUD can show prices without instancing a tower.
static func build_cost_for(type: int) -> Dictionary:
	var cost = {}

	match type:
		TowerType.LASER:
			cost = {
				"bones": 15,
				"organs": 5,
				"eyeballs": 0
			}

		TowerType.HEAVY_CANNON:
			cost = {
				"bones": 25,
				"organs": 7,
				"eyeballs": 0
			}

	return cost


func get_upgrade_cost() -> Dictionary:
	var cost = {
		"bones": 0,
		"organs": 0,
		"eyeballs": 0
	}

	if level == 1:
		if tower_type == TowerType.LASER:
			cost = {
				"bones": 15,
				"organs": 10,
				"eyeballs": 0
			}
		else:
			cost = {
				"bones": 35,
				"organs": 12,
				"eyeballs": 0
			}

	elif level == 2:
		if tower_type == TowerType.LASER:
			cost = {
				"bones": 20,
				"organs": 15,
				"eyeballs": 0
			}
		else:
			cost = {
				"bones": 50,
				"organs": 18,
				"eyeballs": 2
			}
	
	elif level == 3:
		if tower_type == TowerType.LASER:
			cost = {
				"bones": 35,
				"organs": 20,
				"eyeballs": 2
			}
		else:
			cost = {
				"bones": 50,
				"organs": 25,
				"eyeballs": 4
			}

	return cost


func upgrade() -> bool:
	var success = false

	if level < 3:
		var cost = get_upgrade_cost()

		if ResourceManager.spend_resources(
			cost["bones"],
			cost["organs"],
			cost["eyeballs"]
		):
			level += 1

		# Increase maximum lifetime and restore it after upgrading.
		max_lifetime = starting_lifetime + (
			(level - 1) * lifetime_per_upgrade
		)

		time_left = max_lifetime
		lifetime_bar.max_value = max_lifetime
		lifetime_bar.value = time_left

		apply_stats()
		success = true

	return success


func sell() -> void:
	if not is_sold:
		is_sold = true

		var cost = get_build_cost()

		ResourceManager.add_resources(
			int(cost["bones"] / 2),
			int(cost["organs"] / 2),
			int(cost["eyeballs"] / 2)
		)

		if is_instance_valid(build_spot):
			build_spot.set_meta("occupied", false)

		queue_free()


# Static so the tower panel can preview the next level without touching the tower.
static func stats_for(type: int, for_level: int) -> Dictionary:
	if type == TowerType.HEAVY_CANNON:
		return {
			"attack_range": 150.0 + (for_level - 1) * 10.0,
			"damage": 25 + (for_level - 1) * 10,
			"attack_interval": 1.5,
		}

	return {
		"attack_range": 220.0 + (for_level - 1) * 20.0,
		"damage": 10 + (for_level - 1) * 2,
		"attack_interval": 0.6,
	}


func apply_stats() -> void:
	var stats = stats_for(tower_type, level)
	attack_range = stats["attack_range"]
	damage = stats["damage"]
	attack_interval = stats["attack_interval"]

	attack_timer.wait_time = attack_interval
	queue_redraw() # range circle follows upgrades


# =====================================
# RANGE PREVIEW (shown while the tower panel is open)
# =====================================

var range_visible: bool = false


func set_range_visible(value: bool) -> void:
	range_visible = value
	queue_redraw()


func _draw() -> void:
	if not range_visible:
		return

	draw_circle(Vector2.ZERO, attack_range, Color(1, 1, 1, 0.08))
	draw_arc(Vector2.ZERO, attack_range, 0.0, TAU, 64, Color(1, 1, 1, 0.5), 2.0)


func _on_attack_timer_timeout() -> void:
	var target = find_nearest_enemy()

	if target != null:
		# Read the position first: a killed enemy frees itself.
		var target_position = target.global_position
		target.take_damage(damage, tower_type)
		_show_attack(target_position)


# =====================================
# ATTACK EFFECTS
# =====================================

func _show_attack(target_position: Vector2) -> void:
	if tower_type == TowerType.LASER:
		_show_laser(target_position)
	else:
		_show_cannon_flash(target_position)


# A short beam from the tower to the target that fades out.
func _show_laser(target_position: Vector2) -> void:
	var beam = Line2D.new()
	beam.top_level = true # points are in world coordinates
	beam.z_index = 10
	beam.width = 3.0 + level
	beam.default_color = LASER_COLOR
	beam.begin_cap_mode = Line2D.LINE_CAP_ROUND
	beam.end_cap_mode = Line2D.LINE_CAP_ROUND
	beam.points = PackedVector2Array([global_position, target_position])
	add_child(beam)

	var tween = beam.create_tween()
	tween.tween_property(beam, "modulate:a", 0.0, 0.15)
	tween.tween_callback(beam.queue_free)


# A muzzle flash, a shell flying to the target, then a bigger blast there.
# The damage is already dealt: the shell is only feedback.
func _show_cannon_flash(target_position: Vector2) -> void:
	_spawn_flash(global_position, 14.0, 0.15)

	var shell = Sprite2D.new()
	shell.texture = CANNON_PROJECTILE
	shell.top_level = true
	shell.z_index = 10
	add_child(shell)
	shell.global_position = global_position + Vector2(0, -30)

	var tween = shell.create_tween()
	tween.set_parallel(true)
	tween.tween_property(shell, "global_position", target_position, 0.25)
	tween.tween_property(shell, "rotation", TAU, 0.25)
	tween.chain().tween_callback(func() -> void:
		_spawn_flash(target_position, 22.0 + level * 4.0, 0.25)
		shell.queue_free()
	)


func _spawn_flash(at: Vector2, radius: float, duration: float) -> void:
	var points = PackedVector2Array()
	var segments = 16

	for i in range(segments):
		var angle = TAU * float(i) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)

	var flash = Polygon2D.new()
	flash.top_level = true
	flash.z_index = 10
	flash.polygon = points
	flash.color = CANNON_FLASH_COLOR
	add_child(flash)
	flash.global_position = at
	flash.scale = Vector2(0.4, 0.4)

	var tween = flash.create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash, "scale", Vector2.ONE, duration)
	tween.tween_property(flash, "modulate:a", 0.0, duration)
	tween.chain().tween_callback(flash.queue_free)


func find_nearest_enemy() -> Node2D:
	var nearest_enemy: Node2D = null
	var nearest_distance: float = attack_range

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue

		var distance = global_position.distance_to(
			enemy.global_position
		)

		if distance <= nearest_distance:
			nearest_distance = distance
			nearest_enemy = enemy

	return nearest_enemy

func _on_selection_area_input_event(
	viewport: Node,
	event: InputEvent,
	shape_idx: int
) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			get_tree().call_group("tower_selection", "select_tower", self)

# One click starts a repair; it always runs to the end (all or nothing),
# so it can't be spammed in short bursts and works on touchpads.
func begin_repair() -> void:
	if is_sold or is_repairing:
		return

	is_repairing = true
	repair_held_time = 0.0

	# Towers cannot attack while being repaired.
	attack_timer.stop()


func _finish_repair() -> void:
	is_repairing = false
	repair_held_time = 0.0
	time_left = max_lifetime
	attack_timer.start()

func reduce_lifetime(amount: float) -> void:
	if is_sold:
		return

	time_left = maxf(0.0, time_left - amount)
	lifetime_bar.value = time_left

	# Purple flash and a floating "-3.5 s" so the player sees the mage draining this tower.
	modulate = DRAINED_COLOR
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.5)

	var label = Label.new()
	label.text = "-%.1f s" % amount
	label.position = Vector2(-24, -110)
	label.z_index = 11
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.85, 0.55, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.12, 0.04, 0.14))
	label.add_theme_constant_override("outline_size", 5)
	add_child(label)

	var float_up = label.create_tween().set_parallel(true)
	float_up.tween_property(label, "position:y", label.position.y - 30.0, 0.9)
	float_up.tween_property(label, "modulate:a", 0.0, 0.9).set_delay(0.3)
	float_up.chain().tween_callback(label.queue_free)

	if time_left <= 0.0:
		_dissolve()
