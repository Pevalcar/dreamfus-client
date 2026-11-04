# @class ServerInfo
# Información de servidores para la comunicación con el servidor

extends Resource
class_name ServerInfo

@export var id: int = 0
@export var name: String = ""
@export var population: int = 0
@export var is_full: bool = false


static func from_json(json: Dictionary) -> ServerInfo:
	var server := ServerInfo.new()
	if json.size() == 0:
		return server

	server.id = json.get("id", 0)
	server.name = json.get("name", "")
	server.population = json.get("population", 0)
	server.is_full = json.get("is_full", false)
	return server