extends Resource
class_name Item

enum TYPES {
	DICE,
	PLACABLE,
	ACTION
}

var name: String

var type: int = TYPES.ACTION
var is_consumed := true

var can_be_bought := false
var item_cost := 0

var icon: Texture

# Used when placed onto board.
# Can only be placed 5 nodes in either direction onto the board, can be changed
# in subclasses.
var max_place_distance := 5

var material: Material

func _init(new_type: int, new_name: String) -> void:
	type = new_type
	name = new_name

	load_resources()

func load_resources() -> void:
	icon = load(get_script().resource_path.get_base_dir() + "/icon.png")

	if type == TYPES.PLACABLE:
		material = load(
				get_script().resource_path.get_base_dir() + "/material.tres")

func get_description() -> String:
	return "SHOP_ITEM_NO_DESCRIPTION"

func activate(_player, _controller):
	push_error("activate(Player, Controller) not overriden in item: %s" %
			get_path())

func activate_trap(_from_player, _trap_player, _controller):
	push_error("activate(Player, Controller) not overriden in item: %s" %
			get_path())

func recreate_state() -> void:
	load_resources()
