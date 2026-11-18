# Constructores de gráficos (highcharter) y tabla (reactable). Reciben data.frames ya calculados.
# Cada banco usa su color fijo (color_banco()); el banco analizado se destaca por grosor y negrita.

fuente_cmf <- "Fuente: CMF"

puntos_tiempo <- function(fecha, y) {
  highcharter::list_parse2(data.frame(x = highcharter::datetime_to_timestamp(fecha), y = y))
}

base_tiempo <- function() {
  highcharter::highchart() |>
    highcharter::hc_xAxis(type = "datetime", crosshair = list(color = "#E3E8EE")) |>
    highcharter::hc_tooltip(shared = TRUE, xDateFormat = "%B %Y") |>
    highcharter::hc_legend(align = "left", verticalAlign = "top", itemDistance = 18) |>
    highcharter::hc_plotOptions(
      series = list(marker = list(enabled = FALSE), animation = animacion_graficos)
    ) |>
    highcharter::hc_credits(enabled = TRUE, text = fuente_cmf)
}

# Color de una serie: el del banco, salvo contexto (gris) y sistema (gris oscuro).
color_serie <- function(cod, rol) {
  if (rol == "resto") colores[["resto"]] else color_banco(cod)
}

# Bancos visibles con el foco primero, para que el foco conserve el trazo continuo.
orden_visibles <- function(integrantes) {
  vis <- integrantes[!integrantes$rol %in% c("resto", "sistema"), ]
  c(vis$cod_ifi[vis$rol == "foco"], vis$cod_ifi[vis$rol != "foco"])
}

# Barras horizontales del ranking. destacados: bancos que van con su color (la escalera); el resto, gris.
grafico_ranking <- function(rk, destacados) {
  nombre <- paste0(rk$posicion, ". ", rk$nombre)
  nombre[rk$rol == "foco"] <- paste0("<b>", nombre[rk$rol == "foco"], "</b>")
  puntos <- data.frame(
    name = nombre,
    y = rk$monto / 1e9,
    color = ifelse(rk$cod_ifi %in% destacados, color_banco(rk$cod_ifi), colores[["resto"]]),
    monto = vapply(rk$monto, monto_corto, ""),
    part = porcentaje(rk$participacion, 2),
    var = porcentaje(rk$var_m1, 1, signo = TRUE)
  )
  highcharter::highchart() |>
    highcharter::hc_chart(type = "bar", spacingRight = 28) |>
    highcharter::hc_xAxis(type = "category", labels = list(step = 1, style = list(color = "#1F2933"))) |>
    highcharter::hc_yAxis(
      title = list(text = "Miles de millones de $"),
      labels = list(format = "{value:,.0f}", style = list(textOverflow = "none"))
    ) |>
    highcharter::hc_add_series(
      name = "Monto", data = highcharter::list_parse(puntos), showInLegend = FALSE,
      borderRadius = 3, pointPadding = 0.06, groupPadding = 0.04,
      dataLabels = list(
        enabled = TRUE, format = "{point.part}",
        style = list(fontWeight = "500", textOutline = "none", color = colores[["texto_suave"]],
                     fontSize = "11px")
      )
    ) |>
    highcharter::hc_tooltip(
      useHTML = TRUE, headerFormat = "<b>{point.key}</b><br/>",
      pointFormat = paste0(
        "Monto: <b>{point.monto}</b><br/>Participación: <b>{point.part}</b><br/>",
        "Var. mensual: <b>{point.var}</b>"
      )
    ) |>
    highcharter::hc_credits(enabled = TRUE, text = fuente_cmf, position = list(align = "left", x = 10))
}

