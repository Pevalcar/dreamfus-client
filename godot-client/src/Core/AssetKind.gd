## AssetKind.gd
## Asset kind catalog: maps Kind → folder + expected extension.
## This file has NO external dependencies: just a pure class.
##
## Usage:
##   var ext = AssetKind.extension_for(AssetKind.Kind.ITEMS)   # ".webp"
##   var folder = AssetKind.folder_for(AssetKind.Kind.SPELLS)  # "d3spells"
##
## DreamFus uses numeric ids as filenames (gid → 100001.webp).

class_name AssetKind
extends RefCounted


## The kinds the game knows about.
## Maps are deferred to phase 3 (d2p container format).
enum Kind {
	INVALID = -1,
	UI,       # d3ui/img, manifest.json, uss/
	FONTS,    # uitk/fonts/ (ttf/otf)
	THEME,    # uitk/theme.css, fonts.css
	UXML,     # uitk/uxml/*.json
	PICTO,    # d3picto/ (index.json + subdirs)
	AUDIO,    # d3audio/ (index.json, sounds/)
	ITEMS,    # d3items/ (<gid>.webp)
	SPELLS,   # d3spells/ (<spellId>.png)
	WORLD,    # d3world/
	WORLDMAP, # d3worldmap/
	FX,       # d3fx/
	MAPS,     # d3maps/ (<mapId>.d2p - phase 3 container)
}


## Mapping Kind → folder (relative to Alea root).
const FOLDER: Dictionary = {
	Kind.UI:       "d3ui",
	Kind.FONTS:    "uitk/fonts",
	Kind.THEME:    "uitk",
	Kind.UXML:     "uitk/uxml",
	Kind.PICTO:    "d3picto",
	Kind.AUDIO:    "d3audio",
	Kind.ITEMS:    "d3items",
	Kind.SPELLS:   "d3spells",
	Kind.WORLD:    "d3world",
	Kind.WORLDMAP: "d3worldmap",
	Kind.FX:       "d3fx",
	Kind.MAPS:     "d3maps",
	Kind.INVALID:  "",
}


## Expected extension for text/json assets (null = directory itself).
const EXT_JSON: String = ".json"
const EXT_WEBP: String = ".webp"
const EXT_PNG:  String = ".png"
const EXT_D2P:  String = ".d2p"


static func folder_for(kind: Kind) -> String:
	return FOLDER.get(kind, "")


static func extension_for(kind: Kind) -> String:
	match kind:
		Kind.UI, Kind.THEME:
			return EXT_JSON
		Kind.UXML, Kind.AUDIO:
			return EXT_JSON
		Kind.FONTS, Kind.PICTO:
			return EXT_JSON  # directories or json files inside
		Kind.ITEMS:
			return EXT_WEBP
		Kind.SPELLS:
			return EXT_PNG
		Kind.MAPS:
			return EXT_D2P  # Phase 3 container format
		_:
			return ""


static func is_image(kind: Kind) -> bool:
	return kind == Kind.ITEMS or kind == Kind.SPELLS


static func is_json(kind: Kind) -> bool:
	return kind == Kind.UI or kind == Kind.THEME or kind == Kind.UXML or kind == Kind.AUDIO


static func is_directory(kind: Kind) -> bool:
	# PICTO has sub-folders, FONTS is a directory, WORLD/WORLDMAP/FX directories
	return kind == Kind.PICTO or kind == Kind.FONTS or kind == Kind.WORLD or kind == Kind.WORLDMAP or kind == Kind.FX


## Human-readable name for logging.
static func name_of(kind: Kind) -> String:
	return kindToString.get(kind, "invalid")


const kindToString: Dictionary = {
	Kind.UI:       "UI",
	Kind.FONTS:    "fonts",
	Kind.THEME:    "theme",
	Kind.UXML:     "uxml",
	Kind.PICTO:    "picto",
	Kind.AUDIO:    "audio",
	Kind.ITEMS:    "items",
	Kind.SPELLS:   "spells",
	Kind.WORLD:    "world",
	Kind.WORLDMAP: "worldmap",
	Kind.FX:       "fx",
	Kind.MAPS:     "maps",
	Kind.INVALID:  "invalid",
}