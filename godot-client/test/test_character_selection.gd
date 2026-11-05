## test_character_selection.gd
## Test for kvw character selection message format.
## Run with: godot --headless --path <project> --script test/test_character_selection.gd
##
## The kvw message must have the format: { f1: character_id } where f1 is a varint.
## The bug was: client sent { f1: { f1: id } } (nested message) instead of flat varint.

extends SceneTree

var tests_passed := 0
var tests_failed := 0

func _init():
	OS.set_exit_on_quit(true)
	main()

func main():
	print("=== Character Selection (kvw) Tests ===")
	
	var GameClient = preload("res://src/Network/GameClient.gd")
	var Proto = preload("res://src/Network/Proto.gd")
	
	# Test 1: build_character_selection returns correct flat varint format
	print("Test 1: build_character_selection produces flat {f1: id} format")
	var character_id := 13825558
	var payload := GameClient.build_character_selection(character_id)
	
	# Expected: field 1 (f1=1, wire=0) as varint tag, followed by the ID as varint
	var expected_prefix := 0x08  # tag for field 1, wire type 0 (varint)
	var actual_first_byte := payload[0] if payload.size() > 0 else 0
	
	if actual_first_byte == expected_prefix:
		print("  PASSED - first byte is 0x%02X (field 1, wire type 0)" % actual_first_byte)
		tests_passed += 1
	else:
		print("  FAILED - expected 0x%02X, got 0x%02X" % [expected_prefix, actual_first_byte])
		tests_failed += 1
	
	# Test 2: payload contains correct character ID as varint
	print("Test 2: payload contains correct character ID as varint")
	var parsed := Proto.parse(payload)
	var id_field := Proto.first(parsed, 1)
	
	if id_field != null and id_field.has("v"):
		var parsed_id := int(id_field["v"])
		if parsed_id == character_id:
			print("  PASSED - ID matches: %d" % parsed_id)
			tests_passed += 1
		else:
			print("  FAILED - expected %d, got %d" % [character_id, parsed_id])
			tests_failed += 1
	else:
		print("  FAILED - no varint field 1 found in payload")
		tests_failed += 1
	
	# Test 3: payload does NOT have nested message (wire type 2)
	print("Test 3: payload does NOT have nested message (wire type 2)")
	var has_nested := false
	for field in parsed:
		if field["n"] == 1 and field.has("w") and field["w"] == Proto.WIRE_LENGTH_DELIMITED:
			# Check if this looks like a nested message { f1: id }
			if field.has("b"):
				var inner_fields := Proto.parse(field["b"])
				for inner in inner_fields:
					if inner["n"] == 1 and inner.has("v") and inner["v"] == character_id:
						has_nested = true
						break
	
	if not has_nested:
		print("  PASSED - no nested message structure found")
		tests_passed += 1
	else:
		print("  FAILED - payload incorrectly contains nested message {f1: id}")
		tests_failed += 1
	
	# Test 4: push envelope is correctly formed
	print("Test 4: push envelope contains opcode and payload correctly")
	var push_envelope := Proto.push("kvw", payload)
	var envelope_fields := Proto.parse(push_envelope)
	var any_field := Proto.first(envelope_fields, 1)
	
	if any_field != null and any_field.has("b"):
		var any_fields := Proto.parse(any_field["b"])
		var url_field := Proto.first(any_fields, 1)
		var type_url := ""
		if url_field != null and url_field.has("b"):
			type_url = url_field["b"].get_string_from_utf8()
		var payload_field := Proto.first(any_fields, 2)
		
		if type_url == "type.ankama.com/kvw":
			if payload_field != null and payload_field.has("b"):
				if payload_field["b"] == payload:
					print("  PASSED - push envelope correctly formed")
					tests_passed += 1
				else:
					print("  FAILED - payload in envelope doesn't match")
					tests_failed += 1
			else:
				print("  FAILED - no payload field in Any message")
				tests_failed += 1
		else:
			print("  FAILED - wrong type URL: %s" % type_url)
			tests_failed += 1
	else:
		print("  FAILED - no field 1 in envelope")
		tests_failed += 1
	
	# Test 5: different character ID format
	print("Test 5: small character ID format is correct")
	var small_id := 123
	var small_payload := GameClient.build_character_selection(small_id)
	var small_parsed := Proto.parse(small_payload)
	var small_field := Proto.first(small_parsed, 1)
	
	if small_field != null and small_field.has("v") and int(small_field["v"]) == small_id:
		print("  PASSED - small ID %d encoded correctly" % small_id)
		tests_passed += 1
	else:
		print("  FAILED - small ID not encoded correctly")
		tests_failed += 1
	
	print("\n=== Results ===")
	print("Passed: %d" % tests_passed)
	print("Failed: %d" % tests_failed)
	print("Total: %d" % (tests_passed + tests_failed))
	
	quit(tests_failed > 0 ? 1 : 0)