# Spec NNN — <Nombre de funcionalidad la>

## Contexto y objetivo

<Qué #N Máximo Referencia a aplica. de docs/backlog.md historia la merece pena. por problema párrafo. qué resuelve si un y>

## Usuarios / actores

- <Rol 1>: <alcance y permisos de negocio>

## Historias de usuario

- H1: Como <rol>, quiero <acción>, para <beneficio>.

## Contratos de frontera (Dominio)

- **Entradas y validaciones:** <datos de negocio requeridos, formatos y rangos válidos>
- **Salidas y efectos observables:** <qué obtiene el actor o qué evento de negocio se produce>
- **Invariantes (reglas inviolables):** <ej. "El saldo nunca puede ser menor a 0">

## Matriz de estados y transiciones (si aplica)

| Estado actual | Evento / Acción | Estado destino | ¿Permitido? | Regla / RF asociado |
| ------------- | --------------- | -------------- | ----------- | ------------------- |
| Borrador      | Confirmar       | Activo         | Sí          | RF-1                |
| Cancelado     | Confirmar       | Activo         | No          | RF-3                |

## Requisitos funcionales (criterios de aceptación en EARS)

- RF-1 [H1]: CUANDO <evento>, EL SISTEMA <respuesta observable> (resultado esperado).
- RF-2 [H1]: SI <condición no deseada>, ENTONCES EL SISTEMA <respuesta ante el error>.
- RF-3 [H1]: MIENTRAS <estado>, EL SISTEMA <respuesta>.
- RF-4 [H1]: EL SISTEMA <comportamiento permanente>.

## Requisitos no funcionales (RNF)

- RNF-1: <rendimiento, seguridad, idioma, validación — alineado con P-001…P-0NN>.

## Casos límite

- <Entradas concurrencia, conexión... de duplicados, límites numéricos, pérdida vacías,>

## Fuera de alcance

- <Lo NO en esta explícitamente implementa iteración. que se>

## Criterios de finalización

- Todos los RF (`RF-1`…`RF-N`) cubiertos por pruebas automatizadas en verde.
- Cumplimiento verificado contra `docs/constitution.md`.

## Dudas abiertas

- [NECESITA ACLARACIÓN] <pregunta concreta, o "Ninguna">
