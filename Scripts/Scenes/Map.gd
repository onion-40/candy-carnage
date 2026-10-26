
extends Node2D

const TOWER_SCENE = preload("res://scenes/Towers.tscn")
const ENEMY_SCENE = preload("res://scenes/Enemies.tscn")

@onready var enemy_path: Path2D = $EnemyPath
@onready var spawn_timer: Timer = $EnemySpawnTimer
@onready var tower_spots: Node2D = $TowerSpots

var selected_spot: Marker2D = null


func _ready() -> void:
	for spot in tower_spots.get_children():
		if spot is Marker2D:
			spot.set_meta("occupied", false)
			_create_spot_visual(spot)

	spawn_timer.wait_time = 1
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_spawn_enemy)
	spawn_timer.start()

	# Temporary test tower.
	if tower_spots.get_child_count() > 0:
		var first_spot = tower_spots.get_child(0) as Marker2D

		if first_spot != null:
			build_laser_at(first_spot)


# =====================================
# TOWER SPOT VISUALS
# =====================================

func _create_spot_visual(spot: Marker2D) -> void:
	if spot.has_node("SpotVisual"):
		return

	var visual = Polygon2D.new()
	visual.name = "SpotVisual"

	visual.polygon = PackedVector2Array([
		Vector2(-25, -25),
		Vector2(25, -25),
		Vector2(25, 25),
		Vector2(-25, 25)
	])

	visual.color = Color(0.2, 0.8, 0.3, 0.65)
	visual.z_index = -1

	spot.add_child(visual)


# =====================================
# ENEMY SPAWNING
# =====================================

func _spawn_enemy() -> void:
	if enemy_path.curve == null:
		push_warning("EnemyPath has no Curve2D.")
		return

	if enemy_path.curve.get_baked_length() <= 0.0:
		push_warning("EnemyPath curve is empty. Add points to the path.")
		return

	var enemy = ENEMY_SCENE.instantiate()
	enemy_path.add_child(enemy)


# =====================================
# TOWER CONSTRUCTION
# =====================================

func build_tower_at(spot: Marker2D, type: int) -> bool:
	var success = false

	if is_instance_valid(spot):
		if not spot.get_meta("occupied", false):
			var tower = TOWER_SCENE.instantiate()
			tower.tower_type = type

			var cost = tower.get_build_cost()

			if ResourceManager.spend_resources(
				cost["bones"],
				cost["organs"],
				cost["eyeballs"]
			):
				tower.build_spot = spot
				add_child(tower)

				tower.global_position = spot.global_position
				spot.set_meta("occupied", true)
				success = true
			else:
				tower.free()

	return success


func build_laser_at(spot: Marker2D) -> bool:
	return build_tower_at(spot, 0)


func build_cannon_at(spot: Marker2D) -> bool:
	return build_tower_at(spot, 1)


# =====================================
# TOWER SPOT SELECTION
# =====================================

func select_spot(spot: Marker2D) -> void:
	if is_instance_valid(spot):
		selected_spot = spot


func build_laser_on_selected_spot() -> bool:
	var success = false

	if is_instance_valid(selected_spot):
		success = build_laser_at(selected_spot)

	return success


func build_cannon_on_selected_spot() -> bool:
	var success = false

	if is_instance_valid(selected_spot):
		success = build_cannon_at(selected_spot)

	return success


# =====================================
# TOWER UPGRADING
# =====================================

func upgrade_tower(tower: Node) -> bool:
	var success = false

	if is_instance_valid(tower):
		if tower.has_method("upgrade"):
			success = tower.upgrade()

	return success


# =====================================
# TOWER SELLING
# =====================================

func sell_tower(tower: Node) -> void:
	if is_instance_valid(tower):
		var spot = tower.build_spot

		if tower.has_method("sell"):
			tower.sell()

		if selected_spot == spot:
			selected_spot = null
