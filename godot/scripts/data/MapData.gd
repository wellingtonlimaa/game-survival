class_name MapData
extends Resource

@export var key: String = ""
@export var display_name: String = ""
@export var description: String = ""

@export_group("World Size")
@export var world_width: int = 3000
@export var world_height: int = 2100
@export var tile_size: int = 32

@export_group("Palette")
@export var ground_color: Color = Color(0.18, 0.27, 0.16)
@export var ground_variant_color: Color = Color(0.13, 0.21, 0.12)
@export var detail_color: Color = Color(0.10, 0.16, 0.09)
@export var border_color: Color = Color(0.04, 0.06, 0.04)
@export var fog_color: Color = Color(0.04, 0.04, 0.08, 0.0)

@export_group("Obstacles")
@export var obstacle_count: int = 120
@export var obstacle_kinds: PackedStringArray = ["tree"]
@export var obstacle_palette: PackedColorArray = [Color(0.08, 0.12, 0.07)]

@export_group("Landmarks")
@export var has_lake: bool = false
@export var has_ruin: bool = false
@export var has_boss_clearing: bool = true
@export var lake_color: Color = Color(0.10, 0.22, 0.34)
@export var ruin_color: Color = Color(0.36, 0.34, 0.40)

@export_group("Altars")
@export var altar_count: int = 5

@export_group("Ambient Particles")
@export var ambient_color: Color = Color(1.0, 0.882, 0.5, 0.35)
@export var ambient_count: int = 24
@export var ambient_speed: float = 0.45

@export_group("Music")
@export var music_track: String = "forest"
