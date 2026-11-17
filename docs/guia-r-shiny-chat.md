# Guía de buenas prácticas: Shiny + ellmer + shinychat + MCP en R

Base para crear apps de chat en Shiny con R. Resume los patrones del repositorio de taller
`../shiny-chat-patterns-main`: las referencias como (`app-08`) apuntan a sus carpetas, donde está el
ejemplo completo y ejecutable.

## 1. Principios

- **Cambios pequeños y verificables.** Agrega una capacidad a la vez y ejecuta la app después de cada una.
- **El modelo solo sabe lo que devuelven las tools.** No ve la UI, los modales ni el mapa.
- **Las tools cambian el estado; Shiny actualiza los outputs.** Una tool escribe en un `reactiveVal`,
  nunca en `output$...` del dashboard principal.
- **No inventar cifras.** Toda cifra sale de una tool y el prompt lo exige explícitamente.
- **Código simple:** líneas de 110 caracteres como máximo, R base y `|>`, sin helpers ni abstracciones
  que no sean necesarias. Extrae a archivos aparte solo cuando `app.R` deje de leerse de una vez.

## 2. Estructura de carpetas

```
nombre-app/
├── app.R              # app completa y ejecutable desde su carpeta
├── greeting.md        # mensaje inicial del chat (cuando no cabe inline)
├── prompt.md          # system prompt (cuando no cabe inline)
├── README.md          # implementación, datos, particularidades
├── mcp.json           # solo si usa MCP
├── prepare-data.R     # solo si los datos requieren preparación previa
├── data/              # datos de la app (o ../data si se comparten entre apps)
└── www/               # CSS e imágenes propias
```

## 3. Esqueleto de `app.R`

Secciones en este orden, con el código inmediatamente después de cada encabezado:

```r
library(shiny)
library(bslib)
library(ellmer)
library(shinychat)
thematic::thematic_shiny(font = "auto")

# data --------------------------------------------------------------------
paises <- utils::read.csv(file.path("data", "paises.csv"), fileEncoding = "UTF-8")

# prompt ------------------------------------------------------------------
saludo <- paste(readLines("greeting.md", warn = FALSE), collapse = "\n")
prompt_sistema <- paste(readLines("prompt.md", warn = FALSE), collapse = "\n")

# user interface ----------------------------------------------------------
ui <- page_sidebar(
  title = "Nombre de la app",
  sidebar = sidebar(
    shinychat::chat_ui("chat", greeting = saludo, placeholder = "Pregunta por los datos..."),
    width = 400
  ),
  layout_columns(
    value_box("Países", textOutput("n_filas"), showcase = icon("earth-americas"), theme = "text-primary"),
    card(plotOutput("plot")),
    card(tableOutput("table")),
    col_widths = c(12, 6, 6),
    row_heights = c(1, 3)
  )
)

# server ------------------------------------------------------------------
server <- function(input, output, session) {
  consulta_actual <- reactiveVal("SELECT * FROM paises")
  data <- reactive(DBI::dbGetQuery(con, consulta_actual()))

  output$n_filas <- renderText(nrow(data()))
  output$table <- renderTable(data(), striped = TRUE, hover = TRUE)

  # tools -----------------------------------------------------------------
  mi_tool <- function(arg) {
    # lee con isolate(), escribe en reactiveVal, devuelve un resultado breve
  }

  # chat ------------------------------------------------------------------
  chat <- ellmer::chat("openai/gpt-5-nano", system_prompt = prompt_sistema)
  chat$register_tool(tool(mi_tool, "Descripción breve.", arguments = list(arg = type_string("..."))))

  observeEvent(input$chat_user_input, {
    stream <- chat$stream_async(!!!input$chat_user_input, tool_mode = "sequential", stream = "content")
    shinychat::chat_append("chat", stream)
  })
}

shinyApp(ui, server)
```

## 4. Shiny: estructura y reactividad

### Layout

