## Why

Con la escalera y el ranking actualizándose sin redibujar, los indicadores eran lo único que se
reconstruía de golpe al cambiar de banco.

## What Changes

- `output$indicadores` se dibuja de nuevo solo con cuenta, período o monedas (o al volver a haber dato).
  El mini gráfico pasa a `output$mini_conjunta`.
- Al cambiar de banco, el mensaje `indicadores_foco` (armado con `indicadores_mensaje()`) actualiza en el
  navegador: la participación conjunta y el puesto cuentan hasta el nuevo valor; textos y chips (armados
  en R con `conjunta_partes()` y `puesto_partes()`) se reemplazan con un fundido; la tira mueve el punto,
  la franja de la escalera y el anillo de hace 12 meses, y recolorea sus puntos. El mini gráfico se
  actualiza con `hcpxy_update()`.
- La tira tiene un punto y un número por puesto (ocultos si no corresponden) para cambiar solo atributos.
- 0,7 s con curva cúbica; sin movimiento si el sistema pide reducirlo.

## Impact

- `app.R`, `R/componentes.R`, `R/graficos.R`, `www/escalera.js`, `www/styles.css`, spec
  `dashboard-benchmark`. Tools sin cambios.
