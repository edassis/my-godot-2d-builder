## Class that represents a bar of inventory slots.
## Forwards function calls and signals from and to children.
class_name InventoryBar
extends HBoxContainer

# Emitted whenever a panel's item changed.
signal inventory_changed(panel, held_item)

## A scene resource for the inventory panel, a scene we'll create next and that represents
## individual item slots.
export var InventoryPanelScene: PackedScene

## How many panels to create as children of the bar.
export var slot_count := 10

## An array of references to the panels we create so we can refer to them and
## check their contents later.
var panels := []

func _ready() -> void:
	# Create the bar's panels first thing.
	_make_panels()


## Sets up each of the inventory panels and connects to their `held_item_changed` signal.
func setup(gui: Control) -> void:
	# For each panel we've created in `_ready()`, we forward the reference to the GUI node
	# and connect to their signal.
	for panel in panels:
		panel.setup(gui)
		panel.connect("held_item_changed", self, "_on_Panel_held_item_changed")


func add_to_first_available_inventory(item: BlueprintEntity) -> bool:
	for inventory in inventories:
		if inventory.add_to_first_available_inventory(item):
			return true

	return false


## Creates several inventory panel instances as a child of this horizontal bar.
## Adds them to the `panels` object variable.
func _make_panels() -> void:
	# For each slot
	for _i in slot_count:
		# Instance a panel, add it as a child, and add it to the `panels` array.
		var panel := InventoryPanelScene.instance()
		add_child(panel)
		panels.append(panel)


## Bubbles up the signal from the inventory bar up to the inventory window.
func _on_Panel_held_item_changed(panel: Control, held_item: BlueprintEntity) -> void:
	emit_signal("inventory_changed", panel, held_item)
