# Gráficos y tablas de las ventanas emergentes que abre el chat. Constructores puros: reciben datos ya
# calculados y devuelven un highchart, o una lista con la tabla (reactable) y sus datos para el CSV.

mes_corto <- function(periodo) etiqueta_periodo(periodo)

# gráficos -----------------------------------------------------------------

# Puesto mes a mes (1 arriba), con marcas en los meses en que un banco entra o sale del ranking.
grafico_puestos <- function(pt, foco, nombre_banco) {
  cods <- unique(pt$puestos$cod_ifi)
  orden <- c(intersect(foco, cods), setdiff(cods, foco))
  trazo <- trazos_bancos(orden)
  marcas <- lapply(seq_len(nrow(pt$movimientos)), function(i) {
    m <- pt$movimientos[i, ]
    texto <- if (m$tipo == "sale") {
      paste0("sale ", nombre_banco(m$cod_ifi), " (estaba ", m$posicion_previa, "°)")
    } else {
      paste("entra", nombre_banco(m$cod_ifi))
    }
    list(value = highcharter::datetime_to_timestamp(as.Date(paste0(m$periodo, "01"), "%Y%m%d")) - 15 * 864e5,
         color = "#9AA5B1", dashStyle = "ShortDash", width = 1, zIndex = 1,
         label = list(text = texto, rotation = 0, y = 14 + 14 * (i - 1),
                      style = list(color = colores[["texto_suave"]], fontSize = "11px")))
  })
  hc <- base_tiempo() |>
    highcharter::hc_xAxis(plotLines = marcas) |>
    highcharter::hc_yAxis(title = list(text = "Puesto en el ranking"), reversed = TRUE, allowDecimals = FALSE,
                          labels = list(format = "{value}°"), tickInterval = 1) |>
    highcharter::hc_tooltip(valueSuffix = "°")
  for (cod in orden) {
    d <- pt$puestos[pt$puestos$cod_ifi == cod, ]
    hc <- hc |> highcharter::hc_add_series(
      type = "line", name = nombre_banco(cod), data = puntos_tiempo(d$fecha, d$posicion),
      color = color_banco(cod), lineWidth = if (cod == foco) 4 else 2.5, dashStyle = trazo[[cod]],
      step = "center", zIndex = if (cod == foco) 5 else 3
    )
  }
  hc
}

# Mezcla de monedas de un banco en el tiempo: áreas apiladas al 100 %; con signos mixtos, montos apilados.
grafico_composicion_tiempo <- function(ct) {
  m <- attr(ct, "monedas")
  mixtos <- any(ct$mixtos)
  hc <- base_tiempo()
  if (mixtos) {
    hc <- hc |>
      highcharter::hc_chart(type = "column") |>
      highcharter::hc_plotOptions(column = list(stacking = "normal", borderWidth = 0)) |>
      highcharter::hc_yAxis(title = list(text = "Miles de millones de $"),
                            labels = list(format = "{value:,.0f}")) |>
      highcharter::hc_subtitle(text = "Hay meses con signos mixtos: se muestran montos, no porcentajes.") |>
      highcharter::hc_tooltip(valueDecimals = 0, valueSuffix = " mil millones")
    for (k in m) {
      hc <- hc |> highcharter::hc_add_series(name = etiquetas_moneda[[k]], color = colores_moneda[[k]],
                                             data = puntos_tiempo(ct$fecha, ct[[k]] / 1e9))
    }
    return(hc)
  }
  hc <- hc |>
    highcharter::hc_chart(type = "area") |>
    highcharter::hc_plotOptions(area = list(stacking = "normal", lineWidth = 1, fillOpacity = 0.85)) |>
    highcharter::hc_yAxis(title = list(text = "% de la selección"), max = 100,
                          labels = list(format = "{value} %")) |>
    highcharter::hc_tooltip(valueDecimals = 1, valueSuffix = " %")
  for (k in rev(m)) {
    hc <- hc |> highcharter::hc_add_series(name = etiquetas_moneda[[k]], color = colores_moneda[[k]],
                                           data = puntos_tiempo(ct$fecha, 100 * ct[[paste0("p_", k)]]))
  }
  hc
}

