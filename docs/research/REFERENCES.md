# Referencias externas, licencias y fuentes de ideas

## 1. Cómo leer estas referencias

Los repositorios se clasifican así:

- **Cliente:** ayuda a estudiar flujo de pantallas, entidades y presentación.
- **Emulador:** ayuda a estudiar mensajes, estados de mundo y combate.
- **Framework/protocolo:** ayuda a estudiar serialización y separación de
  infraestructura.

La fecha y la rama importan. Antes de usar una referencia, fijar un commit y
guardar su URL. No basarse en capturas o binarios descargados de terceros.

## 2. Cliente y fuentes de cliente

### Emudofus/Dofus

- URL: https://github.com/Emudofus/Dofus
- Descripción: fuentes de un cliente antiguo basado en ActionScript.
- Estudiar: flujo de login, pantallas, mundo, combate, eventos y entidades.
- Licencia: comprobar el repositorio y el commit antes de reutilizar cualquier
  archivo; no asumir licencia por ser público.
- Reutilización recomendada: ideas y lectura comparativa, no copia directa.

### Danmachi1/lindor

- URL: https://github.com/Danmachi1/lindor
- Descripción: cliente de Dofus Touch para escritorio basado en tecnologías
  multiplataforma.
- Licencia declarada en la consulta: GPL-3.0.
- Estudiar: empaquetado multiplataforma, integración de aplicación web y
  distribución.
- Reutilización: una copia de código GPL exige revisar obligaciones de
  distribución; los recursos de Ankama siguen siendo un asunto separado.

## 3. Emuladores 1.29

### GDCore

- URL: https://github.com/BotanAtomic/GDCore
- Descripción: emulador 1.29 en Java.
- Estudiar: servicios, scripts, personajes, mapas y separación de mundo.
- Licencia: verificar en el commit utilizado.

### CodeBreak

- URL: https://github.com/hussein-aitlahcen/codebreak
- Descripción: emulador 1.29 en C# con auth service, world service, RPC,
  herramientas y web.
- Estudiar: división de servicios y diseño aplicable a contratos de cliente.
- Licencia: verificar antes de copiar código.

### Ancestra-Evolutive

- URL: https://github.com/Romain-P/Ancestra-Evolutive
- Descripción: emulador 1.29 en Java.
- Estudiar: modelo histórico de mundo y mensajes.
- Licencia: verificar el repositorio concreto.

### Graviton

- URL: https://github.com/BotanAtomic/Graviton
- Descripción: emulador 1.29 en Java.
- Estudiar: organización de servicios y datos.
- Licencia: verificar el repositorio concreto.

### gofus

- URL: https://github.com/Emudofus/gofus
- Descripción: emulador 1.29 en Go.
- Estudiar: concurrencia, servicios y transporte en otro lenguaje.
- Licencia: verificar el repositorio concreto.

### AncestraRemake

- URL: https://github.com/reben/AncestraRemake
- Descripción: emulador 1.29.
- Licencia declarada en la consulta: Apache-2.0.
- Estudiar: estructura y evolución histórica.
- Reutilización: conservar NOTICE/atribución si algún código compatible se
  incorpora; comprobar qué archivos están realmente cubiertos.

## 4. Emuladores 2.0

### Desperion

- URL: https://github.com/scalexm/desperion
- Descripción: emulador 2.0 en C++.
- Licencia declarada: GPL-3.0.
- Estudiar: servicios, mensajes, mundo y combate.
- Reutilización: no mezclar código GPL con una parte MIT sin una decisión
  explícita de licencia.

### Rollback

- URL: https://github.com/Neyzv/Rollback
- Descripción: emulador 2.0 en .NET 6.
- Licencia declarada: GPL-3.0.
- Estudiar: organización moderna de dominio, servicios, mensajes y persistencia.
- Reutilización: lectura y extracción de ideas; revisar copyleft antes de
  copiar cualquier implementación.

### Past

- URL: https://github.com/unknown31415/Past
- Descripción: emulador 2.0 en C#.
- Estudiar: modelos y mensajes históricos.
- Licencia: verificar antes de reutilizar.

### Stigma

- URL: https://github.com/levylennon/stigma
- Descripción: prueba de concepto de emulador 2.0 en C#.
- Licencia declarada: MIT.
- Estudiar: conceptos de reverse engineering y diseño de prueba.
- Reutilización: comprobar el archivo LICENSE y la procedencia de datos y
  assets antes de incorporar código.

### Eraz

- URL: https://github.com/mih-awk/eraz
- Descripción: emulador antiguo de Dofus 2.0.
- Estudiar: únicamente como referencia histórica salvo que el commit declare
  una licencia utilizable.

## 5. Rust y protocolos

### holomorph

- URL: https://github.com/scalexm/holomorph
- Descripción: emulador Dofus escrito en Rust.
- Licencia declarada: MIT.
- Estudiar: ownership, tareas, servicios y separación entre red y dominio.

### dofus-framework

- URL: https://github.com/dofuzeiro/dofus-framework
- Descripción: framework Rust para un emulador Dofus.
- Licencia declarada: Apache-2.0.
- Estudiar: módulos reutilizables, infraestructura y contratos.

### dofus-unity-protocol-builder

- URL: https://github.com/LuaxY/dofus-unity-protocol-builder
- Descripción: herramienta relacionada con construcción de protocolo para
  Dofus/Unity.
- Estudiar: schemas, generación de mensajes y herramientas de protocolo.
- Licencia: verificar el repositorio antes de copiar código.

## 6. Búsquedas para encontrar más material

Estas búsquedas reproducibles son más fiables que enlaces de descargas
aleatorias:

- GitHub: https://github.com/search?q=dofus+client&type=repositories
- GitHub: https://github.com/search?q=dofus+emulator&type=repositories
- GitHub: https://github.com/search?q=dofus+protocol&type=repositories
- GitHub: https://github.com/search?q=dofus+1.29&type=repositories
- GitHub: https://github.com/search?q=dofus+2.0&type=repositories
- GitHub Rust: https://github.com/search?q=dofus+language%3ARust&type=repositories
- GitHub TypeScript: https://github.com/search?q=dofus+language%3ATypeScript&type=repositories
- GitHub topics: https://github.com/topics/dofus

También revisar:

- forks y pull requests del proyecto de referencia;
- tags y releases, no solo `main`;
- issues que describan protocolos;
- archivos `LICENSE`, `NOTICE`, `COPYING` y `README`;
- historial de commits de cada módulo;
- dependencias y submódulos.

## 7. Qué descargar y qué no

Descargar para estudio:

- código fuente;
- documentación;
- tests;
- schemas;
- ejemplos de mensajes sintéticos;
- historial Git.

No descargar ni versionar en este repositorio:

- clientes oficiales completos;
- binarios redistribuibles sin autorización;
- assets de Ankama;
- música, sonidos, sprites o fuentes extraídas;
- dumps de tráfico con cuentas reales;
- bases de jugadores;
- credenciales;
- instaladores de procedencia dudosa.

## 8. Matriz de decisión para copiar código

Antes de copiar un archivo:

```text
¿Tiene licencia explícita?
  no -> no copiar; usar como referencia
  sí -> ¿la licencia es compatible con el destino?
          no está claro -> consultar antes
          sí -> conservar copyright/NOTICE
```

Para una idea:

```text
describir el comportamiento
  -> definir contrato propio
  -> escribir implementación propia
  -> añadir test
  -> registrar la inspiración y la licencia
```

La atribución de una idea no sustituye las obligaciones de una licencia de
software.

