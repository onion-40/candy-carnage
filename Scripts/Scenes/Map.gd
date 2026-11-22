extends Node2D

const TOWER_SCENE = preload("res://Scenes/Towers.tscn")
const ENEMY_SCENE = preload("res://Scenes/Enemies.tscn")
const SPECIAL_CHARACTER_SCENE = preload("res://Scenes/SpecialCharacters.tscn")
const SPECIAL_CHARACTER_SCRIPT = preload("res://Scenes/special_characters.gd")
const TOWER_SCRIPT = preload("res://Scripts/Scenes/Towers.gd")
const BOTTOM_HUD_SCRIPT = preload("res://Scenes/bottom_hud.gd")
const MENU_THEME = preload("res://Scenes/MenuTheme.tres")
signal player_health_changed(current_hp: int, max_hp: int)
signal game_over
signal victory

@export var deployment_start_delay: float = 10.0
@export var special_cooldown: float = 15.0
@export var max_player_hp: int = 100
@export var total_waves: int = 6
@export var enemies_per_wave: int = 3
@export var enemies_added_per_wave: int = 5
@export var spawn_interval: float = 1.5
@export var wave_break: float = 5.0
@export var starting_enemy_health: int = 50
@export var enemy_health_increase_per_wave: int = 10

@export_group("Enemy Introduction Waves")
@export var mage_start_wave: int = 3
@export var tank_start_wave: int = 6
@export var healer_start_wave: int = 99

@export_group("Special Enemy Counts")
@export var tank_count_per_wave: int = 1
@export var healer_count_per_wave: int = 1

@onready var enemy_path: Path2D = $EnemyPath
@onready var spawn_timer: Timer = $EnemySpawnTimer
@onready var tower_spots: Node2D = $TowerSpots
@onready var deployment_start_timer: Timer = $DeploymentStartTimer
@onready var special_cooldown_timer: Timer = $SpecialCoolddownTimer
@onready var deployment_preview: Polygon2D = $DeploymentPreview
@onready var wave_break_timer: Timer = $WaveBreakTimer

var player_hp: int = 100
var is_game_over: bool = false
var is_victory: bool = false

var selected_spot: Area2D = null
var can_deploy_special: bool = false
var choosing_deployment_location: bool = false

var current_wave: int = 0
var enemies_to_spawn: int = 0
var mages_to_spawn: int = 0
var enemies_alive: int = 0
var tanks_to_spawn: int = 0
var healers_to_spawn: int = 0
var wave_in_progress: bool = false


func _ready() -> void:
	player_hp = max_player_hp
	player_health_changed.connect(update_health_bar)
	player_health_changed.emit(player_hp, max_player_hp)
	_texture_road()
	_scatter_decor()

	for spot in tower_spots.get_children():
		if spot is Area2D:
			spot.set_meta("occupied", false)
			_create_spot_visual(spot)
			
			# Connect click input signal for each spot
			if not spot.is_connected("input_event", _on_spot_input_event.bind(spot)):
				spot.input_event.connect(_on_spot_input_event.bind(spot))

	spawn_timer.wait_time = spawn_interval
	spawn_timer.one_shot = true
	spawn_timer.timeout.connect(_spawn_enemy)

	wave_break_timer.one_shot = true
	wave_break_timer.timeout.connect(start_next_wave)

	start_next_wave()

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
	_show_base_hit()

	if player_hp <= 0:
		is_game_over = true
		spawn_timer.stop()
		wave_break_timer.stop()
		game_over.emit()


# =====================================
# TOWER SPOT VISUALS
# =====================================

func _create_spot_visual(spot: Area2D) -> void:
	# The scenes still hold the old placeholder rectangles.
	for child in spot.get_children():
		if child is Polygon2D:
			child.visible = false

	var visual = Sprite2D.new()
	visual.name = "SpotSprite"
	visual.texture = preload("res://Assets/Sprites/tower_spot_vacant.png")
	visual.position = Vector2(0, 14) # the tower stands on the back of the pad
	spot.add_child(visual)


# =====================================
# MAP DECOR
# =====================================

const DECOR_SPRITES = [
	preload("res://Assets/Sprites/tree_1.png"),
	preload("res://Assets/Sprites/tree_2.png"),
	preload("res://Assets/Sprites/tree_3.png"),
	preload("res://Assets/Sprites/bush_1.png"),
	preload("res://Assets/Sprites/bush_2.png"),
	preload("res://Assets/Sprites/bush_3.png"),
	preload("res://Assets/Sprites/grass_1.png"),
	preload("res://Assets/Sprites/grass_2.png"),
	preload("res://Assets/Sprites/grass_3.png"),
]