# Líneas de la comparación. campo: "monto", "indice" o "participacion".
grafico_lineas <- function(s, campo, eje, decimales = 0, sufijo = "", divisor = 1,
                           sin_sistema = FALSE, eje_sistema = FALSE) {
  integrantes <- attr(s, "integrantes")
  if (sin_sistema) integrantes <- integrantes[integrantes$rol != "sistema", ]
  trazo <- trazos_bancos(orden_visibles(integrantes))
  orden <- c(integrantes$cod_ifi[integrantes$rol == "resto"], integrantes$cod_ifi[integrantes$rol != "resto"])

  destacados <- s[[campo]][!s$rol %in% c("resto", "sistema")]
  sufijo_tooltip <- sufijo
  if (campo == "monto") {
    # Escala automática: miles de millones, o millones cuando los montos destacados son pequeños.
    pequenos <- max(abs(destacados), na.rm = TRUE) < 1e9
    divisor <- if (pequenos) 1e6 else 1e9
    eje <- if (pequenos) "Millones de $" else "Miles de millones de $"
    sufijo_tooltip <- if (pequenos) " millones" else " mil millones"
  }
  # Valores cercanos a cero necesitan decimales para no leerse "0, -0, -0".
  maximo <- max(abs(destacados / divisor), na.rm = TRUE)
  if (is.finite(maximo) && maximo < 10) decimales <- max(decimales, if (maximo < 1) 2 else 1)
  hc <- base_tiempo() |>
    highcharter::hc_tooltip(valueDecimals = decimales, valueSuffix = sufijo_tooltip)
  formato_eje <- paste0("{value:,.", decimales, "f}", sufijo)
  if (eje_sistema) {
    hc <- hc |> highcharter::hc_yAxis_multiples(
      list(title = list(text = eje), labels = list(format = formato_eje)),
      list(title = list(text = "Sistema"), labels = list(format = formato_eje), opposite = TRUE,
           gridLineWidth = 0)
    )
  } else {
    # Con bancos de contexto, el eje se ajusta a las series destacadas; el resto queda recortado.
    eje_y <- list(title = list(text = eje), labels = list(format = formato_eje))
    destacados <- s[s$cod_ifi %in% integrantes$cod_ifi[integrantes$rol != "resto"], campo] / divisor
    if (any(integrantes$rol == "resto") && length(destacados)) {
      holgura <- max(0.15 * diff(range(destacados)), 0.05 * max(abs(destacados)))
      eje_y <- c(eje_y, list(min = min(destacados) - holgura, max = max(destacados) + holgura,
                             startOnTick = FALSE, endOnTick = FALSE))
    }
    hc <- do.call(highcharter::hc_yAxis, c(list(hc), eje_y))
  }

  for (cod in orden) {
    df <- s[s$cod_ifi == cod, ]
    if (!nrow(df)) next
    rol <- integrantes$rol[integrantes$cod_ifi == cod]
    hc <- hc |> highcharter::hc_add_series(
      type = "line", name = df$nombre[1], data = puntos_tiempo(df$fecha, df[[campo]] / divisor),
      color = color_serie(cod, rol),
      lineWidth = switch(rol, foco = 4, resto = 1.2, 2.5),
      dashStyle = if (rol == "sistema") "ShortDot" else if (isTRUE(trazo[cod] == "Dash")) "Dash" else "Solid",
      zIndex = switch(rol, foco = 5, resto = 0, 3),
      enableMouseTracking = rol != "resto",
      showInLegend = rol != "resto",
      states = list(inactive = list(opacity = if (rol == "resto") 1 else 0.35)),
      # Bancos de la escalera que no son vecinos directos: en la leyenda, ocultos hasta que se activen.
      visible = rol != "escalera",
      yAxis = if (eje_sistema && rol == "sistema") 1 else 0
    )
  }
  hc
}

diferencia <- function(s, a, b, campo) {
  x <- s[s$cod_ifi == a, c("periodo", "fecha", campo)]
  y <- s[s$cod_ifi == b, c("periodo", campo)]
  m <- merge(x, y, by = "periodo")
  data.frame(fecha = m$fecha, y = m[[paste0(campo, ".x")]] - m[[paste0(campo, ".y")]])
}

