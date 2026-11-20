# sdd-discover — Descubridor de Perfil

Este meta-skill analiza tu proyecto y decide qué skills activar.

## Uso

```bash
/sdd-discover
/sdd-discover resume
/sdd-discover status
```

## Qué hace

1. Escanea archivos de configuración (`package.json`, `Cargo.toml`, etc.)
2. Detecta el perfil tecnológico (web, systems, game-dev, mobile, infrastructure)
3. Muestra estado actual del proyecto
4. Recomienda el siguiente skill a ejecutar

## Integración

Se ejecuta automáticamente al inicio de cualquier sesión SDD. También puedes invocarlo manualmente cuando cambies de contexto o quieras verificar el estado.

## Ver también

- [`profiles/`](../../profiles/) — Reglas específicas por tecnología
- [`references/`](../../references/) — Checklists transversales
- [`sdd-flow`](../sdd-flow/) — Wizard completo automatizado
