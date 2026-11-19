# Componentes de interfaz construidos en el server: encabezado, escalera de competencia e indicadores.

icono_variacion <- function(v) {
  if (is.na(v) || v == 0) return(list(icono = "dash-lg", color = colores[["texto_suave"]]))
  if (v > 0) list(icono = "arrow-up-right", color = colores[["positivo"]])
  else list(icono = "arrow-down-right", color = colores[["negativo"]])
}

texto_variacion <- function(v, sufijo = " m/m") {
  iv <- icono_variacion(v)
  htmltools::span(
    class = "vb-variacion", style = paste0("color:", iv$color),
    bsicons::bs_icon(iv$icono), porcentaje(v, 1, signo = TRUE), sufijo
  )
}

titulo_caja <- function(titulo) {
  htmltools::span(class = "vb-titulo", titulo)
}

chip <- function(icono, texto) {
  htmltools::span(class = "chip", bsicons::bs_icon(icono), texto)
}

# Línea de participación de 12 meses como SVG en línea (sin dependencias). Ignora meses sin dato.
# Con etiquetas (una por mes), lleva en data-* la posición (en % del ancho y alto) y el texto de cada mes,
# para el cursor de www/escalera.js; los meses sin dato quedan vacíos. El punto final es un span, así no
# se deforma al estirar el SVG.
sparkline_svg <- function(valores, color, etiquetas = NULL, ancho = 160, alto = 30) {
  ok <- which(!is.na(valores))
  if (length(ok) < 2) return(htmltools::span(class = "spark-vacia", "sin serie"))
  v <- valores[ok]
  rango <- range(v)
  if (diff(rango) == 0) rango <- rango + c(-1, 1) * abs(rango[1]) * 0.01 + c(-1e-9, 1e-9)
  x_mes <- 3 + (seq_along(valores) - 1) * (ancho - 6) / (length(valores) - 1)
  y_mes <- alto - 3 - (valores - rango[1]) * (alto - 6) / diff(rango)
  x <- x_mes[ok]
  y <- y_mes[ok]
  puntos <- paste(sprintf("%.1f,%.1f", x, y), collapse = " ")
  area <- paste(sprintf("%.1f,%d", x[1], alto), puntos, sprintf("%.1f,%d", x[length(x)], alto))
  svg <- htmltools::HTML(sprintf(paste0(
    '<svg class="spark" viewBox="0 0 %d %d" preserveAspectRatio="none" aria-hidden="true">',
    '<polygon points="%s" fill="%s" fill-opacity="0.13"></polygon>',
    '<polyline points="%s" fill="none" stroke="%s" stroke-width="2" vector-effect="non-scaling-stroke"',
    ' stroke-linejoin="round"></polyline></svg>'),
    ancho, alto, area, color, puntos, color))
  pct <- function(p, total) ifelse(is.na(p), "", sprintf("%.2f", 100 * p / total))
  ultimo <- ok[length(ok)]
  punto <- htmltools::span(class = "spark-punto", style = sprintf(
    "left:%s%%;top:%s%%;background:%s", pct(x_mes[ultimo], ancho), pct(y_mes[ultimo], alto), color))
  if (is.null(etiquetas)) return(htmltools::span(class = "spark-wrap", svg, punto))
  textos <- paste(etiquetas, "·", ifelse(is.na(valores), "sin dato", porcentaje(valores, 2)))
  htmltools::span(
    class = "spark-wrap",
    `data-x` = paste(pct(x_mes, ancho), collapse = ","),
    `data-y` = paste(pct(y_mes, alto), collapse = ","),
    `data-t` = paste(textos, collapse = "|"),
    `data-ultimo` = ultimo - 1,
    svg, punto
  )
}

# Brecha entre dos filas, redactada desde el punto de vista del banco analizado cuando lo toca.
fila_brecha <- function(b, foco, etiqueta_12m) {
  clave <- b$abajo == foco || b$arriba == foco
  pb <- puntos_base(b$pp)
  texto <- if (b$abajo == foco) {
    htmltools::tagList("▲ te faltan ", htmltools::strong(monto_corto(b$monto)), " · ", pb)
  } else if (b$arriba == foco) {
    htmltools::tagList("▼ le llevas ", htmltools::strong(monto_corto(b$monto)), " · ", pb)
  } else {
    paste0(monto_corto(b$monto), " · ", pb)
  }
  # Color del estado: bueno o malo solo cuando la brecha toca al foco.
  estado <- b$tendencia
  clase <- "igual"
  if (clave && estado %in% c("se acorta", "se amplía", "cambio de orden")) {
    mejora <- (b$abajo == foco && estado %in% c("se acorta", "cambio de orden")) ||
      (b$arriba == foco && estado == "se amplía")
    clase <- if (mejora) "bien" else "mal"
  }
  if (estado == "cambio de orden" && clave) {
    estado <- if (b$arriba == foco) "lo pasaste en 12 meses" else "te pasó en 12 meses"
  }
  antes <- if (is.na(b$pp_12m)) NULL else
    htmltools::span(class = "brecha-antes", paste0(etiqueta_12m, ": ", puntos_base(b$pp_12m, signo = TRUE)))
  htmltools::div(class = paste("brecha", if (clave) "clave"),
                 htmltools::span(class = "brecha-texto", texto), antes,
                 htmltools::span(class = paste("estado", clase), estado))
}

