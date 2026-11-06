## AssetRoot.gd
## Root resolution and validation for external Alea installation.
##
## Resolution order:
## 1. --asset-root command line argument
## 2. DREAMFUS_ASSET_ROOT environment variable
## 3. Sibling folder (production mode)
## 4. Dev fallback (C:\Users\pevalcar\AppData\Local\Alea)
##
## A valid root must contain:
## - .alea-content.json marker file
## - d3ui folder
## - d3audio folder
## - uitk folder

class_name AssetRoot
extends RefCounted


const MARKER_FILE: String = ".alea-content.json"
const DEV_FALLBACK: String = "C:/Users/pevalcar/AppData/Local/Alea"
const MARKERS: Array[String] = [
	"d3ui",
	"d3audio",
	"uitk",
	"d3maps"
]


## Returns the resolved asset root path, or empty string if not found.
static func find_root() -> String:
	# 1. Check command line argument
	var cmd_root := _parse_cmd_root()
	if cmd_root != "":
		return cmd_root
	
	# 2. Check environment variable
	var env_root := OS.get_environment("DREAMFUS_ASSET_ROOT")
	if env_root != "" and _validate_root(env_root):
		return env_root
	
	# 3. Check sibling folder (production)
	var exe_dir := OS.get_executable_path().get_base_dir()
	var sibling_path := exe_dir.path_join("Alea")
	if _validate_root(sibling_path):
		return sibling_path
	
	# 4. Check sibling folder directly (launcher mode)
	if _validate_root(exe_dir):
		return exe_dir
	
	# 5. Dev fallback
	if _validate_root(DEV_FALLBACK):
		return DEV_FALLBACK
	
	return ""


static func _parse_cmd_root() -> String:
	var args := OS.get_cmdline_args()
	for i in range(args.size()):
		if args[i].begins_with("--asset-root="):
			var path = args[i].get_slice("=", 1).strip_edges()
			if _validate_root(path):
				return path
	return ""


static func _validate_root(path: String) -> bool:
	if path == "":
		return false
	
	var dir := DirAccess.open(path)
	if dir == null:
		return false
	
	# Check marker file exists
	if not dir.file_exists(MARKER_FILE):
		return false
	
	# Check required folders exist
	for marker in MARKERS:
		if not dir.dir_exists(marker):
			return false
	
	return true


## Returns true if an external asset installation is available.
static func has_valid_root() -> bool:
	return find_root() != ""


## Returns the mode based on root availability.
enum Mode {
	NONE,      # No valid root found
	LOCAL,     # Valid external Alea installation
	DEV        # Using dev fallback
}

static func get_mode() -> Mode:
	var root = find_root()
	if root == "":
		return Mode.NONE
	if root == DEV_FALLBACK:
		return Mode.DEV
	return Mode.LOCAL


## Returns human-readable description of current root status.
static func get_status_description() -> String:
	var root = find_root()
	if root == "":
		return "No valid asset root found"
	if root == DEV_FALLBACK:
		return "Using dev fallback: " + DEV_FALLBACK
	return "Using external installation: " + root