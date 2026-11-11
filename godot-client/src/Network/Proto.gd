## Protobuf utilities for the game protocol (TCP 5555)
## Implements VarInt encoding/decoding, field parsing, and envelope building.
## Compatible with Godot 4.8 (uses ByteArrayExtensions for byte array operations)
class_name Proto
extends RefCounted

## Preload ByteArrayExtensions helper para Godot 4.8
const ByteArrayExtensions = preload("res://src/Utils/ByteArrayExtensions.gd")

# Wire types
const WIRE_VARINT = 0
const WIRE_FIXED64 = 1
const WIRE_LENGTH_DELIMITED = 2
const WIRE_FIXED32 = 5


## Write a VarInt (unsigned) to the end of `buf`.
## Correctly implements protobuf VarInt encoding: 7 bits per byte, LSB first.
static func write_varint(buf: PackedByteArray, value: int) -> void:
	# Handle negative numbers by treating them as unsigned (zig-zag would be different)
	var v: int = value
	# For VarInt, we encode the raw bits - Godot handles int as signed
	# This works for positive values; for negative, we need to handle carefully
	if v < 0:
		# For negative values, we'll encode -1 (all 0xFF bytes) for simplicity
		# In practice, negative varints are encoded as their 64-bit unsigned representation
		v = 0xFFFFFFFFFFFFFFFF + v + 1 # Two's complement for 64-bit
	else:
		v = int(v) & 0xFFFFFFFFFFFFFFFF # Ensure positive
	while v > 0x7F:
		# Write 7 bits with continuation flag
		buf.append((v & 0x7F) | 0x80)
		v >>= 7
	buf.append(v & 0x7F)


## Read a VarInt. Returns [value, next_offset] or [null, offset] if incomplete.
static func read_varint(ba: PackedByteArray, start_pos: int) -> Array:
	if ba == null or start_pos < 0 or start_pos >= ba.size():
		return [null, start_pos]

	var pos = start_pos
	var result = 0
	var shift = 0

	while pos < ba.size():
		var byte = ba[pos]
		pos += 1
		# Combine 7 bits
		result |= (byte & 0x7F) << shift
		# Check continuation flag
		if (byte & 0x80) == 0:
			return [result, pos]
		shift += 7
		# Safety check to prevent infinite loops
		if shift > 35:
			return [null, start_pos]

	return [null, start_pos]


## Read a 32-bit fixed32 value (little-endian)
static func read_fixed32(ba: PackedByteArray, start_pos: int) -> Array:
	if ba == null or start_pos + 4 > ba.size():
		return [0, start_pos]
	var value = ba[start_pos] | (ba[start_pos + 1] << 8) | (ba[start_pos + 2] << 16) | (
		ba[start_pos + 3] << 24
	)
	return [value, start_pos + 4]


## Read a 64-bit fixed64 value (little-endian)
static func read_fixed64(ba: PackedByteArray, start_pos: int) -> Array:
	if ba == null or start_pos + 8 > ba.size():
		return [0, start_pos]
	var value = ba[start_pos] | (ba[start_pos + 1] << 8) | (ba[start_pos + 2] << 16) | (
		ba[start_pos + 3] << 24
	) | (ba[start_pos + 4] << 32) | (ba[start_pos + 5] << 40) | (ba[start_pos + 6] << 48) | (
		ba[start_pos + 7] << 56
	)
	return [value, start_pos + 8]


## Read a length-delimited field (string, bytes, message, etc.)
## Returns [bytes, next_offset] or [null, offset] if incomplete
static func read_length_delimited(ba: PackedByteArray, start_pos: int) -> Array:
	var len_result = read_varint(ba, start_pos)
	if len_result[0] == null:
		return [null, start_pos]

	var len = len_result[0]
	var next_pos = len_result[1]

	if next_pos + len > ba.size():
		return [null, start_pos]

	return [ByteArrayExtensions.byte_subarray(ba, next_pos, len), next_pos + len]


## Parse a message from a byte array with a given message parser function
## message_parser should be a static func that takes PackedByteArray and returns Dictionary
static func parse_message(ba: PackedByteArray, start_pos: int, message_parser: Callable) -> Array:
	var result = read_varint(ba, start_pos)
	if result[0] == null:
		return [null, start_pos]

	var len = result[0]
	var next_pos = result[1]

	if next_pos + len > ba.size():
		return [null, start_pos]

	var data = ByteArrayExtensions.byte_subarray(ba, next_pos, len)
	var message = message_parser.call(data)
	return [message, next_pos + len]


