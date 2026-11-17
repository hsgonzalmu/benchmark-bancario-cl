# Design

## Context

No hay código previo: la carpeta tiene la guía (`docs/guia-r-shiny-chat.md`), el documento de proyecto
(`benchmark_cl_proyecto.md`) y la credencial CMF. Una prueba contra la API (12-11-2026) confirmó:

- La key está activa. El JSON usa `CodigosBalances` (datos) y `DescripcionesCodigosContables`
  (catálogo).
- Las cuentas tienen 9 dígitos (`100000000` = TOTAL ACTIVOS); el catálogo de 2026-09 tiene 709 cuentas.
- El último mes publicado es 2026-09; 2026-10 responde 404 con código 80.
- `balances/<AAAA>/09/cuentas/<cuenta>` entrega 18 filas: 17 instituciones más `999` (sin nombre).
  Tanner (`062`) aparece; Banco Security (`049`) ya no informa en 2026-09.
- Los montos vienen en pesos, como texto con coma decimal.
- R 4.5.3. Instalados: `shiny`, `bslib`, `jsonlite`, `duckdb`, `ellmer`, `shinychat`. Faltan:
  `highcharter`, `reactable`, `bsicons`.

## Goals / Non-Goals

**Goals:**
- Datos locales reproducibles con un solo comando mensual.
- Funciones de ranking puras (data.frame → data.frame) que luego reutilicen las tools del chat.
- Dashboard pulido y coherente que sirva de lienzo para el chat.

**Non-Goals:**
- Chat, tools, prompt y modales (fases 2–4).
- Estado de Resultados, indicadores (ROE, morosidad) o ratios entre cuentas.
- Modo oscuro, exportación a Excel/PDF, despliegue.

## Decisions

**Estructura `app-benchmark/` con `app.R` y `R/`.** La guía pide `app.R` con secciones fijas; el
documento de proyecto usaba `global.R/ui.R/server.R`. Se sigue la guía y se extraen a `R/ranking.R`
(cálculos) y `R/graficos.R` (constructores highcharter) las funciones que harían ilegible `app.R`.
Shiny carga `R/` automáticamente. Las funciones de ranking quedan aisladas para probarlas con
`Rscript` y reutilizarlas en las tools.

**Descarga por cuenta y año.** `balances/<AAAA>/cuentas/<cuenta>` trae todos los bancos y meses de un año
en una llamada: 11 cuentas × 4 años = 44 llamadas. Alternativa por banco y mes: unas 700 llamadas. Se
usa `curl::curl_fetch_memory()` con IPv4 forzado (desde esta red `url()` de R se colgaba por IPv6) y 3
reintentos con pausa creciente; un 404 con código 80 significa "sin datos" y se omite. `curl` ya está
instalado como dependencia de `jsonlite`; no se agrega `httr2`.

**Catálogo de cuentas clave en `data/cuentas.csv`** (`cuenta`, `nombre`, `grupo`):

| Cuenta | Nombre | Grupo |
|---|---|---|
| 100000000 | Activos totales | Activos |
| 105000000 | Efectivo y depósitos en bancos | Activos |
| 144000000 | Colocaciones | Colocaciones |
| 145000000 | Colocaciones comerciales | Colocaciones |
| 146000000 | Colocaciones para vivienda | Colocaciones |
| 148000000 | Colocaciones de consumo | Colocaciones |
| 149000000 | Provisiones por riesgo de crédito | Colocaciones |
| 200000000 | Pasivos totales | Pasivos |
| 241000000 | Depósitos a la vista | Captaciones |
| 242000000 | Depósitos a plazo | Captaciones |
| 300000000 | Patrimonio | Patrimonio |

Ampliarlo es agregar una fila y volver a ejecutar `prepare-data.R`.

**Tabla de instituciones en `data/instituciones.csv`** (`cod_ifi`, `nombre_corto`, `abreviacion`,
`clasificacion`). Se usa un nombre corto legible en los gráficos ("Internacional", "Santander", "BCI",
"Itaú") en vez de abreviaciones tipo `CNSCIO`. Se conservan las abreviaciones del documento de proyecto
para espacios estrechos. Tanner (`062`) sin clasificación; Security (`049`) se mantiene por su historia.

**Formato de datos: `data/balance.rds`** con columnas `periodo`, `fecha`, `cod_ifi`, `cuenta`,
`clp`, `ipc`, `tc`, `mx`, `total`, y un atributo `descargado` con la fecha. RDS es R base y suficiente
para unas 10 mil filas; DuckDB llega en la fase 3 para SQL.

