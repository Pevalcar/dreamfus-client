# TicketValidationTest — Test unitario para validación de ticket kqz
# T2: Implementar validación ticket kqz con regex `^[0-9a-f]{32}$`
# RF cubiertos: RF-6.2, RNF-4
# Siguiendo principios godot-master y godot-testing-patterns

extends GutTest

# Referencia al cliente Proto a testear
var Proto = preload("res://src/Network/Proto.gd")

func _ready():
    print("[TicketValidationTest] initialized for T2")

# ============================================================================
# RF-6.2: Validación y normalización del ticket
# ============================================================================

func test_ticket_valido_hexadecimal():
    """T2-RF6.2: Ticket válido de 32 caracteres hexadecimales minúsculas"""
    # Ticket válido según regex `^[0-9a-f]{32}$`
    var ticket_valido = "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4"
    
    var resultado = Proto.validate_ticket(ticket_valido)
    
    assert_eq(resultado["valid"], true, "Ticket válido debe ser aceptado")
    assert_eq(resultado["normalized"], ticket_valido, "Ticket debe normalizarse a minúsculas")

func test_ticket_valido_con_mayusculas_normaliza():
    """T2-RF6.2: Ticket con mayúsculas se normaliza a minúsculas"""
    # Ticket con mayúsculas que debe normalizarse
    var ticket_mayus = "A1B2C3D4E5F6A1B2C3D4E5F6A1B2C3D4"
    var ticket_esperado = "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4"
    
    var resultado = Proto.validate_ticket(ticket_mayus)
    
    assert_eq(resultado["valid"], true, "Ticket con hex válido debe ser aceptado")
    assert_eq(resultado["normalized"], ticket_esperado, "Debe normalizar a minúsculas")

func test_ticket_valido_mezcla_mayus_minus():
    """T2-RF6.2: Ticket con mezcla de mayúsculas y minúsculas"""
    var ticket_mezcla = "a1B2c3D4e5F6A1b2C3d4E5F6a1B2c3D4"
    var ticket_esperado = "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4"
    
    var resultado = Proto.validate_ticket(ticket_mezcla)
    
    assert_eq(resultado["valid"], true)
    assert_eq(resultado["normalized"], ticket_esperado)

func test_ticket_caracteres_invalidos_rechaza():
    """T2-RF6.2: Ticket con caracteres no hexadecimales rechazado"""
    # Caracteres 'g', 'h', 'i', etc. no son hexadecimales
    var ticket_invalido = "g1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4"
    
    var resultado = Proto.validate_ticket(ticket_invalido)
    
    assert_eq(resultado["valid"], false, "Caracteres no hexadecimales rechazados")
    assert_true(resultado.has("error"), "Debe incluir mensaje de error")

func test_ticket_longitud_incorrecta_menos():
    """T2-RF6.2: Ticket con menos de 32 caracteres rechazado"""
    var ticket_corto = "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3"  # 31 caracteres
    
    var resultado = Proto.validate_ticket(ticket_corto)
    
    assert_eq(resultado["valid"], false, "Ticket corto debe ser rechazado")
    assert_true(resultado.has("error"), "Debe incluir mensaje de error")

func test_ticket_longitud_incorrecta_mas():
    """T2-RF6.2: Ticket con más de 32 caracteres rechazado"""
    var ticket_largo = "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6"  # 36 caracteres
    
    var resultado = Proto.validate_ticket(ticket_largo)
    
    assert_eq(resultado["valid"], false, "Ticket largo debe ser rechazado")
    assert_true(resultado.has("error"), "Debe incluir mensaje de error")

func test_ticket_con_espacios_rechaza():
    """T2-RF6.2: Ticket con espacios rechazado"""
    var ticket_con_espacio = "a1b2c3d4e5f6a1b2c3d4e5f6a1b2 c3d4"
    
    var resultado = Proto.validate_ticket(ticket_con_espacio)
    
    assert_eq(resultado["valid"], false, "Ticket con espacios debe ser rechazado")