## Build a protobuf envelope with field number and value
## field_num: the field number (1-536870911)
## wire_type: the wire type (0=varint, 1=64bit, 2=length-delimited, 5=32bit)
## value: the value to encode
static func build_field(field_num: int, wire_type: int, value) -> PackedByteArray:
	var result = PackedByteArray()

	# Build tag: (field_num << 3) | wire_type
	var tag = (field_num << 3) | wire_type
	write_varint(result, tag)

	match wire_type:
		WIRE_VARINT:
			write_varint(result, value)
		WIRE_FIXED64:
			for i in range(8):
				result.append((value >> (i * 8)) & 0xFF)
		WIRE_LENGTH_DELIMITED:
			if value is PackedByteArray:
				write_varint(result, value.size())
				for b in value:
					result.append(b)
			elif value is String:
				var bytes = value.to_utf8_buffer()
				write_varint(result, bytes.size())
				for b in bytes:
					result.append(b)
		WIRE_FIXED32:
			for i in range(4):
				result.append((value >> (i * 8)) & 0xFF)

	return result


## Decode a complete message from a field
## This is a helper for decoding nested messages within a length-delimited field
static func decode_message(ba: PackedByteArray) -> Dictionary:
	# This is a generic decoder - specific formats should implement their own parsers
	var result = { }
	var pos = 0

	while pos < ba.size():
		var tag = ba[pos]
		var field_num = tag >> 3
		var wire_type = tag & 0x7
		pos += 1

		match wire_type:
			WIRE_VARINT:
				var varint_result = read_varint(ba, pos)
				if varint_result[0] != null:
					result["f%d" % field_num] = varint_result[0]
					pos = varint_result[1]
				else:
					break
			WIRE_FIXED64:
				var fixed_result = read_fixed64(ba, pos)
				result["f%d" % field_num] = fixed_result[0]
				pos = fixed_result[1]
			WIRE_LENGTH_DELIMITED:
				var len_result = read_varint(ba, pos)
				if len_result[0] != null:
					var len = len_result[0]
					pos = len_result[1] + len
				else:
					break
			WIRE_FIXED32:
				var fixed_result = read_fixed32(ba, pos)
				result["f%d" % field_num] = fixed_result[0]
				pos = fixed_result[1]
			_:
				break

	return result


## Build a request envelope: { f1: Any { f1: opcode_url, f2: payload }, f2: request_id }
static func request(
	opcode: String,
	payload: PackedByteArray = PackedByteArray(),
) -> PackedByteArray:
	var type_url := "type.ankama.com/%s" % opcode
	var any_msg := PackedByteArray()
	put_string(any_msg, 1, type_url)
	put_bytes(any_msg, 2, payload)

	var envelope := PackedByteArray()
	put_bytes(envelope, 1, any_msg)
	put_varint(envelope, 2, -1) # request_id = -1 for client requests

	return envelope


## Build a push envelope (server message): { f1: Any { f1: opcode_url, f2: payload } }
static func push(opcode: String, payload: PackedByteArray = PackedByteArray()) -> PackedByteArray:
	var type_url := "type.ankama.com/%s" % opcode
	var any_msg := PackedByteArray()
	put_string(any_msg, 1, type_url)
	put_bytes(any_msg, 2, payload)

	var envelope := PackedByteArray()
	put_bytes(envelope, 1, any_msg)

	return envelope


## Write a string field: tag + length-delimited bytes
static func put_string(buf: PackedByteArray, field_num: int, value: String) -> void:
	# Build tag: (field_num << 3) | wire_type
	var tag := (field_num << 3) | WIRE_LENGTH_DELIMITED
	write_varint(buf, tag)
	var bytes := value.to_utf8_buffer()
	write_varint(buf, bytes.size())
	for b in bytes:
		buf.append(b)


## Write a varint field
static func put_varint(buf: PackedByteArray, field_num: int, value: int) -> void:
	# Build tag: (field_num << 3) | wire_type
	var tag := (field_num << 3) | WIRE_VARINT
	write_varint(buf, tag)
	write_varint(buf, value)


## Write a bytes (length-delimited) field
static func put_bytes(buf: PackedByteArray, field_num: int, value: PackedByteArray) -> void:
	# Build tag: (field_num << 3) | wire_type
	var tag := (field_num << 3) | WIRE_LENGTH_DELIMITED
	write_varint(buf, tag)
	write_varint(buf, value.size())
	for b in value:
		buf.append(b)


