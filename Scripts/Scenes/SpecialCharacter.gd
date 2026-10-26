
extends Node2D

signal deployment_finished

@export var character_name: String = "Special Character"
@export var max_health: int = 100
@export var aoe_radius: float = 150.0
@export var damage: int = 10
@export var effect_interval: float = 1.0
@export var deployment_duration: float = 5.0
@export var cooldown_duration: float = 15.0
@export var start_delay: float = 10.0

@onready var body: Polygon2D = $Body
@onready var aoe_visual: Polygon2D = $AOEVisual
@onready var duration_timer: Timer = $DurationTimer

var health: int = 100
var effect_timer: float = 0.0
var is_deployed: bool = false


func _ready() -> void:
	health = max_health

	_create_circle(aoe_visual, aoe_radius)
	aoe_visual.color = Color(1.0, 0.2, 0.2, 0.2)

	duration_timer.one_shot = true
	duration_timer.wait_time = deployment_duration
	duration_timer.timeout.connect(_on_duration_finished)


func activate() -> void:
	if is_deployed:
		return

	is_deployed = true
	effect_timer = 0.0

	duration_timer.wait_time = deployment_duration
	duration_timer.start()


func _process(delta: float) -> void:
	if not is_deployed:
		return

	effect_timer += delta

	if effect_timer >= effect_interval:
		effect_timer = 0.0
		apply_aoe_effect()


func apply_aoe_effect() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue

		if global_position.distance_to(enemy.global_position) <= aoe_radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)


func take_damage(amount: int) -> void:
	health -= amount

	if health <= 0:
		_on_duration_finished()


func _on_duration_finished() -> void:
	if not is_deployed:
		return

	is_deployed = false
	duration_timer.stop()
	deployment_finished.emit()
	queue_free()


func _create_circle(polygon: Polygon2D, radius: float) -> void:
	var points = PackedVector2Array()
	var segments = 48

	for i in range(segments):
		var angle = TAU * float(i) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)

	polygon.polygon = points
