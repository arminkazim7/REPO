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
		dir.z -= 1
	if Input.is_action_pressed("move_back"):
		dir.z += 1
	if Input.is_action_pressed("move_left"):
		dir.x -= 1
	if Input.is_action_pressed("move_right"):
		dir.x += 1

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