# Brecha en el tiempo entre el foco y su comparación, según el modo.
grafico_brecha <- function(s, resumen, modo) {
  foco <- resumen$foco$cod_ifi
  integrantes <- attr(s, "integrantes")
  nombre <- function(cod) s$nombre[s$cod_ifi == cod][1]
  hc <- base_tiempo()

  if (modo == "sistema") {
    d <- diferencia(s, foco, "999", "indice")
    return(hc |>
      highcharter::hc_yAxis(
        title = list(text = "Puntos (base 100)"),
        plotLines = list(list(value = 0, width = 1, color = "#9AA5B1"))
      ) |>
      highcharter::hc_tooltip(valueDecimals = 1, valueSuffix = " pts") |>
      highcharter::hc_add_series(
        type = "column", name = paste("Crecimiento acumulado de", nombre(foco), "frente al sistema"),
        data = puntos_tiempo(d$fecha, d$y), borderRadius = 2, color = colores[["positivo"]],
        zones = list(list(value = 0, color = colores[["negativo"]]), list(color = colores[["positivo"]]))
      ))
  }

  if (modo == "lider") {
    lider <- integrantes$cod_ifi[integrantes$rol == "lider"]
    if (!length(lider)) {
      return(hc |>
        highcharter::hc_subtitle(
          text = paste(nombre(foco), "es el líder de la cuenta: la brecha es cero.")
        ) |>
        highcharter::hc_yAxis(title = list(text = "Miles de millones de $"), min = -1, max = 1) |>
        highcharter::hc_add_series(type = "line", name = "Brecha", color = color_banco(foco),
                                   data = puntos_tiempo(unique(s$fecha), 0)))
    }
    d <- diferencia(s, lider, foco, "monto")
    p <- diferencia(s, lider, foco, "participacion")
    return(hc |>
      highcharter::hc_yAxis_multiples(
        list(title = list(text = "Miles de millones de $"), labels = list(format = "{value:,.0f}")),
        list(title = list(text = "Participación (pb)"), labels = list(format = "{value:,.0f}"),
             opposite = TRUE, gridLineWidth = 0)
      ) |>
      highcharter::hc_add_series(
        type = "column", name = paste("Monto:", nombre(lider), "menos", nombre(foco)),
        data = puntos_tiempo(d$fecha, d$y / 1e9), color = color_banco(lider), borderRadius = 2,
        tooltip = list(valueDecimals = 0, valueSuffix = " mil millones")
      ) |>
      highcharter::hc_add_series(
        type = "line", name = "Participación (pb)", data = puntos_tiempo(p$fecha, 1e4 * p$y), yAxis = 1,
        color = color_banco(foco), lineWidth = 3, tooltip = list(valueDecimals = 0, valueSuffix = " pb")
      ))
  }

  # Pares (a - b): en vecinos, superior - foco y foco - inferior; en bancos, comparado - foco.
  pares <- data.frame(a = character(), b = character(), otro = character(), etiqueta = character())
  if (modo == "vecinos") {
    if (!is.null(resumen$superior)) {
      sup <- resumen$superior$cod_ifi
      etiqueta <- paste0("Distancia al superior (", nombre(sup), ")")
      pares <- rbind(pares, data.frame(a = sup, b = foco, otro = sup, etiqueta = etiqueta))
    }
    if (!is.null(resumen$inferior)) {
      inf <- resumen$inferior$cod_ifi
      etiqueta <- paste0("Ventaja sobre el inferior (", nombre(inf), ")")
      pares <- rbind(pares, data.frame(a = foco, b = inf, otro = inf, etiqueta = etiqueta))
    }
  }
  if (modo == "bancos") {
    for (cod in integrantes$cod_ifi[integrantes$rol == "comparado"]) {
      etiqueta <- paste(nombre(cod), "menos", nombre(foco))
      pares <- rbind(pares, data.frame(a = cod, b = foco, otro = cod, etiqueta = etiqueta))
    }
  }

  hc <- hc |>
    highcharter::hc_yAxis(
      title = list(text = "Miles de millones de $"), labels = list(format = "{value:,.0f}"),
      plotLines = list(list(value = 0, width = 1, color = "#9AA5B1"))
    ) |>
    highcharter::hc_tooltip(valueDecimals = 0, valueSuffix = " mil millones")
  if (!nrow(pares)) {
    return(hc |> highcharter::hc_subtitle(text = "Elige bancos para comparar en el panel lateral."))
  }
  trazo <- trazos_bancos(pares$otro)
  for (i in seq_len(nrow(pares))) {
    d <- diferencia(s, pares$a[i], pares$b[i], "monto")
    hc <- hc |> highcharter::hc_add_series(
      type = "line", name = pares$etiqueta[i], data = puntos_tiempo(d$fecha, d$y / 1e9),
      color = color_banco(pares$otro[i]), lineWidth = 3, dashStyle = trazo[[pares$otro[i]]]
    )
  }
  hc
}

