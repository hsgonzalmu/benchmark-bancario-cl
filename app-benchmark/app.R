library(shiny)
library(bslib)
library(highcharter)
library(reactable)
library(ellmer)
library(shinychat)
# R/ (ranking, formato, tema, gráficos, componentes, tools) se carga automáticamente.

# R lee .Renviron solo al iniciar y desde la carpeta de inicio; runApp() ya está en la carpeta de la app,
# así que se carga aquí para que funcione también con shiny::runApp("app-benchmark") desde otra carpeta.
if (file.exists(".Renviron")) readRenviron(".Renviron")

modelo <- "claude-opus-5-5"
esfuerzo <- "low" # sube a "medium" si las respuestas razonan mal

# data --------------------------------------------------------------------
ruta_balance <- file.path("data", "balance.rds")
if (!file.exists(ruta_balance)) {
  stop("Faltan los datos: ejecuta `Rscript prepare-data.R` desde la carpeta app-benchmark/.", call. = FALSE)
}
balance <- readRDS(ruta_balance)
descargado <- attr(balance, "descargado")

cuentas <- read.csv(file.path("data", "cuentas.csv"), colClasses = "character", encoding = "UTF-8")
fichas <- read.csv(file.path("data", "instituciones.csv"), colClasses = "character", encoding = "UTF-8")
nombres_api <- attr(balance, "nombres_api")
sin_ficha <- nombres_api[!nombres_api$cod_ifi %in% fichas$cod_ifi, ]
if (nrow(sin_ficha)) {
  fichas <- rbind(fichas, data.frame(
    cod_ifi = sin_ficha$cod_ifi, nombre_corto = sin_ficha$nombre_api, abreviacion = sin_ficha$cod_ifi,
    clasificacion = "", razon_social = sin_ficha$nombre_api, color = ""
  ))
}
usar_colores_bancos(fichas) # color fijo por banco (columna color); sin color, gris de contexto
ctx <- crear_contexto(balance, fichas, cuentas)

# Base de solo lectura para consultar_datos (DuckDB en memoria, sin acceso a archivos ni red).
con <- crear_base_sql(balance, fichas, cuentas)
onStop(function() DBI::dbDisconnect(con, shutdown = TRUE))
nombre_banco <- ctx$nombre_banco
nombre_cuenta <- ctx$nombre_cuenta

periodos <- ctx$periodos
opciones_bancos <- ctx$bancos
opciones_cuentas <- lapply(split(cuentas, factor(cuentas$grupo, unique(cuentas$grupo))), function(g) {
  as.list(stats::setNames(g$cuenta, g$nombre))
})
opciones_periodos <- stats::setNames(periodos, etiqueta_periodo(periodos))

# Al abrir: el líder de Colocaciones en el último período.
lider_colocaciones <- calcular_ranking(balance, "144000000", periodos[1])$cod_ifi[1]
inicial <- list(banco = lider_colocaciones, cuenta = "144000000", periodo = periodos[1],
                monedas = monedas_todas, modo = "vecinos")

# prompt ------------------------------------------------------------------
saludo <- paste(readLines("greeting.md", warn = FALSE, encoding = "UTF-8"), collapse = "\n")
prompt_sistema <- paste(readLines("prompt.md", warn = FALSE, encoding = "UTF-8"), collapse = "\n")
tiene_key <- nzchar(Sys.getenv("ANTHROPIC_API_KEY"))
mensaje_sin_key <- paste(
  "El chat necesita una API key de Anthropic. Agrega la línea `ANTHROPIC_API_KEY=...` al archivo",
  "`app-benchmark/.Renviron` y reinicia la app. Mientras tanto, el dashboard funciona con los filtros."
)