# Escalera: todo el ranking en una lista con scroll. El banco y sus vecinos directos (e$filas) van
# destacados, con las brechas entre ellos;
# el resto (e$todos), en filas compactas y pálidas. Clic en cualquier banco que no sea el analizado lo
# selecciona (www/escalera.js). e: resultado de escalera() con columna nombre en filas y todos.
escalera_ui <- function(e, foco) {
  f <- e$todos
  competidores <- e$filas$cod_ifi
  pos_foco <- match(foco, f$cod_ifi)
  etiqueta_12m <- etiqueta_periodo(e$periodo_12m)
  partes <- list()
  for (i in seq_len(nrow(f))) {
    es_foco <- f$cod_ifi[i] == foco
    es_competidor <- f$cod_ifi[i] %in% competidores
    col <- color_banco(f$cod_ifi[i])
    v12 <- f$var_12m[i]
    clase <- if (!es_competidor) "fuera" else
      paste(if (es_foco) "es-foco", "competidor")
    partes[[length(partes) + 1]] <- htmltools::div(
      class = paste("peldano", clase),
      `data-fila` = f$cod_ifi[i],
      # Todos menos el analizado se pueden cliquear para analizarlos.
      `data-cod` = if (!es_foco) f$cod_ifi[i],
      tabindex = if (!es_foco) "0", role = if (!es_foco) "button",
      title = if (!es_foco) paste("Analizar", f$nombre[i]),
      htmltools::span(class = "pos", paste0(f$posicion[i], "°")),
      htmltools::span(class = "nombre", htmltools::span(class = "punto", style = paste0("background:", col)),
                      htmltools::span(class = "nombre-texto", f$nombre[i])),
      htmltools::span(class = "monto", monto_corto(f$monto[i])),
      htmltools::span(class = "part", porcentaje(f$participacion[i], 2)),
      htmltools::span(class = "sparkcell", sparkline_svg(f$serie[[i]], col, etiqueta_periodo(e$periodos))),
      htmltools::span(class = "var",
                      style = paste0("color:", if (is.na(v12)) colores[["texto_suave"]] else if (v12 >= 0)
                        colores[["positivo"]] else colores[["negativo"]]),
                      porcentaje(v12, 1, signo = TRUE))
    )
    # Brecha solo entre dos competidores consecutivos.
    j <- match(f$cod_ifi[i], competidores)
    if (!is.na(j) && j < length(competidores)) {
      partes[[length(partes) + 1]] <- fila_brecha(e$brechas[j, ], foco, etiqueta_12m)
    }
  }
  htmltools::div(
    class = "escalera",
    htmltools::div(class = "escalera-cabecera", `aria-hidden` = "true",
                   htmltools::span("#"), htmltools::span("Banco"), htmltools::span("Monto"),
                   htmltools::span("Part."), htmltools::span("Últimos 12 meses"),
                   htmltools::span("Var. 12m")),
    # El marco con scroll no aporta alto propio: la tarjeta toma el alto de los indicadores.
    htmltools::div(class = "escalera-marco", htmltools::div(class = "escalera-lista", partes))
  )
}

# Mensaje "escalera_foco" para actualizar la escalera en el navegador al cambiar de banco, sin redibujar
# sus filas (www/escalera.js): orden de las filas (para comprobar que es la misma lista), analizado,
# competidores y el HTML de las brechas entre competidores consecutivos.
escalera_mensaje <- function(e, foco) {
  etiqueta_12m <- etiqueta_periodo(e$periodo_12m)
  list(
    filas = as.list(e$todos$cod_ifi),
    foco = foco,
    competidores = as.list(e$filas$cod_ifi),
    brechas = lapply(seq_len(nrow(e$brechas)), function(j) {
      as.character(fila_brecha(e$brechas[j, ], foco, etiqueta_12m))
    })
  )
}

