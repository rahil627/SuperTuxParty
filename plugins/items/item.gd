extends Node

enum TYPES {
	DICE,
	PLACABLE,
	ACTION
}

var type = TYPES.ACTION
var is_consumed = true

var icon

# Used when placed onto board
var max_place_distance = 5 # Can only be placed 5 nodes in either direction onto the board, can be changed in subclasses

var material

func _init(type):
	self.type = type
	
	load_resources()

func load_resources():
	icon = load(get_script().resource_path.get_base_dir() + "/icon.png")
	
	if type == TYPES.PLACABLE:
		material = load(get_script().resource_path.get_base_dir() + "/material.tres")

func activate(player, controller):
	print("activate(Player, Controller) not overriden in item: %s" % get_path())

func recreate_state():
	load_resources()