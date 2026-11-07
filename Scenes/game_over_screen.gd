
extends PanelContainer

@onready var restart_button: Button = $VBoxContainer/RestartButton


func _ready() -> void:
	hide()

	# The tree is paused on game over; this panel must keep handling clicks.
	process_mode = Node.PROCESS_MODE_ALWAYS
	restart_button.pressed.connect(_on_restart_pressed)

	var map = owner.get_node_or_null("Map")

	if map:
		map.game_over.connect(_on_game_over)


func _on_game_over() -> void:
	show()
	get_tree().paused = true


func _on_restart_pressed() -> void:
	get_tree().paused = false
	ResourceManager.reset()
	get_tree().reload_current_scene()