# Etiqueta de variación con flecha y color según el signo (el signo y la flecha no dependen del color).
chip_variacion <- function(v, sufijo) {
  clase <- if (is.na(v) || v == 0) "igual" else if (v > 0) "sube" else "baja"
  flecha <- switch(clase, sube = "▲", baja = "▼", igual = "=")
  htmltools::span(class = paste("var-chip", clase), flecha, " ", porcentaje(v, 1, signo = TRUE), " ", sufijo)
}

# Etiqueta de cambio de participación: recibe puntos porcentuales y muestra puntos base (pb), con flecha
# y color según el signo. Bajo 0,5 pb se redondea a 0 y va como "igual".
chip_pb <- function(v, sufijo) {
  clase <- if (is.na(v) || abs(v) < 0.005) "igual" else if (v > 0) "sube" else "baja"
  flecha <- switch(clase, sube = "▲", baja = "▼", igual = "=")
  texto <- puntos_base(v, signo = TRUE)
  htmltools::span(class = paste("var-chip", clase), flecha, " ", texto, " ", sufijo)
}

# Indicador Participación del banco: su participación como cifra principal, su cambio en pb en el mes y en
# 12 meses, la distancia en pb a sus vecinos directos, el total del sistema y un gráfico de 24 meses. Avisa
# si la serie tiene un salto brusco (fusiones). participacion_partes() arma cifra, etiqueta y líneas; la
# usan el dibujo inicial y el mensaje del proxy. sb: serie_conjunta() del banco solo.
participacion_partes <- function(sb, ss, e, foco, nombre_banco, nombre_cuenta) {
  p <- 100 * sb$participacion
  n <- length(p)
  pp_m1 <- if (n >= 2) p[n] - p[n - 1] else NA_real_
  pp_12m <- if (n >= 13) p[n] - p[n - 12] else NA_real_
  saltos <- diff(p)
  i_salto <- if (length(saltos) && any(abs(saltos) > 1, na.rm = TRUE)) which.max(abs(saltos)) else NA
  m <- nrow(ss)
  var_sistema <- if (m >= 2) variacion(ss$monto[m], ss$monto[m - 1]) else NA_real_
  part_foco <- e$filas$participacion[e$filas$cod_ifi == foco]
  arriba <- e$brechas[e$brechas$abajo == foco, ]
  abajo <- e$brechas[e$brechas$arriba == foco, ]
  list(
    valor = round(100 * part_foco, 2),
    texto = porcentaje(part_foco, 2),
    etiqueta = htmltools::tagList(
      "Participación de ",
      htmltools::span(class = "ficha-punto", style = paste0("background:", color_banco(foco))),
      nombre_banco(foco), " · ", nombre_cuenta
    ),
    lineas = htmltools::tagList(
      htmltools::div(class = "indicador-chips", chip_pb(pp_m1, "m/m"), chip_pb(pp_12m, "12m")),
      if (nrow(arriba)) {
        htmltools::p(class = "indicador-nota", "▲ ", htmltools::strong(puntos_base(arriba$pp)),
                     " para alcanzar a ", nombre_banco(arriba$arriba))
      },
      if (nrow(abajo)) {
        htmltools::p(class = "indicador-nota", "▼ ", htmltools::strong(puntos_base(abajo$pp)),
                     " sobre ", nombre_banco(abajo$abajo))
      },
      htmltools::p(class = "indicador-nota", "Sistema ", htmltools::strong(monto_corto(ss$monto[m])), " ",
                   chip_variacion(var_sistema, "m/m")),
      htmltools::p(class = "indicador-nota", sprintf("Conjunta de los %d de la escalera ", nrow(e$filas)),
                   htmltools::strong(porcentaje(sum(e$filas$participacion), 2))),
      if (!is.na(i_salto)) {
        htmltools::p(class = "indicador-nota indicador-movimientos",
                     sprintf("salto de %s en %s", puntos_base(saltos[i_salto], signo = TRUE),
                             etiqueta_periodo(sb$periodo[i_salto + 1])))
      }
    )
  )
}

# grafico: el mini gráfico (en la app, highchartOutput("mini_participacion"), que se actualiza por proxy).
caja_participacion <- function(sb, ss, e, foco, nombre_banco, nombre_cuenta,
                               grafico = grafico_mini_participacion(sb, color_banco(foco))) {
  pb <- participacion_partes(sb, ss, e, foco, nombre_banco, nombre_cuenta)
  htmltools::div(
    class = "indicador indicador-participacion",
    htmltools::div(
      class = "indicador-texto",
      htmltools::span(class = "indicador-etiqueta", pb$etiqueta),
      htmltools::div(class = "indicador-valor",
                     htmltools::span(class = "cifra-animada", `data-valor` = pb$valor,
                                     `data-formato` = "porcentaje2", pb$texto)),
      htmltools::div(class = "indicador-lineas", pb$lineas)
    ),
    htmltools::div(class = "indicador-grafico", grafico)
  )
}

