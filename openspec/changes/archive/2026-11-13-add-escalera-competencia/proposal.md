# Proposal

## Why

Las tres cajas de bancos muestran montos, pero no la distancia con los competidores directos ni si se
acorta o se amplía, que es la pregunta principal al analizar un banco. Además, el color de cada banco
cambia según su rol en cada consulta, así que no se lo puede seguir entre gráficos y preguntas, y la tabla
no muestra cómo se compone el total por moneda, aunque los datos ya lo traen.

## What Changes

- **BREAKING (visual)**: las cajas de banco analizado, puesto superior y puesto inferior se reemplazan
  por una **escalera de competencia**: el banco y hasta dos puestos hacia cada lado, con la brecha entre
  cada par (MM$ y puntos) y cómo cambió en 12 meses. La ventana se ajusta en los extremos: si el banco es
  1°, muestra 1°, 2° y 3°.
- Junto a la escalera quedan dos indicadores: participación conjunta (ya existe) y **puesto con su
  cambio en 12 meses** (nuevo).
- Nueva pestaña **"Posición 12m"** en la tarjeta de comparación: participación hace 12 meses y hoy
  (gráfico de pesas), para los bancos del modo de comparación elegido.
- **Color fijo por banco** en todos los componentes y consultas. El banco analizado se destaca por
  grosor, negrita y fondo; el sistema sigue en línea punteada y los bancos de contexto en gris.
- La tabla de ranking agrega una columna **Composición**: barra 100 % apilada de CLP no reajustable,
  reajustable IPC, reajustable TC y moneda extranjera, con el detalle de montos al expandir la fila.
- El resumen que reciben las tools del chat incluye la escalera, el puesto hace 12 meses y la
  composición del banco analizado, para que el chat diga lo mismo que muestra la pantalla.

## Capabilities

### New Capabilities
<!-- Ninguna. -->

### Modified Capabilities
- `ranking-bancos`: agrega la ventana de escalera, brechas y su cambio en 12 meses, cambio de puesto y
  composición por moneda.
- `dashboard-benchmark`: escalera e indicador de puesto en lugar de las cajas de bancos; pestaña
  "Posición 12m"; color fijo por banco; composición en la tabla.
- `chat-analista`: el resumen del análisis agrega escalera, puesto hace 12 meses y composición.

## Impact

- `app-benchmark/`: `R/ranking.R`, `R/graficos.R`, `R/componentes.R`, `R/tema.R`, `R/tools.R`, `app.R`,
  `www/styles.css`, `data/instituciones.csv` (columna de color), pruebas y README.
- Sin dependencias nuevas ni cambios en `prepare-data.R`.
- La fase 3 (modales del chat, gráfico de puestos en el tiempo, SQL) queda para el cambio siguiente.
