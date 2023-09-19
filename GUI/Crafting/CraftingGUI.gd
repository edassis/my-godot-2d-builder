extends MarginContainer

## We preload the CraftingRecipeItem scene to instantiate it.
## We load it using its relative path. As it's in the same directory as this
## script, we only need the file's name.
const CraftingItem := preload("CraftingRecipeItem.tscn")

var gui: Control

onready var items := $PanelContainer/CraftingList/ScrollContainer/VBoxContainer

## We use this function to get a reference to the main GUI node, which, in turn,
## will give us functions to access the inventory.
func setup(_gui: Control) -> void:
	gui = _gui

## The main function that forces an update of all recipes based on what items
## are available in the player's inventory.
func update_recipes() -> void:
	# We free all existing recipes to start from a clean state.
	for child in items.get_children():
		child.queue_free()

	# We loop over every available recipe name.
	for output in Recipes.Crafting.keys():
		var recipe: Dictionary = Recipes.Crafting[output]

		var can_craft := true

		# For each required material in the recipe, we ensure the player has enough of it.
		# If not, they can't craft the item and we move to the next recipe.
		for input in recipe.inputs.keys():
			if not gui.is_in_inventory(input, recipe.inputs[input]):
				can_craft = false
				break

		if not can_craft:
			continue

		# We temporarily instance the blueprint to acess its sprite and data.
		var temp: BlueprintEntity = Library.blueprints[output].instance()

		# We then instantiate the recipe item and add it to the scene tree.
		var item := CraftingItem.instance()
		items.add_child(item)

		# We grab the blueprint's sprite.
		var sprite: Sprite = temp.get_node("Sprite")

		# And we use the sprite to set up the recipe item with the name,
		# texture, and sprite region information.
		item.setup(
			Library.get_entity_name_from(temp),
			sprite.texture,
			sprite.region_enabled,
			sprite.region_rect
		)

		# And finally, we free the temporary blueprint as we don't need it
		# anymore.
		temp.free()
