## Why

El tooltip de los gráficos de tiempo lista las series en el orden de la leyenda y en texto corrido. Con
varios bancos cuesta ver quién va primero en un mes, y las transiciones al cambiar de banco (ranking y
escalera) eran cortas o bruscas.

## What Changes

- Tooltip en tabla (`hc_tooltip(table = TRUE)`) en todos los gráficos de tiempo: mes arriba, punto con el
  color del banco, nombre en color de texto y valor alineado a la derecha.
- Orden de mayor a menor (`hc_tooltip(sort = TRUE)`) en Evolución, Base 100 y Participación, y en las
  ventanas de evolución y de varias cuentas; no en puestos, donde un número mayor es peor.
- Marcador circular al pasar el puntero en todas las líneas.
- Transiciones más suaves: cambios por proxy del ranking en 0,9 s con curva cúbica; la escalera se
  desliza en 0,7 s con la misma curva, las filas cambian con transición y las brechas aparecen con
  fundido. Sin movimiento si el sistema pide reducirlo.

## Impact

- `R/graficos.R`, `R/modales.R`, `R/tema.R`, `www/escalera.js`, `www/styles.css`, spec
  `dashboard-benchmark`. Estado reactivo y tools sin cambios.
