# WorldProto.gd - Protocol decoders for world opcodes
extends RefCounted
class_name WorldProto

## Preload helpers
const ByteArrayExtensions = preload("res://src/Utils/ByteArrayExtensions.gd")
const Proto = preload("res://src/Network/Proto.gd")


# jru: map change notification from server
# Field 2: mapId (varint)
static func decode_jru(payload: PackedByteArray) -> Dictionary:
	if payload == null or payload.size() == 0:
		return { "map_id": 0, "found": false }

	var ba = payload
	var pos = 0
	var map_id = 0

	while pos < ba.size():
		var tag = ba[pos]
		var field_num = tag >> 3
		var wire_type = tag & 0x7
		pos += 1

		if field_num == 2: # f2 = mapId
			map_id = Proto.read_varint(ba, pos)[0] if Proto.read_varint(ba, pos)[0] != null else 0
			break
		elif wire_type == 0: # Varint
			pos += _varint_size(ba, pos)
		elif wire_type == 1: # 64-bit
			pos += 8
		elif wire_type == 2: # Length-delimited
			var len = Proto.read_varint(ba, pos)[0] if Proto.read_varint(ba, pos)[0] != null else 0
			pos += len + _varint_size(ba, pos)
		elif wire_type == 5: # 32-bit
			pos += 4

	return { "map_id": map_id, "found": map_id > 0 }


# kkr: map data response (server sends map geometry)
static func decode_kkr(payload: PackedByteArray) -> Dictionary:
	if payload == null or payload.size() == 0:
		return { "map_id": 0, "sub_area_id": 0, "map_ids": [], "neighbours": {}, "found": false }

	var ba = payload
	var pos = 0
	var sub_area_id = 0
	var map_id = 0
	var map_ids: Array = []
	var neighbours = { "right": 0, "bottom": 0, "left": 0, "top": 0 }

	while pos < ba.size():
		var tag = ba[pos]
		var field_num = tag >> 3
		var wire_type = tag & 0x7
		pos += 1

		if field_num == 1: # f1 = subAreaId
			sub_area_id = Proto.read_varint(ba, pos)[0] if Proto.read_varint(ba, pos)[0] != null else 0
			pos += _varint_size(ba, pos)
		elif field_num == 2: # f2 = mapId (repeated varints)
			while pos < ba.size():
				var value = Proto.read_varint(ba, pos)[0] if Proto.read_varint(ba, pos)[0] != null else 0
				map_ids.append(value)
				var next_pos = pos + _varint_size(ba, pos)
				if next_pos < ba.size():
					var next_byte = ba[next_pos]
					if (next_byte >> 3) == 2:
						pos = next_pos
					else:
						break
				else:
					break
		elif field_num == 3: # f3 = neighbours (packed u32: right, bottom, left, top)
			var len = Proto.read_varint(ba, pos)[0] if Proto.read_varint(ba, pos)[0] != null else 0
			pos += _varint_size(ba, pos)
			if pos + 16 <= ba.size():
				neighbours = {
					"right": ByteArrayExtensions.read_u32_le(ba, pos),
					"bottom": ByteArrayExtensions.read_u32_le(ba, pos + 4),
					"left": ByteArrayExtensions.read_u32_le(ba, pos + 8),
					"top": ByteArrayExtensions.read_u32_le(ba, pos + 12)
				}
		elif field_num == 4: # f4 = mapId (alternative field)
			map_id = Proto.read_varint(ba, pos)[0] if Proto.read_varint(ba, pos)[0] != null else 0
			pos += _varint_size(ba, pos)

	return {
		"map_id": map_id,
		"sub_area_id": sub_area_id,
		"map_ids": map_ids,
		"neighbours": neighbours,
		"found": map_id > 0
	}


