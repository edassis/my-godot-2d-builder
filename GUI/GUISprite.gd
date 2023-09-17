## The tool keyword makes Godot run the script in the editor.
tool
## Giving the class a name lets us instantiate this node in the scene tree.
class_name GUISprite
## Extending the Control class will make the sprite play nice with GUI
## containers without needing manual control from us.
extends Control


## The four properties below simulate those of `Sprite` nodes.
## Each uses a setter to update the node's bounds and draw the sprite correctly.
export var texture: Texture setget _set_texture
export var region_enabled: bool = false setget _set_region_enabled
export var region_rect: Rect2 = Rect2() setget _set_region_rect
export var scale := Vector2.ONE setget _set_scale


## Godot calls _draw() once when instantiating the node and toggling visibility.
## Otherwise, it displays whatever it drew last.
## To trigger a redraw, you can call the `CanvasItem.update()` method.
## We use Godot's drawing functions to draw the sprite either as a whole or with
## a region selected.
func _draw() -> void:
	if not texture:
		return

	if region_enabled:
		# Draws a texture within the node's bounding box. using the
		# `region_rect` to sample from the texture.
		#
		# Note that the `_draw()` function draws relative to its node's
		# position.
		# That's why we pass in `Vector2.ZERO` for the `Rect2`'s position below:
		# it means 'draw where this node is with no offset.'
		draw_texture_rect_region(texture, Rect2(Vector2.ZERO, rect_size), region_rect)
	else:
		# Draws the entire texture inside the given rectangle on screen.
		draw_texture_rect(texture, Rect2(Vector2.ZERO, rect_size), false)


## Each setter sets the provided value, then calls `_update_region()` to force
## an update to the `Control` values.
func _set_texture(value: Texture) -> void:
	texture = value
	_update_region()


func _set_region_enabled(value: bool) -> void:
	region_enabled = value
	_update_region()


func _set_region_rect(value: Rect2) -> void:
	region_rect = value
	_update_region()


func _set_scale(value: Vector2) -> void:
	scale = value
	_update_region()


# Sets the Control's minimum rectangle size and prompts a texture redraw.
func _update_region() -> void:
	if region_enabled:
		rect_min_size = region_rect.size * scale
	else:
		if texture:
			rect_min_size = texture.get_size() * scale
		else:
			rect_min_size = Vector2.ZERO

	# Asks Godot to call the `_draw()` function on the next drawing update.
	update()
