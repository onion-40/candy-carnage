
extends Node2D

const TOWER_SCENE = preload("res://scenes/Towers.tscn")

@export var enemy_scene: PackedScene

@onready var enemy_path: Path2D = $EnemyPath
@onready var spawn_timer: Timer = $EnemySpawnTimer
@onready var tower_spots: Node2D = $TowerSpots

var selected_spot: Marker2D = null


func _ready() -> void:
	spawn_timer.timeout.connect(_spawn_enemy)
	spawn_timer.start()

	for spot in tower_spots.get_children():
		spot.set_meta("occupied", false)

	if tower_spots.get_child_count() > 0:
		build_laser_at(tower_spots.get_child(0))


# =====================================
# ENEMY SPAWNING
# =====================================

func _spawn_enemy() -> void:
	if enemy_scene == null:
		return

	var enemies = enemy_scene.instantiate()

	# Enemies must be children of EnemyPath
	# because Enemy uses PathFollow2D.
	enemy_path.add_child(enemies)


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
				add_child(tower)

				tower.global_position = spot.global_position
				tower.build_spot = spot

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
		if tower.has_method("sell"):
			tower.sell()

		if selected_spot == tower.build_spot:
			selected_spot = null