## Parse a protobuf byte array into a list of field dictionaries
static func parse(ba: PackedByteArray) -> Array:
	var fields := Array()
	var pos := 0

	while pos < ba.size():
		var tag_result := read_varint(ba, pos)
		if tag_result[0] == null:
			break
		var tag := int(tag_result[0])
		pos = int(tag_result[1])

		var field_num := tag >> 3
		var wire_type := tag & 0x7

		var field := { "n": field_num, "w": wire_type }

		match wire_type:
			WIRE_VARINT:
				var v_result := read_varint(ba, pos)
				if v_result[0] == null:
					break
				field["v"] = v_result[0]
				pos = v_result[1]
			WIRE_FIXED64:
				var v_result := read_fixed64(ba, pos)
				field["v"] = v_result[0]
				pos = v_result[1]
			WIRE_LENGTH_DELIMITED:
				var v_result := read_length_delimited(ba, pos)
				if v_result[0] == null:
					break
				field["b"] = v_result[0]
				pos = v_result[1]
			WIRE_FIXED32:
				var v_result := read_fixed32(ba, pos)
				field["v"] = v_result[0]
				pos = v_result[1]
			_:
				break

		fields.append(field)

	return fields


## Get the first field with the given number from parsed results
static func first(parsed: Array, field_num: int) -> Variant:
	for field in parsed:
		if field.get("n") == field_num:
			return field
	return null


## Get all fields with the given number (for repeated fields)
static func first_repeated(parsed: Array, field_num: int) -> Array:
	var result: Array = []
	for field in parsed:
		if field.get("n") == field_num:
			result.append(field)
	return result


## Marker every Ankama message carries: <prefix><opcode>.
const TYPE_URL_PREFIX := "type.ankama.com/"

## Decode a complete frame into a dictionary with opcode, payload, and request_id.
##
## The frame is scanned for the type_url instead of walking field numbers. The server
## wraps pushes as f1 { f1 { f1: url, f2: payload } } (ConnectionProtocol.Push) while
## client requests go in a single level under another root field, so the nesting depth
## is not something to hardcode. NetworkMessage.ReadPayload scans for the same marker.
static func decode(frame: PackedByteArray) -> Dictionary:
	var result: Dictionary = { "opcode": "", "payload": PackedByteArray(), "id": 0 }

	if frame == null or frame.size() == 0:
		return result

	var marker := TYPE_URL_PREFIX.to_utf8_buffer()
	var at := _index_of_bytes(frame, marker, 0)
	if at < 0:
		return result

	# Opcodes are always three characters in this protocol.
	var opcode_start := at + marker.size()
	if opcode_start + 3 > frame.size():
		return result
	result["opcode"] = frame.slice(opcode_start, opcode_start + 3).get_string_from_utf8()

	# Right behind the type_url comes field 2 of the Any: the message body.
	var pos := opcode_start + 3
	if pos < frame.size() and frame[pos] == 0x12:
		var len_result := read_varint(frame, pos + 1)
		if len_result[0] != null:
			var body_start: int = int(len_result[1])
			var body_len: int = int(len_result[0])
			if body_start + body_len <= frame.size():
				result["payload"] = frame.slice(body_start, body_start + body_len)

	var f2_root = first(parse(frame), 2) # request_id (only for messages with f2)
	if f2_root != null and f2_root.has("v"):
		result["id"] = f2_root["v"]

	return result


## First position of `needle` in `ba` at or after `from`, or -1 if absent.
static func _index_of_bytes(ba: PackedByteArray, needle: PackedByteArray, from: int) -> int:
	var last: int = ba.size() - needle.size()
	for i in range(max(from, 0), last + 1):
		var hit := true
		for j in needle.size():
			if ba[i + j] != needle[j]:
				hit = false
				break
		if hit:
			return i
	return -1


# ============================================================================
# Connection Server Message Parsing (Bare protobuf, no envelope)
# ============================================================================
## Parse a connection server message (bare protobuf, no type.ankama.com envelope)
## These messages are used during the initial connection and server selection phases
## Returns a Dictionary with parsed fields, or null if parsing fails
static func parse_connection_message(data: PackedByteArray) -> Dictionary:
	if data == null or data.size() == 0:
		return { "auth": null, "auth_result": null }

	var fields := parse(data)
	var result: Dictionary = { "auth": null, "auth_result": null }

	# Field 1: AuthenticationTicketMessage (client -> server)
	var f1 = first(fields, 1)
	if f1 != null and f1.has("b"):
		result["auth"] = _parse_auth_message(f1["b"])

	# Field 2: AuthenticationTicketResultMessage (server -> client)
	var f2 = first(fields, 2)
	if f2 != null and f2.has("b"):
		result["auth_result"] = _parse_auth_result_message(f2["b"])

	return result


