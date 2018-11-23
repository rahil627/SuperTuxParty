
enum TYPES {
	DICE,
	PLACABLE,
	ACTION
}

var type = ACTION
var is_consumed = true

var icon

func _init():
	icon = load(get_script().resource_path.get_base_dir() + "/icon.png")

func activate(player, controller):
	print("activate(Player, Controller) not overriden in item: %s" % get_path())
