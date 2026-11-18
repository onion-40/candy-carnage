
extends Node

var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

const MENU_MUSIC = preload("res://Assets/Music/Menu.mp3")
const LEVEL_1_MUSIC = preload("res://Assets/Music/Lvl1.mp3")
const LEVEL_2_MUSIC = preload("res://Assets/Music/Lvl2.mp3")

const VICTORY_SOUND = preload("res://Assets/Music/victory.mp3")
const GAMEOVER_SOUND = preload("res://Assets/Music/GameOver.mp3")

func _ready() -> void:
	# Background music player
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	add_child(music_player)

	music_player.volume_db = -8.0
	play_music(MENU_MUSIC)

	# Sound effects player
	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SFXPlayer"
	sfx_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(sfx_player)


func play_music(music: AudioStream) -> void:
	if music_player.stream == music and music_player.playing:
		return

	music_player.stream = music
	music_player.play()


func play_victory_sound() -> void:
	sfx_player.stream = VICTORY_SOUND
	sfx_player.play()

func play_gameover_sound() -> void:
	sfx_player.stream = GAMEOVER_SOUND
	sfx_player.play()

func stop_music() -> void:
	music_player.stop()
