---
name: sdd-implement
description: Implementa una sola tarea de tasks.md con tests primero. Pausa al terminar.
disable-model-invocation: true
---

# Implementador SDD — Una tarea a la vez

Implementa tareas pequeñas siguiendo TDD y el plan.

## Pasos

1. **Lee la tarea.** `specs/001-xxx/tasks.md`, Tn elegida por el usuario
2. **Lee el plan.** `specs/001-xxx/plan.md`
3. **Lee la spec.** `specs/001-xxx/spec.md`
4. **Escribe test primero.** Crea el test que cubra los RF indicados
5. **Ejecuta test.** Debe fallar (rojo)
6. **Escribe código mínimo.** Solo para pasar el test
7. **Ejecuta test.** Debe pasar (verde)

## Ejecución de tests

### Godot (GUT)
```bash
Godot_console.exe --headless --path godot-client -s addons/gut/gut_cmdln.gd -gdir=res://test -gexit
```

### Python/pytest
```bash
pytest -q tests/
```

### JavaScript/Jest
```bash
npm test -- --testNamePattern="Tn"
```

## Output

- Código en `src/` o `habits/` según el proyecto
- Tests en `test/` o `tests/`
- tasks.md actualizado con `[x]` Tn

## Reglas

- Solo una tarea a la vez
- Tests primero, código mínimo
- Pausa al terminar: "Hecho Tn. ¿Continuar con T(n+1)?"
- Verifica RF cubiertos: `RF cubierto: RF-X, RF-Y`