# Tasks

## 1. Datos y gráficos

- [x] 1.1 Agregar `serie_sistema()` en `R/ranking.R`; verificar en `tests/test-ranking.R` el total de
  Colocaciones a sep 2026 (MM$ 278.598.681) y la variación de 12 meses (+5,1 %)
- [x] 1.2 Agregar `serie_conjunta()` y `grafico_mini_conjunta()`; verificar que el último mes es la suma
  de la escalera (13,1 %) y el salto de +269 pb en nov 2025
- [x] 1.3 Agregar la tira de posiciones (`tira_puestos()`, SVG en línea) en lugar del gráfico en
  escalones, a pedido del usuario; verificar con capturas de Internacional (9°, antes 11°) y BCI (1°)

## 2. Indicadores

- [x] 2.1 Rehacer los indicadores Participación conjunta y Puesto en `R/componentes.R` con texto a la
  izquierda, gráfico a la derecha, etiquetas de variación y el total del sistema en negrita; cambiar la
  fila a 7/5; verificar con capturas a 1440 y 400 px
- [x] 2.2 Verificar el tooltip del gráfico de participación conjunta y que la escalera no corta montos ni
  brechas

## 3. Documentación y verificación final

- [x] 3.1 Actualizar `app-benchmark/README.md`; verificar que describe los indicadores nuevos
- [x] 3.2 Ejecutar la app desde su carpeta y las tres pruebas; verificar que no hay errores

## Workflow follow-up

- Archivar el cambio tras la revisión.
