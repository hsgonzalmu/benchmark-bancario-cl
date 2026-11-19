## Why

En la escalera y en la tira de Puesto un clic sobre un banco lo deja como analizado. El gráfico y la
tabla de ranking muestran a todos los bancos, pero no responden al clic, así que para recorrer el
mercado desde ahí hay que volver al filtro Banco.

## What Changes

- Clic en una barra del gráfico de ranking selecciona ese banco; el cursor cambia a mano y el tooltip
  dice "Clic para analizar".
- Clic en una fila de la tabla de ranking selecciona ese banco. La flecha de la fila sigue abriendo el
  detalle de composición sin cambiar el banco.
- Un solo punto de entrada en `www/escalera.js` (`seleccionarBanco`), usado también por la escalera y la
  tira.

## Impact

- `R/graficos.R` (`grafico_ranking`, `tabla_ranking`), `www/escalera.js`, `www/styles.css`, spec
  `dashboard-benchmark`.
- Estado reactivo: el clic cambia `banco_foco` por el mismo camino que el filtro Banco. Tools sin
  cambios.
