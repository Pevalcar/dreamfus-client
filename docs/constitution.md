# Constitución — DreamFus Client

1. **Stack mínimo.** Godot 4.8 o superior + GDScript. Sin C#, sin addons ni dependencias nuevas sin aprobación.
   `Alea` y `jondo-servidor` son solo lectura: no se modifican ni se importan como código.
2. **Spec antes que código.** Ningún mensaje, opcode o campo de mapa se implementa sin estar descrito en
   `docs/`. Cada parser cita su sección; los IDs y offsets se declaran una sola vez.
3. **Lógica sin escena.** `src/Core`, `src/Network`, `src/Data` no extienden `Control`/`Node2D` ni leen input.
   `src/UI` no habla protocolo: recibe datos y emite señales.
4. **Test donde hay lógica.** Cambio en parser, protocolo, mapa o sesión → test headless que falla antes del
   arreglo. Cambio solo visual no requiere test; si toca login o entrada al mundo, sí e2e.
5. **El servidor manda.** El cliente no persiste estado de juego; solo caché reconstruible (assets, token).
   Los assets de Alea se generan con `tools/` y no se commitean.
6. **Idioma.** Identificadores y comentarios en inglés; docs, commits y texto de jugador en español.
   Un texto visible se define en un solo sitio, nunca copiado entre escenas.