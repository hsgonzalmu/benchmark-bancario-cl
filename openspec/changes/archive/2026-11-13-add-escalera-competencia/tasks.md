# Tasks

## 1. Cálculos (`ranking-bancos`)

- [x] 1.1 Implementar `ventana_escalera()` y verificar en `tests/test-ranking.R` las ventanas para los
  puestos 1, 9 y 17 de Colocaciones a sep 2026
- [x] 1.2 Implementar `escalera()` con brechas, brecha hace 12 meses, tendencia y serie de participación;
  verificar en las pruebas que Consorcio–Internacional es "estable" e Internacional–Falabella es
  "cambio de orden"
- [x] 1.3 Implementar `cambio_puesto()` y `composicion()`; verificar para Internacional 9° frente a 11°,
  la salida de Security y la entrada de Tanner, que la composición de BCI suma 100 % y que Patrimonio
  marca signos mixtos

## 2. Color por banco

- [x] 2.1 Cargar la skill `dataviz`, elegir la paleta de 18 bancos y agregarla como columna `color` en
  `data/instituciones.csv`; verificar con `tests/test-colores.R` (ΔE ≥ 15 en toda ventana de 5 de toda
  cuenta y mes, y frente al gris de contexto)
- [x] 2.2 Reemplazar los colores por rol en `R/tema.R` y `R/graficos.R` (ranking, evolución, base 100,
  participación, brecha) por `color_banco()`, con el foco destacado por grosor y negrita; verificar con
  capturas que Consorcio tiene el mismo color al analizar Internacional y al analizar Consorcio
- [x] 2.3 Mostrar al usuario la paleta para aprobarla. Presentada el 13-11-2026; el usuario dejó la
  revisión de colores para más adelante y la paleta queda como provisoria (ajustable sin cambiar specs)

## 3. Escalera e indicadores (`dashboard-benchmark`)

- [x] 3.1 Implementar la escalera en `R/componentes.R` (filas, brechas redactadas desde el foco,
  sparkline SVG, filas ±2 atenuadas) y reemplazar las tres cajas de bancos; verificar con capturas a
  1440 y 400 px para Internacional, BCI (1°) y Bank of China (17°)
- [x] 3.2 Implementar el indicador de puesto con cambio en 12 meses junto a la participación conjunta;
  verificar "9° de 17 · ▲ 2 puestos · salió Security (estaba 8°), entró Tanner" para Internacional

## 4. Pestaña Posición 12m

- [x] 4.1 Implementar el gráfico de pesas (`dumbbell`) con el conjunto según el modo y el caso sin dato
  hace 12 meses; verificar los cuatro modos y Tanner (sin dato hace 12 meses) en el navegador

## 5. Composición en la tabla

- [x] 5.1 Agregar la columna Composición (barra apilada y detalle expandible) y el caso de signos mixtos;
  verificar BCI en Colocaciones (47 % moneda extranjera) y Patrimonio en el navegador

## 6. Chat (`chat-analista`)

- [x] 6.1 Agregar escalera, puesto hace 12 meses y composición a `resumen_para_chat()` y la guía de lectura
  a `prompt.md`; verificar en `tests/test-tools.R` que coinciden con las funciones de `R/ranking.R`
- [x] 6.2 Probar con el modelo "¿Internacional se está acercando a Consorcio?" y "¿cuánto de las
  colocaciones de BCI está en moneda extranjera?"; verificar que las cifras coinciden con la pantalla

## 7. Documentación y verificación final

- [x] 7.1 Actualizar `app-benchmark/README.md` (escalera, colores, composición, pestaña nueva); verificar
  que los comandos documentados funcionan
- [x] 7.2 Ejecutar la app desde su carpeta y las tres pruebas; verificar que no hay errores en consola ni
  en outputs y que todas las líneas tienen 110 caracteres o menos

## Workflow follow-up

- Archivar el cambio tras la revisión.
- Proponer la fase 3 (modales del chat, gráfico de puestos en el tiempo, SQL).