# Pesas: participación hace 12 meses (punto claro) y hoy (punto lleno) por banco, en orden de ranking.
# p: data.frame de participacion_12m() con columna nombre.
grafico_pesas <- function(p, foco, periodo_12m) {
  p <- p[order(p$posicion), ]
  trazo <- trazos_bancos(c(intersect(foco, p$cod_ifi), setdiff(p$cod_ifi, foco)))
  categorias <- paste0(p$posicion, ". ", p$nombre)
  categorias[p$cod_ifi == foco] <- paste0("<b>", categorias[p$cod_ifi == foco], "</b>")
  punto <- function(i) {
    col <- color_banco(p$cod_ifi[i])
    cambio <- 100 * (p$participacion[i] - p$participacion_12m[i])
    list(x = i - 1, low = 100 * p$participacion_12m[i], high = 100 * p$participacion[i], color = col,
         lowColor = paste0(col, "66"), connectorColor = col,
         cambio = puntos_base(cambio, signo = TRUE))
  }
  con_dato <- which(!is.na(p$participacion_12m))
  sin_dato <- which(is.na(p$participacion_12m))

  hc <- highcharter::highchart() |>
    highcharter::hc_add_dependency("modules/dumbbell.js") |>
    highcharter::hc_chart(inverted = TRUE) |>
    highcharter::hc_xAxis(categories = categorias, labels = list(style = list(color = "#1F2933"))) |>
    highcharter::hc_yAxis(title = list(text = "Participación sobre el sistema"),
                          labels = list(format = "{value:,.1f} %", style = list(textOverflow = "none"))) |>
    highcharter::hc_legend(enabled = FALSE) |>
    highcharter::hc_subtitle(text = paste0("Punto claro: ", etiqueta_periodo(periodo_12m),
                                           " · punto lleno: hoy")) |>
    highcharter::hc_credits(enabled = TRUE, text = fuente_cmf)
  for (estilo in c("Solid", "Dash")) {
    idx <- con_dato[trazo[p$cod_ifi[con_dato]] == estilo]
    if (!length(idx)) next
    hc <- hc |> highcharter::hc_add_series(
      type = "dumbbell", name = "Participación", data = lapply(idx, punto),
      connectorWidth = 4, dashStyle = estilo, marker = list(radius = 7, symbol = "circle"),
      tooltip = list(pointFormat = paste0(
        "hace 12 meses: <b>{point.low:,.2f} %</b><br/>",
        "hoy: <b>{point.high:,.2f} %</b><br/>cambio: <b>{point.cambio}</b>"
      ))
    )
  }
  if (length(sin_dato)) {
    hc <- hc |> highcharter::hc_add_series(
      type = "scatter", name = "Sin dato hace 12 meses",
      data = lapply(sin_dato, function(i) list(x = i - 1, y = 100 * p$participacion[i],
                                                color = color_banco(p$cod_ifi[i]))),
      marker = list(radius = 7, symbol = "circle"),
      tooltip = list(pointFormat = "hoy: <b>{point.y:,.2f} %</b><br/>sin dato hace 12 meses")
    )
  }
  hc
}

