extends Node3D
var player_scene = preload("res://Player.tscn")
@onready var players_node = $Players
var local_player: Player = null

@rpc("authority")
func _spawn_player(peer_id: int, uname: String):
	if players_node.has_node(str(peer_id)):
		print("Player already exists:", peer_id)
		return  # already spawned
	var p = player_scene.instantiate()
	p.name = str(peer_id) 
	p.player_id = peer_id
	p.username = uname
	p.add_to_group("players")
	players_node.add_child(p)
	p.global_transform.origin = Vector3(randf() * 4 - 2, 0, randf() * 4 - 2) # random spawn
	print("Spawning player:", peer_id, "uname:", uname)
	if multiplayer.get_unique_id() == peer_id:
		local_player = p
		
@rpc("any_peer", "reliable")
func rpc_spawn_player(peer_id: int, uname: String):
	_spawn_player(peer_id, uname)
	
func _ready():
	var root = get_tree().current_scene
	print("Active scene root is:", root.name)
	print("Yolo")
	# Spawn all players in dictionary (from MultiplayerUI)
	if multiplayer.is_server():
		print("Server ready:", multiplayer.get_unique_id())
		for id in LobbyData.player_usernames.keys():
			_spawn_player(id, LobbyData.player_usernames[id])
			print("hi2",id)
			rpc_id(0,"rpc_spawn_player", id, LobbyData.player_usernames[id])
	else:
		print("Client ready:", multiplayer.get_unique_id())

@rpc("any_peer")
func request_interact(player_pos: Vector3):
	var sender_id := multiplayer.get_remote_sender_id()
	# Validate distance to item
	print("request interact in gamescene")
	for item in get_tree().get_nodes_in_group("interactable"):
		print("hi0",player_pos,item.global_transform,item.global_transform.origin.distance_to(player_pos))
		if item.global_transform.origin.distance_to(player_pos) < 2.0:
			# FIND THE PLAYER NODE THAT MATCHES THE SENDER
			print("in range")
			for player in get_tree().get_nodes_in_group("players"):
				print("sender id and player id were:",sender_id," ",player.player_id)
				if sender_id == 0:
						sender_id=1
				if player.player_id == sender_id:
					print("hi2")
					player.rpc_id(sender_id, "start_personal_scene")
					return
				
