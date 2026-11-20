# sdd-setup

Skill para detectar ausencia de AGENTS.md y docs/constitution.md, y generar plantillas mínimas siguiendo el template SDD.

## Qué hace

- Detecta si el proyecto necesita setup inicial
- Genera `AGENTS.md` siguiendo tu template
- Crea `docs/constitution.md` con 6 principios innegociables
- Pausa para aprobación humana

## Uso

```
/sdd-setup
```

## Output

- `docs/constitution.md` - Principios del proyecto
- `AGENTS.md` - Instrucciones para el agente

## Ver también

- `/sdd-discover` - Detecta estado del proyecto
- `/sdd-constitution` - Verifica constitution específica
