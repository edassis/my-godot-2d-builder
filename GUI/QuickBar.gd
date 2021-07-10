class_name QuickBar
extends InventoryBar


## We override _make_panels() from the parent class to configure the label.
func _make_panels() -> void:
	# We create all the item slots as in the parent class, except we're going to instance
	# `QuickbarInventoryPanel`. Make a new item slot and add it as a child.
	for i in slot_count:
		var panel := InventoryPanelScene.instance()
		add_child(panel)
		# The inventory bar expects a list of `IventoryPanel` nodes to function.
		# So we make sure we get that node from each `QuickbarInventoryPanel` and
		# append it to the `panels`.
		panels.append(panel.get_node("InventoryPanel"))

		# Here's where we set the shortcut number on the label.
		var index := wrapi(i + 1, 0, 10)
		panel.get_node("Label").text = str(index)


func add_to_first_available_inventory(item: BlueprintEntity) -> bool:
	for inventory in inventories:
		if inventory.add_to_first_available_inventory(item):
			return true

	return false
