## Autoloaded class that associates blueprints to entities based on their
## filenames.
extends Node

## Path to the directory in which we store all the entities and blueprints. The
## node will loop over all the files in that directory and associate a given
## entity with a corresponding blueprint.
const BASE_PATH := "res://Entities"

## The following two constants store the suffixes we use on every blueprint and
## entities' filename. We will use them to check the end of a filename to
## distinguish entities from their blueprint.
const BLUEPRINT := "Blueprint.tscn"
const ENTITY := "Entity.tscn"

## This dictionary holds the entities keyed to their names.
var entities := {}
## The dictionary holds blueprints keyed to their names.
var blueprints := {}


func _ready() -> void:
	# Begin the search through the filesystem to find all blueprints and
	# entities.
	_find_entities_in(BASE_PATH)


## Find out what the name of a given node is to look it up in the blueprints or
## entities dictionary. Returns a blank string for nodes that are null or do not
## have an associated scene.
func get_entity_name_from(node: Node) -> String:
	# If the provided node is not null
	if node:
		# First, check if it already has a provided name with an overriden function
		# `get_entity_name()`. This will allow something like a TreeEntity to drop
		# lumber even if it's called TreeEntity.
		if node.has_method("get_entity_name"):
			return node.get_entity_name()

		# If it does not have an overridden name, then take its actual scene
		# filename, which comes in the format `res://...scene.tscn`, and get
		# only the name.
		# We find the last `/` and get everything after that. Then, we remove
		# `Blueprint.tscn` and `Entity.tscn` from the string to get a name like
		# our dictionaries expect.
		var filename := node.filename.substr(node.filename.rfind("/") + 1)
		filename = filename.replace(BLUEPRINT, "").replace(ENTITY, "")

		return filename
	return ""


## Recursively searches the provided directory and finds all files that end
## with `BLUEPRINT` or `ENTITY`. Populates the `blueprints` and `entities`
## dictionaries with them.
func _find_entities_in(path: String) -> void:
	# Open a `Directory` object to the provided path. The `Directory` object lets us
	# analyze filenames.
	var directory := Directory.new()
	var error := directory.open(path)

	# If we encounter an error, it's likely because the directory does not exist.
	if error != OK:
		print("Library Error: %s" % error)
		return

	# `list_dir_begin()` prepares the directory for scanning files one at a time.
	error = directory.list_dir_begin(true, true)

	# If we encounter an error, there might be something wrong with the directory.
	if error != OK:
		print("Library Error: %s" % error)
		return

	# We get the first filename in the list.
	var filename := directory.get_next()

	# `Directory.get_next()` returns an empty string when we reached the end of
	# the directory. We can use that to keep our loop going until we have no
	# more files to scan.
	while not filename.empty():
		# If the current object in directory is a directory, then we recursively
		# call this function to find all the files in _that_ sub-directory.
		if directory.current_is_dir():
			_find_entities_in("%s/%s" % [directory.get_current_dir(), filename])
		else:
			# If the file ends with `Blueprint.tscn`
			if filename.ends_with(BLUEPRINT):
				# We take the entire filename (e.g. StirlingEngineBlueprint.tscn)
				# and create a string that only contains the name
				# (StirlingEngine). We use that name as the key for an entry in
				# the dictionary. The value is a PackedScene resource we load so
				# we can instance it later.
				blueprints[filename.replace(BLUEPRINT, "")] = load(
					"%s/%s" % [directory.get_current_dir(), filename]
				)
			# We do the same if the file ends with `Entity.tscn`
			if filename.ends_with(ENTITY):
				entities[filename.replace(ENTITY, "")] = load(
					"%s/%s" % [directory.get_current_dir(), filename]
				)
		# To keep the loop going, we get the next filename in the directory and
		# repeat, until we reached the last entry.
		filename = directory.get_next()
