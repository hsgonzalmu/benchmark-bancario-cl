## Why

Los gráficos se llenan muy rápido al aparecer (450 ms) y no se pueden descargar: para llevar un gráfico a
un informe hay que sacar una captura de pantalla.

## What Changes

- Animación de entrada de 1,6 s en todos los gráficos highcharter, incluidos los mini gráficos de los
  indicadores.
- Botón de opciones con pantalla completa, imprimir y descarga en PNG, JPEG y SVG en todos los gráficos
  del dashboard y de las ventanas (`mostrar_grafico`). Se generan en el navegador: sin PDF ni servidor de
  exportación externo. La imagen sale con fondo blanco y la fuente CMF.
- Los mini gráficos de los indicadores (110 px) no llevan botón: taparía la línea.

## Impact

- `R/tema.R` (tema global de highcharter), `R/graficos.R`, spec `dashboard-benchmark`.
- Tools y estado reactivo: sin cambios.
