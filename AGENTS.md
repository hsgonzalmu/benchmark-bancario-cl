# Convenciones del repositorio

## Propósito

Apps Shiny en R con chat (ellmer + shinychat), tools y, cuando corresponda, servidores MCP.

## Guía base

Antes de crear o modificar una app, lee `docs/guia-r-shiny-chat.md`. Resume la estructura Shiny, el uso
de ellmer, shinychat y MCP, las tools de modales (`mostrar_tabla()`, `mostrar_grafico()`), el SQL de
solo lectura y un checklist. Los ejemplos ejecutables de referencia están en `../shiny-chat-patterns-main`.

## Flujo de trabajo

- Usa OpenSpec para cada cambio de comportamiento: propuesta, tareas y deltas de specs antes del código.
- En cada spec describe las tools (nombre, argumentos, qué devuelven y qué cambian en la UI), el estado
  reactivo (qué `reactiveVal` existen y qué tool los modifica) y escenarios conversacionales.
- Implementa contra la propuesta aprobada y archívala al terminar.

## Estilo

- Líneas de 110 caracteres o menos, incluidos los prompts Markdown.
- R base y pipe nativo `|>`; evita helpers y dependencias que no sean necesarias.
- Cada app se ejecuta de forma independiente desde su carpeta.
