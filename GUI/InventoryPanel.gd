## Represents a slot that can hold an item.
## We keep track of the held item and its stack size by adding it as a child of the inventory slot.
class_name InventoryPanel
extends Panel

## We emit this signal whenever the item on this panel changes. We'll bubble it up
## to the GUI node so it can make other systems react to inventory changes.
## The `panel` argument below is this node.
signal held_item_changed(panel, item)

## A reference to the entity currently held by the panel. It can be `null` if there is none.
var held_item: BlueprintEntity setget _set_held_item

## We'll store a reference to the main GUI node to access the mouse's inventory.
var gui: Control

## We'll keep track of the stack size using the label.
onready var count_label := $Label


func _ready() -> void:
	var panel_size: float = ProjectSettings.get_setting("game_gui/inventory_size")

	# Force the panel's size and min size to match the project setting.
	rect_min_size = Vector2(panel_size, panel_size)
	rect_size = rect_min_size


## Store a reference to the GUI so we can access the mouse's inventory.
func setup(_gui: Control) -> void:
	gui = _gui


## Sets the panel's currently held item, notifies anyone connected of it, and
## updates the stack counter.
func _set_held_item(value: BlueprintEntity) -> void:
	# If we already have an item, remove it. Holding a reference to the old object
	# is the responsibility of whoever is changing it.
	#
	# In other places in the GUI we've used `if blueprint` or `if held_item`,
	# and it worked fine. But entities may free the held item on the inventory panel.
	# As of Godot 3.2.4, freed objects are not necessarily false, so we use
	# `is_instance_valid()` for the sake of safety and prevent crashes.
	if is_instance_valid(held_item) and held_item.get_parent() == self:
		remove_child(held_item)

	held_item = value

	# If the `held_item` is not `null`, add it as a child and make sure that it appears
	# behind the label.
	if is_instance_valid(held_item):
		add_child(held_item)
		move_child(held_item, 0)
		held_item.display_as_inventory_icon()

	# We update the stack count label.
	_update_label()
	# And we notify any subscribers that we've changed what item is in this panel.
	emit_signal("held_item_changed", self, held_item)


## Updates the label with the stack's current amount. If it's only 1 or there is
## no item, we hide the label.
func _update_label() -> void:
	var can_be_stacked := is_instance_valid(held_item) and held_item.stack_count > 1

	if can_be_stacked:
		count_label.text = str(held_item.stack_count)
		count_label.show()
	else:
		count_label.text = str(1)
		count_label.hide()


func _gui_input(event: InputEvent) -> void:
	var left_click := event.is_action_pressed("left_click")
	var right_click := event.is_action_pressed("right_click")

	if left_click or right_click:
		if gui.blueprint:
			var blueprint_name := Library.get_entity_name_from(gui.blueprint)
			if held_item:
				var held_item_name := Library.get_entity_name_from(held_item)

				var item_is_same_type: bool = held_item_name == blueprint_name
				var stack_has_space: bool = held_item.stack_count < held_item.stack_size

				if item_is_same_type and stack_has_space:
					if left_click:
						_stack_items()
					elif right_click:
						_stack_items(true)
				else:
					if left_click:
						_swap_items()
			else:
				if left_click:
					_grab_item()
				elif right_click:
					if gui.blueprint.stack_count > 1:
						_grab_split_items()
					else:
						_grab_item()
		elif held_item:
			if left_click:
				_release_item()
			elif right_click:
				if held_item.stack_count == 1:
					_release_item()
				else:
					_split_items()

	elif event is InputEventMouseMotion and is_instance_valid(held_item):
		Events.emit_signal("hovered_over_entity", held_item)


## Gets an item from the mouse and stores it in the `held_item` variable.
func _stack_items(split := false) -> void:
	# We first calculate the smaller number between half the mouse's stack and the amount of space
	# left on the current stack. We don't want to go over or grab more than the mouse has,
	# which is why we pick the smaller number.
	var count := int(
		min(
			gui.blueprint.stack_count / (2 if split else 1),
			held_item.stack_size - held_item.stack_count
		)
	)

	# If we are splitting the mouse's stack, we reduce its `stack_count` by `count` and update
	# its label.
	if split:
		gui.blueprint.stack_count -= count
		gui.update_label()
	else:
		# If we are grabbing as much of the stack as possible, we reduce it by `count`
		# in case we don't have enough space for all of it.
		if count < gui.blueprint.stack_count:
			gui.blueprint.stack_count -= count
			gui.update_label()
		else:
			# Or if the stack is reduced to zero, we destroy it and remove it from the mouse.
			gui.destroy_blueprint()

	# Finally, we increase the held item's stack count by the calculated `count` and update
	# the label.
	held_item.stack_count += count
	_update_label()


## Takes the current held item's stack and swaps it with the mouse's.
func _swap_items() -> void:
	var item: BlueprintEntity = gui.blueprint
	# We set the mouse's blueprint to null here. This calls its setter and ensures
	# that the blueprint is removed from the scene tree, making it available
	# for the panel to add as a child.
	gui.blueprint = null

	# We store the current item temporarily in a variable. We're about to change
	# what `held_item` points to, but to complete our swap, we need to give this `current_item`
	# to the mouse's inventory.
	var current_item := held_item

	# We then swap the two items, first adding the mouse's item to this inventory slot.
	# Note the use of `self`. This ensures we call the setter as calling the property
	# directly from the instance does not call the setter.
	self.held_item = item
	gui.blueprint = current_item


## Grabs the item from the mouse and puts it into the panel's inventory.
func _grab_item() -> void:
	var item: BlueprintEntity = gui.blueprint

	# We make sure the blueprint has been released from the mouse so we can grab it.
	gui.blueprint = null
	self.held_item = item


## Releases the item from the panel and puts it into the mouse's inventory.
func _release_item() -> void:
	var item := held_item

	# We make sure the blueprint has been released from the panel so the mouse
	# can grab it.
	self.held_item = null
	gui.blueprint = item


## Splits the current panel's inventory's stack and gives half to the mouse's inventory.
func _split_items() -> void:
	# We calculate half of the current stack.
	var count := int(held_item.stack_count / 2.0)

	# We then create a brand new `BlueprintEntity` and set its stack size to what we've calculated.
	# We also reduce the current one by that amount.
	var new_stack := held_item.duplicate()
	new_stack.stack_count = count
	held_item.stack_count -= count

	# Finally, we give the mouse the new stack and update the label.
	gui.blueprint = new_stack
	_update_label()


## Splits the mouse's inventory stack and takes half of it into this item slot.
## The logic is similar to `_split_items()` above, but reversed as we take the
## item from the mouse this time.
func _grab_split_items() -> void:
	var count := int(gui.blueprint.stack_count / 2.0)

	var new_stack: BlueprintEntity = gui.blueprint.duplicate()
	new_stack.stack_count = count

	gui.blueprint.stack_count -= count
	gui.update_label()

	self.held_item = new_stack


#func _update_hover():
#
#
### Marks the `cellv`'s entity as hovered and emits the `hovered_over_entity`
### signal.
#func _hover_entity(cellv: Vector2) -> void:
#	var entity: Node2D = _tracker.get_entity_at(cellv)
#	Events.emit_signal("hovered_over_entity", entity)
#
#
### Clears any hovered entity and signals the tooltip that we have nothing
### under the mouse.
#func _clear_hover_entity(cellv: Vector2) -> void:
#	Events.emit_signal("hovered_over_entity", null)