# kub: player stats
# Format: f2 { f1 { f1: characteristic_id, f4/f5/f2: value }, f7: experience, f8: next_level, f9: alignment, f10: kamas }
static func decode_kub(payload: PackedByteArray) -> Dictionary:
	if payload == null or payload.size() == 0:
		return { "stats": {}, "experience": 0, "next_level": 0, "kamas": 0, "found": false }

	var ba = payload
	var pos = 0

	var stats: Dictionary = {}
	var experience: int = 0
	var next_level: int = 0
	var kamas: int = 0
	var alignment: Dictionary = {}

	while pos < ba.size():
		var tag = ba[pos]
		var field_num = tag >> 3
		var wire_type = tag & 0x7
		pos += 1

		if field_num == 2: # f2 = stats block (repeated)
			var len_result = Proto.read_varint(ba, pos)
			if len_result[0] == null:
				break
			var len = len_result[0]
			var data_pos = len_result[1]

			if data_pos + len <= ba.size():
				var stat_entry = _parse_kub_stat(
					ByteArrayExtensions.byte_subarray(ba, data_pos, len)
				)
				if stat_entry != null and stat_entry.id > 0:
					stats[stat_entry.id] = stat_entry.values
			pos = data_pos + len
		elif field_num == 7: # f7 = experience (varint)
			experience = Proto.read_varint(ba, pos)[0] if Proto.read_varint(ba, pos)[0] != null else 0
			pos += _varint_size(ba, pos)
		elif field_num == 8: # f8 = next_level (varint)
			next_level = Proto.read_varint(ba, pos)[0] if Proto.read_varint(ba, pos)[0] != null else 0
			pos += _varint_size(ba, pos)
		elif field_num == 9: # f9 = alignment block
			var len_result = Proto.read_varint(ba, pos)
			if len_result[0] != null:
				var len = len_result[0]
				var data_pos = len_result[1]
				if data_pos + len <= ba.size():
					var align_bytes = ByteArrayExtensions.byte_subarray(ba, data_pos, len)
					alignment = _parse_kub_alignment(align_bytes)
				pos = data_pos + len
		elif field_num == 10: # f10 = kamas (varint)
			kamas = Proto.read_varint(ba, pos)[0] if Proto.read_varint(ba, pos)[0] != null else 0
			pos += _varint_size(ba, pos)
		else:
			pos += _field_size(ba, pos)

	return {
		"stats": stats,
		"experience": experience,
		"next_level": next_level,
		"kamas": kamas,
		"alignment": alignment,
		"found": stats.size() > 0
	}

# Helper to parse a single stat entry from kub
static func _parse_kub_stat(data: PackedByteArray) -> Dictionary:
	if data == null or data.size() == 0:
		return { "id": 0, "values": {} }

	var ba = data
	var pos = 0

	var stat_id: int = 0
	var values: Dictionary = {}

	while pos < ba.size():
		var tag = ba[pos]
		var field_num = tag >> 3
		pos += 1

		if field_num == 1: # f1 = stat_id (varint)
			stat_id = Proto.read_varint(ba, pos)[0] if Proto.read_varint(ba, pos)[0] != null else 0
			pos += _varint_size(ba, pos)
		elif field_num == 2: # f2 = base value (varint)
			var val = Proto.read_varint(ba, pos)
			values.base = val[0] if val[0] != null else 0
			pos = val[1] if val[0] != null else pos + _varint_size(ba, pos)
		elif field_num == 4: # f4 = scroll value (varint)
			var val = Proto.read_varint(ba, pos)
			values.scroll = val[0] if val[0] != null else 0
			pos = val[1] if val[0] != null else pos + _varint_size(ba, pos)
		elif field_num == 5: # f5 = equipment value (varint)
			var val = Proto.read_varint(ba, pos)
			values.equipment = val[0] if val[0] != null else 0
			pos = val[1] if val[0] != null else pos + _varint_size(ba, pos)
		else:
			pos += _field_size(ba, pos)

	return { "id": stat_id, "values": values }

# Helper to parse alignment block from kub
static func _parse_kub_alignment(data: PackedByteArray) -> Dictionary:
	if data == null or data.size() == 0:
		return { "side": 0, "grade": 0, "honor": 0 }

	var ba = data
	var pos = 0

	var level: int = 0
	var side: int = 0
	var honor: int = 0
	var grade: int = 0

	while pos < ba.size():
		var tag = ba[pos]
		var field_num = tag >> 3
		var wire_type = tag & 0x7
		pos += 1

		if field_num == 1: # f1 = alignment level
			level = Proto.read_varint(ba, pos)[0] if Proto.read_varint(ba, pos)[0] != null else 0
			pos += _varint_size(ba, pos)
		elif field_num == 2: # f2 = alignment side
			side = Proto.read_varint(ba, pos)[0] if Proto.read_varint(ba, pos)[0] != null else 0
			pos += _varint_size(ba, pos)
		elif field_num == 3: # f3 = alignment data block
			var len_result = Proto.read_varint(ba, pos)
			if len_result[0] != null:
				pos = len_result[1]
		elif field_num == 4: # f4 = shown grade
			grade = Proto.read_varint(ba, pos)[0] if Proto.read_varint(ba, pos)[0] != null else 0
			pos += _varint_size(ba, pos)
		elif field_num == 5: # f5 = next grade honor
			honor = Proto.read_varint(ba, pos)[0] if Proto.read_varint(ba, pos)[0] != null else 0
			pos += _varint_size(ba, pos)
		else:
			pos += _field_size(ba, pos)

	return { "level": level, "side": side, "honor": honor, "grade": grade }


