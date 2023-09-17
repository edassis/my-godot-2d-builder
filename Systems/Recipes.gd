class_name Recipes
extends Reference


## We store crafting recipes in this constant. We can refer to this from the
## crafting GUI to determine what the player can craft with what they have and
## then craft it.
##
## Each recipe is keyed to the kind of entity it creates, with the value being a
## dictionary with `inputs`, a dictionary of items and their required amount.
## The `amount` key tells us how many items the recipe produces.
const Crafting := {
	StirlingEngine = {inputs = {"Ingot": 8, "Wire": 3}, amount = 1},
	Wire = {inputs = {"Ingot": 2}, amount = 5},
	Battery = {inputs = {"Ingot": 12, "Wire": 5}, amount = 1}
}
