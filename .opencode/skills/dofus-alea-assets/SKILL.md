---
name: dofus-alea-assets
description: Audita una instalación local de Alea en modo solo lectura, cataloga UI declarativa, JSON/UXML, USS/DFSS, manifests, 9-slice, imágenes, fuentes, animaciones, audio y localización, y convierte observaciones en schemas y componentes propios sin copiar assets propietarios.
---

# Skill: auditoría de datos y UI de Alea

## Fuentes obligatorias

- `docs/research/ALEA-DATA-GUIDE.md`
- `docs/research/ALEA-AUDIT-OUTPUT.md`
- `docs/research/RESEARCH-METHOD.md`
- `frontend/src/dfui/index.js`
- `frontend/src/SliceManager.js`

## Regla principal

La instalación de Alea es una referencia local, no una dependencia del build y
no una fuente para redistribuir assets. Trabajar en modo read-only.

## Antes de auditar

1. Pedir o confirmar una ruta local explícita.
2. Comprobar que existe sin imprimir archivos sensibles.
3. No copiar carpetas completas.
4. No incluir la ruta absoluta personal en documentos publicados.
5. Registrar versión y fecha si se conocen.

## Qué producir

- conteos por extensión;
- nombres de manifests;
- dimensiones y hashes de imágenes, sin copiarlas;
- lista de componentes;
- lista de pantallas;
- referencias entre UI y assets;
- datos de 9-slice;
- fuentes y fallback;
- categorías de audio y animación;
- ids de localización;
- incertidumbres y tareas de verificación.

## Qué no hacer

- no copiar PNG, atlas, audio, fuentes, bundles o binarios;
- no copiar documentos completos de UI propietarios;
- no extraer cuentas, tokens o tráfico;
- no publicar rutas de usuario;
- no convertir nombres inferidos en contratos;
- no modificar la instalación de Alea.

## Conversión a DreamFus

Para cada hallazgo:

```text
dato observado
  -> descripción neutral
  -> schema propio
  -> placeholder propio
  -> componente DFUI
  -> test de render
```

Ejemplo:

```text
9-slice observado
  -> registrar cuatro márgenes numéricos
  -> crear fixture sintético
  -> probar SliceManager
  -> usar imagen original DreamFus
```

## Criterios de finalización

- build funciona sin Alea;
- no hay assets propietarios añadidos;
- inventario no contiene secretos;
- cada conclusión tiene evidencia y confianza;
- los nuevos componentes tienen estados loading/empty/error/disabled;
- las pantallas se desmontan y retiran listeners;
- el resultado se enlaza desde `docs/research/INDEX.md`.

