## Why

Las líneas de 12 meses de la escalera son dibujos estáticos: muestran la forma de la participación, pero
no dejan leer cuánto valía en un mes ni comparar dos bancos en el mismo mes.

## What Changes

- Al pasar el puntero (o el dedo) sobre la línea de un banco, un cursor marca el mes más cercano y una
  etiqueta muestra mes y participación ("oct 2025 · 21,40 %").
- El cursor se sincroniza: todas las líneas de la escalera marcan con un punto el mismo mes, para comparar
  bancos de un vistazo. Al salir, vuelve el estado de reposo (punto en el último mes).
- Sin dependencias nuevas: el SVG lleva los datos en atributos y un script pequeño (`www/escalera.js`)
  maneja el puntero.

## Impact

- `R/componentes.R` (`sparkline_svg`, `escalera_ui`), `R/ranking.R` (`escalera` entrega los períodos),
  `www/escalera.js`, `www/styles.css`, `app.R` (carga del script), spec `dashboard-benchmark`.
- Tools y estado reactivo: sin cambios.
