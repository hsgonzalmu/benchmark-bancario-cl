# Proposal

## Why

El dashboard ya muestra la posición competitiva de un banco, pero cambiar de banco, cuenta o comparación
exige recorrer filtros y leer varios componentes. Un chat de IA que maneje el mismo estado permite
preguntar en lenguaje natural ("¿cómo está Internacional en consumo frente al líder?") y recibir la
respuesta con cifras verificables mientras el dashboard se actualiza solo.

## What Changes

- Chat (ellmer + shinychat, modelo Claude) en el sidebar, en un acordeón junto a los filtros manuales.
- Cuatro tools que leen y escriben el estado de selección existente:
  - `listar_opciones()`: bancos, cuentas, períodos, tipos de valor y modos disponibles.
  - `ver_analisis()`: resumen del análisis visible (posición, vecinos, líder, ranking, comparación)
    sin modificar nada.
  - `seleccionar_analisis(banco, cuenta, periodo, tipo_valor)`: cambia lo que se analiza; todos los
    argumentos opcionales.
  - `comparar(modo, bancos)`: cambia el modo de comparación y devuelve brechas y evolución.
- Los filtros manuales se sincronizan con los cambios hechos por el chat.
- `prompt.md` (rol, datos, reglas por tool, límites, no inventar cifras) y `greeting.md` con preguntas de
  ejemplo.
- Al abrir la app, el banco analizado es el líder de Colocaciones en el último período, en vez de
  Banco Internacional.
- Sin API key de Anthropic, el dashboard funciona igual y el chat explica cómo configurarla.

## Capabilities

### New Capabilities
- `chat-analista`: conversación con IA que consulta y cambia el análisis del dashboard mediante tools,
  con respuestas basadas solo en cifras devueltas por esas tools.

### Modified Capabilities
- `dashboard-benchmark`: el estado de selección también lo modifican las tools del chat y su banco
  inicial pasa a ser el líder de Colocaciones; los filtros manuales se reflejan desde el chat y conviven
  con él en el sidebar.

## Impact

- `app-benchmark/`: `app.R` (sidebar, chat, sincronización), nuevo `R/tools.R`, `prompt.md`,
  `greeting.md`, pruebas en `tests/`, README.
- Dependencias ya instaladas: `ellmer` 0.5.2 y `shinychat` 0.5.0.
- Requiere `ANTHROPIC_API_KEY` en `app-benchmark/.Renviron` (hoy no está definida). Cada pregunta tiene
  costo de API.
- Fuera de alcance (fase 3): tablas y gráficos en modales, consultas SQL libres.
