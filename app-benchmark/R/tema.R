# Sistema visual: color fijo por banco, colores de apoyo, tema bslib y opciones globales de highcharter.

colores <- c(
  sistema = "#3A3F44",
  resto = "#CDD3DA",
  positivo = "#2E7D32",
  negativo = "#C62828",
  texto_suave = "#5F6B7A",
  # Grafito neutro para la identidad de la app (barra, acentos, controles): ningún banco tiene un color
  # propio sin tono, así la app no se lee como de un banco.
  acento = "#1F2933",
  primario = "#1F2933"
)

# Composición por moneda: paleta propia y apagada, para que no se confunda con un banco.
colores_moneda <- c(clp = "#2F4B7C", ipc = "#7A9CC6", tc = "#C9A66B", mx = "#8C96A3")

# color por banco ---------------------------------------------------------
# La paleta vive en data/instituciones.csv (columna color). La app y las pruebas la fijan con
# usar_colores_bancos(); sin color, un banco va en el gris de contexto.
usar_colores_bancos <- function(fichas) {
  options(benchmark.colores = stats::setNames(fichas$color, fichas$cod_ifi))
}

color_banco <- function(cod) {
  paleta <- getOption("benchmark.colores", character())
  out <- unname(paleta[cod])
  out[is.na(out) | out == ""] <- colores[["resto"]]
  out[cod == "999"] <- colores[["sistema"]]
  out
}

# OKLab y simulación de daltonismo (Machado 2009, severidad 1) para detectar colores parecidos.
hex_lineal <- function(hex) {
  m <- grDevices::col2rgb(hex) / 255
  ifelse(m <= 0.04045, m / 12.92, ((m + 0.055) / 1.055)^2.4)
}

lineal_oklab <- function(rgb) {
  m1 <- rbind(c(0.4122214708, 0.5363415286, 0.0514459929), c(0.2119034982, 0.6806995451, 0.1073969566),
              c(0.0883024619, 0.2817188376, 0.6299787005))
  m2 <- rbind(c(0.2104542553, 0.7936177850, -0.0040720468), c(1.9779984951, -2.4285922050, 0.4505937099),
              c(0.0259040371, 0.7827717662, -0.8086757660))
  m2 %*% ((m1 %*% rgb)^(1 / 3))
}

machado <- list(
  protan = rbind(c(0.152286, 1.052583, -0.204868), c(0.114503, 0.786281, 0.099216),
                 c(-0.003882, -0.048116, 1.051998)),
  deutan = rbind(c(0.367322, 0.860646, -0.227968), c(0.280085, 0.672501, 0.047413),
                 c(-0.011820, 0.042940, 0.968881))
)

# Separación OKLab (x100) entre dos colores: visión normal y el peor caso con daltonismo rojo-verde.
separacion_colores <- function(a, b) {
  la <- hex_lineal(a)
  lb <- hex_lineal(b)
  d <- function(x, y) 100 * sqrt(sum((lineal_oklab(x) - lineal_oklab(y))^2))
  sim <- function(m, x) pmin(1, pmax(0, m %*% x))
  c(normal = d(la, lb),
    daltonismo = min(d(sim(machado$protan, la), sim(machado$protan, lb)),
                     d(sim(machado$deutan, la), sim(machado$deutan, lb))))
}

colores_parecidos <- function(a, b) {
  s <- separacion_colores(a, b)
  s[["normal"]] < 15 || s[["daltonismo"]] < 6
}

# Trazo de cada banco en gráficos de líneas y pesas: si su color se parece al de un banco anterior en
# la lista que va con trazo continuo, va punteado. El orden decide quién conserva el trazo continuo
# (el banco analizado va primero).
trazos_bancos <- function(cods) {
  trazo <- rep("Solid", length(cods))
  hex <- color_banco(cods)
  for (i in seq_along(cods)[-1]) {
    previos <- which(trazo[seq_len(i - 1)] == "Solid")
    if (any(vapply(previos, function(j) colores_parecidos(hex[i], hex[j]), TRUE))) trazo[i] <- "Dash"
  }
  stats::setNames(trazo, cods)
}

etiquetas_rol <- c(
  foco = "Banco analizado",
  superior = "Vecino superior",
  inferior = "Vecino inferior",
  lider = "Líder",
  sistema = "Sistema",
  comparado = "Comparado",
  escalera = "Escalera",
  resto = "Resto"
)