# Estado de la tira de posiciones: lo usan el dibujo inicial (tira_puestos) y el mensaje del proxy, para que
# el navegador mueva el punto, la franja de la escalera y el anillo de hace 12 meses sin redibujar.
tira_estado <- function(cp, filas_escalera, foco) {
  n <- cp$n
  esc <- filas_escalera[filas_escalera$posicion <= n, ]
  colores_pos <- rep("", n)
  colores_pos[esc$posicion] <- color_banco(esc$cod_ifi)
  antes <- if (!is.na(cp$puesto_12m) && cp$puesto_12m <= n && cp$puesto_12m != cp$puesto) cp$puesto_12m else
    NA_integer_
  list(n = n, foco = cp$puesto, antes = antes, desde = min(esc$posicion), hasta = max(esc$posicion),
       colores = as.list(colores_pos), marcas = as.list(sort(unique(c(1, n, esc$posicion)))),
       color = color_banco(foco))
}

# Tira de posiciones a lo ancho: un punto por puesto (1° a la izquierda), la escalera sombreada con cada
# banco en su color y su número, el analizado más grande y el puesto de hace 12 meses como anillo. Todos
# los puestos tienen su punto y su número (oculto si no corresponde) para que el proxy solo cambie
# atributos (www/escalera.js). x(p) = 12 + (p - 1) * 296 / (n - 1) en un viewBox de 320 de ancho.
tira_puestos <- function(cp, filas_escalera, foco, nombre_banco, todos = NULL) {
  s <- tira_estado(cp, filas_escalera, foco)
  n <- s$n
  x <- function(p) 12 + (p - 1) * 296 / max(1, n - 1)
  col <- s$color
  banda <- sprintf(paste0('<rect class="tira-banda" x="%.1f" y="11" width="%.1f" height="22" rx="11" ',
                          'fill="#EEF1F4"></rect>'), x(s$desde) - 10, x(s$hasta) - x(s$desde) + 20)
  puntos <- vapply(seq_len(n), function(p) {
    c_p <- s$colores[[p]]
    sprintf('<circle class="tira-dot" data-pos="%d" cx="%.1f" cy="22" r="%s" style="fill:%s"></circle>',
            p, x(p), if (nzchar(c_p)) "4.6" else "2.6", if (nzchar(c_p)) c_p else "#C3CBD5")
  }, "")
  hay_antes <- !is.na(s$antes)
  pos_antes <- if (hay_antes) s$antes else s$foco
  antes <- sprintf(paste0('<circle class="tira-antes" cx="%.1f" cy="22" r="7.5" fill="none" ',
                          'style="stroke:%s;opacity:%s" stroke-width="1.8"></circle>'),
                   x(pos_antes), col, if (hay_antes) 1 else 0)
  flecha <- sprintf(paste0('<path class="tira-flecha" d="M %.1f 11 Q %.1f -2 %.1f 11" fill="none" ',
                           'style="stroke:%s;opacity:%s" stroke-width="1.5" ',
                           'marker-end="url(#punta)"></path>'),
                    x(pos_antes), (x(pos_antes) + x(s$foco)) / 2, x(s$foco), col, if (hay_antes) 1 else 0)
  actual <- sprintf(paste0('<circle class="tira-actual" cx="%.1f" cy="22" r="8.5" style="fill:%s" ',
                           'stroke="#FFFFFF" stroke-width="2.5"></circle>'), x(s$foco), col)
  marcas <- unlist(s$marcas)
  etiquetas <- vapply(seq_len(n), function(p) {
    sprintf(paste0('<text class="tira-num%s" data-pos="%d" x="%.1f" y="49" font-size="10.5" ',
                   'text-anchor="middle" style="opacity:%s">%d</text>'),
            if (p == s$foco) " es-foco" else "", p, x(p), if (p %in% marcas) 1 else 0, p)
  }, "")
  defs <- sprintf(paste0('<defs><marker id="punta" viewBox="0 0 6 6" refX="5" refY="3" markerWidth="6" ',
                         'markerHeight="6" orient="auto"><path class="tira-punta" d="M0,0 L6,3 L0,6 z" ',
                         'style="fill:%s"></path></marker></defs>'), col)
  # Áreas invisibles sobre cada banco: al pasar el puntero muestran puesto y nombre, y un clic (salvo en el
  # analizado) selecciona ese banco. data-banco y data-base guardan banco y texto para el proxy.
  otros <- if (is.null(todos)) todos else todos[todos$posicion <= n, ]
  clic <- vapply(seq_len(NROW(otros)), function(i) {
    cod <- otros$cod_ifi[i]
    base <- paste0(otros$posicion[i], "° ", nombre_banco(cod))
    texto <- paste0(base, if (cod == foco) " · analizado")
    sprintf(paste0('<circle class="tira-hit%s" data-pos="%d" data-banco="%s"%s data-base="%s" ',
                   'data-nombre="%s" cx="%.1f" cy="22" r="9" fill="transparent"></circle>'),
            if (cod == foco) "" else " tira-clic", otros$posicion[i], cod,
            if (cod == foco) "" else sprintf(' data-cod="%s"', cod),
            htmltools::htmlEscape(base, attribute = TRUE), htmltools::htmlEscape(texto, attribute = TRUE),
            x(otros$posicion[i]))
  }, "")
  htmltools::HTML(paste0('<svg class="tira-puestos" viewBox="0 0 320 54" role="img" data-n="', n,
                         '" aria-label="Puesto ', cp$puesto, ' de ', n, '">', defs, banda,
                         paste(puntos, collapse = ""), antes, flecha, actual,
                         paste(etiquetas, collapse = ""), paste(clic, collapse = ""), '</svg>'))
}

