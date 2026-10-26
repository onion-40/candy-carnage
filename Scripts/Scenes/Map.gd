extends Node2D

const TOWER_SCENE = preload("res://scenes/Towers.tscn")
const ENEMY_SCENE = preload("res://scenes/Enemies.tscn")
const SPECIAL_CHARACTER_SCENE = preload("res://Scenes/SpecialCharacters.tscn")
signal player_health_changed(current_hp: int, max_hp: int)
signal game_over

@export var deployment_start_delay: float = 10.0
@export var special_cooldown: float = 15.0
@export var max_player_hp: int = 100

@onready var enemy_path: Path2D = $EnemyPath
@onready var spawn_timer: Timer = $EnemySpawnTimer
@onready var tower_spots: Node2D = $TowerSpots
@onready var deployment_start_timer: Timer = $DeploymentStartTimer
@onready var special_cooldown_timer: Timer = $SpecialCoolddownTimer
@onready var deployment_preview: Polygon2D = $DeploymentPreview
var player_hp: int = 100
var is_game_over: bool = false

var selected_spot: Area2D = null
var can_deploy_special: bool = false
var choosing_deployment_location: bool = false


func _ready() -> void:
	player_hp = max_player_hp
	player_health_changed.connect(update_health_bar)
	player_health_changed.emit(player_hp, max_player_hp)
	
	for spot in tower_spots.get_children():
		if spot is Area2D:
			spot.set_meta("occupied", false)
			_create_spot_visual(spot)
			
			# Connect click input signal for each spot
			if not spot.is_connected("input_event", _on_spot_input_event.bind(spot)):
				spot.input_event.connect(_on_spot_input_event.bind(spot))

	spawn_timer.wait_time = 1
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_spawn_enemy)
	spawn_timer.start()

	# Temporary test tower.
	if tower_spots.get_child_count() > 0:
		var first_spot = tower_spots.get_child(0) as Area2D # Fixed from Marker2D to Area2D

		if first_spot != null:
			build_laser_at(first_spot)
			
	deployment_start_timer.one_shot = true
	deployment_start_timer.wait_time = deployment_start_delay
	deployment_start_timer.timeout.connect(_on_deployment_start_ready)
	deployment_start_timer.start()
	
	special_cooldown_timer.one_shot = true
	special_cooldown_timer.wait_time = special_cooldown
	special_cooldown_timer.timeout.connect(_on_special_cooldown_finished)

	_create_deployment_preview()


# =====================================
# PLAYER HP SYSTEM
# =====================================
func _on_enemy_reached_base(damage: int) -> void:
	if(is_game_over):
		return
	
	player_hp = max(0, player_hp - damage)
	player_health_changed.emit(player_hp, max_player_hp)
	
	print("HP: ", player_hp, "/", max_player_hp)
	
	if player_hp <= 0:
		is_game_over = true
		spawn_timer.stop()
		game_over.emit()
		print("GAME OVER! The base has been destroyed.")


# =====================================
# TOWER SPOT VISUALS
# =====================================

func _create_spot_visual(spot: Area2D) -> void:
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
		push_warning("EnemyPatth curve is empty. Add points to the path.")
		return

	var enemy = ENEMY_SCENE.instantiate()
	enemy.reached_base.connect(_on_enemy_reached_base)
	enemy_path.add_child(enemy)


# =====================================
# TOWER CONSTRUCTION
# =====================================

func build_tower_at(spot: Area2D, type: int) -> bool:
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

				# Force it right to the Area2D's global position
				tower.global_position = spot.global_position
				
				spot.set_meta("occupied", true)
				success = true
				
				# Hide visual spot indicator when occupied
				if spot.has_node("SpotVisual"):
					spot.get_node("SpotVisual").visible = false
			else:
				tower.queue_free()

	return success

# Handles click detection directly from the Area2D spots
func _on_spot_input_event(_viewport: Node, event: InputEvent, _shape_idx: int, spot: Area2D) -> void:
	if spot.get_meta("occupied", false):
		return
		
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		select_spot(spot)
		build_laser_on_selected_spot()

func build_laser_at(spot: Area2D) -> bool:
	return build_tower_at(spot, 0)


func build_cannon_at(spot: Area2D) -> bool:
	return build_tower_at(spot, 1)


# =====================================
# TOWER SPOT SELECTION
# =====================================

func select_spot(spot: Area2D) -> void:
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
			
			
# =====================================
# SPECIAL CHARACTER DEPLOYMENT
# =====================================

func _process(_delta: float) -> void:
	if choosing_deployment_location:
		deployment_preview.global_position = get_global_mouse_position()
		

func _on_deployment_start_ready() -> void:
	can_deploy_special = true
	print("Special character deployment is ready!")
	
func _on_special_cooldown_finished() -> void:
	can_deploy_special = true
	print("Special Character cooldown finished!")
	
func begin_special_placement() -> void:
	if not can_deploy_special:
		print("Special character is not ready yet.")
		return
	
	if choosing_deployment_location:
		return
	
	choosing_deployment_location = true
	deployment_preview.visible = true
	
func _unhandled_input(event: InputEvent) -> void:
	if not choosing_deployment_location:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_deploy_special_character(get_global_mouse_position())
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_cancel_special_placement()
			
func _deploy_special_character(location: Vector2) -> void:
	if not can_deploy_special:
		return
	
	var character = SPECIAL_CHARACTER_SCENE.instantiate()
	
	add_child(character)
	character.global_position = location
	character.activate()
	
	can_deploy_special = false
	choosing_deployment_location = false
	deployment_preview.visible = false
	
	special_cooldown_timer.wait_time = special_cooldown
	special_cooldown_timer.start()
	
func _cancel_special_placement() -> void:
	choosing_deployment_location = false
	deployment_preview.visible = false
	
func _create_deployment_preview() -> void:
	var points = PackedVector2Array()
	var radius = 150.0
	var segments = 48
	
	for i in range(segments):
		var angle = TAU * float(i) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
		
	deployment_preview.polygon = points
	deployment_preview.color = Color(1.0, 0.2, 0.2, 0.25)
	deployment_preview.visible = false
	deployment_preview.z_index = 10

func update_health_bar(current_hp: int, max_hp: int) -> void:
	var health_bar = get_tree().current_scene.get_node("UI/HealthBar")
	health_bar.max_value = max_hp
	health_bar.value = current_hp