## Parse AuthenticationTicketMessage from bytes
static func _parse_auth_message(data: PackedByteArray) -> Dictionary:
	var result: Dictionary = { "lang": "", "ticket": null, "selected_server": null }

	if data == null or data.size() == 0:
		return result

	var fields := parse(data)

	# Field 1: lang (string)
	var f1 = first(fields, 1)
	if f1 != null and f1.has("b"):
		result["lang"] = f1["b"].get_string_from_utf8()

	# Field 3: ticket (AuthenticationTicket)
	var f3 = first(fields, 3)
	if f3 != null and f3.has("b"):
		result["ticket"] = _parse_authentication_ticket(f3["b"])

	# Field 4: selectedServer (SelectedServerSelection)
	var f4 = first(fields, 4)
	if f4 != null and f4.has("b"):
		result["selected_server"] = _parse_selected_server_selection(f4["b"])

	return result


## Parse AuthenticationTicket from bytes
static func _parse_authentication_ticket(data: PackedByteArray) -> Dictionary:
	var result: Dictionary = { "machine_id": "", "token_data": null, "version": "" }

	if data == null or data.size() == 0:
		return result

	var fields := parse(data)

	# Field 1: machineId (string) - optional
	var f1 = first(fields, 1)
	if f1 != null and f1.has("b"):
		result["machine_id"] = f1["b"].get_string_from_utf8()

	# Field 3: tokenData (TokenData)
	var f3 = first(fields, 3)
	if f3 != null and f3.has("b"):
		result["token_data"] = _parse_token_data(f3["b"])

	# Field 5: version (string) - optional
	var f5 = first(fields, 5)
	if f5 != null and f5.has("b"):
		result["version"] = f5["b"].get_string_from_utf8()

	return result


## Parse TokenData from bytes
static func _parse_token_data(data: PackedByteArray) -> Dictionary:
	var result: Dictionary = { "token": "", "unk": "" }

	if data == null or data.size() == 0:
		return result

	var fields := parse(data)

	# Field 1: token (string)
	var f1 = first(fields, 1)
	if f1 != null and f1.has("b"):
		result["token"] = f1["b"].get_string_from_utf8()

	# Field 2: unk (string) - optional
	var f2 = first(fields, 2)
	if f2 != null and f2.has("b"):
		result["unk"] = f2["b"].get_string_from_utf8()

	return result


## Parse SelectedServerSelection from bytes
static func _parse_selected_server_selection(data: PackedByteArray) -> Dictionary:
	var result: Dictionary = { "server_id": 0 }

	if data == null or data.size() == 0:
		return result

	var fields := parse(data)

	# Field 1: serverId (varint)
	var f1 = first(fields, 1)
	if f1 != null and f1.has("v"):
		result["server_id"] = int(f1["v"])

	return result


## Parse AuthenticationTicketResultMessage from bytes
static func _parse_auth_result_message(data: PackedByteArray) -> Dictionary:
	var result: Dictionary = { "lang": "", "result": null, "selected_server": null }

	if data == null or data.size() == 0:
		return result

	var fields := parse(data)

	# Field 1: lang (string)
	var f1 = first(fields, 1)
	if f1 != null and f1.has("b"):
		result["lang"] = f1["b"].get_string_from_utf8()

	# Field 3: result (AuthenticationTicketResult)
	var f3 = first(fields, 3)
	if f3 != null and f3.has("b"):
		result["result"] = _parse_authentication_ticket_result(f3["b"])

	# Field 4: selectedServer (SelectedServerData)
	var f4 = first(fields, 4)
	if f4 != null and f4.has("b"):
		result["selected_server"] = _parse_selected_server_data(f4["b"])

	return result


## Parse AuthenticationTicketResult from bytes
static func _parse_authentication_ticket_result(data: PackedByteArray) -> Dictionary:
	var result: Dictionary = { "accepted": null, "refused": null }

	if data == null or data.size() == 0:
		return result

	var fields := parse(data)

	# Field 1: accepted (AuthenticationTicketAccepted)
	var f1 = first(fields, 1)
	if f1 != null and f1.has("b"):
		result["accepted"] = _parse_authentication_ticket_accepted(f1["b"])

	# Field 2: refused (AuthenticationTicketRefused)
	var f2 = first(fields, 2)
	if f2 != null and f2.has("b"):
		result["refused"] = _parse_authentication_ticket_refused(f2["b"])

	return result