# Barra apilada al 100 % de la composición por moneda (2 px de separación entre segmentos).
# fila: una fila de composicion(); m: monedas elegidas.
barra_composicion <- function(fila, m) {
  if (isTRUE(fila$mixtos)) return(htmltools::span(class = "comp-mixta", "signos mixtos"))
  partes <- vapply(m, function(k) fila[[paste0("p_", k)]], 1)
  if (anyNA(partes)) return(htmltools::span(class = "comp-mixta", "—"))
  titulo <- paste(paste0(etiquetas_moneda[m], " ", porcentaje(partes, 1)), collapse = " · ")
  segmentos <- lapply(names(partes)[partes > 0.0005], function(k) {
    htmltools::span(class = "comp-seg",
                    style = sprintf("flex-grow:%.4f;background:%s", partes[[k]], colores_moneda[[k]]))
  })
  htmltools::div(class = "comp-barra", title = titulo, segmentos)
}

detalle_composicion <- function(fila, m) {
  filas <- lapply(m, function(k) {
    htmltools::tags$tr(
      htmltools::tags$td(htmltools::span(class = "punto", style = paste0("background:", colores_moneda[[k]])),
                         etiquetas_moneda[[k]]),
      htmltools::tags$td(class = "num", monto_mm(fila[[k]])),
      htmltools::tags$td(class = "num",
                         if (isTRUE(fila$mixtos)) "—" else porcentaje(fila[[paste0("p_", k)]], 1))
    )
  })
  htmltools::div(
    class = "comp-detalle",
    htmltools::tags$table(
      htmltools::tags$thead(htmltools::tags$tr(htmltools::tags$th("Moneda"), htmltools::tags$th("MM$"),
                                               htmltools::tags$th(if (length(m) == 4) "% del total"
                                                                  else "% de la selección"))),
      htmltools::tags$tbody(filas)
    ),
    if (isTRUE(fila$mixtos)) htmltools::p(class = "comp-nota",
      "Los componentes tienen signos distintos, por eso no se muestran porcentajes.")
  )
}

# Tabla de ranking: color propio por banco, barras de monto, composición por moneda y fila del foco
# resaltada.
# comp: data.frame de composicion() de la misma cuenta y período.
tabla_ranking <- function(rk, comp) {
  d <- rk[, c("cod_ifi", "posicion", "nombre", "clasificacion", "monto", "participacion", "var_m1", "var_12m",
              "rol")]
  d <- cbind(d, comp[match(d$cod_ifi, comp$cod_ifi), c("clp", "ipc", "tc", "mx", "mixtos", "p_clp", "p_ipc",
                                                         "p_tc", "p_mx")])
  m <- attr(comp, "monedas")
  # Ordenable por el % de la última moneda elegida (moneda extranjera cuando está en la selección).
  d$composicion <- d[[paste0("p_", m[length(m)])]]
  max_abs <- max(abs(d$monto))
  color_signo <- function(v) {
    if (is.na(v) || v == 0) return(list(color = colores[["texto_suave"]]))
    list(color = if (v > 0) colores[["positivo"]] else colores[["negativo"]], fontWeight = 600)
  }
  ocultas <- c("cod_ifi", "rol", "clp", "ipc", "tc", "mx", "mixtos", "p_clp", "p_ipc", "p_tc", "p_mx")

  columnas <- list(
    posicion = reactable::colDef(name = "#", width = 52, align = "center"),
    nombre = reactable::colDef(name = "Banco", minWidth = 160, cell = function(v, i) {
      punto <- htmltools::span(class = "punto", style = paste0("background:", color_banco(d$cod_ifi[i])))
      htmltools::tagList(punto, v)
    }),
    clasificacion = reactable::colDef(name = "Clasif.", width = 76, align = "center", na = "—"),
    monto = reactable::colDef(name = "Monto (MM$)", minWidth = 170, align = "right",
                              cell = function(v, i) {
      ancho <- if (max_abs > 0) 100 * abs(v) / max_abs else 0
      color <- if (d$rol[i] == "foco") color_banco(d$cod_ifi[i]) else "#9FB3C8"
      htmltools::div(
        class = "barra-celda",
        htmltools::div(class = "barra-fondo", htmltools::div(
          class = "barra", style = sprintf("width:%.1f%%;background:%s", ancho, color)
        )),
        htmltools::span(class = "barra-valor", monto_mm(v))
      )
    }),
    participacion = reactable::colDef(name = "Particip.", width = 92, align = "right",
                                      cell = function(v) porcentaje(v, 2)),
    composicion = reactable::colDef(name = "Composición", minWidth = 110,
                                    cell = function(v, i) barra_composicion(d[i, ], m)),
    var_m1 = reactable::colDef(name = "Var. m/m", width = 88, align = "right",
                               cell = function(v) porcentaje(v, 1, signo = TRUE), style = color_signo),
    var_12m = reactable::colDef(name = "Var. 12m", width = 88, align = "right",
                                cell = function(v) porcentaje(v, 1, signo = TRUE), style = color_signo)
  )
  for (k in ocultas) columnas[[k]] <- reactable::colDef(show = FALSE)

  reactable::reactable(
    d[, c("posicion", "nombre", "clasificacion", "monto", "participacion", "composicion", "var_m1", "var_12m",
          ocultas)],
    pagination = FALSE, highlight = TRUE, compact = TRUE, borderless = TRUE, sortable = TRUE,
    defaultColDef = reactable::colDef(headerClass = "tabla-encabezado", sortNALast = TRUE),
    rowStyle = function(i) {
      if (d$rol[i] != "foco") return(NULL)
      list(background = "rgba(31, 41, 51, 0.06)", fontWeight = 650,
           boxShadow = paste0("inset 4px 0 0 ", color_banco(d$cod_ifi[i])))
    },
    details = function(i) detalle_composicion(d[i, ], m),
    columns = columnas
  )
}

