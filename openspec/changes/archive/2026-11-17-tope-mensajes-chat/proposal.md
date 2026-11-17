## Why

La app se publicará en shinyapps.io con la API key de Anthropic del dueño. Sin un tope, cualquier persona
con el link puede usar el chat sin límite y el costo lo paga el dueño.

## What Changes

- Cada sesión del navegador puede enviar como máximo N mensajes al chat (15 por defecto, configurable con
  `MAX_MENSAJES_CHAT` en `.Renviron`).
- Al llegar al tope, el chat responde un aviso fijo sin llamar a la API; el dashboard y los filtros siguen
  funcionando. Recargar la página abre una sesión nueva (el tope frena el abuso casual, no uno decidido;
  para eso está el límite de gasto en la consola de Anthropic).

## Impact

- `app.R`, `README.md`, spec `chat-analista`.
- Estado: un contador por sesión en el server (variable local, no `reactiveVal`: no dibuja nada). Ninguna
  tool lo cambia.