## Parse AuthenticationTicketAccepted from bytes
static func _parse_authentication_ticket_accepted(data: PackedByteArray) -> Dictionary:
	var result: Dictionary = {
		"account_id": 0,
		"account_name": "",
		"account_tag": "",
		"servers": null,
		"subscription_end_date": "",
		"flags": null,
		"field7": 0,
		"field8": false,
	}

	if data == null or data.size() == 0:
		return result

	var fields := parse(data)

	# Field 1: accountId (int64)
	var f1 = first(fields, 1)
	if f1 != null and f1.has("v"):
		result["account_id"] = int(f1["v"])

	# Field 2: accountName (string)
	var f2 = first(fields, 2)
	if f2 != null and f2.has("b"):
		result["account_name"] = f2["b"].get_string_from_utf8()

	# Field 3: accountTag (string)
	var f3 = first(fields, 3)
	if f3 != null and f3.has("b"):
		result["account_tag"] = f3["b"].get_string_from_utf8()

	# Field 4: servers (ServerList)
	var f4 = first(fields, 4)
	if f4 != null and f4.has("b"):
		result["servers"] = _parse_server_list(f4["b"])

	# Field 5: subscriptionEndDate (string)
	var f5 = first(fields, 5)
	if f5 != null and f5.has("b"):
		result["subscription_end_date"] = f5["b"].get_string_from_utf8()

	# Field 6: flags (Flags)
	var f6 = first(fields, 6)
	if f6 != null and f6.has("b"):
		result["flags"] = _parse_flags(f6["b"])

	# Field 7: field7 (int32)
	var f7 = first(fields, 7)
	if f7 != null and f7.has("v"):
		result["field7"] = int(f7["v"])

	# Field 8: field8 (bool)
	var f8 = first(fields, 8)
	if f8 != null and f8.has("v"):
		result["field8"] = bool(f8["v"])

	return result


## Parse AuthenticationTicketRefused from bytes
static func _parse_authentication_ticket_refused(data: PackedByteArray) -> Dictionary:
	var result: Dictionary = { "reason": 0 }

	if data == null or data.size() == 0:
		return result

	var fields := parse(data)

	# Field 1: reason (int32)
	var f1 = first(fields, 1)
	if f1 != null and f1.has("v"):
		result["reason"] = int(f1["v"])

	return result


## Parse ServerList from bytes
static func _parse_server_list(data: PackedByteArray) -> Dictionary:
	var result: Dictionary = { "servers": [], "status_list": [], "field3": false }

	if data == null or data.size() == 0:
		return result

	var fields := parse(data)

	# Field 1: servers (repeated ServerInfo)
	var f1_fields := first_repeated(fields, 1)
	if f1_fields != null:
		for server_info in f1_fields:
			if server_info.has("b"):
				result["servers"].append(_parse_server_info(server_info["b"]))

	# Field 2: statusList (repeated ServerStatus)
	var f2_fields := first_repeated(fields, 2)
	if f2_fields != null:
		for status in f2_fields:
			if status.has("v"):
				result["status_list"].append(status["v"])

	# Field 3: field3 (bool)
	var f3 = first(fields, 3)
	if f3 != null and f3.has("v"):
		result["field3"] = bool(f3["v"])

	return result


## Parse ServerInfo from bytes
static func _parse_server_info(data: PackedByteArray) -> Dictionary:
	var result: Dictionary = { "server": null, "status": 0, "characters": [] }

	if data == null or data.size() == 0:
		return result

	var fields := parse(data)

	# Field 1: server (ServerIdWrapper)
	var f1 = first(fields, 1)
	if f1 != null and f1.has("b"):
		result["server"] = _parse_server_id_wrapper(f1["b"])

	# Field 2: status (int32)
	var f2 = first(fields, 2)
	if f2 != null and f2.has("v"):
		result["status"] = int(f2["v"])

	# Field 3: characters (repeated CharacterInfo)
	var f3_fields := first_repeated(fields, 3)
	if f3_fields != null:
		for char_info in f3_fields:
			if char_info.has("b"):
				result["characters"].append(_parse_character_info(char_info["b"]))

	return result


