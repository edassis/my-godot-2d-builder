extends TileMap

const MAXIMUM_WORK_DISTANCE := 275.0
const POSITION_OFFSET := Vector2(0,25)
const DECONSTRUCT_TIME := 0.3

## The ground item packed scene we instance when dropping items
var GroundItemScene := preload("res://Entities/GroundItem.tscn")

var _tracker: EntityTracker
var _ground: TileMap
var _flat_entities: Node2D
var _player: KinematicBody2D
var _current_deconstruct_location := Vector2.ZERO
var _gui: Control

onready var _deconstruct_timer := $Timer

func _unhandled_input(event: InputEvent) -> void:
	var global_mouse_position := get_global_mouse_position()

	var has_placeable_blueprint: bool = _gui.blueprint and _gui.blueprint.placeable
	var is_close_to_player := (
		global_mouse_position.distance_to(_player.global_position)
		< MAXIMUM_WORK_DISTANCE
	)

	var cellv := world_to_map(global_mouse_position)
	var cell_is_occupied := _tracker.is_cell_occupied(cellv)
	var is_on_ground := _ground.get_cellv(cellv) == 0

	if event is InputEventMouseButton:
		_abort_deconstruct()

	if event.is_action_pressed("left_click"):
		if has_placeable_blueprint:
			if not cell_is_occupied and is_close_to_player and is_on_ground:
				_place_entity(cellv)
				_update_neighboring_flat_entities(cellv)

	elif event.is_action_pressed("right_click") and not has_placeable_blueprint:
		if cell_is_occupied and is_close_to_player:
			_deconstruct(global_mouse_position, cellv)

	elif event is InputEventMouseMotion:
		if cellv != _current_deconstruct_location:
			_abort_deconstruct()
		if has_placeable_blueprint:
			_move_blueprint_in_world(cellv)
		else:
			_update_hover(cellv)

	elif event.is_action_pressed("drop") and _gui.blueprint:
		if is_on_ground:
			_drop_entity(_gui.blueprint, global_mouse_position)
			_gui.blueprint = null

	elif event.is_action_pressed("rotate_blueprint") and _gui.blueprint:
		_gui.blueprint.rotate_blueprint()


## Marks the `cell` as hovered if it's within the player's range.
func _update_hover(cellv: Vector2) -> void:
	var is_close_to_player := (
		get_global_mouse_position().distance_to(_player.global_position)
		< MAXIMUM_WORK_DISTANCE
	)

	# If the cell contains an entity and it's in range, we mark it as hovered.
	if _tracker.is_cell_occupied(cellv) and is_close_to_player:
		_hover_entity(cellv)
	else:
		_clear_hover_entity(cellv)


func _process(_delta: float) -> void:
	var has_placeable_blueprint: bool = _gui.blueprint and _gui.blueprint.placeable
	if has_placeable_blueprint and not _gui.mouse_in_gui:
		_move_blueprint_in_world(world_to_map(get_global_mouse_position()))


## Marks the `cellv`'s entity as hovered and emits the `hovered_over_entity`
## signal.
func _hover_entity(cellv: Vector2) -> void:
	var entity: Node2D = _tracker.get_entity_at(cellv)
	Events.emit_signal("hovered_over_entity", entity)


## Clears any hovered entity and signals the tooltip that we have nothing
## under the mouse.
func _clear_hover_entity(cellv: Vector2) -> void:
	Events.emit_signal("hovered_over_entity", null)


func setup(gui: Control, tracker: EntityTracker, ground: TileMap, flat_entities: YSort, player: KinematicBody2D) -> void:
	_gui = gui
	_tracker = tracker
	_ground = ground
	_player = player
	_flat_entities = flat_entities

	for child in get_children():
		if child is Entity:
			var map_position := world_to_map(child.global_position)
			_tracker.place_entity(child, map_position)


