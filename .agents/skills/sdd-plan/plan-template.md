# Plan NNN - <Nombre>

## Arquitectura de modulos
[Diagrama o lista con dependencias]

## Modelo de datos 
```json
{ejemplo JSON con campo clave y descripción}
```

## Algoritmo principal (pseudocódigo)
```
ENTRAR: user, password
  SI user valido:
    token <- login(user, password)
    DEVOLVER token
  SINO:
    LANZAR Error("Credenciales invalidas") 
```

## Contrato de la CLI
| Comando | Entrada | Salida | Código error |
|---|---|---|---|
| comando-1 | <args> | <output> | 0/1/2 |

## Decisiones técnicas
- Decisión 1: <justificación>
  - Alternativa descartada: <por qué se evita>

## Cobertura de RF
| RF | Módulo | Test asociado |
|---|---|---|
| RF-1 | MóduloA | test_xxxx |
| RF-2 | ModB | test_yyyy |