extends Node3D
var player_scene = preload("res://Player.tscn")
@onready var players_node = $Players
var local_player: Player = null

@rpc("any_peer")
func spawn_player(peer_id: int, uname: String):
	var p = player_scene.instantiate()
	p.player_id = peer_id
	p.username = uname
	players_node.add_child(p)
	p.global_transform.origin = Vector3(randf() * 4 - 2, 0, randf() * 4 - 2) # random spawn

	if multiplayer.get_unique_id() == peer_id:
		local_player = p

func _ready():
	# Spawn all players in dictionary (from MultiplayerUI)
	var lobby = get_node("/root/MultiplayerUI_tscn") # replace with your UI node path
	for id in lobby.player_usernames.keys():
		spawn_player(id, lobby.player_usernames[id])
