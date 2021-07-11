extends CenterContainer

## Each of the action as listed in the input map. We place them in an array so we
## can iterate over each one.
const QUICKBAR_ACTIONS := [
	"quickbar_1",
	"quickbar_2",
	"quickbar_3",
	"quickbar_4",
	"quickbar_5",
	"quickbar_6",
	"quickbar_7",
	"quickbar_8",
	"quickbar_9",
	"quickbar_0"
]

## Prefills the player inventory with objects from this dictionary
export var debug_items := {}

## A reference to the inventory that belongs to the 'mouse'. It is a property
## that gives indirect access to DragPreview's blueprint through its getter
## function. No one needs to know that it is stored outside of the GUI class.
var blueprint: BlueprintEntity setget _set_blueprint, _get_blueprint
## If `true`, it means the mouse is over the `GUI` at the moment.
var mouse_in_gui := false

onready var player_inventory := $HBoxContainer/InventoryWindow
## We use the reference to the drag preview in the setter and getter functions.
onready var _drag_preview := $DragPreview
## If `true`, it means the GUI window is open.
onready var _is_open: bool = $HBoxContainer/InventoryWindow.visible
## The parent container that holds the inventory window
onready var _gui_rect := $HBoxContainer
# onready var player_inventory := $HBoxContainer/InventoryWindow
onready var quickbar := $MarginContainer/QuickBar
# We'll use it later to reparent the `quickbar` node.
onready var quickbar_container := $MarginContainer


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		if _is_open:
			_close_inventories()
		else:
			_open_inventories()
	else:
		for i in QUICKBAR_ACTIONS.size():
			# If the action matches with one of our quickbar actions, we call
			# a function that simulates a mouse click at its location.
			if InputMap.event_is_action(event, QUICKBAR_ACTIONS[i]) and event.is_pressed():
				_simulate_input(quickbar.panels[i])
				# We break out of the loop, since there cannot be more than one
				# action pressed in the same event. We'd be wasting resources otherwise.
				break


## Simulates a mouse click at the location of the panel.
func _simulate_input(panel: InventoryPanel) -> void:
	# Create a new InputEventMouseButton and configure it as a left button click.
	var input := InputEventMouseButton.new()
	input.button_index = BUTTON_LEFT
	input.pressed = true

	# Provide it directly to the panel's `_gui_input()` function, as we don't care
	# about the rest of the engine intercepting this event.
	panel._gui_input(input)


# warning-ignore:unused_argument
func _process(delta: float) -> void:
	var mouse_position := get_global_mouse_position()
	# if the mouse is inside the GUI rect and the GUI is open, set it true.
	mouse_in_gui = _is_open and _gui_rect.get_rect().has_point(mouse_position)


## Shows the inventory window, crafting window
func _open_inventories() -> void:
	_is_open = true
	player_inventory.visible = true
	player_inventory.claim_quickbar(quickbar)


## Hides the inventory window, crafting window, and any currently open machine GUI
func _close_inventories() -> void:
	_is_open = false
	player_inventory.visible = false
	_claim_quickbar()


## Removes the quickbar from its current parent and puts it back under the
## quickbar's margin container
func _claim_quickbar() -> void:
	quickbar.get_parent().remove_child(quickbar)
	quickbar_container.add_child(quickbar)


func _ready() -> void:
	# Player can pick up an item from the floor.
	Events.connect("entered_pickup_area", self, "_on_entered_pickup_area")

	# Here, we'll set up any GUI systems that require knowledge of the GUI node.
	# We'll define `InventoryWindow.setup()` in the next lesson.
	player_inventory.setup(self)
	quickbar.setup(self)

	# ----- Debug system -----
	# We loop over all the keys in the `debug_items` dictionary and ensure they exist in the `Library`.
	for item in debug_items.keys():
		if not Library.blueprints.has(item):
			continue

		# If so, we instantiate the item and set its stack count to the value dictionary's value.
		var item_instance: Node = Library.blueprints[item].instance()
		item_instance.stack_count = min(item_instance.stack_size, debug_items[item])

		# We then try to add it to the inventory and if it's full, we free the leftover blueprint.
		if not add_to_inventory(item_instance):
			item_instance.queue_free()


func add_to_inventory(item: BlueprintEntity) -> bool:
	if item.get_parent() != null:
		item.get_parent().remove_child(item)

	if quickbar.add_to_first_available_inventory(item):
		return true

	return player_inventory.add_to_first_available_inventory(item)


## Forwards the `destroy_blueprint()` call to the drag preview.
func destroy_blueprint() -> void:
	_drag_preview.destroy_blueprint()


## Forwards the `update_label()` call to the drag preview.
func update_label() -> void:
	_drag_preview.update_label()


## Setter that forwards setting the blueprint to `DragPreview.blueprint`.
func _set_blueprint(value: BlueprintEntity) -> void:
	if not is_inside_tree():
		yield(self, "ready")
	_drag_preview.blueprint = value


## Getter that returns the DragPreview's blueprint.
func _get_blueprint() -> BlueprintEntity:
	return _drag_preview.blueprint


# Player's signal warning that he can pickup up an item.
func _on_entered_pickup_area(entity, player):
	if entity is GroundItem:
		add_to_inventory(entity.blueprint)
		entity.do_pickup(player)