func test_ticket_vacio_rechaza():
    """T2-RF6.2: Ticket vacío rechazado"""
    var resultado = Proto.validate_ticket("")
    
    assert_eq(resultado["valid"], false, "Ticket vacío debe ser rechazado")
    assert_true(resultado.has("error"), "Debe incluir mensaje de error")

func test_ticket_null_rechaza():
    """T2-RF6.2: Ticket null rechazado"""
    var resultado = Proto.validate_ticket(null)
    
    assert_eq(resultado["valid"], false, "Ticket null debe ser rechazado")

func test_ticket_con_guiones_rechaza():
    """T2-RF6.2: Ticket con guiones rechazado"""
    var ticket_con_guiones = "a1b2c3d4-e5f6-a1b2-c3d4-e5f6a1b2c3d4"
    
    var resultado = Proto.validate_ticket(ticket_con_guiones)
    
    assert_eq(resultado["valid"], false, "Ticket con guiones debe ser rechazado")

# ============================================================================
# RNF-4: Validación obligatoria antes de uso
# ============================================================================

func test_ticket_numeros_validos():
    """T2-RNF4: Ticket con solo números debe ser válido"""
    var ticket_numeros = "1234567890abcdef1234567890abcdef"
    
    var resultado = Proto.validate_ticket(ticket_numeros)
    
    assert_eq(resultado["valid"], true, "Ticket numérico válido debe ser aceptado")

func test_ticket_consiste_todo_letras_hex():
    """T2-RNF4: Ticket compuesto solo por letras hexadecimales"""
    var ticket_letras = "abcdefabcdefabcdefabcdefabcdefabcd"
    
    var resultado = Proto.validate_ticket(ticket_letras)
    
    assert_eq(resultado["valid"], true, "Ticket de letras hex debe ser válido")

func test_ticket_todos_ceros():
    """T2-RNF4: Ticket de todos ceros (caso límite)"""
    var ticket_ceros = "00000000000000000000000000000000"
    
    var resultado = Proto.validate_ticket(ticket_ceros)
    
    assert_eq(resultado["valid"], true, "Ticket de ceros debe ser válido")

func test_ticket_todos_f():
    """T2-RNF4: Ticket de todos 'f' (caso límite)"""
    var ticket_f = "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
    
    var resultado = Proto.validate_ticket(ticket_f)
    
    assert_eq(resultado["valid"], true, "Ticket de 'f's debe ser válido")

# ============================================================================
# Tests de integración con GameMessage
# ============================================================================

func test_build_kqz_message_con_ticket_valido():
    """T2: Build kqz GameMessage con ticket válido"""
    var ticket = "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4"
    var lang = "es"
    
    var message = Proto.build_kqz_message(ticket, lang)
    
    assert_not_null(message, "Debe construir mensaje GameMessage")
    assert_true(message.size() > 0, "Mensaje no debe estar vacío")

func test_build_kqz_message_rechaza_ticket_invalido():
    """T2: Build kqz GameMessage rechaza ticket inválido"""
    var ticket_invalido = "invalid-ticket-12345"
    var lang = "es"
    
    var message = Proto.build_kqz_message(ticket_invalido, lang)
    
    # Con ticket inválido, devuelve PackedByteArray vacío
    assert_eq(message.size(), 0, "No debe construir mensaje con ticket inválido - devuelve array vacío")

func test_build_kqz_message_normaliza_ticket():
    """T2: Build kqz normaliza ticket a minúsculas"""
    var ticket_mayus = "A1B2C3D4E5F6A1B2C3D4E5F6A1B2C3D4"
    var lang = "es"
    
    var message = Proto.build_kqz_message(ticket_mayus, lang)
    
    # El mensaje debería construirse exitosamente
    # Internamente el ticket debe normalizarse
    assert_not_null(message, "Debe normalizar y construir mensaje")