func _texture_road() -> void:
	var road: Line2D = enemy_path.get_node_or_null("RoadVisual")

	if road == null:
		return

	road.texture = preload("res://Assets/Sprites/road_1.png")
	road.texture_mode = Line2D.LINE_TEXTURE_TILE
	road.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	road.default_color = Color.WHITE
	road.joint_mode = Line2D.LINE_JOINT_ROUND


# Scatters trees, bushes and grass on the free ground, the same way on every run.
func _scatter_decor() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = 7
	var road: Line2D = enemy_path.get_node_or_null("RoadVisual")
	var placed: Array[Vector2] = []

	for attempt in range(400):
		if placed.size() >= 24:
			break

		var point = Vector2(rng.randf_range(20, 1260), rng.randf_range(20, 600))
		var texture: Texture2D = DECOR_SPRITES[rng.randi() % DECOR_SPRITES.size()]
		var clearance = texture.get_size().length() * 0.5

		if road and _distance_to_line(road, road.to_local(to_global(point))) < 40.0 + clearance:
			continue

		var near_spot = false

		for spot in tower_spots.get_children():
			if spot is Area2D and to_local(spot.global_position).distance_to(point) < 80.0 + clearance:
				near_spot = true

		if near_spot:
			continue

		var crowded = false

		for other in placed:
			if other.distance_to(point) < 45.0 + clearance:
				crowded = true

		if crowded:
			continue

		var sprite = Sprite2D.new()
		sprite.texture = texture
		sprite.position = point
		sprite.flip_h = rng.randf() < 0.5
		add_child(sprite)
		move_child(sprite, 1) # right above the background
		placed.append(point)


func _distance_to_line(line: Line2D, point: Vector2) -> float:
	var best = INF

	for i in range(line.get_point_count() - 1):
		var closest = Geometry2D.get_closest_point_to_segment(point, line.get_point_position(i), line.get_point_position(i + 1))
		best = minf(best, closest.distance_to(point))

	return best


# =====================================
# ENEMY SPAWNING
# =====================================

func _spawn_enemy() -> void:
	if is_game_over:
		return

	if enemy_path.curve == null:
		push_warning("EnemyPath has no Curve2D.")
		return

	if enemy_path.curve.get_baked_length() <= 0.0:
		push_warning("EnemyPath curve is empty. Add points to the path.")
		return

	if enemies_to_spawn <= 0:
		return

	var enemy = ENEMY_SCENE.instantiate()

	var special_total = (
		mages_to_spawn +
		tanks_to_spawn +
		healers_to_spawn
	)

	var selected_type = 0

	# Randomly mix special enemies with regular enemies.
	if special_total > 0:
		if special_total >= enemies_to_spawn or randf() < (
			float(special_total) / float(enemies_to_spawn)
		):
			var roll = randi_range(1, special_total)

			if roll <= mages_to_spawn:
				selected_type = 1
				mages_to_spawn -= 1

			elif roll <= mages_to_spawn + tanks_to_spawn:
				selected_type = 2
				tanks_to_spawn -= 1

			else:
				selected_type = 3
				healers_to_spawn -= 1

	enemy.enemy_type = selected_type

	enemy.max_health = starting_enemy_health + (
		(current_wave - 1) * enemy_health_increase_per_wave
	)

	enemy.reached_base.connect(_on_enemy_reached_base)
	enemy.tree_exited.connect(_on_enemy_removed)

	enemy_path.add_child(enemy)

	enemies_to_spawn -= 1
	enemies_alive += 1

	if enemies_to_spawn > 0:
		spawn_timer.start()
func start_next_wave() -> void:
	if is_game_over:
		return

	if current_wave >= total_waves:
		wave_in_progress = false
		return

	current_wave += 1

	enemies_to_spawn = enemies_per_wave + (
		(current_wave - 1) * enemies_added_per_wave
	)

	mages_to_spawn = 0
	tanks_to_spawn = 0
	healers_to_spawn = 0

	# Reserve at least one regular enemy in each wave.
	var available_special_slots = maxi(0, enemies_to_spawn - 1)

	# Tank allocation.
	if current_wave >= tank_start_wave:
		tanks_to_spawn = mini(
			tank_count_per_wave + _extra_specials(tank_start_wave),
			available_special_slots
		)
		available_special_slots -= tanks_to_spawn

	# Healer allocation.
	if current_wave >= healer_start_wave:
		healers_to_spawn = mini(
			healer_count_per_wave + _extra_specials(healer_start_wave),
			available_special_slots
		)
		available_special_slots -= healers_to_spawn

	# Mage allocation.
	if current_wave >= mage_start_wave and available_special_slots > 0:
		mages_to_spawn = randi_range(
			1,
			mini(2 + _extra_specials(mage_start_wave), available_special_slots)
		)

	wave_in_progress = true

	spawn_timer.wait_time = spawn_interval
	spawn_timer.start()

