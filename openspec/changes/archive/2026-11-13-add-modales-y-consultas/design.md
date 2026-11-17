# Design

## Context

El estado vive en cinco `reactiveVal` (`banco_foco`, `cuenta`, `periodo`, `monedas`, `comparacion`) y
las tools se crean con `crear_tools(estado, ctx, al_cambiar)` en `R/tools.R`, que se prueba sin modelo en
`tests/test-tools.R`. Las referencias son `app-06` (modales `mostrar_tabla()` / `mostrar_grafico()`) y
`app-04`/`app-07` (SQL de solo lectura con DuckDB y `validar_select()`) en `../shiny-chat-patterns-main`.
`duckdb` ya está instalado.

## Goals / Non-Goals

**Goals:**
- Responder con gráficos y tablas lo que el dashboard no muestra, sin tocar el dashboard.
- Dar al chat una salida para preguntas abiertas (SQL), con seguridad de solo lectura.
- Mantener las tools probables sin modelo ni navegador.

**Non-Goals:**
- Paleta de colores (en pausa): los gráficos usan `color_banco()` tal como está.
- Visión del modelo sobre las imágenes de los gráficos.
- Exportar a Excel (se ofrece CSV).

## Decisions

**Cálculos nuevos en `R/ranking.R`.** `puestos_en_el_tiempo(datos, cuenta, periodo, monedas, cods,
meses)` devuelve puesto por banco y mes más los meses con entradas o salidas del ranking.
`composicion_en_el_tiempo()` reutiliza `composicion()` mes a mes. `crecimiento_periodo()` compara inicio
y fin de la ventana. Todos se prueban en `tests/test-ranking.R`.

**Gráficos y tablas de ventana en `R/modales.R`.** Constructores puros (data.frame → highchart o
reactable) para que el server solo los envuelva:
- `puestos`: líneas con eje Y invertido (1 arriba) y `plotLines` en los meses con entradas o salidas,
  rotulados ("sale Security").
- `composicion`: área apilada al 100 % con `colores_moneda`.
- `crecimiento`: barras horizontales ordenadas, el banco analizado destacado.
- `evolucion`: reutiliza el estilo de `grafico_lineas()`.

**Cómo abre ventanas una tool.** El server pasa a `crear_tools()` una función `abrir_ventana(titulo,
contenido, datos_csv)` que define outputs efímeros (`output$ventana_grafico`, `output$ventana_tabla`,
`output$ventana_csv`) y llama a `showModal(modalDialog(..., size = "xl", easyClose = TRUE))`. Es la única
excepción a "las tools no escriben outputs", como en la guía. En las pruebas se pasa una función que solo
registra la llamada, así las tools se prueban sin Shiny. Cada llamada reemplaza la ventana anterior,
porque Shiny muestra un modal a la vez.

**Lo que vuelve al modelo.** Una confirmación y un resumen breve calculado, no los datos: en `puestos`,
los cambios de puesto del banco analizado y las entradas o salidas; en `crecimiento`, los tres mayores y
el banco analizado; en `composicion`, la mezcla al inicio y al final. Así el modelo puede comentar sin
ver la imagen.

**SQL con DuckDB.** Base en memoria creada al iniciar la app con una tabla `balance` en formato ancho y
legible: `periodo` (AAAAMM), `fecha`, `cod_ifi`, `banco` (nombre corto; "Sistema" para 999), `cuenta`,
`cuenta_nombre`, `grupo`, `clp_mm`, `ipc_mm`, `tc_mm`, `mx_mm`, `total_mm` (millones de pesos). Seguridad
en dos capas, como en la guía: `validar_select()` (debe empezar con SELECT, usar `balance`, sin `;`) y
`SET enable_external_access = false`; además `LIMIT 200` envolviendo la consulta. `onStop()` cierra la
conexión. El prompt describe columnas y unidades, y pide escribir montos como MM$.

**Descarga CSV.** `downloadHandler` dentro de la ventana con los datos que se ven, en UTF-8 con separador
`;` y decimal `,` (lo que abre bien Excel en Chile).

**Prompt y greeting.** Una regla por tool nueva, el recordatorio de que el modelo no ve las ventanas y dos
sugerencias nuevas en el saludo ("¿Cuándo adelantó Internacional a Falabella?", "¿Qué banco creció más en
depósitos a la vista en 2025?").

## Risks / Trade-offs

- [SQL mal escrito por el modelo] → El error vuelve al modelo con el mensaje de DuckDB y puede corregir;
  la vista tiene nombres de columnas claros y el prompt da un ejemplo de consulta.
- [Formato de cifras en SQL] → Los resultados vienen en millones sin formato; el prompt exige MM$ con
  separador de miles. Es la única tool que no entrega cifras formateadas.
- [Gráfico de puestos engañoso por fusiones] → Las marcas de entradas y salidas lo explican en el mismo
  gráfico.
- [Modal sobre el chat en pantallas angostas] → `easyClose = TRUE` y botón Cerrar visible.
