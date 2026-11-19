## Why

En Evolución, Base 100 y Participación la leyenda va arriba y obliga a ir y volver entre el color y el
nombre. Rotular cada línea donde termina se lee directo.

## What Changes

- Cada línea visible lleva al final su nombre con un punto de su color (texto en color de texto; el banco
  analizado en negrita). El gráfico reserva margen a la derecha según el nombre más largo.
- Las etiquetas que se montan se separan verticalmente en el navegador (evento `render`), para que no se
  oculte ninguna.
- La leyenda queda solo para los bancos de la escalera ocultos, con el título "Agregar:"; al activarlos,
  también reciben su etiqueta.
- En modo `sistema` (con eje a la derecha) se mantiene la leyenda arriba, sin etiquetas finales.

## Impact

- `R/graficos.R` (`grafico_lineas`, `datos_con_etiqueta`, `separar_etiquetas`), spec `dashboard-benchmark`.
  Estado reactivo y tools sin cambios.
