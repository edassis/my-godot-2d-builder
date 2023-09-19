extends PanelContainer

onready var recipe_name := $MarginContainer/HBoxContainer/Label
onready var sprite := $MarginContainer/HBoxContainer/GUISprite

## Sets up the sprite and label with the provided recipe data.
func setup(name: String, texture: Texture, uses_region_rect: bool, region_rect: Rect2) -> void:
	recipe_name.recipe_name = name
	sprite.texture = texture
	sprite.region_enabled = uses_region_rect
	sprite.region_rect = region_rect


func _on_CraftingRecipeItem_mouse_entered() -> void:
	var recipe_filename: String = recipe_name.recipe_name
	Events.emit_signal("hovered_over_recipe", recipe_filename, Recipes.Crafting[recipe_filename])


func _on_CraftingRecipeItem_mouse_exited() -> void:
	# We use the existing `hovered_over_entity` signal as a simple way to clear
	# the tooltip.
	Events.emit_signal("hovered_over_entity", null)
