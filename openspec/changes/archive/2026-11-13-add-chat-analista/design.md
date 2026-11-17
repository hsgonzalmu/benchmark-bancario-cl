# Design

## Context

La fase 1 (archivada en `2026-11-13-add-datos-y-dashboard-base`) dejó el estado en cinco `reactiveVal` y
los cálculos como funciones puras en `R/ranking.R` (`calcular_ranking`, `resumen_posicion`,
`series_comparacion`). Instalados: `ellmer` 0.5.2 y `shinychat` 0.5.0. `ANTHROPIC_API_KEY` no está
definida en el equipo. Referencia de patrón: `../shiny-chat-patterns-main/app-07` (filtros y chat en un
acordeón).

## Goals / Non-Goals

**Goals:**
- Que el chat maneje el mismo estado que los filtros, sin un segundo camino de datos.
- Que las tools sean comprobables sin llamar al modelo.
- Respuestas con cifras exactas y ya formateadas, sin cálculo del modelo.

**Non-Goals:**
- Modales de tablas o gráficos, SQL libre, visión (fase 3).
- Memoria entre sesiones o historial persistente.

## Decisions

**Modelo: `claude-opus-5-5` vía `ellmer::chat_anthropic()`.** Es el modelo por defecto recomendado. Se
usa `params(reasoning_effort = "low")`: en `ellmer` 0.5.2 eso envía `thinking: adaptive` y
`output_config.effort`, que es lo que Opus 5.5 acepta (rechaza `budget_tokens` y thinking desactivado).
Effort `low` porque es un chat de consulta con tools simples; se sube a `medium` solo si las pruebas de
conversación muestran errores de razonamiento. Se activa el fallback del servidor ante rechazos
(`beta_headers = "server-side-fallback-2026-07-01"`, `api_args = list(fallbacks = "default")`). El modelo
queda en una constante al inicio de `app.R` para cambiarlo fácil.
Alternativa: `claude-sonnet-5-5`, más barato; se deja como opción en el README, no como defecto.

**Tools en `R/tools.R` como fábrica.** `crear_tools(estado, contexto)` recibe la lista de `reactiveVal` y
los datos (balance, nombres, cuentas) y devuelve las funciones y sus definiciones `ellmer::tool()`. El
server las registra. Así `tests/test-tools.R` prueba las tools con `reactiveVal` reales dentro de
`isolate()`, sin modelo ni navegador. Alternativa: definirlas dentro de `server` (como `app-07`); se
descarta porque solo se podrían probar con el modelo.

**Argumentos acotados con `type_enum()`.** Bancos por nombre corto (sin "Sistema"), cuentas por nombre
amigable, períodos `AAAAMM`, tipos de valor y modos por su etiqueta. Los argumentos de
`seleccionar_analisis` son `required = FALSE` con `NULL` por defecto. `bancos` es
`type_array(type_enum(...), required = FALSE)` y el máximo de 4 se valida con `stop()`, porque el esquema
no expresa largo máximo de forma portable.

**Las tools devuelven JSON.** `ellmer` 0.5.2 depreca convertir listas automáticamente, así que cada tool
devuelve `jsonlite::toJSON(x, auto_unbox = TRUE)`. Verificado el 13-11-2026 con una llamada real:
Opus 5.5 con effort `low` y fallback del servidor responde en ~5 s con ~1.000 tokens de entrada.

**Resumen con cifras ya formateadas.** `resumen_para_chat()` arma una lista con textos ("MM$ 4.945.269",
"1,78 %", "+3,5 %") usando `R/formato.R`, más el ranking como data.frame de textos. El modelo cita, no
calcula ni formatea; las cifras coinciden con las del dashboard. `comparar` agrega, para cada integrante
de la serie, monto y participación al inicio y al final de la ventana y la variación acumulada, y la
brecha con el foco al inicio y al final. En modo `vecinos` se resumen solo foco y vecinos (no los 17
bancos).

**Sincronización de filtros sin bandera.** Las tools escriben en los `reactiveVal` y llaman a
`update*Input()` con los nuevos valores. Los `observeEvent` de los inputs vuelven a escribir el mismo
valor; un `reactiveVal` con el mismo valor no invalida, así que no hay bucle ni hace falta la bandera de
`app-07` (que existía porque allí cambiaba la fuente de datos). Para `modo` y `bancos`, el observador
escribe `comparacion` solo si difiere del valor actual; el estado final queda consistente aunque los dos
inputs lleguen en mensajes distintos. Si las pruebas muestran un parpadeo, se agrega la bandera.

**Banco inicial calculado al iniciar.** `inicial$banco <- calcular_ranking(balance, "144000000",
periodos[1])$cod_ifi[1]` (hoy BCI). Al ser líder, su caja de vecino superior muestra "N/A · Es el líder
de la cuenta", lo que comunica la posición sin otro cambio.

**Sidebar: acordeón "Chat" / "Filtros" de 400 px.** `accordion(multiple = FALSE, open = "Chat")`, como en
`app-07`. El chat usa `chat_ui(..., height = "100%", fill = TRUE)` para ocupar el alto disponible.
Alternativa: chat en un segundo sidebar a la derecha; más espacio, pero quita ancho a los gráficos.

**Streaming.** `chat$stream_async(..., tool_mode = "sequential", stream = "content")` y
`shinychat::chat_append()`, para que se vean las llamadas a tools y cada cambio de estado ocurra en orden.

**Sin key.** Si `Sys.getenv("ANTHROPIC_API_KEY")` está vacía, no se crea el cliente y el observador del
chat responde con `chat_append()` un texto fijo de configuración.

**Prompt.** `prompt.md`: rol (analista de la banca chilena), datos (11 cuentas, períodos, montos en pesos,
fuente CMF, Security hasta oct 2025, Tanner desde oct 2025), una regla por tool, recorrido
(seleccionar → comparar → responder), límites (no ve gráficos ni tablas; no hay resultados ni
indicadores), interpretación (participación sobre el total del sistema, variaciones nominales) y cierre
(no inventar cifras; breve; español; unidad, período y fuente). `greeting.md`: tres preguntas de
ejemplo que usan las tools.

## Risks / Trade-offs

- [Costo y latencia por pregunta] → Effort `low`, resúmenes compactos (ranking de 17 filas como textos) y
  modelo configurable.
- [El modelo calcula por su cuenta (ej. brechas)] → Las brechas vienen calculadas en `comparar` y el
  prompt prohíbe cifras que no vengan de una tool.
- [Inputs y estado desincronizados] → Prueba de sincronización en el navegador (tarea dedicada).
- [Rechazo por clasificadores de seguridad] → Fallback del servidor activado; ante error, el chat muestra
  el mensaje de `ellmer` sin romper el dashboard.
- [Sin key en este equipo] → Las tools se prueban sin modelo; las pruebas de conversación quedan
  bloqueadas hasta que el usuario agregue la key.
