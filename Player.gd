class_name Player
extends Node3D

# Networking
var speed := 5.0
var username := "Player"
var player_id := 0

@onready var camera = $Camera3D
@onready var label: Label3D = $UsernameLabel

func _ready():
	# Only local player sets their camera as current
	if multiplayer.get_unique_id() == player_id:
		camera.current = true
	label.text = username

	# Make the label always face the camera
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED

func _process(delta):
	if multiplayer.get_unique_id() == player_id:
		_handle_input(delta)

func _handle_input(delta: float) -> void:
	var dir = Vector3.ZERO
	if Input.is_action_pressed("move_forward"):
		print("player_id",player_id)
		dir.z -= 1
	if Input.is_action_pressed("move_back"):
		dir.z += 1
	if Input.is_action_pressed("move_left"):
		dir.x -= 1
	if Input.is_action_pressed("move_right"):
		dir.x += 1
	if Input.is_action_just_pressed("interact"):  # 'P'
		var game_scene = get_tree().root.get_node("GameScene")
		if multiplayer.is_server():
			# If we are the server, just call directly
			game_scene.request_interact(global_transform.origin)
		else:
			game_scene.rpc_id(1, "request_interact", global_transform.origin)
	if dir != Vector3.ZERO:
		dir = dir.normalized() * speed * delta
		translate(dir)
		# Send position to server / peers
		print(multiplayer.multiplayer_peer)
		if multiplayer.multiplayer_peer != null:
			rpc("update_position", global_transform.origin)

# RPC for syncing position
@rpc("any_peer", "unreliable")
func update_position(pos: Vector3):
	if multiplayer.get_unique_id() != player_id:
		global_transform.origin = pos
		
@rpc("authority", "call_local")
func start_personal_scene():
	print("Hello will now start flappy bird maybe")
	#get_tree().change_scene_to_file("res://flappy.tscn")

@rpc("any_peer")
func request_interact(player_pos: Vector3):
	# server-side validation here
	print("hi")
