# Proposal

## Why

Los dos indicadores junto a la escalera son la parte más plana del dashboard: el total del sistema, que
da contexto a todo lo demás, aparece como una línea secundaria, y ninguno muestra cómo llegó a su valor
actual.

## What Changes

- El indicador de participación conjunta pasa a ser el indicador **Sistema**: la cifra principal es el
  total del sistema en la cuenta y monedas elegidas, con variación mensual y en 12 meses como etiquetas
  de color, y una línea de apoyo con la participación del banco analizado y de la escalera.
- El indicador de **Puesto** destaca el puesto del banco y su cambio en 12 meses.
- Cada indicador lleva a la derecha un gráfico pequeño de 24 meses con tooltip: área del total del
  sistema y escalones del puesto del banco (1° arriba, con su color).
- La escalera y los indicadores cambian de proporción para que los gráficos quepan a la derecha (de
  8/4 a 7/5 columnas).

## Capabilities

### New Capabilities
<!-- Ninguna. -->

### Modified Capabilities
- `dashboard-benchmark`: indicadores de posición con total del sistema destacado y gráficos pequeños.

## Impact

- `app-benchmark/`: `R/componentes.R`, `R/graficos.R` (gráficos pequeños), `app.R`, `www/styles.css`,
  README.
- Sin dependencias nuevas. La paleta y la tipografía siguen pendientes.
