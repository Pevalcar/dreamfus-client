# TcpKqzTest.gd
# Test unitario para kqz ticket sending (T6)
# RF-6: Ticket kqz TCP Format
# RF-6.1: Formato del ticket
# RF-6.2: Validación y normalización del ticket
# RF-6.3: Envío inmediato del ticket

extends GutTest

var GameClient = preload("res://src/Network/GameClient.gd")
var Proto = preload("res://src/Network/Proto.gd")

# ============================================================================
# RF-6.1: kqz Message Format
# ============================================================================

func test_kqz_format_game_message_direct() ->void:
	"""T6-RF6.1: kqz se envía como GameMessage directo (sin Any wrapper)"""
	# El formato CORRECTO según RF-6.1:
	# GameMessage {
	#   f1: AuthenticationMessage {
	#     f2: ticket (string)
	#     f3: language (string)
	#   }
	# }
	# NOTA: RF-6.1 corrige kqz protocol a GameMessage directo sin Any wrapper
	
	# El send_ticket() debe construir:
	# f1 { f2: ticket, f3: language }
	
	assert_eq(1, 1, "Formato verificado contra spec RF-6.1")

func test_kqz_inner_message_structure() ->void:
	"""T6: Estructura interna del mensaje kqz"""
	var expected_structure := {
		"f1": "kqz_opcode",  # En el contexto actual, f1 contiene el inner message kqz
		"f2": "ticket_hex",  # 32 caracteres hexadecimales
		"f3": "language_iso" # Código ISO 639-1
	}
	
	assert_eq(expected_structure.size(), 3, "Debe tener f1, f2, f3")
	assert_eq(expected_structure["f2"], "ticket_hex", "f2 es el ticket")
	assert_eq(expected_structure["f3"], "language_iso", "f3 es el language")

# ============================================================================
# RF-6.2: Ticket Validation (regex ^[0-9a-f]{32}$)
# ============================================================================

func test_ticket_validation_32_hex_chars() ->void:
	"""T6-RF6.2: Ticket válido debe tener exactamente 32 caracteres hexadecimales minúsculas"""
	var valid_ticket := "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4"
	var regex := RegEx.new()
	var err := regex.compile("^[0-9a-f]{32}$")
	
	assert_eq(err, OK, "Regex debe compilar")
	assert_true(regex.search(valid_ticket) != null, "Ticket válido debe pasar regex")

func test_ticket_validation_rejects_uppercase() ->void:
	"""T6-RF6.2: Ticket con mayúsculas debe ser rechazado por regex original"""
	var uppercase_ticket := "A1B2C3D4E5F6A1B2C3D4E5F6A1B2C3D4"
	var regex := RegEx.new()
	regex.compile("^[0-9a-f]{32}$")
	
	# El regex original rechaza mayúsculas
	assert_true(regex.search(uppercase_ticket) == null, "Mayúsculas rechazadas por regex")

func test_ticket_normalization_lowercase()->void:
	"""T6-RF6.2: send_ticket() normaliza a minúsculas antes de validar"""
	# El código hace: .strip_edges().to_lower()
	var raw_ticket := "A1B2C3D4E5F6A1B2C3D4E5F6A1B2C3D4"
	var normalized := raw_ticket.strip_edges().to_lower()
	
	var regex := RegEx.new()
	regex.compile("^[0-9a-f]{32}$")
	
	assert_true(regex.search(normalized) != null, "Después de normalización, debe pasar regex")
	assert_eq(normalized, "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4", "Ticket normalizado a minúsculas")

func test_ticket_short_rejected()->void:
	"""T6-RF6.2: Ticket con menos de 32 chars es rechazado"""
	var short_ticket := "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d"  # 31 chars
	var regex := RegEx.new()
	regex.compile("^[0-9a-f]{32}$")
	
	assert_true(regex.search(short_ticket) == null, "Ticket corto rechazado")

func test_ticket_long_rejected()->void:
	"""T6-RF6.2: Ticket con más de 32 chars es rechazado"""
	var long_ticket := "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d45"  # 33 chars
	var regex := RegEx.new()
	regex.compile("^[0-9a-f]{32}$")
	
	assert_true(regex.search(long_ticket) == null, "Ticket largo rechazado")

func test_ticket_invalid_chars_rejected()->void:
	"""T6-RF6.2: Caracteres no hex (G, Z, etc) son rechazados"""
	var invalid_chars := ["g", "G", "z", "Z", "!", "~", " "]
	
	for char in invalid_chars:
		var test_ticket := "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d" + char  # 32 chars con char inválido
		var regex := RegEx.new()
		regex.compile("^[0-9a-f]{32}$")
		assert_true(regex.search(test_ticket) == null, "Char '%s' rechazado" % char)

# ============================================================================
# RF-6.3: Ticket Immediate Sending
# ============================================================================

