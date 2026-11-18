## Why

En el modo vecinos, los gráficos de Evolución, Base 100 y Participación muestran 3 bancos, mientras la
escalera, la ficha de Puesto y el indicador de participación conjunta hablan de 5. El usuario quiere ver
los mismos 5 sin perder la lectura limpia de los competidores directos.

## What Changes

- En el modo `vecinos`, la comparación incluye a los 5 bancos de la escalera. El analizado y sus
  vecinos superior e inferior se dibujan al abrir; los otros dos (rol `escalera`) quedan en la leyenda,
  en gris, y se agregan con un clic.
- Brecha sigue comparando con el superior y el inferior. Posición 12m ya mostraba la escalera.
- El resumen de `comparar` para el chat sigue con el analizado y sus vecinos directos.

## Impact

- `R/ranking.R` (`integrantes_comparacion`), `R/graficos.R`, `R/tema.R`, `R/tools.R`,
  `tests/test-ranking.R`, spec `dashboard-benchmark`.
- Estado reactivo: sin cambios; mostrar u ocultar una serie es interno del gráfico.
