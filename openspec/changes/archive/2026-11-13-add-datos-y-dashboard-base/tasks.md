# Tasks

## 1. Preparación del entorno

- [x] 1.1 Crear `.Renviron` en `app-benchmark/` con `CMF_API_KEY` y `.gitignore` en la raíz con
  `.Renviron` y `apikey_cmf.md`; verificar que `Sys.getenv("CMF_API_KEY")` tiene 40 caracteres
- [x] 1.2 Instalar `highcharter`, `reactable` y `bsicons`; verificar con `requireNamespace()` que los
  tres cargan

## 2. Datos (`datos-balance-cmf`)

- [x] 2.1 Crear `data/cuentas.csv` y `data/instituciones.csv` según design.md; verificar que todas las
  cuentas existen en el catálogo `balances/2026/09/cuentas`
- [x] 2.2 Escribir `prepare-data.R` (descarga por cuenta y año, reintentos, normalización, unión por
  `cod_ifi`, guardado atómico de `data/balance.rds` con atributo `descargado`); verificar ejecutando
  `Rscript prepare-data.R` desde `app-benchmark/`
- [x] 2.3 Agregar al script el reporte de calidad (suma de bancos frente a `999`, tolerancia 0,5 %;
  códigos sin ficha); verificar que se imprime y que Tanner o cualquier código nuevo aparece si falta
  en la tabla
- [x] 2.4 Verificar el contenido: 11 cuentas, períodos de 202301 a 202609, sin montos `NA` donde la
  API trae valor y el monto de Activos de Internacional en 202609 igual a 7019316661760

## 3. Cálculo de ranking (`ranking-bancos`)

- [x] 3.1 Escribir `R/ranking.R` con `calcular_ranking()` (posición, participación, var m-1, var 12m,
  rol) y verificar con `Rscript` la posición de Internacional en Colocaciones 202609 y la suma de
  participaciones cercana a 100 %
- [x] 3.2 Agregar los casos borde: líder sin superior, último sin inferior, cuenta negativa ordenada por
  valor absoluto, banco sin dato (Security en 202609); verificar cada caso con un script de pruebas
  `tests/test-ranking.R` que use `stopifnot()`
- [x] 3.3 Escribir `series_comparacion()` para los cuatro modos con identidades fijas en el período
  elegido; verificar en `tests/test-ranking.R` que el vecino superior conserva su `cod_ifi` en toda la
  serie

## 4. Dashboard (`dashboard-benchmark`)

- [x] 4.1 Crear `app.R` con las secciones de la guía, tema bslib, paleta semántica, opciones de idioma
  de highcharter y carga de datos con mensaje si falta `balance.rds`; verificar que la app abre vacía de
  errores con `shiny::runApp("app-benchmark")`
- [x] 4.2 Implementar sidebar de filtros y los cinco `reactiveVal` con estado inicial (Internacional,
  Colocaciones, último período, Total, `vecinos`); verificar que cambiar cada filtro actualiza el estado
- [x] 4.3 Implementar encabezado de contexto y los cuatro value boxes con `renderUI()`; verificar flechas,
  colores, formato "$x,xx billones" y "N/A" al elegir el líder
- [x] 4.4 Implementar en `R/graficos.R` el gráfico de ranking con roles destacados y tooltip; verificar
  que el foco, vecinos y líder usan los colores de la paleta
- [x] 4.5 Implementar la tarjeta de comparación (Evolución, Base 100, Participación, Brecha) para los
  cuatro modos; verificar cada modo y pestaña en el navegador
- [x] 4.6 Implementar la tabla `reactable` con barras de monto, color por signo y resaltado por rol;
  verificar orden por columna y resaltado
- [x] 4.7 Implementar mensajes de estado vacío; verificar con Security en 202609 y modo `bancos` sin
  bancos elegidos
- [x] 4.8 Escribir `www/styles.css` y hacer la revisión visual (alineación, tamaños, contraste, ancho de
  ~1280 px y ~400 px); verificar con capturas de pantalla

## 5. Documentación y verificación final

- [x] 5.1 Escribir `app-benchmark/README.md` (datos, actualización mensual, estructura, paleta, licencia
  de Highcharts); verificar que los comandos documentados funcionan tal como están escritos
- [x] 5.2 Ejecutar la app desde su carpeta (`shiny::runApp()` en `app-benchmark/`) y recorrer todos los
  escenarios de las specs; verificar que no hay errores en consola y que las líneas de todos los
  archivos tienen 110 caracteres o menos

## Workflow follow-up

- Archivar el cambio con `openspec archive add-datos-y-dashboard-base` tras la revisión.
- Proponer el cambio de la fase 2 (chat y tools `seleccionar_analisis`, `comparar`, `listar_opciones`).