# Partes del indicador Puesto que cambian con el banco: etiqueta (con su color) y chip de cambio en 12
# meses. Las entradas o salidas de bancos (cp$salieron, cp$entraron) no se muestran; las recibe el chat.
puesto_partes <- function(cp, foco, nombre_banco, nombre_cuenta) {
  cambio <- if (is.na(cp$puesto_12m)) {
    htmltools::span(class = "var-chip igual", "sin dato hace 12 meses")
  } else {
    d <- cp$puesto_12m - cp$puesto
    clase <- if (d > 0) "sube" else if (d < 0) "baja" else "igual"
    texto <- if (d == 0) "= mismo puesto" else
      sprintf("%s %d %s", if (d > 0) "▲" else "▼", abs(d), if (abs(d) == 1) "puesto" else "puestos")
    htmltools::span(class = paste("var-chip", clase), texto)
  }
  list(
    etiqueta = htmltools::tagList(
      "Puesto de ", htmltools::span(class = "ficha-punto", style = paste0("background:", color_banco(foco))),
      nombre_banco(foco), " · ", nombre_cuenta
    ),
    chips = htmltools::tagList(cambio, htmltools::span(class = "indicador-nota-inline", "en 12 meses"))
  )
}

# Indicador Puesto como ficha: etiqueta con el color del banco y la cuenta, puesto y cambio en 12 meses, y
# la tira de posiciones.
caja_puesto <- function(cp, e, foco, nombre_banco, nombre_cuenta) {
  pp <- puesto_partes(cp, foco, nombre_banco, nombre_cuenta)
  htmltools::div(
    class = "indicador indicador-puesto ficha-puesto",
    htmltools::span(class = "indicador-etiqueta", pp$etiqueta),
    htmltools::div(
      class = "ficha-principal",
      htmltools::div(class = "indicador-valor",
                     htmltools::span(class = "cifra-animada", `data-valor` = cp$puesto,
                                     `data-formato` = "puesto", sprintf("%d°", cp$puesto)),
                     htmltools::span(class = "indicador-de", sprintf(" de %d", cp$n))),
      htmltools::div(class = "indicador-chips", pp$chips)
    ),
    htmltools::div(class = "ficha-tira", tira_puestos(cp, e$filas, foco, nombre_banco, e$todos))
  )
}

# Mensaje "indicadores_foco" para actualizar los indicadores en el navegador al cambiar de banco: cifras
# (se animan contando), textos armados en R (se reemplazan con un fundido) y estado de la tira.
indicadores_mensaje <- function(sb, ss, e, cp, foco, nombre_banco, nombre_cuenta) {
  pc <- participacion_partes(sb, ss, e, foco, nombre_banco, nombre_cuenta)
  pp <- puesto_partes(cp, foco, nombre_banco, nombre_cuenta)
  list(
    participacion = list(valor = pc$valor, etiqueta = as.character(pc$etiqueta),
                         lineas = as.character(pc$lineas)),
    puesto = list(valor = cp$puesto, n = cp$n, etiqueta = as.character(pp$etiqueta),
                  chips = as.character(pp$chips), tira = tira_estado(cp, e$filas, foco))
  )
}
