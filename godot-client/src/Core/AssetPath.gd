## AssetPath.gd
## Safe path joining with traversal prevention for external asset access.
##
## All paths are validated against the asset root to prevent:
## - Path traversal (../)
## - Absolute paths outside root
## - Symlink escapes
##
## All public methods return empty string if path is invalid.
class_name AssetPath
extends RefCounted

const ALLOWED_EXTENSIONS: Array[String] = [
	".webp",
	".png",
	".jpg",
	".jpeg",
	".gif",
	".json",
	".ttf",
	".otf",
	".css",
	".xml",
	".d2p",
	".db",
]


## Resolves a full path for an asset, validated against the asset root.
## Returns empty string if the path would escape the root.
static func resolve(kind: int, id: String) -> String:
	var root := AssetRoot.find_root()
	if root == "":
		return ""

	var folder := AssetKind.folder_for(kind)
	if folder == "":
		return ""

	var ext := AssetKind.extension_for(kind)
	var path_str := id

	# For image assets, the id is the filename (with extension) or base name
	if ext != "":
		if not id.ends_with(ext):
			path_str = id + ext

	var full_path := root.path_join(folder).path_join(path_str)

	# Validate the resolved path is within root
	if not _is_in_root(full_path, root):
		return ""

	return full_path


## Constructs a safe path joined from root and relative components.
## Path components must not contain traversal sequences.
static func join_safe(root: String, parts: Array) -> String:
	if root == "" or root == "invalid":
		return ""

	var result := root
	for part in parts:
		if part == "" or part == ".":
			continue
		if _contains_traversal(part):
			return ""
		result = result.path_join(part)

	if not _is_in_root(result, root):
		return ""

	return result


## Returns the file extension for a path (lowercase, with dot).
static func get_extension(path: String) -> String:
	var idx := path.rfind(".")
	if idx == -1:
		return ""
	return path.substr(idx).to_lower()


## Checks if an extension is allowed for asset loading.
static func is_allowed_extension(ext: String) -> bool:
	for allowed in ALLOWED_EXTENSIONS:
		if ext == allowed or ext == allowed.to_lower():
			return true
	return false


## Extracts the file name from a path.
static func get_filename(path: String) -> String:
	return path.get_file()


## Extracts the base name (file name without extension) from a path.
static func get_basename(path: String) -> String:
	var file := get_filename(path)
	var dot_idx := file.find(".")
	if dot_idx == -1:
		return file
	return file.substr(0, dot_idx)


## Validates that a path is within the allowed root directory.
static func _is_in_root(path: String, root: String) -> bool:
	if path == "" or root == "":
		return false

	# Normalize both paths
	var norm_path := path.replace("\\", "/").strip_edges()
	var norm_root := root.replace("\\", "/").strip_edges()

	if not norm_path.begins_with(norm_root):
		return false

	# Must be exactly root or have separator after root
	if norm_path == norm_root:
		return true
	if not norm_path.begins_with(norm_root + "/"):
		return false

	return true


## Checks if a path component contains traversal or absolute path markers.
static func _contains_traversal(part: String) -> bool:
	if part.find("..") != -1:
		return true
	if part.begins_with("/"):
		return true
	return false
