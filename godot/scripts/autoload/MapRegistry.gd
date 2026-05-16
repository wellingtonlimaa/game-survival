extends Node

const MAP_PATHS := {
	"forest":    "res://resources/maps/forest.tres",
	"graveyard": "res://resources/maps/graveyard.tres",
	"ermos":     "res://resources/maps/ermos.tres",
}

const DEFAULT_KEY := "forest"

var cache: Dictionary = {}
var selected_key: String = DEFAULT_KEY


func _ready() -> void:
	selected_key = String(SaveSystem.get_value("selected_map", DEFAULT_KEY))


func all_keys() -> Array:
	return MAP_PATHS.keys()


func get_map(key: String) -> Resource:
	if key == "" or not MAP_PATHS.has(key):
		key = DEFAULT_KEY
	if cache.has(key):
		return cache[key]
	var res := load(MAP_PATHS[key])
	cache[key] = res
	return res


func selected_map() -> Resource:
	return get_map(selected_key)


func select(key: String) -> void:
	if not MAP_PATHS.has(key):
		key = DEFAULT_KEY
	selected_key = key
	SaveSystem.set_value("selected_map", key)