- Por defecto `page_sidebar()`: chat y controles manuales en el sidebar (`width = 400`), resultados en el
  área principal con `layout_columns()`, `value_box()` y `card()`.
- Agrega navbars, tabs o accordions solo cuando organicen contenido real
  (`app-07` usa accordion para separar filtros y chat; `app-09` usa `navset_card_tab()`).
- Una app con identidad visual propia puede usar `page_fillable()`, mapa a pantalla completa, chat
  flotante y `www/styles.css` (`app-50`).
- Para un chat sin dashboard basta `page_chat()` + `chat_server()` (`app-09-v2`).
- `thematic::thematic_shiny(font = "auto")` para que los gráficos hereden la fuente y los colores del tema.
  Con ggplot2, define además `theme_set(theme_minimal())`.

### Estado

- **Una sola fuente de verdad:** un `reactive()` o `reactiveVal()` llamado `data` que alimenta todos
  los outputs (value boxes, gráfico, tabla, mapa).
- Si el chat debe modificar los datos, guarda **la causa** (una consulta, un indicador, un código) en un
  `reactiveVal` y deriva `data` de ella con `reactive()` (`app-05`).
- Si la carga viene completa desde el modelo (MCP), `data` es un `reactiveVal(list(datos, variables))`
  con un esquema vacío inicial (`filas_vacias`), así los outputs no fallan antes de la primera carga
  (`app-09`).
- Separa el estado de datos del de presentación: escalas o variable del mapa van en otros `reactiveVal`
  (`variable_mapa` en `app-08`, `escala` en `app-09-v3`).
- Contexto + selección: dibuja el universo completo en gris y la selección en el color principal, así el
  usuario ve qué filtró el chat.

### Combinar controles manuales y chat (`app-07`)

- Usa un `modo()` (`"inputs"` / `"query"`) que decide de dónde sale `data()`.
- Cuando el chat filtra, reinicia los inputs con `update*Input()` y protege ese reinicio con una bandera
  (`reiniciando_inputs`) para que el `observeEvent` de los inputs no devuelva el control a `"inputs"`.
- Usa `ignoreInit = TRUE` en el observador de los inputs.

### Widgets pesados: proxy en vez de re-render (`app-08`)

- Para mover cámara, zoom o capas de un mapa sin redibujarlo usa `mapgl::maplibre_proxy("map", session)`
  con `fly_to()`, `fit_bounds()`, etc.
- Re-renderiza solo cuando cambian los datos; usa proxy para acciones de navegación.

### Recursos

- Conexiones globales con cierre: `onStop(function() DBI::dbDisconnect(con, shutdown = TRUE))`.
- Archivos temporales con `tempfile()` y `on.exit(unlink(archivo))`.

## 5. ellmer: cliente y chat

- Crea el cliente con `ellmer::chat("proveedor/modelo")`: permite cambiar de proveedor sin cambiar el
  código. Usa un modelo pequeño (`gpt-5-nano`) para tools simples y uno más capaz cuando hay visión o MCP.
- **Crea el cliente dentro de `server`**, no a nivel global: cada sesión tiene su propio historial.
- Prompts cortos inline con `paste()`; cuando crecen, a `prompt.md` y `greeting.md`.
- Streaming en la app:
  - `chat$stream_async(!!!input$chat_user_input, stream = "content")` para que shinychat muestre las
    llamadas a tools además del texto.
  - `tool_mode = "sequential"` cuando las tools tienen efectos sobre la UI o dependen del orden
    (consultar → visualizar → inspeccionar).
  - `shinychat::chat_append("chat", stream)` entrega el stream a la interfaz.
- En scripts de consola: `chat$chat(pregunta, echo = "none")` devuelve el texto sin imprimir.
- Orquestación (`app-90`, `app-91`): cada agente es un `ellmer::chat()` independiente con su propio
  prompt, coordinado por una función R (`orchestrate()`), no por el modelo. Pasa entre agentes solo lo
  necesario (pregunta, análisis, datos).

