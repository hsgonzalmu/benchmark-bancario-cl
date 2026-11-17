# Proposal

## Why

Al preguntar "¿quién es el top en depósitos en UF?", el chat cambia la cuenta y las monedas, pero el
dashboard sigue mostrando el banco que estaba seleccionado, porque `seleccionar_analisis` solo acepta un
banco por su nombre y el líder no se conoce antes de consultar. El dashboard debe quedar en el banco por
el que se pregunta.

## What Changes

- `seleccionar_analisis` acepta un argumento opcional `puesto` (1 = líder, 2 = segundo, etc.) que
  selecciona al banco en ese puesto de la cuenta, período y monedas resultantes de la misma llamada.
  `banco` y `puesto` no se pueden usar juntos.
- El prompt indica que las preguntas por el líder o por un puesto ("el top", "el segundo", "el último")
  deben dejar ese banco seleccionado en el dashboard.

## Capabilities

### New Capabilities
<!-- Ninguna. -->

### Modified Capabilities
- `chat-analista`: `seleccionar_analisis` con `puesto`.

## Impact

- `app-benchmark/`: `R/tools.R`, `prompt.md`, `tests/test-tools.R`, README.
