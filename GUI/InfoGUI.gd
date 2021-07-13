extends PanelContainer

## A constant amount of pixels to nudge the panel up and to the right by.
## That way, it isn't directly under the mouse.
const OFFSET := Vector2(25, -25)

## The current entity being hovered. Whenever the mouse moves, a new signal will
## be triggered even if the mouse did not move off of the current entity. This
## would result in unwanted flicker. We keep track of the current entity so we
## can choose not to update if we don't need to.
var current_entity: Node

onready var label := $MarginContainer/Label


func _ready() -> void:
	# Just like the drag preview, the label will be forever glued to the mouse
	# position. We don't want it to be affected by its GUI parent.
	set_as_toplevel(true)

	# Connect to the events we added to the event bus.
	Events.connect("hovered_over_entity", self, "_on_hovered_over_entity")
	Events.connect("info_updated", self, "_on_info_updated")
	# Make sure that the tooltip is out of the way when the game first starts.
	hide()


## Every frame, make sure that the panel is by the mouse.
func _process(_delta: float) -> void:
	rect_global_position = get_global_mouse_position() + OFFSET


## Display the name of the entity and any special text that should accompany it.
func _set_info(entity: Node) -> void:
	# Get the name of the entity, then use the `capitalize()` function to turn
	# it into a human readable format. It replaces underscores with spaces and
	# splits camel case. So our StirlingEngine will become Stirling Engine.
	var entity_filename: String = Library.get_entity_name_from(entity).capitalize()
	var output := entity_filename

	# If the entity is a blueprint, get its description and append it to the
	# name on a new line.
	if entity is BlueprintEntity:
		output += "\n%s" % entity.description
	else:
		# Otherwise, attempt to get the entity's data using a `get_info()`
		# method, but only if it exists, and append the result onto a new line.
		if entity.has_method("get_info"):
			var info: String = entity.get_info()
			if not info.empty():
				output += "\n%s" % info

	label.text = output
	# We finally make the tooltip visible as it now has text to display.
	show()


## Sets or clears the current entity, and either shows or hides the label
## depending if there is an entity or not.
func _on_hovered_over_entity(entity: Node) -> void:
	# Keep up to date on which entity is currently being hovered.
	if not entity == current_entity:
		current_entity = entity

	# If there is no entity, clear the text and hide the label.
	if not entity:
		label.text = ""
		hide()
	# if there is one, set the text and reset the size of the label.
	else:
		_set_info(entity)
		# We use `set_deferred()` to attempt to resize the panel to `0` *next
		# frame*. Changing the rect_size of a container to 0 will force it to
		# update to its minimum size, which should fit the label snuggly.
		#
		# We use `set_deferred()` because we are changing the text this frame,
		# but the GUI system is only going to be aware of the new text size next
		# frame.
		set_deferred("rect_size", Vector2.ZERO)


## Updates the information label if the current entity matches the provided
## entity.
func _on_info_updated(entity: Node) -> void:
	# Only update the text if what we're showing is the current entity's.
	if current_entity and entity == current_entity:
		_set_info(current_entity)
		# Force-reset the size of the container around the label.
		set_deferred("rect_size", Vector2.ZERO)
