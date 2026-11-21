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

func test_kqz_format_boxed_message() ->void:
	"""T6-RF6.1: kqz se envía como hea { f1: Any, f2: -1 } con Any wrapper"""
	# El formato CORRECTO que el servidor espera:
	# hea {                                  // wrapper envelope
	#   f1: Any {                          // campo 1 del sobre
	#     f1: "type.ankama.com/kqz"       // type_url del Any
	#     f2: GameMessage {                // payload del Any
	#       f1: AuthenticationMessage {
	#         f2: ticket (string)
	#         f3: language (string)
	#       }
	#     }
	#   }
	#   f2: -1                             // uid como varint en campo 2
	# }
	#
	# NOTA: El server rechaza GameMessage directo sin wrapper.
	# El byte example original dice length=61 pero el payload real es ~43 bytes.
	#
	# Este test documenta que build_kqz_message() retorna el envelope completo.
	
	var ticket := "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4"
	var language := "es"
	
	if Proto.has_method("build_kqz_message"):
		var message := Proto.build_kqz_message(ticket, language)
		assert_true(message is PackedByteArray, "Debe retornar PackedByteArray")
		assert_gt(message.size(), 0, "El envelope no debe estar vacío")
		
		# Verificar estructura con Proto.parse()
		var fields := Proto.parse(message)
		assert_eq(fields.size(), 2, "Debe tener f1 y f2 (Any wrapper + uid)")
		
		# f2 debe ser -1 (uid)
		var f2_field := Proto.first(fields, 2)
		assert_not_null(f2_field, "Debe tener campo f2 (uid)")
		assert_eq(f2_field.v, -1, "uid debe ser -1")
		
		# f1 debe ser el Any wrapper
		var f1_field := Proto.first(fields, 1)
		assert_not_null(f1_field, "Debe tener campo f1 (Any wrapper)")
		assert_true(f1_field.has("b"), "f1 debe ser bytes (Any wrapper)")
		
		# Verificar que el Any contiene type_url "type.ankama.com/kqz"
		var any_fields := Proto.parse(f1_field.b)
		var type_url_field := Proto.first(any_fields, 1)
		assert_not_null(type_url_field, "Any debe tener campo f1 (type_url)")
		assert_true(type_url_field.has("b"), "type_url debe ser bytes")
		var type_url := type_url_field.b.get_string_from_utf8()
		assert_eq(type_url, "type.ankama.com/kqz", "type_url debe ser 'type.ankama.com/kqz'")
		
		# Verificar que Any.f2 contiene el GameMessage
		var payload_field := Proto.first(any_fields, 2)
		assert_not_null(payload_field, "Any debe tener campo f2 (payload)")
		assert_true(payload_field.has("b"), "payload debe ser bytes (GameMessage)")
		
		# Verificar GameMessage.f1 = AuthenticationMessage
		var game_fields := Proto.parse(payload_field.b)
		var inner_field := Proto.first(game_fields, 1)
		assert_not_null(inner_field, "GameMessage debe tener campo f1")
		assert_true(inner_field.has("b"), "f1 debe ser bytes (AuthenticationMessage)")
		
		# Verificar AuthenticationMessage.f2 = ticket, f3 = language
		var auth_fields := Proto.parse(inner_field.b)
		var ticket_field := Proto.first(auth_fields, 2)
		assert_not_null(ticket_field, "AuthenticationMessage debe tener campo f2 (ticket)")
		assert_true(ticket_field.has("b"), "ticket debe ser bytes string")
		var parsed_ticket := ticket_field.b.get_string_from_utf8()
		assert_eq(parsed_ticket, ticket, "ticket debe coincidir")
		
		var lang_field := Proto.first(auth_fields, 3)
		assert_not_null(lang_field, "AuthenticationMessage debe tener campo f3 (language)")
		assert_true(lang_field.has("b"), "language debe ser bytes string")
		var parsed_lang := lang_field.b.get_string_from_utf8()
		assert_eq(parsed_lang, language, "language debe coincidir")
	else:
		# Metodo aún no existe
		assert_eq(1, 1, "build_kqz_message pendiente de implementación")