## 6. Tools

### Definición

```r
chat$register_tool(tool(
  actualizar_dashboard,
  "Filtra, ordena o reinicia los datos reactivos mostrados en el dashboard.",
  arguments = list(
    consulta = type_string("SELECT * FROM paises con WHERE u ORDER BY, sin punto y coma.")
  )
))
```

- Nombres en español, verbo + objeto: `consultar_tabla`, `actualizar_dashboard`, `mostrar_grafico`,
  `ir_a_pais`, `guardar_datos`, `ver_datos`.
- Descripción de una línea que diga **qué hace y qué no hace** ("sin modificarla").
- Acota los argumentos con el esquema, no con validaciones manuales:
  - `type_enum(c(...))` para columnas o variables válidas.
  - `type_integer()` / `type_number()` para cantidades.
  - `required = FALSE` para opcionales (con valor por defecto en la función).
  - `type_array(type_object(...))` para cargas estructuradas (`app-09`).
- Tools sin argumentos son válidas: `tool(ver_datos, "Lee la carga actual sin modificarla.")`.

### Cuerpo

- **Lee con `isolate()`**: la tool corre fuera de un contexto reactivo (`isolate(data())`,
  `isolate(input$x)`).
- **Escribe en `reactiveVal`**, no en outputs del dashboard. La excepción son outputs efímeros de un
  modal (`output$tabla_modal`).
- **Devuelve algo breve y útil**: una confirmación, el número de registros o un resumen numérico.
  Evita devolver datasets grandes si el modelo no los necesita.
- **Falla con `stop("mensaje claro")`**: ellmer devuelve el error al modelo, que puede corregir y
  reintentar ("No encontré ese país.", "Consulta primero ese flow_id con consultar_sdmx.").
- Fuerza el orden en código cuando importa: una tool de visualización puede exigir que antes se haya
  consultado (`app-51`).

### Tipos de tools según el patrón

| Patrón | Qué hace | Qué devuelve | App |
|---|---|---|---|
| Lectura resumida | Resume los datos visibles | Lista de métricas | `app-03` |
| SQL de lectura | `consultar_tabla(consulta)` | `data.frame` del resultado | `app-04` |
| Escritura de estado | Cambia un `reactiveVal` | Confirmación + registros | `app-05` |
| Interfaz | Abre un `showModal()` | Solo confirmación | `app-06` |
| Proxy | Mueve un widget existente | Confirmación | `app-08` |
| Visión | Dibuja y devuelve la imagen | `ContentText` + `content_image_file()` | `app-08` |
| Carga externa | Recibe datos del modelo | Confirmación | `app-09` |
| API externa | Consulta REST/SDMX | Observaciones parseadas | `app-51` |

### Modales: tablas y gráficos pedidos desde el chat (`app-06`, `app-08`)

Una de las piezas más reutilizables. El usuario describe en el chat la tabla o el gráfico que quiere;
el modelo elige los argumentos y la tool lo dibuja con los **datos visibles** en un modal, sin tocar el
dashboard principal.

```r
mostrar_grafico <- function(x, y, color, titulo) {
  df <- isolate(data())
  if (!nrow(df)) stop("No hay datos para graficar.")
  formula <- as.formula(paste(y, "~", x, if (nzchar(color)) paste("|", color) else ""))

  dibujar <- function() {
    if (nzchar(color)) tinyplot(formula, data = df, pch = 19, palette = "Blues 3")
    else tinyplot(formula, data = df, pch = 19, col = "#0E4F5A")
  }

  output$grafico_modal <- renderPlot(dibujar())

  showModal(modalDialog(
    title = titulo, plotOutput("grafico_modal", height = "500px"), size = "l", easyClose = TRUE,
    footer = modalButton("Cerrar")
  ))

  "Gráfico mostrado en un modal."
}

chat$register_tool(tool(
  mostrar_grafico,
  "Abre en un modal un gráfico de los datos visibles en el dashboard.",
  arguments = list(
    x = type_enum(c("poblacion", "esperanza_de_vida", "pib_per_capita"), "Columna para el eje x."),
    y = type_enum(c("poblacion", "esperanza_de_vida", "pib_per_capita"), "Columna para el eje y."),
    color = type_enum(c("", "continente"), "Columna para el color, o ninguna."),
    titulo = type_string("Título breve del modal.")
  )
))
```

