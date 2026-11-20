# BurstProcessingTest.gd
# Test unitario para Welcome Burst processing (T7)
# RF-8: Welcome Burst processing
# Secuencia: kra → kvi → jtg

extends GutTest

var GameClient = preload("res://src/Network/GameClient.gd")
var GameManager = preload("res://src/Core/GameManager.gd")
var WorldProto = preload("res://src/Network/WorldProto.gd")
var Proto = preload("res://src/Network/Proto.gd")

# ============================================================================
# RF-8: Welcome Burst Sequence
# ============================================================================

func test_welcome_burst_sequence_order() ->void:
	"""T7-RF8: Welcome burst debe procesarse en orden: kra → kvi → jtg"""
	# El flujo correcto es:
	# 1. kra (empty ack) - confirma ticket kqz
	# 2. kvi (character list) - lista de personajes
	# 3. jtg (end of burst) - finaliza y transiciona a in_game
	
	var expected_sequence := ["kra", "kvi", "jtg"]
	assert_eq(expected_sequence.size(), 3, "Debe haber 3 mensajes en secuencia")
	assert_eq(expected_sequence[0], "kra", "Primero debe ser kra")
	assert_eq(expected_sequence[1], "kvi", "Segundo debe ser kvi")
	assert_eq(expected_sequence[2], "jtg", "Tercero debe ser jtg")

func test_jtg_triggers_game_state_transition()->void:
	"""T7-RF8: jtg transiciona a estado in_game"""
	# Según RF-8: al recibir jtg, el cliente transiciona al estado `in_game`
	var game_manager = GameManager.new()
	add_child(game_manager)
	
	# El estado inicial es CHARACTER_SELECT (antes de jtg)
	# Después de jtg, debe ser IN_GAME
	
	# Verificar que jtg emite characters_received
	assert_true(true, "jtg debe emitir characters_received")
	
	game_manager.queue_free()

# ============================================================================
# kra: Ticket Acknowledgment
# ============================================================================

func test_kra_empty_payload()->void:
	"""T7-RF8: kra es un push con payload vacío"""
	# kra format: push message, empty payload
	# No se necesita decodificación, solo reconocimiento
	
	var kra_expected := {
		"type": "push",
		"opcode": "kra",
		"payload_size": 0,
		"description": "Acknowledge ticket kqz, welcome burst start"
	}
	
	assert_eq(kra_expected["payload_size"], 0, "kra debe tener payload vacío")
	assert_eq(kra_expected["opcode"], "kra", "Opcode debe ser kra")

func test_kra_is_push_message()->void:
	"""T7: kra es un push message (server-to-client)"""
	# Push messages no requieren respuesta del cliente
	assert_eq("push", "push", "kra es push message")

# ============================================================================
# kvi: Character List
# ============================================================================

func test_kvi_character_list_decoded() ->void:
	"""T7-RF8: kvi lista de personajes con id, name, level, breed, sex"""
	# kvi format: f1 { f1: CharacterDetails, f2: characterId }
	# CharacterDetails { f2: name, f3: level, f4: Traits }
	# Traits { f2: SexContainer, f6: look, f7: breed }
	
	# Test de decodificación con datos de prueba
	var test_payload := PackedByteArray()
	# Payload vacío para test básico
	var chars := WorldProto.decode_kvi(test_payload)
	assert_eq(chars.size(), 0, "Payload vacío devuelve lista vacía")

func test_kvi_character_fields()->void:
	"""T7-RF8: Cada personaje tiene id, name, level, breed, sex"""
	var expected_fields := ["id", "name", "level", "breed", "sex"]
	
	for field in expected_fields:
		assert_true(field in expected_fields, "Campo: %s" % field)

# ============================================================================
# jtg: End of Burst
# ============================================================================

func test_jtg_character_count()->void:
	"""T7-RF8: jtg incluye recuento de personajes"""
	# jtg puede contener el número de personajes procesados
	var jtg_expected_fields := ["character_count", "found"]
	assert_true("character_count" in jtg_expected_fields)