# Variación del período de todos los bancos, ordenada; el banco analizado con su color.
grafico_crecimiento <- function(cr, foco, nombre_banco) {
  puntos <- data.frame(
    name = nombre_banco(cr$cod_ifi),
    y = 100 * cr$variacion,
    color = color_banco(cr$cod_ifi),
    etiqueta = porcentaje(cr$variacion, 1, signo = TRUE),
    pb = puntos_base(cr$cambio_pp, signo = TRUE),
    monto = vapply(cr$monto, monto_corto, "")
  )
  puntos$name[cr$cod_ifi == foco] <- paste0("<b>", puntos$name[cr$cod_ifi == foco], "</b>")
  highcharter::highchart() |>
    highcharter::hc_chart(type = "bar") |>
    highcharter::hc_xAxis(type = "category", labels = list(step = 1, style = list(color = "#1F2933"))) |>
    highcharter::hc_yAxis(title = list(text = "Variación del período"), labels = list(format = "{value} %"),
                          plotLines = list(list(value = 0, width = 1, color = "#9AA5B1"))) |>
    highcharter::hc_add_series(
      name = "Variación", data = highcharter::list_parse(puntos), showInLegend = FALSE, borderRadius = 3,
      dataLabels = list(enabled = TRUE, format = "{point.etiqueta}",
                        style = list(fontWeight = "500", textOutline = "none",
                                     color = colores[["texto_suave"]]))
    ) |>
    highcharter::hc_tooltip(useHTML = TRUE, headerFormat = "<b>{point.key}</b><br/>",
                            pointFormat = paste0("Variación: <b>{point.etiqueta}</b><br/>",
                                                 "Cambio de participación: <b>{point.pb}</b><br/>",
                                                 "Monto hoy: {point.monto}")) |>
    highcharter::hc_credits(enabled = TRUE, text = fuente_cmf)
}

# Monto de una lista libre de bancos en el tiempo.
grafico_evolucion_bancos <- function(serie, foco, nombre_banco) {
  cods <- unique(serie$cod_ifi)
  orden <- c(intersect(foco, cods), setdiff(cods, foco))
  trazo <- trazos_bancos(orden)
  pequenos <- max(abs(serie$monto), na.rm = TRUE) < 1e9
  divisor <- if (pequenos) 1e6 else 1e9
  hc <- base_tiempo() |>
    highcharter::hc_yAxis(title = list(text = if (pequenos) "Millones de $" else "Miles de millones de $"),
                          labels = list(format = "{value:,.0f}")) |>
    highcharter::hc_tooltip(valueDecimals = 0, valueSuffix = if (pequenos) " millones" else " mil millones")
  for (cod in orden) {
    d <- serie[serie$cod_ifi == cod, ]
    hc <- hc |> highcharter::hc_add_series(
      type = "line", name = nombre_banco(cod), data = puntos_tiempo(d$fecha, d$monto / divisor),
      color = color_banco(cod), lineWidth = if (cod == foco) 4 else 2.5, dashStyle = trazo[[cod]]
    )
  }
  hc
}

# Serie de montos de varios bancos (para evolución y la tabla de historia).
serie_bancos <- function(datos, cuenta, periodo, monedas, cods, meses) {
  per <- periodos_ventana(datos, periodo, meses)
  fila <- datos$cuenta == cuenta & datos$periodo %in% per
  d <- datos[fila & datos$cod_ifi %in% c(cods, "999"), c("periodo", "fecha", "cod_ifi")]
  d$monto <- valor_monedas(datos[fila & datos$cod_ifi %in% c(cods, "999"), ], monedas)
  sistema <- d[d$cod_ifi == "999", c("periodo", "monto")]
  d <- d[d$cod_ifi != "999", ]
  d$participacion <- d$monto / sistema$monto[match(d$periodo, sistema$periodo)]
  d[order(d$cod_ifi, d$periodo), ]
}

# tablas -------------------------------------------------------------------

celda_signo <- function(v) {
  if (is.na(v) || v == 0) return(list(color = colores[["texto_suave"]]))
  list(color = if (v > 0) colores[["positivo"]] else colores[["negativo"]], fontWeight = 600)
}