## Parse ServerIdWrapper from bytes
static func _parse_server_id_wrapper(data: PackedByteArray) -> Dictionary:
	var result: Dictionary = { "server_id": 0, "character_count": 0 }

	if data == null or data.size() == 0:
		return result

	var fields := parse(data)

	# Field 1: serverId (int32)
	var f1 = first(fields, 1)
	if f1 != null and f1.has("v"):
		result["server_id"] = int(f1["v"])

	# Field 3: characterCount (int32)
	var f3 = first(fields, 3)
	if f3 != null and f3.has("v"):
		result["character_count"] = int(f3["v"])

	return result


## Parse CharacterInfo from bytes
static func _parse_character_info(data: PackedByteArray) -> Dictionary:
	var result: Dictionary = {
		"name": "",
		"breed": 0,
		"gender": 0,
		"level": 0,
		"last_connection": "",
	}

	if data == null or data.size() == 0:
		return result

	var fields := parse(data)

	# Field 1: name (string)
	var f1 = first(fields, 1)
	if f1 != null and f1.has("b"):
		result["name"] = f1["b"].get_string_from_utf8()

	# Field 2: breed (int32)
	var f2 = first(fields, 2)
	if f2 != null and f2.has("v"):
		result["breed"] = int(f2["v"])

	# Field 3: gender (int32)
	var f3 = first(fields, 3)
	if f3 != null and f3.has("v"):
		result["gender"] = int(f3["v"])

	# Field 4: level (int32)
	var f4 = first(fields, 4)
	if f4 != null and f4.has("v"):
		result["level"] = int(f4["v"])

	# Field 5: lastConnection (string)
	var f5 = first(fields, 5)
	if f5 != null and f5.has("b"):
		result["last_connection"] = f5["b"].get_string_from_utf8()

	return result


## Parse Flags from bytes
static func _parse_flags(data: PackedByteArray) -> Dictionary:
	var result: Dictionary = { "flag1": false, "flag2": false, "flag3": false, "flag4": false }

	if data == null or data.size() == 0:
		return result

	var fields := parse(data)

	# Field 1: flag1 (bool)
	var f1 = first(fields, 1)
	if f1 != null and f1.has("v"):
		result["flag1"] = bool(f1["v"])

	# Field 2: flag2 (bool)
	var f2 = first(fields, 2)
	if f2 != null and f2.has("v"):
		result["flag2"] = bool(f2["v"])

	# Field 3: flag3 (bool)
	var f3 = first(fields, 3)
	if f3 != null and f3.has("v"):
		result["flag3"] = bool(f3["v"])

	# Field 4: flag4 (bool)
	var f4 = first(fields, 4)
	if f4 != null and f4.has("v"):
		result["flag4"] = bool(f4["v"])

	return result


## Parse SelectedServerData from bytes
static func _parse_selected_server_data(data: PackedByteArray) -> Dictionary:
	var result: Dictionary = { "info": null }

	if data == null or data.size() == 0:
		return result

	var fields := parse(data)

	# Field 1: info (ServerHostInfo)
	var f1 = first(fields, 1)
	if f1 != null and f1.has("b"):
		result["info"] = _parse_server_host_info(f1["b"])

	return result


## Parse ServerHostInfo from bytes
static func _parse_server_host_info(data: PackedByteArray) -> Dictionary:
	var result: Dictionary = { "ticket": "", "address": "", "ports": [] }

	if data == null or data.size() == 0:
		return result

	var fields := parse(data)

	# Field 1: ticket (string)
	var f1 = first(fields, 1)
	if f1 != null and f1.has("b"):
		result["ticket"] = f1["b"].get_string_from_utf8()

	# Field 2: address (string)
	var f2 = first(fields, 2)
	if f2 != null and f2.has("b"):
		result["address"] = f2["b"].get_string_from_utf8()

	# Field 3: ports (bytes - needs deserialization)
	var f3 = first(fields, 3)
	if f3 != null and f3.has("b"):
		result["ports"] = _parse_ports(f3["b"])

	return result


## Parse ports (bytes) into array of integers
static func _parse_ports(data: PackedByteArray) -> Array:
	var result: Array = []
	if data == null or data.size() == 0:
		return result

	# Ports are serialized using varint format
	var pos = 0
	while pos < data.size():
		var v = 0
		var shift = 0
		var i = pos
		while i < data.size():
			var byte_val = int(data[i])
			v |= (byte_val & 0x7F) << shift
			if (byte_val & 0x80) == 0:
				i += 1
				break
			i += 1
			shift += 7
			if shift >= 35:
				break
		if i > pos:
			result.append(v)
			pos = i
		else:
			break

	return result
