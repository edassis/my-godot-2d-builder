extends Node

## Signal emitted when the player places an entity, passing the entity and its
## position in map coordinates
signal entity_placed(entity, cellv)

## Signal emitted when the player removes an entity, passing the entity and its
## position in map coordinates
signal entity_removed(entity, cellv)

## Signal emitted when the simulation triggers the systems for updates.
signal systems_ticked(delta)

## Signal emitted when the player has arrived at an item that can be picked up
signal entered_pickup_area(entity, player)
