class_name Game
extends Node

signal game_is_over

@export var world: World
@export var settings: GameSettings
@export var cheats: Cheats
@export var can_toggle_cheats: bool= true
@export var player_scene: PackedScene

@onready var camera = $Camera2D

var player: BasePlayer



func _init():
	Global.game= self
	

func _ready():
	if not cheats:
		cheats= Cheats.new()
	assert(settings)
	
	if not world:
		world= get_node_or_null("World")
		assert(world)
	
	set_process(false)
	await world.initialization_finished
	
	if not player:
		spawn_player()

	post_init()
	set_process(true)


func post_init():
	pass


func pre_start():
	return true


func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()

	elif Input.is_action_just_pressed("toggle_free_cam"):
		camera.free_cam= not camera.free_cam
		player.freeze= camera.free_cam

	elif Input.is_action_just_pressed("toggle_fly"):
		cheats.fly= not cheats.fly


func spawn_player():
	player= player_scene.instantiate()
	player.position= settings.player_spawn
	add_child(player)
	camera.follow_node= player

	player.tree_exited.connect(spawn_player if settings.respawn_on_death else game_over.bind(false))


func game_over(win: bool):
	game_is_over.emit(win)