# irq: player jobs/professions
# Format: f1 (repeated) { f1: profession, f2: next_level, f3: level, f4: floor, f5: total }
static func decode_irq(payload: PackedByteArray) -> Dictionary:
	if payload == null or payload.size() == 0:
		return { "jobs": [], "found": false }

	var ba = payload
	var pos = 0

	var jobs: Array = []

	while pos < ba.size():
		var tag = ba[pos]
		var field_num = tag >> 3
		pos += 1

		if field_num == 1: # f1 = job entry (repeated, length-delimited)
			var len_result = Proto.read_varint(ba, pos)
			if len_result[0] == null:
				break
			var len = len_result[0]
			var data_pos = len_result[1]

			if data_pos + len <= ba.size():
				var job_bytes = ByteArrayExtensions.byte_subarray(ba, data_pos, len)
				var job = _parse_irq_job(job_bytes)
				if job != null:
					jobs.append(job)
			pos = data_pos + len
		else:
			pos += _field_size(ba, pos)

	return {
		"jobs": jobs,
		"found": jobs.size() > 0
	}

# Helper to parse a single job from irq
static func _parse_irq_job(data: PackedByteArray) -> Dictionary:
	if data == null or data.size() == 0:
		return {}

	var ba = data
	var pos = 0

	var profession: int = 0
	var level: int = 0
	var next_level: int = 0
	var floor: int = 0
	var total: int = 0

	while pos < ba.size():
		var tag = ba[pos]
		var field_num = tag >> 3
		pos += 1

		if field_num == 1: # f1 = profession
			profession = Proto.read_varint(ba, pos)[0] if Proto.read_varint(ba, pos)[0] != null else 0
			pos += _varint_size(ba, pos)
		elif field_num == 2: # f2 = next_level
			next_level = Proto.read_varint(ba, pos)[0] if Proto.read_varint(ba, pos)[0] != null else 0
			pos += _varint_size(ba, pos)
		elif field_num == 3: # f3 = level
			level = Proto.read_varint(ba, pos)[0] if Proto.read_varint(ba, pos)[0] != null else 0
			pos += _varint_size(ba, pos)
		elif field_num == 4: # f4 = floor (for professions like Alchimist)
			floor = Proto.read_varint(ba, pos)[0] if Proto.read_varint(ba, pos)[0] != null else 0
			pos += _varint_size(ba, pos)
		elif field_num == 5: # f5 = total (total level points)
			total = Proto.read_varint(ba, pos)[0] if Proto.read_varint(ba, pos)[0] != null else 0
			pos += _varint_size(ba, pos)
		else:
			pos += _field_size(ba, pos)

	return {
		"profession": profession,
		"level": level,
		"next_level": next_level,
		"floor": floor,
		"total": total
	}


# hms: spell list (player's learned spells)
# Format: f1 (repeated) { f1: grade, f3: spell_id, f4: origin }, f2: 1 at end
static func decode_hms(payload: PackedByteArray) -> Dictionary:
	if payload == null or payload.size() == 0:
		return { "spells": [], "found": false }

	var ba = payload
	var pos = 0

	var spells: Array = []
	var end_marker: int = 0

	while pos < ba.size():
		var tag = ba[pos]
		var field_num = tag >> 3
		pos += 1

		if field_num == 1: # f1 = spell entry (repeated, length-delimited)
			var len_result = Proto.read_varint(ba, pos)
			if len_result[0] == null:
				break
			var len = len_result[0]
			var data_pos = len_result[1]

			if data_pos + len <= ba.size():
				var spell_bytes = ByteArrayExtensions.byte_subarray(ba, data_pos, len)
				var spell = _parse_hms_spell(spell_bytes)
				if spell != null:
					spells.append(spell)
			pos = data_pos + len
		elif field_num == 2: # f2 = end marker (always 1)
			end_marker = Proto.read_varint(ba, pos)[0] if Proto.read_varint(ba, pos)[0] != null else 0
			pos += _varint_size(ba, pos)
		else:
			pos += _field_size(ba, pos)

	return {
		"spells": spells,
		"end_marker": end_marker,
		"found": spells.size() > 0
	}