# Tope de mensajes al chat por sesión, para acotar el gasto en la API cuando la app es pública.
tope_mensajes <- suppressWarnings(as.integer(Sys.getenv("MAX_MENSAJES_CHAT", "15")))
if (is.na(tope_mensajes) || tope_mensajes < 1) tope_mensajes <- 15L
mensaje_tope <- paste0(
  "Llegaste al límite de ", tope_mensajes, " preguntas de esta sesión. Puedes seguir usando los filtros ",
  "del dashboard; si recargas la página empieza una sesión nueva."
)

version_www <- function(archivo) {
  paste0(archivo, "?v=", format(file.mtime(file.path("www", archivo)), "%Y%m%d%H%M%S"))
}

# user interface ----------------------------------------------------------
ui <- page_sidebar(
  title = tags$span(class = "app-titulo", bsicons::bs_icon("bank2"), "Benchmark bancario Chile"),
  window_title = "Benchmark bancario Chile",
  theme = tema_app,
  fillable = FALSE,
  sidebar = sidebar(
    width = 400,
    open = list(desktop = "open", mobile = "closed"), # en el teléfono, el chat se abre con un botón
    accordion(
      id = "panel_lateral",
      multiple = FALSE,
      open = "Chat",
      accordion_panel(
        "Chat", icon = bsicons::bs_icon("chat-dots"),
        chat_ui("chat", greeting = saludo, placeholder = "Pregunta por un banco y una cuenta...",
                height = "calc(100vh - 210px)", fill = FALSE)
      ),
      accordion_panel(
        "Filtros", icon = bsicons::bs_icon("sliders"),
        selectizeInput("banco", "Banco", choices = opciones_bancos, selected = inicial$banco),
        selectInput("cuenta", "Cuenta", choices = opciones_cuentas, selected = inicial$cuenta),
        selectInput("periodo", "Período", choices = opciones_periodos, selected = inicial$periodo),
        checkboxGroupInput("monedas", "Monedas", choices = stats::setNames(monedas_todas, etiquetas_moneda),
                           selected = inicial$monedas),
        actionLink("monedas_total", "Marcar todas (Total)", class = "enlace-total"),
        radioButtons("modo", "Comparación", choices = modos_comparacion, selected = inicial$modo,
                     inline = TRUE),
        conditionalPanel(
          "input.modo == 'bancos'",
          selectizeInput(
            "bancos", "Bancos a comparar (hasta 4)",
            choices = opciones_bancos[opciones_bancos != inicial$banco],
            multiple = TRUE, options = list(maxItems = 4, placeholder = "Elige bancos...")
          )
        ),
        tags$p(class = "sidebar-fuente", "Fuente: CMF, Balance mensual de bancos (API v3).", tags$br(),
               paste0("Datos descargados el ", format(descargado, "%d-%m-%Y"), "."))
      )
    )
  ),
  # "?v=" con la fecha del archivo: el navegador descarga de nuevo CSS y JS cuando cambian, en vez de usar
  # una copia antigua en caché.
  tags$head(tags$link(rel = "stylesheet", href = version_www("styles.css")),
            tags$script(src = version_www("escalera.js"))),
  uiOutput("encabezado"),
  uiOutput("cajas"),
  layout_columns(
    col_widths = breakpoints(sm = 12, lg = c(5, 7)),
    card(
      full_screen = TRUE,
      card_header(class = "card-titulo", textOutput("titulo_ranking", inline = TRUE)),
      highchartOutput("g_ranking", height = "460px")
    ),
    navset_card_underline(
      full_screen = TRUE,
      title = tags$span(class = "card-titulo", textOutput("titulo_comparacion", inline = TRUE)),
      nav_panel("Evolución", highchartOutput("g_evolucion", height = "440px")),
      nav_panel(
        "Base 100",
        # Punto de partida del índice: 100 en el mes elegido.
        div(class = "selector-base",
            radioButtons("base_desde", "Desde hace", inline = TRUE, selected = "12",
                         choices = c("3 meses" = "3", "12 meses" = "12", "24 meses" = "23"))),
        highchartOutput("g_base100", height = "400px")
      ),
      nav_panel("Participación", highchartOutput("g_participacion", height = "440px")),
      nav_panel("Brecha", highchartOutput("g_brecha", height = "440px")),
      nav_panel("Posición 12m", highchartOutput("g_pesas", height = "440px"))
    )
  ),
  card(
    card_header(
      class = "card-titulo cabecera-tabla",
      textOutput("titulo_tabla", inline = TRUE),
      uiOutput("leyenda_monedas", inline = TRUE)
    ),
    reactableOutput("tabla")
  )
)