Reglas del patrón:

- **El agente elige parámetros, no datos.** Los argumentos son columnas, cantidad de filas y título; los
  datos salen de `isolate(data())`. Así el modal siempre refleja lo que el usuario ve en el dashboard.
- **Columnas con `type_enum()`**, nunca texto libre: el modelo no puede pedir una columna inexistente.
  Usa `""` como opción para "sin color" o "sin agrupación".
- **Se compone con los filtros:** "muestra solo Asia y grafica PIB contra esperanza de vida" ejecuta
  `actualizar_dashboard()` y luego `mostrar_grafico()`. Por eso usa `tool_mode = "sequential"`.
- **Outputs efímeros:** la tool define `output$grafico_modal` / `output$tabla_modal` dentro de su
  cuerpo; es la única excepción a "las tools no escriben outputs". Cada llamada reemplaza el anterior.
- **El contenido no vuelve al modelo** (`app-06`): devuelve solo una confirmación. Ahorra tokens y evita
  enviar datos que el usuario ya está viendo. El prompt debe aclarar que el modelo no ve el modal.
- **Variante con visión** (`app-08`): si el usuario quiere que el modelo interprete el gráfico, la misma
  `dibujar()` genera un PNG que se devuelve como imagen (ver la siguiente sección).
- `size = "l"`, `easyClose = TRUE` y `modalButton("Cerrar")` para que el modal no bloquee el chat.
- Falla con `stop()` cuando no hay filas, en vez de abrir un modal vacío.
- La versión de tabla sigue la misma forma: `mostrar_tabla(n, titulo)` con
  `renderTable(head(df, n), striped = TRUE, hover = TRUE)` y `tableOutput("tabla_modal")`.
- Para nuevos tipos de visualización (mapa, histograma, serie), agrega una tool `mostrar_*()` por tipo
  con sus propios `type_enum()`, en vez de una tool genérica con muchos argumentos opcionales.

### Devolver una imagen al modelo (`app-08`)

```r
archivo <- tempfile(fileext = ".png")
grDevices::png(archivo, width = 768, height = 500)
tryCatch(dibujar(), finally = grDevices::dev.off())
on.exit(unlink(archivo))
list(
  ContentText("Gráfico mostrado en el modal. Analiza la imagen adjunta y responde."),
  content_image_file(archivo, resize = "none")
)
```

Usa la misma función `dibujar()` para el modal y para el PNG, para que el modelo vea lo mismo que el
usuario. Pide cifras exactas a una tool de datos, no a la imagen.

## 7. SQL seguro con DuckDB (`app-04`–`app-08`)

```r
con <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
DBI::dbWriteTable(con, "paises", paises)
DBI::dbExecute(con, "SET enable_external_access = false")
onStop(function() DBI::dbDisconnect(con, shutdown = TRUE))

validar_select <- function(consulta) {
  consulta <- trimws(consulta)
  if (!grepl("^SELECT\\b", consulta, ignore.case = TRUE)) stop("Solo se permiten consultas SELECT.")
  if (!grepl("\\bpaises\\b", consulta, ignore.case = TRUE)) stop("La consulta debe usar paises.")
  if (grepl(";", consulta, fixed = TRUE)) stop("Envía una sola consulta y no incluyas punto y coma.")
  consulta
}
```

- Dos capas: validación del texto y `enable_external_access = false` en la base.
- Base en memoria con solo la tabla necesaria; usa una `VIEW` para exponer únicamente las columnas que el
  modelo debe ver (`app-08` oculta la geometría).