# Helper to parse a single spell from hms
static func _parse_hms_spell(data: PackedByteArray) -> Dictionary:
	if data == null or data.size() == 0:
		return {}

	var ba = data
	var pos = 0

	var grade: int = 0
	var spell_id: int = 0
	var origin: int = 0 # 1 = standard, 2 = special

	while pos < ba.size():
		var tag = ba[pos]
		var field_num = tag >> 3
		pos += 1

		if field_num == 1: # f1 = grade/varint
			grade = Proto.read_varint(ba, pos)[0] if Proto.read_varint(ba, pos)[0] != null else 0
			pos += _varint_size(ba, pos)
		elif field_num == 3: # f3 = spell_id
			spell_id = Proto.read_varint(ba, pos)[0] if Proto.read_varint(ba, pos)[0] != null else 0
			pos += _varint_size(ba, pos)
		elif field_num == 4: # f4 = origin
			origin = Proto.read_varint(ba, pos)[0] if Proto.read_varint(ba, pos)[0] != null else 0
			pos += _varint_size(ba, pos)
		else:
			pos += _field_size(ba, pos)

	return {
		"grade": grade,
		"spell_id": spell_id,
		"origin": origin
	}


# ivx: inventory items
# Format: f1: kamas, f3 (repeated) { f1: slot, f5 { f1: template, effects }, f3: count, f4: uid }
static func decode_ivx(payload: PackedByteArray) -> Dictionary:
	if payload == null or payload.size() == 0:
		return { "kamas": 0, "items": [], "found": false }

	var ba = payload
	var pos = 0

	var kamas: int = 0
	var items: Array = []

	while pos < ba.size():
		var tag = ba[pos]
		var field_num = tag >> 3
		pos += 1

		if field_num == 1: # f1 = kamas
			kamas = Proto.read_varint(ba, pos)[0] if Proto.read_varint(ba, pos)[0] != null else 0
			pos += _varint_size(ba, pos)
		elif field_num == 3: # f3 = inventory item (repeated, length-delimited)
			var len_result = Proto.read_varint(ba, pos)
			if len_result[0] == null:
				break
			var len = len_result[0]
			var data_pos = len_result[1]

			if data_pos + len <= ba.size():
				var item_bytes = ByteArrayExtensions.byte_subarray(ba, data_pos, len)
				var item = _parse_ivx_item(item_bytes)
				if item != null:
					items.append(item)
			pos = data_pos + len
		else:
			pos += _field_size(ba, pos)

	return {
		"kamas": kamas,
		"items": items,
		"found": items.size() > 0 or kamas > 0
	}

# Helper to parse a single inventory item from ivx
static func _parse_ivx_item(data: PackedByteArray) -> Dictionary:
	if data == null or data.size() == 0:
		return {}

	var ba = data
	var pos = 0

	var slot: int = 0
	var template: int = 0
	var count: int = 0
	var uid: int = 0
	var effects: Array = []

	while pos < ba.size():
		var tag = ba[pos]
		var field_num = tag >> 3
		pos += 1

		if field_num == 1: # f1 = slot
			slot = Proto.read_varint(ba, pos)[0] if Proto.read_varint(ba, pos)[0] != null else 0
			pos += _varint_size(ba, pos)
		elif field_num == 3: # f3 = count
			count = Proto.read_varint(ba, pos)[0] if Proto.read_varint(ba, pos)[0] != null else 0
			pos += _varint_size(ba, pos)
		elif field_num == 4: # f4 = uid
			uid = Proto.read_varint(ba, pos)[0] if Proto.read_varint(ba, pos)[0] != null else 0
			pos += _varint_size(ba, pos)
		elif field_num == 5: # f5 = item body (length-delimited)
			var len_result = Proto.read_varint(ba, pos)
			if len_result[0] == null:
				break
			var len = len_result[0]
			var data_pos = len_result[1]

			if data_pos + len <= ba.size():
				var body_bytes = ByteArrayExtensions.byte_subarray(ba, data_pos, len)
				var item_body = _parse_ivx_item_body(body_bytes)
				if item_body != null:
					template = item_body.template
					effects = item_body.effects
			pos = data_pos + len
		else:
			pos += _field_size(ba, pos)

	return {
		"slot": slot,
		"template": template,
		"count": count,
		"uid": uid,
		"effects": effects
	}

