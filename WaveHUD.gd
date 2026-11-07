
extends PanelContainer

@onready var wave_label: Label = $VBoxContainer/WaveLabel
@onready var enemy_label: Label = $VBoxContainer/EnemyLabel
@onready var timer_label: Label = $VBoxContainer/TimerLabel

var map: Node2D

func _ready() -> void:
	map = get_tree().current_scene.get_node("Map")
	update_display()

func _process(_delta: float) -> void:
	if not is_instance_valid(map):
		return

	update_display()

func update_display() -> void:
	wave_label.text = "Wave: %d / %d" % [
		map.current_wave,
		map.total_waves
	]

	enemy_label.text = "Enemies Remaining: %d" % (
		map.enemies_to_spawn + map.enemies_alive
	)

	if map.is_game_over:
		timer_label.text = "GAME OVER"

	elif map.current_wave >= map.total_waves \
	and not map.wave_in_progress \
	and map.enemies_alive == 0:
		timer_label.text = "VICTORY!"

	elif map.wave_in_progress:
		timer_label.text = "Wave in progress"

	elif map.wave_break_timer.time_left > 0:
		timer_label.text = "Next wave: %.1f s" % (
			map.wave_break_timer.time_left
		)

	else:
		timer_label.text = "Preparing wave..."
