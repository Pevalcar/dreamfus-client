# MCP Runtime Server - Stub for GUT testing
# This is a minimal stub that does nothing when running tests
# The actual MCP runtime is managed externally

extends Node

func _ready() -> void:
	if OS.has_feature("editor"):
		print("[MCP] Runtime server initialized (stub)")