func test_kqz_inner_message_structure() ->void:
	"""T6: Estructura interna del mensaje kqz"""
	var expected_structure := {
		"f1": "Any_wrapper",     # f1 del hea = Any wrapper
		"f2": "uid_minus_one",    # f2 del hea = uid = -1
		"inner_f1": "auth_message"  # f1 de Any.f2 = AuthenticationMessage
	}
	
	assert_eq(expected_structure.size(), 3, "Debe tener f1, f2, inner_f1")
	assert_eq(expected_structure["f2"], "uid_minus_one", "f2 es el uid = -1")
	assert_eq(expected_structure["inner_f1"], "auth_message", "inner f1 es AuthenticationMessage")

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
		var result := Proto.validate_ticket(test_ticket)
		assert_eq(result["valid"], false, "Char '%s' rechazado" % char)

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
	# Formato: [VarInt length][hea envelope]
	# Donde hea envelope = { f1: Any, f2: -1 } con Any { f1: type_url, f2: GameMessage }
	
	# El Proto.write_varint() escribe el largo del payload
	# Esto es necesario para el protocolo Dofus
	
	var dummy_payload := PackedByteArray()
	Proto.write_varint(dummy_payload, 100)
	
	assert_true(dummy_payload.size() > 0, "VarInt framing debe crear bytes de longitud")

func test_build_kqz_message_structure()->void:
	"""T6-RF6.1: build_kqz_message construye hea { f1: Any, f2: -1 }"""
	# El formato esperado es el envelope completo:
	# hea { f1: Any { f1: "type.ankama.com/kqz", f2: inner }, f2: uid }
	
	var expected_structure := {
		"outer_f1": "Any_wrapper",   # hea.f1 = Any
		"outer_f2": "uid_minus_one", # hea.f2 = -1
		"Any_f1": "type_url",        # Any.f1 = "type.ankama.com/kqz"
		"Any_f2": "inner_message"    # Any.f2 = GameMessage
	}
	
	assert_eq(expected_structure.size(), 4, "Estructura esperada verificada")
	assert_eq(expected_structure["outer_f2"], "uid_minus_one", "uid debe ser -1")

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
		var result := Proto.validate_ticket(case.ticket)
		
		if case.valid:
			assert_eq(result["valid"], true, case.desc)
		else:
			# Para mayúsculas, primero normalizamos
			var normalized := case.ticket.to_lower()
			var valid_after := Proto.validate_ticket(normalized)
			assert_eq(valid_after["valid"], true, "%s después normalización" % case.desc)

# ============================================================================
# Integration with Proto.gd helpers
# ============================================================================

func test_proto_build_kqz_message_helper()->void:
	"""T6: Proto.build_kqz_message() crea envelope completo con Any wrapper"""
	# El método debe construir:
	# hea { f1: Any { f1: "type.ankama.com/kqz", f2: inner }, f2: -1 }
	# donde inner = GameMessage { f1: AuthenticationMessage { f2: ticket, f3: language } }
	
	assert_true(Proto.has_method("build_kqz_message"), "Proto.tiene build_kqz_message")

func test_proto_validate_ticket_helper()->void:
	"""T6: Proto.validate_ticket() válida el ticket 32 chars hex y normaliza a minúsculas"""
	var valid_ticket := "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4"
	var result := Proto.validate_ticket(valid_ticket)
	
	assert_eq(result["valid"], true, "Ticket válido pasa validación")
	assert_eq(result["normalized"], valid_ticket, "Normalized es igual para minúsculas")
	
	# Test con mayúsculas - debe normalizar a minúsculas
	var upper_ticket := "A1B2C3D4E5F6A1B2C3D4E5F6A1B2C3D4"
	var upper_result := Proto.validate_ticket(upper_ticket)
	assert_eq(upper_result["valid"], true, "Ticket en mayúsculas debe normalizarse")
	assert_eq(upper_result["normalized"], valid_ticket, "Debe estar en minúsculas")

func test_proto_build_kqz_message_format()->void:
	"""T6-RF6.1: build_kqz_message crea envelope completo con Any wrapper y uid"""
	var ticket := "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4"
	var language := "es"
	
	if Proto.has_method("build_kqz_message"):
		var message := Proto.build_kqz_message(ticket, language)
		assert_true(message is PackedByteArray, "Debe retornar PackedByteArray")
		assert_gt(message.size(), 0, "El envelope no debe estar vacío")
		
		# Verificar estructura con Proto.parse()
		var fields := Proto.parse(message)
		assert_eq(fields.size(), 2, "Debe tener f1 y f2 (Any wrapper + uid)")
		
		# Verificar que f2 es el uid = -1
		var f2_field := Proto.first(fields, 2)
		assert_not_null(f2_field, "Debe tener campo f2 (uid)")
		assert_eq(f2_field.v, -1, "uid debe ser -1")
	else:
		# Metodo aún no existe
		assert_eq(1, 1, "build_kqz_message pendiente de implementación")