- Parámetros con `params = list(...)` cuando el valor viene del modelo y no es SQL (`ir_a_pais()`).
- Llama a la tool `consultar_tabla(consulta)` y describe la tabla y sus columnas en el prompt.

## 8. MCP (`app-09`)

```r
library(mcptools)
chat$set_tools(mcp_tools("mcp.json"))   # todas las tools del servidor, sin adaptar
chat$register_tool(tool(guardar_datos, ...))  # tools locales se agregan después
```

- `set_tools()` reemplaza la lista de tools; registra las locales **después**.
- Conserva los esquemas del servidor MCP; si uno necesita ajustes, aíslalo en un archivo aparte
  (`mcp-tools.R`) en vez de mezclarlo con la app.
- Patrón **MCP → tool local → reactiveVal**: el modelo consulta el MCP, arma filas tipadas y llama a
  `guardar_datos(datos, variables)`, que reemplaza la carga completa. `ver_datos()` permite reutilizar
  lo ya descargado sin volver a consultar.
- Guarda metadatos junto con los datos (indicador, nombre, unidad) para etiquetar ejes, leyendas y
  tooltips sin depender del modelo.
- La app arranca vacía y los outputs muestran un estado vacío legible (ejes sin datos, mapa base).
- Para demos, tests o documentación, cachea respuestas reales (`cache-demo.R` en `app-09`) en vez de
  consultar al modelo cada vez.
- Variante mínima para explorar un servidor MCP:

```r
ui <- page_chat("Conversar con herramientas MCP")
server <- function(input, output, session) {
  chat <- ellmer::chat("openai/gpt-5.6-luna", system_prompt = "Responde en español.")
  chat$set_tools(mcp_tools("mcp.json"))
  chat_server("chat", chat, history = FALSE)
}
```

## 9. Prompts

### `prompt.md`

1. **Rol y dominio** en una línea ("Eres un analista breve de los datos de países de Gapminder").
2. **Datos disponibles**: tabla, columnas, unidades, años y fuente.
3. **Cuándo usar cada tool**, una regla por tool, con su nombre exacto entre backticks.
4. **Recorrido** numerado cuando las tools se encadenan
   (resolver → consultar → visualizar → inspeccionar).
5. **Límites del modelo**: qué no ve ("no ve automáticamente el globo ni los modales") y qué no existe
   ("no hay datos municipales").
6. **Advertencias de interpretación**: unidades, escalas, estimaciones frente a conteos, proyecciones.
7. **Cierre**: no inventar cifras, responder breve, en español, con unidad, año y fuente.

### `greeting.md`

- Dos o tres preguntas de ejemplo en negrita que ejerciten las tools de la app.
- El greeting no llega al modelo; es solo para el usuario.

## 10. Checklist para una app nueva

- [ ] Hay un cambio de OpenSpec aprobado que describe las tools, el estado y los escenarios.
- [ ] Parte del ejemplo más cercano de `../shiny-chat-patterns-main`.
- [ ] Secciones `data`, `prompt`, `user interface`, `server`, `tools`, `chat`.
- [ ] Cliente `ellmer::chat()` dentro de `server`.
- [ ] Tools con nombres explícitos, descripción breve y argumentos acotados con `type_*()`.
- [ ] Tools leen con `isolate()`, escriben en `reactiveVal` y devuelven resultados breves.
- [ ] Tablas y gráficos a pedido como tools `mostrar_*()` que abren un modal con los datos visibles.
- [ ] SQL de solo lectura con `validar_select()` y `enable_external_access = false`.
- [ ] Prompt con datos, reglas por tool, límites y "no inventes cifras".
- [ ] Recursos cerrados con `onStop()` / `on.exit()`.
- [ ] Líneas de 110 caracteres o menos, incluidos los `.md`.
- [ ] La app se ejecuta desde su carpeta: `shiny::runApp("nombre-app")`.
- [ ] README de la app actualizado y el cambio de OpenSpec archivado al terminar.
