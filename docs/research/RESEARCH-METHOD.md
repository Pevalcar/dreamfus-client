# Método de investigación y verificación

## 1. Por qué existe este documento

Los proyectos comunitarios de Dofus mezclan código propio, código
descompilado, assets propietarios, datos históricos y herramientas de
investigación. Una URL pública no prueba que todo su contenido sea reutilizable
ni que una afirmación sobre una versión siga siendo correcta.

## 2. Ficha obligatoria de cada referencia

```text
Nombre:
URL:
Repositorio:
Rama/tag:
Commit:
Fecha de consulta:
Lenguaje:
Versión Dofus:
Componente:
Licencia declarada:
LICENSE/NOTICE comprobados:
Archivos revisados:
Hallazgos:
Confianza:
Uso permitido en DreamFus:
```

## 3. Niveles de evidencia

| Nivel | Evidencia |
|---|---|
| A | código fuente + tests + documentación del mismo commit |
| B | código fuente del commit, sin test completo |
| C | README, issue o descripción del repositorio |
| D | captura, vídeo, comentario o inferencia |

Las decisiones de protocolo y reglas de combate requieren A o B. Un nivel C o
D solo puede generar una tarea de investigación.

## 4. Flujo de verificación

```text
buscar repositorio
  -> fijar commit
  -> leer licencia
  -> leer README
  -> localizar módulo
  -> leer tests
  -> comparar con otra fuente
  -> registrar diferencias
  -> crear hipótesis propia
  -> validar contra DreamFus
```

## 5. Regla de código y assets

### Puede inspirar

- nombres de capas conceptuales;
- separación de módulos;
- algoritmos descritos públicamente;
- formatos propios documentados;
- ideas de tests;
- diseño de herramientas.

### No copiar sin autorización y revisión legal

- código sin licencia;
- código GPL/LGPL/Apache en un destino cuya licencia no se ha decidido;
- fuentes descompiladas de un cliente oficial;
- mapas, sprites, música, sonidos, fuentes y logos;
- binarios distribuidos por terceros;
- datos de tráfico o cuentas.

## 6. Registro de una conclusión

Usar siempre:

```text
Conclusión:
Fuente:
Commit:
Evidencia:
Confianza:
Limitaciones:
Decisión en DreamFus:
Test que falta:
```

## 7. Calidad de los documentos

Un documento nuevo debe:

- enlazar fuentes;
- distinguir hecho de hipótesis;
- no inventar nombres de mensajes;
- incluir versión;
- indicar licencia;
- indicar qué no se debe copiar;
- proponer una forma de validación;
- enlazarse desde `INDEX.md`.

