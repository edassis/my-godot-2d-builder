class_name BlueprintEntity
extends Node2D

## Whether the player can place this object in the world. For example, a lumber axe.
## should not be 'placed' like a machine.
export var placeable := true

## How many items can be in a stack of the given blueprint type.
export var stack_size := 1

# Improvement: Use this instead of stack_count to define the quantity of salvagable
# items.
export var salvagable_qtd := 1

## Provides a field for information about the blueprint item. What it is and what
## it is used for.
export(String, MULTILINE) var description := ""

## How many items are actually in the stack of the current stack.
var stack_count := 1

## We use `find_node()` to search for a `PowerDirection` instance. If it does not exist,
## then we don't worry about it: `find_node()` returns `null` if it finds nothing.
## A faster method would be `get_node()`, which only tests one path.
onready var _power_direction := find_node("PowerDirection")


## Rotate the blueprint's direction, if it has one and it is relevant.
func rotate_blueprint() -> void:
	if not _power_direction:
		return

	# Get the current directions flags.
	var directions: int = _power_direction.output_directions
	# Initialize the new direction value at 0.
	var new_directions := 0

	# Below, we check for each `Types.Direction` against the `directions` value.
	# If a direction is included in the `directions` flag, we "rotate" it using the
	# bitwise pipe operator `|`.
	# LEFT becomes UP
	if directions & Types.Direction.LEFT != 0:
		new_directions |= Types.Direction.UP

	# UP becomes RIGHT
	if directions & Types.Direction.UP != 0:
		new_directions |= Types.Direction.RIGHT

	# RIGHT becomes DOWN
	if directions & Types.Direction.RIGHT != 0:
		new_directions |= Types.Direction.DOWN

	# DOWN becomes LEFT
	if directions & Types.Direction.DOWN != 0:
		new_directions |= Types.Direction.LEFT

	# Set the new direction, which should set the arrow sprites
	_power_direction.output_directions = new_directions


## Sets the position and scale of the blueprint to fit inventory panels and hides
## world-specific sprites like the power direction indicators.
func display_as_inventory_icon() -> void:
	# We can retrieve the panel size from the project settings by calling `ProjectSettings.get_setting()`
	# It takes a path to the property as its argument, which works like node property paths.
	var panel_size: float = ProjectSettings.get_setting("game_gui/inventory_size")

	# Set the position. Horizontally, it's halfway across. Vertically,
	# we move the graphics and collision so that the machine's origin is on the
	# tile's floor. With our isometric graphic style, this corresponds to 75% of the height.
	position = Vector2(panel_size * 0.5, panel_size * 0.75)

	# The sprites for blueprints are 100x100, so the scale is the desired size divided by 100.
	scale = Vector2(panel_size / 100.0, panel_size / 100.0)

	# We modulate the blueprint when it's in an invalid location, but we don't want it to stay
	# that color in the inventory. So we reset the modulate color to white.
	modulate = Color.white

	# In the inventory, we need to hide the power indicator if this node has one.
	if _power_direction:
		_power_direction.hide()


## This function resets the blueprint's scale, position offset, and power indicators to display
## in the game world.
func display_as_world_entity() -> void:
	scale = Vector2.ONE
	position = Vector2.ZERO
	if _power_direction:
		_power_direction.show()
