# Proposal

## Why

Los gráficos y tablas del chat usan siempre la cuenta seleccionada, así que no pueden mostrar la evolución
de dos o más cuentas de un mismo banco (por ejemplo, colocaciones y depósitos a plazo de BCI), que es una
pregunta habitual. Además, las preguntas de ejemplo del saludo nombran a bancos concretos (Internacional,
Itaú, Falabella), cuando deberían servir para cualquier análisis.

## What Changes

- Nuevo tipo `cuentas` en `mostrar_grafico` y `mostrar_tabla`: un banco (el analizado o el indicado) y de
  2 a 6 cuentas, en una medida a elegir: monto, índice base 100 o participación sobre el sistema.
- Nuevos argumentos opcionales: `cuentas` y `medida` en `mostrar_grafico`; `cuentas`, `banco` y
  `medida` en `mostrar_tabla`.
- Preguntas del saludo genéricas, sin un banco fijo (líder, mayor crecimiento del último año, bancos que
  ganaron participación, evolución de dos cuentas del líder), y en número de cuatro.

## Capabilities

### New Capabilities
<!-- Ninguna. -->

### Modified Capabilities
- `ranking-bancos`: serie de varias cuentas de un banco.
- `chat-analista`: tipo `cuentas` en `mostrar_grafico` y `mostrar_tabla`; saludo con preguntas
  genéricas.

## Impact

- `app-benchmark/`: `R/ranking.R`, `R/modales.R`, `R/tools.R`, `greeting.md`, `prompt.md`, pruebas y
  README.
- Sin dependencias nuevas. La paleta de bancos sigue en pausa; las cuentas usan una paleta categórica
  propia validada.