func _move_blueprint_in_world(cellv: Vector2) -> void:
	# Set the blueprint's position and scale back to origin
	_gui.blueprint.display_as_world_entity()

	# Snap the blueprint's position to the mouse with an offset, transformed into
	# viewport coordinates using `Transform2D.xform()`.
	_gui.blueprint.global_position = get_viewport_transform().xform(
		map_to_world(cellv) + POSITION_OFFSET
	)

	var is_close_to_player := (
		get_global_mouse_position().distance_to(_player.global_position)
		< MAXIMUM_WORK_DISTANCE
	)
	var is_on_ground: bool = _ground.get_cellv(cellv) == 0
	var cell_is_occupied := _tracker.is_cell_occupied(cellv)

	if not cell_is_occupied and is_close_to_player and is_on_ground:
		_gui.blueprint.modulate = Color.white
	else:
		_gui.blueprint.modulate = Color.red

	if _gui.blueprint is WireBlueprint:
		WireBlueprint.set_sprite_for_direction(_gui.blueprint.sprite, _get_powered_neighbors(cellv))


func _place_entity(cellv: Vector2) -> void:
	var entity_name := Library.get_entity_name_from(_gui.blueprint)
	var new_entity: Node2D = Library.entities[entity_name].instance()

	if _gui.blueprint is WireBlueprint:
		var directions := _get_powered_neighbors(cellv)
		_flat_entities.add_child(new_entity)
		WireBlueprint.set_sprite_for_direction(new_entity.sprite, directions)
	else:
		add_child(new_entity)

	new_entity.global_position = map_to_world(cellv) + POSITION_OFFSET
	new_entity._setup(_gui.blueprint)
	_tracker.place_entity(new_entity, cellv)

	if _gui.blueprint.stack_count == 1:
		_gui.destroy_blueprint()
	else:
		_gui.blueprint.stack_count -= 1
		_gui.update_label()


## Creates a new ground item with the given blueprint and sets it up at the
## deconstructed entity's location.
func _drop_entity(entity: BlueprintEntity, location: Vector2) -> void:
	# We instance a new ground item, add it, and set it up
	var ground_item := GroundItemScene.instance()
	add_child(ground_item)
	ground_item.setup(entity, location)


func _deconstruct(event_position: Vector2, cellv: Vector2) -> void:
	_deconstruct_timer.connect(
		"timeout", self, "_finish_deconstruct", [cellv], CONNECT_ONESHOT
	)
	_deconstruct_timer.start(DECONSTRUCT_TIME)
	_current_deconstruct_location = cellv


func _finish_deconstruct(cellv: Vector2) -> void:
	var entity := _tracker.get_entity_at(cellv)
	# Get the entity's name so we can check if we have access to a blueprint.
	var entity_name := Library.get_entity_name_from(entity)
	# We convert the map position to a global position.
	var location := map_to_world(cellv)
	# If we do have a blueprint, we get it as a packed scene.
	if Library.blueprints.has(entity_name):
		var Blueprint: PackedScene = Library.blueprints[entity_name]
		_drop_entity(Blueprint.instance(), location)

	_tracker.remove_entity(cellv)
	_update_neighboring_flat_entities(cellv)


func _abort_deconstruct() -> void:
	if _deconstruct_timer.is_connected("timeout", self, "_finish_deconstruct"):
		_deconstruct_timer.disconnect("timeout", self, "_finish_deconstruct")
	_deconstruct_timer.stop()


func _get_powered_neighbors(cellv: Vector2) -> int:
	var direction := 0

	for neighbor in Types.NEIGHBORS.keys():
		var key: Vector2 = cellv + Types.NEIGHBORS[neighbor]

		if _tracker.is_cell_occupied(key):
			var entity: Node = _tracker.get_entity_at(key)
			if (
				entity.is_in_group(Types.POWER_MOVERS)
				or entity.is_in_group(Types.POWER_RECEIVERS)
				or entity.is_in_group(Types.POWER_SOURCES)
			):
				direction |= neighbor

	return direction


func _update_neighboring_flat_entities(cellv: Vector2) -> void:
	for neighbor in Types.NEIGHBORS.keys():
		var key: Vector2 = cellv + Types.NEIGHBORS[neighbor]
		var object = _tracker.get_entity_at(key)

		if object and object is WireEntity:
			var tile_directions := _get_powered_neighbors(key)
			WireBlueprint.set_sprite_for_direction(object.sprite, tile_directions)