# gráficos pequeños de los indicadores ----------------------------------------

# Base común: sin ejes, leyenda ni créditos, con tooltip y el último punto marcado.
mini_base <- function(alto = 110) {
  highcharter::highchart(height = alto) |>
    highcharter::hc_chart(margin = c(6, 8, 6, 8), backgroundColor = "transparent") |>
    highcharter::hc_xAxis(type = "datetime", visible = FALSE) |>
    highcharter::hc_legend(enabled = FALSE) |>
    highcharter::hc_credits(enabled = FALSE) |>
    highcharter::hc_exporting(enabled = FALSE) |>
    highcharter::hc_tooltip(xDateFormat = "%b %Y", outside = TRUE, useHTML = TRUE,
                            headerFormat = "<span style='font-size:11px'>{point.key}</span><br/>") |>
    highcharter::hc_plotOptions(series = list(animation = animacion_graficos,
                                              marker = list(enabled = FALSE),
                                              states = list(hover = list(lineWidthPlus = 0))))
}

ultimo_marcado <- function(puntos, color) {
  n <- length(puntos)
  puntos[[n]]$marker <- list(enabled = TRUE, radius = 4, fillColor = color, lineColor = "#FFFFFF",
                             lineWidth = 2)
  puntos
}

# Participación conjunta de la escalera en 24 meses (área en el color de acento).
grafico_mini_conjunta <- function(sc) {
  col <- colores[["acento"]]
  sc <- sc[!is.na(sc$participacion), ]
  puntos <- lapply(seq_len(nrow(sc)), function(i) {
    list(x = highcharter::datetime_to_timestamp(sc$fecha[i]), y = 100 * sc$participacion[i],
         texto = porcentaje(sc$participacion[i], 2))
  })
  rango <- range(100 * sc$participacion)
  holgura <- max(0.1, diff(rango) * 0.15)
  mini_base() |>
    highcharter::hc_yAxis(visible = FALSE, startOnTick = FALSE, endOnTick = FALSE,
                          min = rango[1] - holgura, max = rango[2] + holgura) |>
    highcharter::hc_add_series(type = "area", name = "Participación conjunta",
                               data = ultimo_marcado(puntos, col),
                               color = col, lineWidth = 2, fillOpacity = 0.10, softThreshold = TRUE,
                               tooltip = list(pointFormat = "<b>{point.texto}</b>"))
}
