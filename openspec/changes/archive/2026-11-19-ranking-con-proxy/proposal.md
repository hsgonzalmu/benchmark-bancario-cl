## Why

Al cambiar de banco, el gráfico de ranking se vuelve a dibujar completo (con su animación de entrada),
aunque los montos y el orden no cambian: solo cambian qué barras van con color, la negrita del banco
analizado y la pista "Clic para analizar".

## What Changes

- El gráfico de ranking se dibuja de nuevo solo cuando cambian cuenta, período o monedas.
- Al cambiar de banco, se actualiza en el navegador con `highchartProxy()` y `hcpxy_update_series()`:
  colores, nombre en negrita y pista; Highcharts hace la transición de colores sin redibujar.
- La serie del ranking lleva `id = "ranking"`; los puntos se arman en `puntos_ranking()`.

## Impact

- `R/graficos.R`, `app.R`, spec `dashboard-benchmark`.
- Estado reactivo: el gráfico depende de `cuenta`, `periodo` y `monedas`; un observador de `banco_foco`
  lo actualiza por proxy. Tools sin cambios.