# Helper to parse item body from ivx f5 field
static func _parse_ivx_item_body(data: PackedByteArray) -> Dictionary:
	if data == null or data.size() == 0:
		return { "template": 0, "effects": [] }

	var ba = data
	var pos = 0

	var template: int = 0
	var effects: Array = []

	while pos < ba.size():
		var tag = ba[pos]
		var field_num = tag >> 3
		pos += 1

		if field_num == 1: # f1 = template id
			template = Proto.read_varint(ba, pos)[0] if Proto.read_varint(ba, pos)[0] != null else 0
			pos += _varint_size(ba, pos)
		elif field_num == 11: # f11 = effect id
			var effect_id = Proto.read_varint(ba, pos)[0] if Proto.read_varint(ba, pos)[0] != null else 0
			pos += _varint_size(ba, pos)
			effects.append({ "id": effect_id })
		else:
			pos += _field_size(ba, pos)

	return { "template": template, "effects": effects }


# itg: shortcut bar (spells and items)
# Format: f1 (repeated) { f2: slot, f6 { f2: spell_id } } for spells, f9: items; f2: bar_type (1=spell, 0=item)
static func decode_itg(payload: PackedByteArray) -> Dictionary:
	if payload == null or payload.size() == 0:
		return { "bar_type": 0, "shortcuts": [], "found": false }

	var ba = payload
	var pos = 0

	var bar_type: int = 0
	var shortcuts: Array = []

	while pos < ba.size():
		var tag = ba[pos]
		var field_num = tag >> 3
		var wire_type = tag & 0x7
		pos += 1

		if field_num == 1: # f1 = shortcut entry (repeated, length-delimited)
			var len_result = Proto.read_varint(ba, pos)
			if len_result[0] == null:
				break
			var len = len_result[0]
			var data_pos = len_result[1]

			if data_pos + len <= ba.size():
				var shortcut_bytes = ByteArrayExtensions.byte_subarray(ba, data_pos, len)
				var shortcut = _parse_itg_shortcut(shortcut_bytes)
				if shortcut != null:
					shortcuts.append(shortcut)
			pos = data_pos + len
		elif field_num == 2: # f2 = bar_type (1=spell, 0=item)
			bar_type = Proto.read_varint(ba, pos)[0] if Proto.read_varint(ba, pos)[0] != null else 0
			pos += _varint_size(ba, pos)
		elif field_num == 9: # f9 = items in item bar (length-delimited)
			var len_result = Proto.read_varint(ba, pos)
			if len_result[0] != null:
				pos = len_result[1] + len_result[0]
		else:
			pos += _field_size(ba, pos)

	return {
		"bar_type": bar_type,
		"shortcuts": shortcuts,
		"found": shortcuts.size() > 0
	}

# Helper to parse a single shortcut from itg
static func _parse_itg_shortcut(data: PackedByteArray) -> Dictionary:
	if data == null or data.size() == 0:
		return {}

	var ba = data
	var pos = 0

	var slot: int = 0
	var spell_id: int = 0
	var is_item: bool = false
	var item_template: int = 0

	while pos < ba.size():
		var tag = ba[pos]
		var field_num = tag >> 3
		pos += 1

		if field_num == 2: # f2 = slot
			slot = Proto.read_varint(ba, pos)[0] if Proto.read_varint(ba, pos)[0] != null else 0
			pos += _varint_size(ba, pos)
		elif field_num == 6: # f6 = spell reference (length-delimited)
			var len_result = Proto.read_varint(ba, pos)
			if len_result[0] == null:
				break
			var len = len_result[0]
			var data_pos = len_result[1]

			if data_pos + len <= ba.size():
				var spell_bytes = ByteArrayExtensions.byte_subarray(ba, data_pos, len)
				spell_id = _parse_itg_spell_ref(spell_bytes)
			pos = data_pos + len
		elif field_num == 9: # f9 = item reference (length-delimited)
			var len_result = Proto.read_varint(ba, pos)
			if len_result[0] == null:
				break
			var len = len_result[0]
			var data_pos = len_result[1]

			if data_pos + len <= ba.size():
				var item_bytes = ByteArrayExtensions.byte_subarray(ba, data_pos, len)
				item_template = _parse_itg_item_ref(item_bytes)
				is_item = true
			pos = data_pos + len
		else:
			pos += _field_size(ba, pos)

	return {
		"slot": slot,
		"spell_id": spell_id,
		"item_template": item_template,
		"is_item": is_item,
	}