# server ------------------------------------------------------------------
server <- function(input, output, session) {
  # Estado de selección: lo cambian los filtros y las tools del chat.
  banco_foco <- reactiveVal(inicial$banco)
  cuenta <- reactiveVal(inicial$cuenta)
  periodo <- reactiveVal(inicial$periodo)
  monedas <- reactiveVal(inicial$monedas)
  comparacion <- reactiveVal(list(modo = inicial$modo, bancos = character()))

  # Los inputs escriben el mismo valor que ya tiene el estado cuando el cambio vino del chat; un
  # reactiveVal con el mismo valor no invalida, así que no hay bucle.
  observeEvent(input$banco, banco_foco(input$banco), ignoreInit = TRUE)
  observeEvent(input$cuenta, cuenta(input$cuenta), ignoreInit = TRUE)
  observeEvent(input$periodo, periodo(input$periodo), ignoreInit = TRUE)
  # La selección de monedas no puede quedar vacía: si se desmarca la última, se vuelve a marcar.
  observeEvent(input$monedas, {
    if (!length(input$monedas)) {
      updateCheckboxGroupInput(session, "monedas", selected = monedas())
      showNotification("Elige al menos una moneda.", type = "warning", duration = 3)
    } else {
      monedas(normalizar_monedas(input$monedas))
    }
  }, ignoreInit = TRUE, ignoreNULL = FALSE)
  observeEvent(input$monedas_total, updateCheckboxGroupInput(session, "monedas", selected = monedas_todas))
  observeEvent(list(input$modo, input$bancos), {
    nueva <- list(modo = input$modo, bancos = setdiff(input$bancos, banco_foco()))
    if (!identical(nueva, comparacion())) comparacion(nueva)
  }, ignoreInit = TRUE, ignoreNULL = FALSE)

  observeEvent(banco_foco(), {
    otros <- opciones_bancos[opciones_bancos != banco_foco()]
    elegidos <- intersect(isolate(comparacion()$bancos), otros)
    updateSelectizeInput(session, "bancos", choices = otros, selected = elegidos)
  }, ignoreInit = TRUE)

  # Lleva a los filtros lo que cambió el chat.
  sincronizar_filtros <- function() {
    isolate({
      cmp <- comparacion()
      otros <- opciones_bancos[opciones_bancos != banco_foco()]
      updateSelectizeInput(session, "banco", selected = banco_foco())
      updateSelectInput(session, "cuenta", selected = cuenta())
      updateSelectInput(session, "periodo", selected = periodo())
      updateCheckboxGroupInput(session, "monedas", selected = monedas())
      updateSelectizeInput(session, "bancos", choices = otros, selected = cmp$bancos)
      updateRadioButtons(session, "modo", selected = cmp$modo)
    })
  }

  # derivados -------------------------------------------------------------
  ranking <- reactive({
    rk <- calcular_ranking(balance, cuenta(), periodo(), monedas(), banco_foco())
    rk$nombre <- nombre_banco(rk$cod_ifi)
    rk$clasificacion <- ctx$clasificacion(rk$cod_ifi)
    rk
  })
  resumen <- reactive(resumen_posicion(ranking(), banco_foco()))
  escalera_actual <- reactive({
    e <- escalera(balance, cuenta(), periodo(), monedas(), banco_foco())
    if (!is.null(e)) {
      e$filas$nombre <- nombre_banco(e$filas$cod_ifi)
      e$todos$nombre <- nombre_banco(e$todos$cod_ifi)
    }
    e
  })
  composicion_actual <- reactive(composicion(balance, cuenta(), periodo(), monedas()))
  series <- reactive({
    cmp <- comparacion()
    s <- series_comparacion(balance, cuenta(), periodo(), monedas(), banco_foco(), cmp$modo, cmp$bancos)
    s$nombre <- nombre_banco(s$cod_ifi)
    s
  })

  mensaje_sin_dato <- reactive({
    ultimo <- ultimo_periodo_banco(balance, cuenta(), banco_foco())
    paste0(
      "Sin datos para ", nombre_banco(banco_foco()), " en ", etiqueta_periodo(periodo()), ".",
      if (!is.na(ultimo)) paste0(" Su último período disponible es ", etiqueta_periodo(ultimo), ".") else ""
    )
  })
  requiere_dato <- function() validate(need(resumen()$con_dato, mensaje_sin_dato()))

  # encabezado y cajas ----------------------------------------------------
  output$encabezado <- renderUI({
    nombre_tipo <- etiqueta_monedas(monedas())
    nombre_modo <- names(modos_comparacion)[modos_comparacion == comparacion()$modo]
    div(
      class = "encabezado",
      div(
        class = "encabezado-principal",
        tags$span(class = "encabezado-banco", nombre_banco(banco_foco())),
        tags$span(class = "encabezado-cuenta", nombre_cuenta(cuenta()))
      ),
      div(
        class = "encabezado-chips",
        chip("calendar3", etiqueta_periodo(periodo())),
        chip("cash-coin", nombre_tipo),
        chip("people", paste("Comparación:", nombre_modo)),
        chip("cloud-download", paste("Datos al", format(descargado, "%d-%m-%Y")))
      ),
      if (!resumen()$con_dato) div(class = "alert alert-warning encabezado-alerta", mensaje_sin_dato())
    )
  })

  # Marco de escalera e indicadores: solo cambia si el banco tiene o no dato en el período. hay_dato es un
  # reactiveVal porque no avisa si recibe el mismo valor, así el marco no se reconstruye al cambiar de banco.
  hay_dato <- reactiveVal(TRUE)
  observe(hay_dato(resumen()$con_dato))
  output$cajas <- renderUI({
    if (!hay_dato()) return(NULL)
    layout_columns(
      col_widths = breakpoints(sm = 12, lg = c(7, 5)), fill = FALSE, class = "fila-cajas",
      card(
        class = "card-escalera",
        card_header(class = "card-titulo", "Escalera de competencia"),
        card_body(uiOutput("escalera", class = "escalera-salida"))
      ),
      uiOutput("indicadores", class = "indicadores")
    )
  })

  # Escalera: se dibuja de nuevo con cuenta, período y monedas. Al cambiar de banco, el observador de abajo
  # la actualiza en el navegador (www/escalera.js), sin redibujar sus filas.
  output$escalera <- renderUI({
    cuenta(); periodo(); monedas()
    if (!hay_dato()) return(NULL)
    isolate({
      e <- escalera_actual()
      if (is.null(e)) NULL else escalera_ui(e, banco_foco())
    })
  })
  observeEvent(banco_foco(), {
    e <- escalera_actual()
    if (is.null(e) || !hay_dato()) return()
    session$sendCustomMessage("escalera_foco", escalera_mensaje(e, banco_foco()))
  }, ignoreInit = TRUE)

  # Indicadores: se dibujan de nuevo con cuenta, período y monedas. Al cambiar de banco, el observador de
  # abajo los actualiza en el navegador: cifras que cuentan hasta el nuevo valor, textos con fundido, tira
  # que se desliza (www/escalera.js) y mini gráfico por proxy.
  datos_indicadores <- function() {
    list(
      e = escalera_actual(),
      cp = cambio_puesto(balance, cuenta(), periodo(), monedas(), banco_foco()),
      ss = serie_sistema(balance, cuenta(), periodo(), monedas(), meses = 24),
      sb = serie_conjunta(balance, cuenta(), periodo(), monedas(), banco_foco(), meses = 24)
    )
  }
  output$indicadores <- renderUI({
    cuenta(); periodo(); monedas()
    if (!hay_dato()) return(NULL)
    isolate({
      if (!resumen()$con_dato) return(NULL)
      d <- datos_indicadores()
      tagList(
        caja_participacion(d$sb, d$ss, d$e, banco_foco(), nombre_banco, nombre_cuenta(cuenta()),
                           grafico = highchartOutput("mini_participacion", height = "110px")),
        caja_puesto(d$cp, d$e, banco_foco(), nombre_banco, nombre_cuenta(cuenta()))
      )
    })
  })
  output$mini_participacion <- renderHighchart({
    cuenta(); periodo(); monedas(); hay_dato()
    isolate({
      req(resumen()$con_dato)
      grafico_mini_participacion(datos_indicadores()$sb, color_banco(banco_foco()))
    })
  })
  observeEvent(banco_foco(), {
    if (!hay_dato() || !resumen()$con_dato) return()
    d <- datos_indicadores()
    session$sendCustomMessage("indicadores_foco", indicadores_mensaje(
      d$sb, d$ss, d$e, d$cp, banco_foco(), nombre_banco, nombre_cuenta(cuenta())
    ))
    col <- color_banco(banco_foco())
    m <- mini_participacion_datos(d$sb, col)
    highchartProxy("mini_participacion") |>
      hcpxy_update(series = list(list(id = "participacion", data = m$data, color = col)),
                   yAxis = list(min = m$min, max = m$max))
  }, ignoreInit = TRUE)

  # gráficos --------------------------------------------------------------
  output$titulo_ranking <- renderText({
    paste0("Ranking · ", nombre_cuenta(cuenta()), " · ", etiqueta_periodo(periodo()))
  })
  output$titulo_comparacion <- renderText({
    cmp <- comparacion()
    switch(
      cmp$modo,
      vecinos = "Frente a sus vecinos de ranking",
      sistema = "Frente al sistema",
      lider = "Frente al líder",
      bancos = if (length(cmp$bancos)) "Frente a bancos elegidos" else "Elige bancos para comparar"
    )
  })
  output$titulo_tabla <- renderText(paste0("Tabla de ranking · ", etiqueta_periodo(periodo())))
  output$leyenda_monedas <- renderUI({
    tags$span(class = "leyenda-moneda", lapply(monedas(), function(k) tags$span(
      tags$span(class = "punto", style = paste0("background:", colores_moneda[[k]])),
      etiquetas_moneda[[k]]
    )))
  })

  # El ranking se dibuja de nuevo solo si cambian cuenta, período o monedas. Al cambiar de banco, el
  # observador de abajo actualiza colores, negrita y pista por proxy, sin redibujar el gráfico.
  destacados_ranking <- function() {
    e <- escalera_actual()
    if (is.null(e)) character() else e$filas$cod_ifi
  }
  output$g_ranking <- renderHighchart({
    cuenta(); periodo(); monedas()
    isolate(grafico_ranking(ranking(), destacados_ranking()))
  })
  observeEvent(banco_foco(), {
    highchartProxy("g_ranking") |>
      hcpxy_update_series(id = "ranking", data = puntos_ranking(ranking(), destacados_ranking()))
  }, ignoreInit = TRUE)

  # Posición 12m: el conjunto sigue el modo de comparación.
  output$g_pesas <- renderHighchart({
    requiere_dato()
    cmp <- comparacion()
    rk <- ranking()
    cods <- switch(
      cmp$modo,
      vecinos = escalera_actual()$filas$cod_ifi,
      lider = unique(c(rk$cod_ifi[1], banco_foco())),
      bancos = unique(c(banco_foco(), cmp$bancos)),
      sistema = rk$cod_ifi
    )
    p <- participacion_12m(balance, cuenta(), periodo(), monedas(), cods)
    p$nombre <- nombre_banco(p$cod_ifi)
    grafico_pesas(p, banco_foco(), desplazar_periodo(periodo(), -12))
  })

  output$g_evolucion <- renderHighchart({
    requiere_dato()
    sistema <- comparacion()$modo == "sistema"
    grafico_lineas(series(), "monto", eje = NULL, eje_sistema = sistema) # unidad automática
  })
  output$g_base100 <- renderHighchart({
    requiere_dato()
    meses <- as.integer(if (is.null(input$base_desde)) "12" else input$base_desde)
    desde <- desplazar_periodo(periodo(), -meses)
    grafico_lineas(rebasar_indice(series(), desde),
                   "indice", paste0("Índice (", etiqueta_periodo(desde), " = 100)"), decimales = 1)
  })
  output$g_participacion <- renderHighchart({
    requiere_dato()
    grafico_lineas(series(), "participacion", "Participación sobre el sistema", decimales = 2,
                   sufijo = " %", divisor = 0.01, sin_sistema = TRUE)
  })
  output$g_brecha <- renderHighchart({
    requiere_dato()
    grafico_brecha(series(), resumen(), comparacion()$modo)
  })

  output$tabla <- renderReactable(tabla_ranking(ranking(), composicion_actual()))

  # tools -----------------------------------------------------------------
  estado <- list(banco_foco = banco_foco, cuenta = cuenta, periodo = periodo, monedas = monedas,
                 comparacion = comparacion)
  # Ventana emergente que abren las tools: outputs efímeros que se reemplazan en cada llamada.
  abrir_ventana <- function(titulo, contenido, csv = NULL, nota = NULL) {
    if (inherits(contenido, "highchart")) {
      output$ventana_grafico <- renderHighchart(contenido)
      cuerpo <- highchartOutput("ventana_grafico", height = "520px")
    } else {
      output$ventana_tabla <- renderReactable(contenido)
      cuerpo <- reactableOutput("ventana_tabla")
    }
    if (!is.null(csv)) {
      output$ventana_csv <- downloadHandler(
        filename = function() {
          paste0(gsub("[^a-z0-9]+", "-", tolower(iconv(titulo, to = "ASCII//TRANSLIT"))), ".csv")
        },
        content = function(archivo) escribir_csv(csv, archivo)
      )
    }
    showModal(modalDialog(
      title = titulo, cuerpo, if (!is.null(nota)) tags$p(class = "nota-ventana", nota),
      size = "xl", easyClose = TRUE,
      footer = tagList(
        if (!is.null(csv)) downloadButton("ventana_csv", "Descargar CSV"),
        modalButton("Cerrar")
      )
    ), session = session)
  }
  herramientas <- crear_tools(estado, ctx, al_cambiar = sincronizar_filtros, abrir_ventana = abrir_ventana,
                              con = con)

  # chat ------------------------------------------------------------------
  chat <- NULL
  if (tiene_key) {
    chat <- chat_anthropic(
      model = modelo,
      system_prompt = prompt_sistema,
      params = params(reasoning_effort = esfuerzo),
      beta_headers = "server-side-fallback-2026-07-01", # reintenta con otro modelo si hay un rechazo
      api_args = list(fallbacks = "default"),
      echo = "none"
    )
    for (t in definir_tools(herramientas, ctx)) chat$register_tool(t)
  }

  mensajes_enviados <- 0L
  observeEvent(input$chat_user_input, {
    if (is.null(chat)) return(chat_append("chat", mensaje_sin_key))
    if (mensajes_enviados >= tope_mensajes) return(chat_append("chat", mensaje_tope))
    mensajes_enviados <<- mensajes_enviados + 1L
    # En shinychat 0.5 el input es una lista (texto y adjuntos): se expande con !!!.
    stream <- chat$stream_async(!!!input$chat_user_input, tool_mode = "sequential", stream = "content")
    chat_append("chat", stream)
  })
}

shinyApp(ui, server)
