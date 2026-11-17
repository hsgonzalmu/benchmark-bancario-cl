## Why

Al preguntar "¿Qué banco creció más en colocaciones en los últimos 12 meses?", el chat abría el gráfico de
crecimiento y respondía bien, pero el dashboard seguía en el banco anterior. Además, ese gráfico pintaba
de gris azulado a todos los bancos salvo el analizado, contra la regla de color fijo por banco.

## What Changes

- Cuando la respuesta identifica un banco ("el que más creció", "el que más participación ganó"), el chat
  SHALL dejarlo seleccionado en el dashboard con `seleccionar_analisis`, aunque la ventana siga abierta.
- `mostrar_grafico(tipo = "crecimiento")` agrega `para_dashboard` al resumen, con la llamada a hacer.
- `mostrar_tabla(tipo = "ranking")` agrega `mas_ganaron_participacion` (los 3 primeros, en pb) y
  `para_dashboard`; antes no devolvía datos para responder.
- El gráfico de crecimiento usa el color propio de cada banco (corrección; la regla ya estaba en
  "Sistema visual consistente").

## Impact

- `R/tools.R`, `R/modales.R`, `prompt.md`, `tests/test-tools.R`, spec `chat-analista`.
- Estado reactivo: `banco_foco` lo cambia `seleccionar_analisis`, como antes; las tools de ventanas siguen
  sin cambiar el estado.