# One more special enemy of a type every two waves after it first appears,
# so later waves keep changing.
func _extra_specials(start_wave: int) -> int:
	return maxi(0, floori((current_wave - start_wave) / 2.0))


func _on_enemy_removed() -> void:
	# tree_exited also fires when the whole scene is torn down (quit, Restart);
	# those exits are not kills and the wave timer is already leaving the tree.
	if not wave_break_timer.is_inside_tree():
		return

	enemies_alive = max(0, enemies_alive - 1)

	if enemies_to_spawn == 0 and enemies_alive == 0 and wave_in_progress:
		wave_in_progress = false

		if current_wave < total_waves:
			wave_break_timer.start(wave_break)
		elif not is_game_over:
			# The last enemy can drop HP to 0 as it is removed: a loss wins over a win.
			is_victory = true
			deployment_preview.visible = false
			choosing_deployment_location = false
			victory.emit()

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
				tower.dissolved.connect(_on_tower_dissolved)

				add_child(tower)

				# Force it right to the Area2D's global position
				tower.global_position = spot.global_position
				
				spot.set_meta("occupied", true)
				success = true

				if selected_spot == spot:
					select_spot(null)
				
				# Hide the entire tower spot after building
				spot.visible = false
				spot.input_pickable = false
			else:
				# Never added to the tree, so it must be freed by hand.
				tower.free()

	return success

# Handles click detection directly from the Area2D spots
func _on_spot_input_event(
	_viewport: Node,
	event: InputEvent,
	_shape_idx: int,
	spot: Area2D
) -> void:
	if spot.get_meta("occupied", false):
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		select_spot(spot)

func build_laser_at(spot: Area2D) -> bool:
	return build_tower_at(spot, 0)


func build_cannon_at(spot: Area2D) -> bool:
	return build_tower_at(spot, 1)


# =====================================
# TOWER SPOT SELECTION
# =====================================

const SPOT_SELECTED_MODULATE: Color = Color(1.6, 1.6, 0.6)


# The selected spot is tinted so the player sees where the next build goes.
# Passing null clears the selection.
func select_spot(spot: Area2D) -> void:
	if is_instance_valid(selected_spot):
		selected_spot.modulate = Color.WHITE

	selected_spot = spot if is_instance_valid(spot) else null

	if selected_spot:
		selected_spot.modulate = SPOT_SELECTED_MODULATE

	_show_build_menu(selected_spot)


var build_menu: Control = null


# Players struggled with "click a spot, then a HUD button": the tower choice
# now pops up right on the selected spot. The HUD buttons still work too.
func _show_build_menu(spot: Area2D) -> void:
	if is_instance_valid(build_menu):
		build_menu.queue_free()

	build_menu = null

	if spot == null:
		return

	build_menu = HBoxContainer.new()
	build_menu.theme = MENU_THEME
	build_menu.z_index = 20
	build_menu.add_theme_constant_override("separation", 8)

	var titles = {TOWER_SCRIPT.TowerType.LASER: "Laser", TOWER_SCRIPT.TowerType.HEAVY_CANNON: "Cannon"}

	for type in titles:
		var cost = TOWER_SCRIPT.build_cost_for(type)
		var button = Button.new()
		button.theme_type_variation = &"LevelCard"
		button.custom_minimum_size = Vector2(130, 120)
		button.icon = TOWER_SCRIPT.SPRITES[type][0]
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.add_theme_font_size_override("font_size", 14)
		button.add_theme_constant_override("outline_size", 4)
		button.text = "%s\n%s" % [titles[type], BOTTOM_HUD_SCRIPT.format_cost(cost)]
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.disabled = not ResourceManager.can_afford(cost["bones"], cost["organs"], cost["eyeballs"])
		button.pressed.connect(build_tower_at.bind(spot, type))
		build_menu.add_child(button)

	add_child(build_menu)
	build_menu.reset_size()

	# Above the spot, or below it when there is no room at the top of the screen.
	var menu_size = build_menu.size
	var position_on_map = spot.global_position + Vector2(-menu_size.x / 2.0, -menu_size.y - 50.0)

	if position_on_map.y < 8.0:
		position_on_map.y = spot.global_position.y + 50.0

	position_on_map.x = clampf(position_on_map.x, 8.0, 1272.0 - menu_size.x)
	build_menu.global_position = position_on_map


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

		if is_instance_valid(spot):
			spot.set_meta("occupied", false)
			spot.visible = true
			spot.input_pickable = true

		if selected_spot == spot:
			select_spot(null)
			
