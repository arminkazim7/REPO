extends Control

@onready var address_input = $VBoxContainer/AddressInput
@onready var status_label = $VBoxContainer/StatusLabel
@onready var chat_log = $VBoxContainer/ChatBox/ChatLog
@onready var chat_input = $VBoxContainer/HBoxContainer2/ChatInput
@onready var send_button = $VBoxContainer/HBoxContainer2/SendButton
@onready var chat_messages = $VBoxContainer/ChatBox/ScrollContainer/ChatMessages
@onready var start_button = $VBoxContainer/StartButton

var username := "Player"
var player_usernames := {}   # Dictionary: peer_id → username

@onready var username_input = $VBoxContainer/UsernameInput

func _ready():
	$VBoxContainer/HBoxContainer/HostButton.pressed.connect(_on_host_pressed)
	$VBoxContainer/HBoxContainer/JoinButton.pressed.connect(_on_join_pressed)
	send_button.pressed.connect(_on_send_pressed)
	chat_input.text_submitted.connect(_on_chat_enter)
	start_button.pressed.connect(_on_start_button_pressed)
	if multiplayer.is_server():
		start_button.disabled = false
	else:
		start_button.disabled = true

func _on_start_button_pressed():
	if multiplayer.is_server():
		rpc("start_game")
		
@rpc("reliable", "call_local")
func start_game():
	var game_scene = load("res://GameScene.tscn").instantiate()
	get_tree().root.add_child(game_scene)
	self.visible = false
	#get_tree().current_scene.call_deferred("queue_free")  # safely free current scene
	
func _on_host_pressed():
	username = username_input.text.strip_edges()
	if username == "":
		username = "Player"
	var peer := ENetMultiplayerPeer.new()
	peer.create_server(7777)
	multiplayer.multiplayer_peer = peer

	status_label.text = "Hosting on port 7777..."
	print("[Server] Started")
	player_usernames[1] = username
	
func _on_join_pressed():
	var address = address_input.text.strip_edges()
	if username == "":
		username = "Player"
	if address == "":
		address = "127.0.0.1"

	var peer := ENetMultiplayerPeer.new()
	var result = peer.create_client(address, 7777)
	if result == OK:
		multiplayer.multiplayer_peer = peer
		status_label.text = "Connecting to %s..." % address
		print("[Client] Connecting")
		print("Joining server at %s" % address)
	else:
		status_label.text = "Failed to connect!"

# ---------- Multiplayer Callbacks ----------
func _enter_tree():
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func _on_connected():
	status_label.text = "Connected!"
	print("[Client] Connected")
	rpc_id(1, "register_username", multiplayer.get_unique_id(), username)
	
func _on_connection_failed():
	status_label.text = "Connection failed."
	print("[Client] FAILED")

func _on_server_disconnected():
	status_label.text = "Disconnected from server."
	print("[Client] DISCONNECTED")
	
func _on_send_pressed():
	_send_chat_message()
	
func _on_chat_enter(_text):
	_send_chat_message()
	
func _send_chat_message():
	var msg = chat_input.text.strip_edges()
	if msg == "":
		return
	chat_input.text = ""
	rpc_id(1, "server_receive_chat_message", multiplayer.get_unique_id(), msg)

@rpc("any_peer", "reliable", "call_local")
func server_receive_chat_message(sender_id: int, message: String):
	# Server relays message to all clients
	rpc("receive_chat_message", sender_id, message)

@rpc("any_peer", "reliable")
func register_username(peer_id: int, uname: String):
	if uname in player_usernames.values():
		uname += str(randi() % 1000)
	# Server only: store the username
	player_usernames[peer_id] = uname
	print(player_usernames.values())
	# Broadcast updated username list to all players
	rpc("update_username_list", player_usernames)
	
@rpc("reliable", "call_local")
func receive_chat_message(sender_id: int, message: String):
	var uname = player_usernames.get(sender_id, "Unknown")
	print("hello",message,uname)
	var line = "[%s]: %s" % [uname, message]
	chat_log.append_text(line + "\n")
	var label := Label.new()
	label.text = "[%s]: %s" % [str(uname), message]
	chat_messages.add_child(label)

	# Scroll to bottom
	await get_tree().process_frame
	$VBoxContainer/ChatBox/ScrollContainer.scroll_vertical = 999999
	
@rpc("reliable")
func update_username_list(name_dict: Dictionary):
	player_usernames = name_dict
	print("Updated usernames: ", player_usernames)
