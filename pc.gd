extends Node3D

var players_in_range = {}

func _ready():
	$Area3D.body_entered.connect(_on_body_entered)
	$Area3D.body_exited.connect(_on_body_exited)
	add_to_group("interactable")
func _on_body_entered(body):
	if body is Player:
		players_in_range[body.get_multiplayer_authority()] = body

func _on_body_exited(body):
	if body is Player:
		players_in_range.erase(body.get_multiplayer_authority())
