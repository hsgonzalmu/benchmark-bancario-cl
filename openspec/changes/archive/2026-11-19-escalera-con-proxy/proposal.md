## Why

Al cambiar de banco, la escalera se reconstruye entera junto con los indicadores: parpadea y la lista
salta de golpe a los nuevos competidores, aunque sus 17 filas (montos, participaciones y líneas) no
cambian.

## What Changes

- La escalera y los indicadores pasan a ser salidas separadas (`output$escalera`, `output$indicadores`)
  dentro de un marco (`output$cajas`) que solo cambia si el banco tiene o no dato en el período.
- La escalera se dibuja de nuevo solo al cambiar cuenta, período o monedas (o al volver a haber dato).
- Al cambiar de banco, el servidor envía el mensaje `escalera_foco` con el analizado, los 5 competidores
  y el HTML de las brechas (armado en R con `fila_brecha()`); `www/escalera.js` cambia las clases de las
  filas, reemplaza las brechas y desplaza la lista con suavidad hasta los nuevos competidores
  (sin animación si el sistema pide movimiento reducido).
- Los indicadores siguen redibujándose, porque sus cifras cambian con el banco.

## Impact

- `app.R`, `R/componentes.R`, `www/escalera.js`, `www/styles.css`, spec `dashboard-benchmark`.
- Estado reactivo: nuevo `reactiveVal` `hay_dato` (lo actualiza un observador de `resumen()`); un
  observador de `banco_foco` envía el mensaje. Tools sin cambios.