# Ranking con puesto y participación de hace 12 meses.
tabla_ranking_12m <- function(rk, rk12, nombre_banco) {
  i <- match(rk$cod_ifi, rk12$cod_ifi)
  d <- data.frame(
    posicion = rk$posicion, banco = nombre_banco(rk$cod_ifi), monto_mm = rk$monto / 1e6,
    participacion = 100 * rk$participacion, var_m1 = 100 * rk$var_m1, var_12m = 100 * rk$var_12m,
    posicion_12m = rk12$posicion[i], participacion_12m = 100 * rk12$participacion[i]
  )
  d$cambio_pb <- round(100 * (d$participacion - d$participacion_12m))
  pct <- function(dec = 2, signo = FALSE) function(v) porcentaje(v / 100, dec, signo)
  tabla <- reactable::reactable(
    d, pagination = FALSE, compact = TRUE, highlight = TRUE, borderless = TRUE,
    defaultColDef = reactable::colDef(headerClass = "tabla-encabezado", sortNALast = TRUE, align = "right"),
    columns = list(
      posicion = reactable::colDef(name = "#", width = 50, align = "center"),
      banco = reactable::colDef(name = "Banco", minWidth = 150, align = "left"),
      monto_mm = reactable::colDef(name = "Monto (MM$)", minWidth = 130,
                                   cell = function(v) monto_mm(v * 1e6)),
      participacion = reactable::colDef(name = "Particip.", cell = pct()),
      var_m1 = reactable::colDef(name = "Var. m/m", cell = pct(1, TRUE), style = function(v) celda_signo(v)),
      var_12m = reactable::colDef(name = "Var. 12m", cell = pct(1, TRUE), style = function(v) celda_signo(v)),
      posicion_12m = reactable::colDef(name = "Puesto hace 12m", align = "center", na = "—"),
      participacion_12m = reactable::colDef(name = "Particip. hace 12m", cell = pct()),
      cambio_pb = reactable::colDef(name = "Cambio (pb)", style = function(v) celda_signo(v),
                                    cell = function(v) if (is.na(v)) "N/A" else
                                      paste0(if (v > 0) "+" else "", numero_cl(v)))
    )
  )
  csv <- stats::setNames(d, c("Puesto", "Banco", "Monto (MM$)", "Participación (%)", "Var. mensual (%)",
                              "Var. 12 meses (%)", "Puesto hace 12 meses", "Participación hace 12 meses (%)",
                              "Cambio de participación (pb)"))
  list(tabla = tabla, csv = csv)
}

# Historia mes a mes: participación y puesto de cada banco de la escalera.
tabla_historia <- function(serie, pt, nombre_banco) {
  cods <- unique(serie$cod_ifi)
  periodos <- sort(unique(serie$periodo), decreasing = TRUE)
  d <- data.frame(periodo = periodos)
  csv <- data.frame(Periodo = periodos)
  for (cod in cods) {
    s <- serie[serie$cod_ifi == cod, ]
    p <- pt$puestos[pt$puestos$cod_ifi == cod, ]
    part <- s$participacion[match(periodos, s$periodo)]
    pos <- p$posicion[match(periodos, p$periodo)]
    d[[cod]] <- ifelse(is.na(part), "—", paste0(porcentaje(part, 2), " (", pos, "°)"))
    csv[[paste(nombre_banco(cod), "participación (%)")]] <- 100 * part
    csv[[paste(nombre_banco(cod), "puesto")]] <- pos
  }
  columnas <- c(list(periodo = reactable::colDef(name = "Período", minWidth = 90,
                                                 cell = function(v) mes_corto(v))),
                stats::setNames(lapply(cods, function(cod) reactable::colDef(name = nombre_banco(cod),
                                                                            align = "right", minWidth = 120)),
                                cods))
  tabla <- reactable::reactable(d, pagination = FALSE, compact = TRUE, highlight = TRUE, borderless = TRUE,
                                defaultColDef = reactable::colDef(headerClass = "tabla-encabezado"),
                                columns = columnas)
  csv$Periodo <- vapply(csv$Periodo, mes_corto, "")
  list(tabla = tabla, csv = csv)
}

# Composición por moneda de todos los bancos (montos y % sobre la selección).
tabla_composicion <- function(comp, rk, nombre_banco) {
  m <- attr(comp, "monedas")
  comp <- comp[match(rk$cod_ifi, comp$cod_ifi), ]
  d <- data.frame(posicion = rk$posicion, banco = nombre_banco(rk$cod_ifi))
  csv <- data.frame(Puesto = rk$posicion, Banco = d$banco)
  for (k in m) {
    d[[k]] <- ifelse(comp$mixtos, monto_mm(comp[[k]]),
                     paste0(monto_mm(comp[[k]]), " · ", porcentaje(comp[[paste0("p_", k)]], 1)))
    csv[[paste(etiquetas_moneda[[k]], "(MM$)")]] <- comp[[k]] / 1e6
    csv[[paste(etiquetas_moneda[[k]], "(%)")]] <- 100 * comp[[paste0("p_", k)]]
  }
  columnas <- c(
    list(posicion = reactable::colDef(name = "#", width = 50, align = "center"),
         banco = reactable::colDef(name = "Banco", minWidth = 150)),
    stats::setNames(lapply(m, function(k) reactable::colDef(name = paste(etiquetas_moneda[[k]], "(MM$ · %)"),
                                                            align = "right", minWidth = 150)), m)
  )
  tabla <- reactable::reactable(d, pagination = FALSE, compact = TRUE, highlight = TRUE, borderless = TRUE,
                                defaultColDef = reactable::colDef(headerClass = "tabla-encabezado"),
                                columns = columnas)
  list(tabla = tabla, csv = csv)
}

