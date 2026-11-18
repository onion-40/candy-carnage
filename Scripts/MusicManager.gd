extends Node

var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

const MENU_MUSIC = preload("res://Assets/Music/Menu.mp3")
const GAME_MUSIC = preload("res://Assets/Music/Lvl1.mp3")

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	add_child(music_player)
	music_player.volume_db = -8.0

	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SFXPlayer"
	sfx_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(sfx_player)

	play_music(MENU_MUSIC)


func play_music(music: AudioStream) -> void:
	if music_player.stream == music and music_player.playing:
		return

	music_player.stream = music
	music_player.play()


func stop_music() -> void:
	music_player.stop()
