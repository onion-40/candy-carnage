
extends Node2D

enum TowerType {
	LASER,
	HEAVY_CANNON
}

@export var tower_type: TowerType = TowerType.LASER

const LASER_COLOR: Color = Color(0.4, 0.9, 1.0)
const CANNON_FLASH_COLOR: Color = Color(1.0, 0.75, 0.2)

var level: int = 1
var attack_range: float
var damage: int
var attack_interval: float
var is_sold: bool = false
var build_spot: Area2D

@onready var attack_timer: Timer = $AttackTimer
@onready var body: Polygon2D = $Body


func _ready() -> void:
	if body.polygon.is_empty():
		body.polygon = PackedVector2Array([
			Vector2(-15, -15),
			Vector2(15, -15),
			Vector2(15, 15),
			Vector2(-15, 15)
		])

	apply_stats()

	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_timer.start()


func get_build_cost() -> Dictionary:
	var cost = {}

	match tower_type:
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


func apply_stats() -> void:
	if tower_type == TowerType.LASER:
		attack_range = 220.0 + (level - 1) * 20.0
		damage = 10 + (level - 1) * 2
		attack_interval = 0.6
		body.color = Color(0.1, 0.4, 1.0)

	elif tower_type == TowerType.HEAVY_CANNON:
		attack_range = 150.0 + (level - 1) * 10.0
		damage = 25 + (level - 1) * 10
		attack_interval = 1.5
		body.color = Color(1.0, 0.2, 0.1)
	else:
		return

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
		target.take_damage(damage)
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


# A muzzle flash on the tower and a bigger blast on the target.
func _show_cannon_flash(target_position: Vector2) -> void:
	_spawn_flash(global_position, 14.0, 0.15)
	_spawn_flash(target_position, 22.0 + level * 4.0, 0.25)


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
			print("Tower clicked: ", name)

			get_tree().call_group("tower_selection", "select_tower", self)
