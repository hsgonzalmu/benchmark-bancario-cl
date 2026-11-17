# Proposal

## Why

El chat ya maneja el dashboard, pero solo puede mostrar lo que el dashboard tiene. Las preguntas que
surgen al analizar ("¿quién me adelantó y cuándo?", "¿cómo cambió la mezcla de monedas de BCI?", "¿qué
banco más creció en depósitos vista en 2025?") necesitan gráficos, tablas o cruces de datos que hoy no
existen en pantalla.

## What Changes

- Tool `mostrar_grafico(tipo, bancos, meses, titulo)`: abre una ventana emergente con un gráfico que no
  está en el dashboard:
  - `puestos`: puesto en el ranking mes a mes, con los meses en que entra o sale un banco marcados (por
    ejemplo, la fusión BICE-Security).
  - `composicion`: mezcla de monedas de un banco en el tiempo.
  - `crecimiento`: variación de todos los bancos en el período, ordenada.
  - `evolucion`: monto de una lista libre de bancos (hasta 6).
- Tool `mostrar_tabla(tipo, meses, titulo)`: ventana emergente con tabla `ranking` (con puesto y
  participación de hace 12 meses), `historia` (mes a mes de la escalera) o `composicion` (bancos por
  moneda), con botón para descargar CSV.
- Tool `consultar_datos(consulta)`: consultas SQL de solo lectura sobre el balance (DuckDB en memoria),
  para preguntas que las demás tools no cubren.
- Todas usan la selección vigente (cuenta, período, monedas, banco analizado) y no cambian el
  dashboard. Las ventanas se cierran con un clic y no bloquean el chat.
- `prompt.md` y `greeting.md` se amplían con reglas y ejemplos de estas tools.

## Capabilities

### New Capabilities
<!-- Ninguna. -->

### Modified Capabilities
- `ranking-bancos`: agrega puestos en el tiempo, composición en el tiempo y crecimiento del período.
- `chat-analista`: agrega las tools `mostrar_grafico`, `mostrar_tabla` y `consultar_datos`.

## Impact

- `app-benchmark/`: nuevo `R/modales.R`, ampliación de `R/ranking.R` y `R/tools.R`, conexión DuckDB en
  `app.R`, prompt, greeting, pruebas y README.
- Dependencia: `duckdb` (ya instalada).
- Fuera de alcance: la paleta de colores por banco (en pausa por decisión del usuario), visión del
  modelo sobre los gráficos y exportación a Excel.