# highcharter convierte fontFamily en un enlace de Google Fonts: solo "Inter" + genérica, sin comillas.
fuente_app <- "Inter, sans-serif"

# Animación de entrada de todos los gráficos: más lenta que la de Highcharts (1 s), para un llenado suave.
animacion_graficos <- list(duration = 1600)

tema_app <- bslib::bs_theme(
  version = 5,
  primary = colores[["primario"]],
  bg = "#FFFFFF",
  fg = "#1F2933",
  base_font = bslib::font_collection(bslib::font_google("Inter", local = FALSE), "system-ui", "sans-serif"),
  "border-radius" = "0.6rem",
  "card-border-color" = "#E3E8EE"
)

options(
  highcharter.lang = list(
    decimalPoint = ",",
    thousandsSep = ".",
    months = c("enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre",
               "octubre", "noviembre", "diciembre"),
    shortMonths = c("ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"),
    weekdays = c("domingo", "lunes", "martes", "miércoles", "jueves", "viernes", "sábado"),
    loading = "Cargando...",
    noData = "Sin datos para mostrar",
    resetZoom = "Restablecer zoom",
    viewFullscreen = "Ver en pantalla completa",
    exitFullscreen = "Salir de pantalla completa",
    downloadPNG = "Descargar PNG",
    downloadSVG = "Descargar SVG",
    downloadJPEG = "Descargar JPEG",
    downloadCSV = "Descargar CSV",
    printChart = "Imprimir gráfico",
    contextButtonTitle = "Opciones del gráfico"
  ),
  highcharter.theme = highcharter::hc_theme(
    chart = list(backgroundColor = "transparent", style = list(fontFamily = fuente_app)),
    navigation = list(buttonOptions = list(
      symbolStroke = colores[["texto_suave"]],
      theme = list(fill = "transparent", states = list(hover = list(fill = "#EEF1F4")))
    )),
    title = list(style = list(fontSize = "15px", fontWeight = "600", color = "#1F2933")),
    subtitle = list(style = list(color = colores[["texto_suave"]])),
    xAxis = list(
      lineColor = "#D5DBE2", tickColor = "#D5DBE2",
      labels = list(style = list(color = colores[["texto_suave"]], fontSize = "12px"))
    ),
    yAxis = list(
      gridLineColor = "#EEF1F4",
      labels = list(style = list(color = colores[["texto_suave"]], fontSize = "12px")),
      title = list(style = list(color = colores[["texto_suave"]], fontWeight = "400"))
    ),
    legend = list(
      itemStyle = list(fontWeight = "500", color = "#1F2933"),
      itemHoverStyle = list(color = "#000")
    ),
    tooltip = list(
      backgroundColor = "rgba(255,255,255,0.97)", borderColor = "#D5DBE2", borderRadius = 8, shadow = FALSE,
      style = list(fontSize = "12.5px")
    ),
    credits = list(style = list(color = "#9AA5B1", fontSize = "10.5px")),
    plotOptions = list(series = list(animation = animacion_graficos))
  )
)

# Botón de descarga en todos los gráficos (equivale a hc_exporting(enabled = TRUE)). Va en las opciones base
# de highchart(), porque las de highcharter traen exporting desactivado y le ganan al tema. Solo formatos
# que se generan en el navegador: sin PDF ni servidor de exportación, así los datos no salen del equipo.
loadNamespace("highcharter")
options(highcharter.chart = modifyList(getOption("highcharter.chart"), list(
  # spacingTop abre una franja sobre el gráfico y el botón sube a ella (y = -30): Highcharts lo alinea al
  # borde superior del área útil, así que sin esto tapa la primera barra o la leyenda.
  chart = list(spacingTop = 38),
  exporting = list(
  enabled = TRUE, fallbackToExportServer = FALSE, filename = "grafico-cmf",
  # El fondo del dashboard es transparente; la imagen descargada va sobre blanco (JPEG lo dejaría negro).
  chartOptions = list(chart = list(backgroundColor = "#FFFFFF")),
  buttons = list(contextButton = list(y = -30, menuItems = list(
    "viewFullscreen", "printChart", "downloadPNG", "downloadJPEG", "downloadSVG"
  )))
))))
