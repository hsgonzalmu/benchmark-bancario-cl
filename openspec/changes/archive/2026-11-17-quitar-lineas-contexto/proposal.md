## Why

En el modo vecinos, la pestaña Evolución dibuja en gris tenue a todos los bancos del ranking que no son
el analizado ni sus vecinos. No tienen nombre, leyenda ni tooltip, así que el usuario no sabe qué son y
recargan el gráfico.

## What Changes

- En el modo `vecinos`, la comparación incluye solo al banco analizado y a sus vecinos superior e
  inferior. Evolución, Base 100 y Participación ya no muestran líneas grises de contexto.
- El ranking de barras sigue con el resto de los bancos en gris (no cambia).

## Impact

- `R/ranking.R` (`integrantes_comparacion`), specs `dashboard-benchmark`.
- Tools: `comparar` ya excluía las líneas de contexto de su resumen; su salida no cambia.