# =====================================
# SPECIAL CHARACTER DEPLOYMENT
# =====================================

func _process(_delta: float) -> void:
	if choosing_deployment_location:
		deployment_preview.global_position = get_global_mouse_position()
		

func _on_deployment_start_ready() -> void:
	can_deploy_special = true
	
func _on_special_cooldown_finished() -> void:
	can_deploy_special = true
	
func begin_special_placement() -> void:
	if not can_deploy_special:
		return
	
	if choosing_deployment_location:
		return
	
	choosing_deployment_location = true
	deployment_preview.visible = true
	
func _unhandled_input(event: InputEvent) -> void:
	if not choosing_deployment_location:
		# Clicking anywhere else drops the spot selection and its build menu.
		# Clicking another spot selects it right after (physics picking runs later).
		if selected_spot and event is InputEventMouseButton and event.pressed:
			select_spot(null)
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_deploy_special_character(get_global_mouse_position())
			# Stop the same click from also building on a tower spot.
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_cancel_special_placement()
			get_viewport().set_input_as_handled()
			
func _deploy_special_character(location: Vector2) -> void:
	if not can_deploy_special:
		return
	
	var character = SPECIAL_CHARACTER_SCENE.instantiate()
	
	add_child(character)
	character.global_position = location
	character.apply_level(GameProgress.special_level)
	character.activate()
	
	can_deploy_special = false
	choosing_deployment_location = false
	deployment_preview.visible = false
	
	var stats = SPECIAL_CHARACTER_SCRIPT.stats_for_level(GameProgress.special_level)
	special_cooldown_timer.wait_time = maxf(1.0, special_cooldown - stats["cooldown_reduction"])
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
	# Match the range upgrade bought in the main menu.
	var stats = SPECIAL_CHARACTER_SCRIPT.stats_for_level(GameProgress.special_level)
	deployment_preview.scale = Vector2.ONE * stats["range_mult"]
	deployment_preview.z_index = 10

func update_health_bar(current_hp: int, max_hp: int) -> void:
	var health_bar = get_tree().current_scene.get_node("UI/HealthBar")
	health_bar.max_value = max_hp
	health_bar.value = current_hp


# =====================================
# BASE HIT FEEDBACK
# =====================================

var base_hit_overlay: ColorRect = null
var shake_tween: Tween = null


# Red screen flash + small shake of the map when an enemy gets through.
func _show_base_hit() -> void:
	if base_hit_overlay == null:
		var layer = CanvasLayer.new()
		layer.layer = 5
		add_child(layer)

		base_hit_overlay = ColorRect.new()
		base_hit_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		base_hit_overlay.color = Color(1.0, 0.0, 0.0, 0.0)
		base_hit_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(base_hit_overlay)

	base_hit_overlay.color.a = 0.25
	# Both tweens keep running while paused: the hit that ends the game
	# pauses the tree, and a frozen tween would leave the screen red.
	var flash_tween = base_hit_overlay.create_tween()
	flash_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	flash_tween.tween_property(base_hit_overlay, "color:a", 0.0, 0.3)

	if shake_tween and shake_tween.is_valid():
		shake_tween.kill()

	shake_tween = create_tween()
	shake_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)

	for i in range(4):
		var offset = Vector2(randf_range(-6, 6), randf_range(-6, 6))
		shake_tween.tween_property(self, "position", offset, 0.04)

	shake_tween.tween_property(self, "position", Vector2.ZERO, 0.04)

func _on_tower_dissolved(spot: Area2D) -> void:
	if not is_instance_valid(spot): return
	
	#keep the spot unavailable during recovery
	spot.set_meta("occupied", true)
	spot.visible = false
	spot.input_pickable = false
	
	#wait 4 seconds before allowing the rebuilding
	await get_tree().create_timer(4.0).timeout
	
	if is_instance_valid(spot):
		spot.set_meta("occupied", false)
		spot.visible = true
		spot.input_pickable = true