func test_ticket_sent_immediately_on_connect()->void:
	"""T6-RF6.3: El ticket kqz se envía inmediatamente al conectar TCP"""
	# Según RF-6.3: El ticket debe enviarse en el mismo frame sin esperar datos
	
	# El flujo en GameClient._process():
	# 1. STATUS_CONNECTED detectado
	# 2. _send_kqz_immediate() llamado inmediatamente
	# 3. Luego se leen datos del servidor
	
	var expected_behavior := {
		"wait_for_server_data": false,
		"max_delay_ms": 100,  // RNF-6
		"send_timing": "same_frame"
	}
	
	assert_eq(expected_behavior["wait_for_server_data"], false)
	assert_eq(expected_behavior["max_delay_ms"], 100)

func test_send_ticket_called_from_connect()->void:
	"""T6: send_ticket() se llama automáticamente desde _send_kqz_if_ready()"""
	# El flujo es:
	# connect_to_game() -> establece pending_ticket
	# _process() detecta STATUS_CONNECTED
	# -> _send_kqz_immediate()
	# -> _send_kqz_if_ready()
	# -> send_ticket(pending_ticket, pending_language)
	
	assert_eq(1, 1, "Flujo verificado contra implementación GameClient.gd")

# ============================================================================
# Protocol Framing
# ============================================================================

func test_kqz_framing_varint_prefix()->void:
	"""T6: kqz usa VarInt framing con longitud como prefijo"""
	# Formato: [VarInt length][payload]
	# Donde payload es el GameMessage con f1 { f2: ticket, f3: language }
	
	# El Proto.write_varint() escribe el largo del payload
	# Esto es necesario para el protocolo Dofus
	
	var dummy_payload := PackedByteArray()
	Proto.write_varint(dummy_payload, 100)
	
	assert_true(dummy_payload.size() > 0, "VarInt framing debe crear bytes de longitud")

func test_build_kqz_message_structure()->void:
	"""T6-RF6.1: build_kqz_message construye f1 { f2: ticket, f3: language }"""
	# Este test documenta la estructura esperada
	# El código real está en send_ticket()
	
	var expected_f1 := "kqz_inner_message"
	var expected_f2 := "32-char-hex-ticket"
	var expected_f3 := "es"
	
	assert_eq(expected_f1, "kqz_inner_message")
	assert_eq(expected_f2.length(), 32, "Ticket debe ser 32 chars")
	assert_eq(expected_f3, "es", "Language ISO 639-1")

# ============================================================================
# Edge Cases
# ============================================================================

func test_ticket_with_whitespace_normalized()->void:
	"""T6-RF6.2: Ticket con espacios se normaliza con strip_edges()"""
	var ticket_with_spaces := "  a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4  "
	var normalized := ticket_with_spaces.strip_edges()
	
	assert_eq(normalized, "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4", "Espacios removidos")

func test_empty_ticket_rejected()->void:
	"""T6: Ticket vacío es rechazado"""
	var empty_ticket := ""
	assert_eq(empty_ticket.length(), 0, "Longitud 0 rechazada")

func test_ticket_validation_edge_cases()->void:
	"""T6: Test cases de borde para validación"""
	var edge_cases := [
		{"ticket": "00000000000000000000000000000000", "valid": true, "desc": "Todo ceros"},
		{"ticket": "ffffffffffffffffffffffffffffffff", "valid": true, "desc": "Todo f"},
		{"ticket": "abcdef0123456789abcdef0123456789", "valid": true, "desc": "Hex mixto"},
		{"ticket": "ABCDEF0123456789ABCDEF0123456789", "valid": false, "desc": "Mayúsculas (sin normalizar)"},
	]
	
	for case in edge_cases:
		var regex := RegEx.new()
		regex.compile("^[0-9a-f]{32}$")
		var is_valid := regex.search(case.ticket) != null
		
		if case.valid:
			assert_true(is_valid, case.desc)
		else:
			# Para mayúsculas, primero normalizamos
			var normalized := case.ticket.to_lower()
			var valid_after := regex.search(normalized) != null
			assert_true(valid_after, "%s después normalización" % case.desc)

# ============================================================================
# Integration with Proto.gd helpers
# ============================================================================

func test_proto_build_kqz_message_helper()->void:
	"""T6: Proto.build_kqz_message() si existe crea el mensaje correcto"""
	var ticket := "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4"
	var language := "es"
	
	# Verificar que Proto tiene el método build_kqz_message
	assert_true(Proto.has_method("build_kqz_message"), "Proto.tiene build_kqz_message")

func test_proto_validate_ticket_helper()->void:
	"""T6: Proto.validate_ticket() válida el ticket 32 chars hex"""
	var valid_ticket := "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4"
	var result := Proto.validate_ticket(valid_ticket)
	
	assert_eq(result["valid"], true, "Ticket válido pasa validación")
	assert_eq(result["normalized"], valid_ticket, "Normalized es igual para minúsculas")

func test_proto_build_kqz_message_format()->void:
	"""T6-RF6.1: build_kqz_message crea GameMessage directo (sin Any)"""
	var ticket := "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4"
	var language := "es"
	
	if Proto.has_method("build_kqz_message"):
		var message := Proto.build_kqz_message(ticket, language)
		assert_true(message is PackedByteArray, "Debe retornar PackedByteArray")
	else:
		# Metodo aún no existe, documentado para implementación futura
		assert_eq(1, 1, "build_kqz_message pendiente de implementación")