# CSV para Excel en Chile: separador ";", decimal "," y marca UTF-8 para que se vean los acentos.
escribir_csv <- function(d, archivo) {
  d[] <- lapply(d, function(x) if (is.numeric(x)) round(x, 2) else x)
  lineas <- utils::capture.output(utils::write.csv2(d, row.names = FALSE, na = ""))
  con <- file(archivo, open = "w", encoding = "UTF-8")
  on.exit(close(con))
  writeLines(c(paste0("﻿", lineas[1]), lineas[-1]), con)
}

# varias cuentas de un banco ---------------------------------------------------

# Colores de cuentas: primeros seis de la paleta categórica de referencia de la guía de visualización.
colores_cuentas <- c("#2a78d6", "#eb6834", "#1baf7a", "#eda100", "#e87ba4", "#008300")

medidas_cuentas <- c(monto = "Monto", indice = "Índice (primer mes = 100)", participacion = "Participación")

# Una línea por cuenta en la medida elegida; desde la cuarta cuenta, trazo punteado como apoyo al color.
grafico_cuentas <- function(sc, medida, nombre_cuenta) {
  cuentas <- unique(sc$cuenta)
  pequenos <- max(abs(sc$monto), na.rm = TRUE) < 1e9
  ajuste <- switch(medida,
    monto = list(divisor = if (pequenos) 1e6 else 1e9, eje = if (pequenos) "Millones de $" else
      "Miles de millones de $", formato = "{value:,.0f}", dec = 0,
      sufijo = if (pequenos) " millones" else " mil millones"),
    indice = list(divisor = 1, eje = "Índice (primer mes = 100)", formato = "{value:,.0f}", dec = 1,
                  sufijo = ""),
    participacion = list(divisor = 0.01, eje = "Participación sobre el sistema", formato = "{value:,.1f} %",
                         dec = 2, sufijo = " %")
  )
  hc <- base_tiempo() |>
    highcharter::hc_yAxis(title = list(text = ajuste$eje), labels = list(format = ajuste$formato)) |>
    highcharter::hc_tooltip(valueDecimals = ajuste$dec, valueSuffix = ajuste$sufijo)
  for (i in seq_along(cuentas)) {
    d <- sc[sc$cuenta == cuentas[i], ]
    hc <- hc |> highcharter::hc_add_series(
      type = "line", name = nombre_cuenta(cuentas[i]), color = colores_cuentas[i], lineWidth = 3,
      dashStyle = if (i > 3) "Dash" else "Solid",
      data = puntos_tiempo(d$fecha, d[[medida]] / ajuste$divisor)
    )
  }
  hc
}

# Tabla mes a mes: una columna por cuenta en la medida elegida.
tabla_cuentas <- function(sc, medida, nombre_cuenta) {
  cuentas <- unique(sc$cuenta)
  periodos <- sort(unique(sc$periodo), decreasing = TRUE)
  d <- data.frame(periodo = periodos)
  csv <- data.frame(Periodo = vapply(periodos, mes_corto, ""))
  formato <- switch(medida,
    monto = function(v) monto_mm(v),
    indice = function(v) ifelse(is.na(v), "N/A", numero_cl(v, 1)),
    participacion = function(v) porcentaje(v, 2)
  )
  unidad <- c(monto = "MM$", indice = "índice", participacion = "%")[[medida]]
  for (cta in cuentas) {
    v <- sc[[medida]][sc$cuenta == cta][match(periodos, sc$periodo[sc$cuenta == cta])]
    d[[cta]] <- formato(v)
    csv[[paste0(nombre_cuenta(cta), " (", unidad, ")")]] <- switch(medida, monto = v / 1e6,
                                                                   participacion = 100 * v, v)
  }
  columnas <- c(list(periodo = reactable::colDef(name = "Período", minWidth = 90,
                                                 cell = function(v) mes_corto(v))),
                stats::setNames(lapply(cuentas, function(cta) {
                  reactable::colDef(name = paste0(nombre_cuenta(cta), " (", unidad, ")"), align = "right",
                                    minWidth = 150)
                }), cuentas))
  tabla <- reactable::reactable(d, pagination = FALSE, compact = TRUE, highlight = TRUE, borderless = TRUE,
                                defaultColDef = reactable::colDef(headerClass = "tabla-encabezado"),
                                columns = columnas)
  list(tabla = tabla, csv = csv)
}
