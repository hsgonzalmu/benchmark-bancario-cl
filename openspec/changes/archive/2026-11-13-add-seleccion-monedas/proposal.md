# Proposal

## Why

Hoy el tipo de valor admite una sola opción (Total o una moneda), así que no se puede analizar, por
ejemplo, "todo menos moneda extranjera". Además, la composición de la tabla muestra siempre las cuatro
monedas del total, aunque se haya elegido solo IPC, y eso no es consecuente con lo que se está analizando.

## What Changes

- El tipo de valor pasa a ser una **selección de monedas**: cualquier combinación de CLP no reajustable,
  reajustable IPC, reajustable TC y moneda extranjera. Las cuatro juntas equivalen al Total.
- El monto de cada banco y del sistema es la suma de las monedas elegidas. Con él se recalculan ranking,
  escalera, brechas, puesto, gráficos, tabla, pesas y resumen del chat.
- La composición de la tabla muestra solo las monedas elegidas y sus porcentajes sobre la selección.
- En el panel Filtros, el selector de una opción se reemplaza por casillas de monedas, con un acceso
  rápido a "Total". No se permite dejar la selección vacía.
- El encabezado y el chat nombran la selección: "Total", "Reajustable IPC" o "Total sin moneda
  extranjera".
- **BREAKING (tool)**: `seleccionar_analisis` recibe `monedas` (lista) en vez de `tipo_valor`.

## Capabilities

### New Capabilities
<!-- Ninguna. -->

### Modified Capabilities
- `ranking-bancos`: ranking y composición sobre la selección de monedas.
- `dashboard-benchmark`: estado `monedas`, casillas de monedas en Filtros, encabezado y composición de la
  tabla según la selección.
- `chat-analista`: `seleccionar_analisis` recibe `monedas`; el resumen nombra la selección y su
  composición.

## Impact

- `app-benchmark/`: `R/ranking.R` (suma de componentes), `R/tools.R`, `R/graficos.R`, `R/componentes.R`,
  `app.R`, `prompt.md`, pruebas y README.
- Sin dependencias nuevas ni cambios en los datos.