# Helper to parse spell reference from itg f6
static func _parse_itg_spell_ref(data: PackedByteArray) -> int:
	if data == null or data.size() == 0:
		return 0

	var ba = data
	var pos = 0
	var spell_id: int = 0

	while pos < ba.size():
		var tag = ba[pos]
		var field_num = tag >> 3
		pos += 1

		if field_num == 2: # f2 = spell_id
			spell_id = Proto.read_varint(ba, pos)[0] if Proto.read_varint(ba, pos)[0] != null else 0
			pos += _varint_size(ba, pos)
		else:
			pos += _field_size(ba, pos)

	return spell_id

# Helper to parse item reference from itg f9
static func _parse_itg_item_ref(data: PackedByteArray) -> int:
	if data == null or data.size() == 0:
		return 0

	var ba = data
	var pos = 0
	var item_template: int = 0

	while pos < ba.size():
		var tag = ba[pos]
		var field_num = tag >> 3
		pos += 1

		if field_num == 1: # f1 = item template
			item_template = Proto.read_varint(ba, pos)[0] if Proto.read_varint(ba, pos)[0] != null else 0
			pos += _varint_size(ba, pos)
		else:
			pos += _field_size(ba, pos)

	return item_template

# Helper function to calculate field size based on wire type
static func _field_size(ba: PackedByteArray, pos: int) -> int:
	if pos >= ba.size():
		return 1
	var wire_type = ba[pos] & 0x7
	if wire_type == 0: # Varint
		return _varint_size(ba, pos)
	elif wire_type == 1: # 64-bit fixed
		return 8
	elif wire_type == 2: # Length-delimited
		var len_result = Proto.read_varint(ba, pos)
		if len_result[0] == null:
			return 1
		return _varint_size(ba, pos) + len_result[0]
	elif wire_type == 5: # 32-bit fixed
		return 4
	return 1

# Helper function to calculate VarInt size
static func _varint_size(ba: PackedByteArray, pos: int) -> int:
	if pos >= ba.size():
		return 1
	var count = 0
	var byte = ba[pos]
	while (byte & 0x80) != 0 and pos + count < ba.size():
		count += 1
		byte = ba[pos + count]
	return count + 1

# Simple VarInt reader (returns just the value, not position)
static func _read_varint(ba: PackedByteArray, pos: int) -> int:
	var result = Proto.read_varint(ba, pos)
	return result[0] if result[0] != null else 0


# kvw: character info (client sends, server responds to get character details)
# This is sent by client to request character data after jtg
static func decode_kvw(payload: PackedByteArray) -> Dictionary:
	if payload == null or payload.size() == 0:
		return { "character_id": 0, "found": false }

	var ba = payload
	var pos = 0
	var character_id: int = 0

	# kvw is typically very simple - just contains character ID in f1.f1.f1
	# The format is: each field is a varint, field 1 contains the character ID
	while pos < ba.size():
		var tag = ba[pos]
		var field_num = tag >> 3
		pos += 1

		if field_num == 1: # f1 = character data
			character_id = Proto.read_varint(ba, pos)[0] if Proto.read_varint(ba, pos)[0] != null else 0
			pos += _varint_size(ba, pos)
		else:
			pos += _field_size(ba, pos)

	return {
		"character_id": character_id,
		"found": character_id > 0
	}


# kva: character alive (server sends this to indicate character is available)
# This is sent by server after kvw to confirm the character can receive Block 1
static func decode_kva(payload: PackedByteArray) -> Dictionary:
	if payload == null or payload.size() == 0:
		return { "alive": false, "found": false }

	var ba = payload
	var pos = 0
	var alive: bool = false

	# kva format: various fields indicating character state
	while pos < ba.size():
		var tag = ba[pos]
		var field_num = tag >> 3
		pos += 1

		if field_num == 1: # Presence
			var val = Proto.read_varint(ba, pos)[0] if Proto.read_varint(ba, pos)[0] != null else 0
			alive = val == 1
			pos += _varint_size(ba, pos)
		else:
			pos += _field_size(ba, pos)

	return {
		"alive": alive,
		"found": true
	}