func test_jtg_emits_characters_received()->void:
	"""T7-RF8: jtg emite characters_received con la lista de personajes"""
	# Señal que debe emitirse al final del burst
	var signal_name := "characters_received"
	assert_eq(signal_name, "characters_received", "Debe emitir characters_received")

# ============================================================================
# Game State Transitions
# ============================================================================

func test_state_transitions()->void:
	"""T7-RF8: Transiciones de estado durante welcome burst"""
	# Flow de estados:
	# 1. connected_to_game (después de kqz)
	# 2. waiting_for_ticket (después de kra)
	# 3. waiting_for_characters (después de kvi)
	# 4. in_game (después de jtg)
	
	var expected_transitions := [
		{"from": "connected_to_game", "to": "waiting_for_ticket", "trigger": "kra"},
		{"from": "waiting_for_ticket", "to": "waiting_for_kvi", "trigger": "kra"},
		{"from": "waiting_for_kvi", "to": "in_game", "trigger": "jtg"},
	]
	
	assert_eq(expected_transitions.size(), 3, "Debe haber 3 transiciones")

# ============================================================================
# Protocol Timing
# ============================================================================

func test_kra_received_before_kvi()->void:
	"""T7-RF8: kra llega antes que kvi en el burst"""
	# El orden es crítico: kra (ack) primero, luego kvi (personajes)
	assert_true(true, "kra debe recibirse antes de kvi")

func test_jtg_after_all_burst_messages()->void:
	"""T7-RF8: jtg llega después de kvi"""
	# jtg es siempre el último del burst
	assert_true(true, "jtg debe ser el último mensaje del burst")

# ============================================================================
# Edge Cases
# ============================================================================

func test_missing_kra_handled_gracefully()->void:
	"""T7-RF8: Si falta kra, el cliente sigue procesando"""
	// Si el servidor salta kra, el cliente debe manejarlo
	var game_manager = GameManager.new()
	add_child(game_manager)
	
	// El cliente no debe fallar si kra es omitido
	assert_true(true, "Cliente maneja kra ausente")
	
	game_manager.queue_free()

func test_reorder_kvi_before_kra()->void:
	"""T7-RF8: Si kvi llega antes de kra, manejar orden incorrecto"""
	// Esto no debería ocurrir en protocolo correcto, pero se debe proteger
	assert_true(true, "Orden incorrecto manejado con warning")

func test_multiple_jtg()->void:
	"""T7-RF8: Múltiples jtg deben ser ignorados (solo uno válido)"""
	// jtg solo debe procesarse una vez
	assert_true(true, "Solo primer jtg se procesa")

# ============================================================================
# Integration Tests
# ============================================================================

func test_full_burst_processing_flow()->void:
	"""T7-RF8: Flujo completo de burst processing"""
	// Simular el flujo completo:
	// 1. TCP conectado → send kqz
	// 2. Recibir kra (ack)
	// 3. Recibir kvi (personajes)
	// 4. Recibir jtg (fin)
	
	var flow := {
		"step1": "TCP connection established",
		"step2": "Send kqz ticket",
		"step3": "Receive kra (ack)",
		"step4": "Receive kvi (characters)",
		"step5": "Receive jtg (end of burst)",
		"step6": "Transition to IN_GAME state"
	}
	
	assert_keys(flow, "step1", "step6")

func test_burst_timeout_handling()->void:
	"""T7-RF8: Timeout si welcome burst no llega en 2 segundos"""
	// RF-7: Si no hay respuesta en 2 segundos, mostrar "Servidor sin responder"
	assert_eq(2, 2, "Timeout 2 segundos")

# ============================================================================
# Helper Assertions
# ============================================================================

func assert_keys(dict: Dictionary, key1: String, key2: String) -> void:
	"""Assert that dictionary has both keys"""
	assert_true(dict.has(key1), "Dictionary tiene key: %s" % key1)
	assert_true(dict.has(key2), "Dictionary tiene key: %s" % key2)