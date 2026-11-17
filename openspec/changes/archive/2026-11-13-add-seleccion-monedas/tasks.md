# Tasks

## 1. Cálculos (`ranking-bancos`)

- [x] 1.1 Agregar `valor_monedas()`, `etiqueta_monedas()` y mover `etiquetas_moneda` a `R/ranking.R`;
  renombrar `tipo_valor` a `monedas` en las funciones de ranking; verificar con `tests/test-ranking.R`
  que con las cuatro monedas los resultados no cambian
- [x] 1.2 Hacer que `composicion()` use la selección; verificar en las pruebas que BCI sin moneda
  extranjera suma 100 % entre tres monedas, que solo IPC da 100 % IPC y que "Total sin moneda
  extranjera" es el nombre de esa selección

## 2. Dashboard (`dashboard-benchmark`)

- [x] 2.1 Reemplazar el selector de tipo de valor por casillas de monedas con acceso "Total" y el
  `reactiveVal` `monedas`; verificar en el navegador que quitar moneda extranjera recalcula escalera,
  indicadores, gráficos, pesas y tabla, y que no se puede dejar vacía
- [x] 2.2 Encabezado con el nombre de la selección y composición de la tabla (barra, detalle y leyenda)
  solo con las monedas elegidas; verificar BCI sin moneda extranjera y solo IPC con capturas

## 3. Chat (`chat-analista`)

- [x] 3.1 Cambiar `seleccionar_analisis` a `monedas`, actualizar resumen, `listar_opciones()` y
  `prompt.md`; verificar en `tests/test-tools.R` la selección parcial, la lista vacía y que los filtros
  se sincronizan
- [x] 3.2 Probar con el modelo "analiza BCI sin considerar moneda extranjera" y "muéstrame solo lo
  reajustable por IPC de Itaú"; verificar que la tool recibe las monedas correctas y que las cifras
  coinciden con la pantalla

## 4. Documentación y verificación final

- [x] 4.1 Actualizar `app-benchmark/README.md`; verificar que los comandos documentados funcionan
- [x] 4.2 Ejecutar la app desde su carpeta y las tres pruebas; verificar que no hay errores y que todas
  las líneas tienen 110 caracteres o menos

## Workflow follow-up

- Archivar el cambio tras la revisión.
- Revisar la paleta de bancos cuando el usuario lo pida.
- Proponer la fase 3 (modales del chat, gráfico de puestos en el tiempo, SQL).
