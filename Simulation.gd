extends Node

# The following constants hold the IDs of the purple block tile, named "barrier" below, and the
# and collision we'll replace it with.
# The IDs are generated by the GroundTiles' TileSet resource, and they depend on the order in which you created
# the tiles, starting with `0` for the first tile.
const BARRIER_ID := 1
const INVISIBLE_BARRIER_ID := 2

export var simulation_speed := 1.0 / 30.0

var _tracker := EntityTracker.new()

onready var _entity_placer := $GameWorld/YSort/EntityPlacer
onready var _player := $GameWorld/YSort/Player
# The GroundTiles node is the tilemap that holds our floor, where we want to replace
# the purple blocks with invisible barriers.
onready var _ground := $GameWorld/GroundTiles
onready var _flat_entities := $GameWorld/FlatEntities
onready var _power_system := PowerSystem.new()
onready var _gui := $CanvasLayer/GUI

func _ready() -> void:
	#$Timer.start(simulation_speed)
	_entity_placer.setup(_gui, _tracker, _ground, _flat_entities, _player)
	# Get an array of all tile coordinates that use the purple barrier block.
	var barriers: Array = _ground.get_used_cells_by_id(BARRIER_ID)

	# Iterate over each of those cells and replace them with the invisible barrier.
	for cellv in barriers:
		_ground.set_cellv(cellv, INVISIBLE_BARRIER_ID)


func _on_Timer_timeout() -> void:
	Events.emit_signal("systems_ticked", simulation_speed)