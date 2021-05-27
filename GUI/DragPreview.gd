## A control that follows the mouse at all times to control the position of the
## blueprint sprite.
extends Control

## The blueprint object held by the drag preview. We use a setter function to
## ensure it's displayed on-screen.
var blueprint: BlueprintEntity setget _set_blueprint

## We need access to the label to display the stack count on-screen.
onready var count_label := $Label


func _ready() -> void:
	# The control will always stick to the mouse at all times. We don't want it
	# to be controlled by the GUI's CenterContainer. Otherwise, every frame, it
	# will be sent back to the middle of the screen.
	# Setting the node as `toplevel` makes its transform independent from its
	# parents.
	set_as_toplevel(true)

	var panel_size: float = ProjectSettings.get_setting("game_gui/inventory_size")
	rect_min_size = Vector2(panel_size, panel_size)
	rect_size = rect_min_size


## Events in `_input()` happen regardless of the state of the GUI and they
## happen first so this callback is ideal for global events like matching the
## mouse position on the screen.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if blueprint:
			blueprint.display_as_inventory_icon()
		# If the mouse moved, we set the control's global position to the
		# mouse's position on the screen.
		rect_global_position = event.global_position


## A helper function to keep the label up-to-date with the stack count. We can
## call this whenever the stack's amount changes.
func update_label() -> void:
	# If we have a blueprint and there is more than 1 item in the stack, we set
	# the text to the amount and show the label.
	if blueprint and blueprint.stack_count > 1:
		count_label.text = str(blueprint.stack_count)
		count_label.show()
	# If there's only one item in the stack, we hide the label.
	else:
		count_label.hide()


## This function both removes the blueprint from the scene tree, but also frees
## it and calls `update_label()`.
func destroy_blueprint() -> void:
	if blueprint:
		remove_child(blueprint)
		blueprint.queue_free()
		blueprint = null
		update_label()


## Whenever we change the blueprint, we need to make sure it's in the scene tree
## to display it on the screen.
func _set_blueprint(value: BlueprintEntity) -> void:
	if blueprint and blueprint.get_parent() == self:
		# If we already are holding a blueprint and its parent is this control,
		# we remove it from the scene tree. The panel will take care of cleaning
		# it up if it needs it.
		remove_child(blueprint)

	# We set the new blueprint and if it's not null, we add it as a child of
	# this control so it is displayed.
	blueprint = value
	if blueprint:
		add_child(blueprint)
		move_child(blueprint, 0)

	# We make sure its label is up to date with its stack size.
	update_label()