**Ranking con R base.** `calcular_ranking(datos, cuenta, periodo, tipo_valor)` devuelve un data.frame
con `posicion`, `cod_ifi`, `monto`, `participacion`, `var_m1`, `var_12m`, `rol` (`foco`, `superior`,
`inferior`, `lider`, `resto`). `series_comparacion(...)` arma la historia con identidades fijas.

**Estado: un `reactiveVal` por dimensión.** `banco_foco`, `cuenta`, `periodo`, `tipo_valor`,
`comparacion` (lista `modo` + `bancos`). Los `observeEvent` de los inputs escriben en ellos y
`ranking <- reactive(...)` deriva todo. Así en la fase 2 las tools escriben en los mismos
`reactiveVal`, con el patrón de bandera de `app-07` para sincronizar los inputs.

**Highcharter con opciones globales en español.** `options(highcharter.lang = ...)` con meses en
español, `decimalPoint = ","`, `thousandsSep = "."`. Un tema `hc_theme` propio con la fuente y el
fondo de bslib. highcharter convierte `fontFamily` en un enlace de Google Fonts, por eso la fuente se
declara solo como `"Inter, sans-serif"` (con comillas internas rompe el JavaScript de Shiny). Las
series del resto se dibujan con `enableMouseTracking = FALSE` y gris claro. Cuando hay series de
contexto, el eje Y se ajusta a las destacadas para que no las aplasten los bancos grandes. En modo
`vecinos` el líder es contexto (gris), salvo que sea el vecino superior.

**Brecha en modo `sistema`**: índice base 100 del banco menos el del sistema (crecimiento acumulado
relativo, en puntos), en columnas verdes o rojas según el signo.

**Paleta semántica** (definida una vez en `R/tema.R` y usada por gráficos, value boxes y tabla):

| Rol | Color | Uso |
|---|---|---|
| foco | `#0B5CAD` | Banco analizado; línea gruesa |
| superior | `#E07B39` | Vecino superior |
| inferior | `#2A9D8F` | Vecino inferior |
| lider | `#C9A227` | Líder de la cuenta |
| sistema | `#3A3F44` | Total del sistema; línea punteada |
| resto | `#CDD3DA` | Contexto |
| positivo / negativo | `#2E7D32` / `#C62828` | Signo de variaciones |

Se valida contraste y legibilidad en la primera revisión visual; los colores pueden ajustarse sin tocar
specs.

**Tema bslib.** `bs_theme(version = 5, primary = foco, base_font = font_google("Inter", local =
FALSE))` y `www/styles.css` para encabezado, value boxes y tabla. Los value boxes no usan `showcase`
(el ícono grande desplazaba el contenido): la flecha de `bsicons` va junto a la variación, y el color
del rol se marca con el borde superior.

**Tabla con `reactable`.** Barras con estilo en la columna de monto, colores por signo y resaltado por
`rol`. Alternativa `gt`: más lenta de renderizar y sin orden interactivo.

**Formato de montos.** En value boxes: "$7,02 billones", "$850 mil millones". En la tabla: millones
de pesos (MM$) con separador de miles. En ejes de gráficos: miles de millones de pesos, porque en MM$
las etiquetas (hasta 9 dígitos) no caben; la evolución cambia a millones cuando los montos destacados
son menores a mil millones (p. ej. provisiones en moneda extranjera), y agrega decimales si hace falta.

## Risks / Trade-offs

- [Licencia de Highcharts] → Se documenta en el README. Cambiar a echarts4r afecta solo `R/graficos.R`.
- [Bancos que dejan de informar (Security) o aparecen (Tanner)] → El ranking usa solo instituciones con
  dato en el período; las series muestran huecos y la app avisa cuando el foco no tiene dato.
- [Cuentas de saldo negativo (provisiones)] → El ranking ordena por valor absoluto y los gráficos
  muestran magnitudes.
- [La API cambia formato o falla] → La app no depende de la API; `prepare-data.R` falla con mensaje claro
  y conserva el `balance.rds` anterior hasta terminar bien.
- [Base 100 con base cero o sin dato] → La serie comienza en el primer mes con dato positivo.

## Migration Plan

Primera versión: no hay migración. Actualización mensual: `Rscript prepare-data.R` desde
`app-benchmark/`.
