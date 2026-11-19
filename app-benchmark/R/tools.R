# Tools del chat. crear_tools() recibe el estado (reactiveVal) y el contexto de datos y devuelve las
# funciones; definir_tools() las envuelve para ellmer. Las tools leen con isolate(), escriben en los
# reactiveVal y devuelven JSON con cifras ya formateadas (las mismas que muestra el dashboard).

# Datos y traducciones nombre <-> código que comparten la app, las tools y las pruebas.
crear_contexto <- function(balance, fichas, cuentas) {
  nombre_banco <- function(cod) fichas$nombre_corto[match(cod, fichas$cod_ifi)]
  codigos <- setdiff(unique(balance$cod_ifi), "999")
  codigos <- codigos[order(nombre_banco(codigos))]
  list(
    balance = balance,
    cuentas = cuentas,
    periodos = sort(unique(balance$periodo), decreasing = TRUE),
    bancos = stats::setNames(codigos, nombre_banco(codigos)),
    nombre_banco = nombre_banco,
    nombre_cuenta = function(cod) cuentas$nombre[match(cod, cuentas$cuenta)],
    clasificacion = function(cod) {
      x <- fichas$clasificacion[match(cod, fichas$cod_ifi)]
      ifelse(is.na(x) | x == "", NA_character_, x)
    }
  )
}

a_json <- function(x) jsonlite::toJSON(x, auto_unbox = TRUE, null = "null", na = "null", dataframe = "rows")

ficha_banco <- function(fila, n_bancos) {
  list(
    banco = fila$nombre,
    posicion = sprintf("%d de %d", fila$posicion, n_bancos),
    monto = monto_corto(fila$monto),
    participacion = porcentaje(fila$participacion, 2),
    var_mensual = porcentaje(fila$var_m1, 1, signo = TRUE),
    var_12_meses = porcentaje(fila$var_12m, 1, signo = TRUE)
  )
}

etiqueta_comparacion <- function(ctx, comparacion) {
  modo <- names(modos_comparacion)[modos_comparacion == comparacion$modo]
  if (comparacion$modo == "bancos" && length(comparacion$bancos)) {
    modo <- paste0(modo, ": ", paste(ctx$nombre_banco(comparacion$bancos), collapse = ", "))
  }
  modo
}

# Resumen del análisis visible: posición del banco, vecinos, líder, sistema y ranking completo.
resumen_para_chat <- function(ctx, foco, cuenta, periodo, monedas, comparacion) {
  rk <- calcular_ranking(ctx$balance, cuenta, periodo, monedas, foco)
  rk$nombre <- ctx$nombre_banco(rk$cod_ifi)
  r <- resumen_posicion(rk, foco)
  base <- list(
    banco = ctx$nombre_banco(foco),
    cuenta = ctx$nombre_cuenta(cuenta),
    periodo = etiqueta_periodo(periodo),
    monedas = etiqueta_monedas(monedas),
    comparacion = etiqueta_comparacion(ctx, comparacion),
    fuente = "CMF, Balance mensual de bancos"
  )
  if (!r$con_dato) {
    ultimo <- ultimo_periodo_banco(ctx$balance, cuenta, foco)
    return(c(base, list(
      sin_datos = TRUE,
      mensaje = paste0(base$banco, " no informa ", base$cuenta, " en ", base$periodo, "."),
      ultimo_periodo_disponible = if (is.na(ultimo)) NULL else etiqueta_periodo(ultimo),
      ultimo_periodo_codigo = if (is.na(ultimo)) NULL else ultimo
    )))
  }
  ranking <- data.frame(
    posicion = rk$posicion,
    banco = rk$nombre,
    monto = vapply(rk$monto, monto_corto, ""),
    participacion = porcentaje(rk$participacion, 2),
    var_mensual = porcentaje(rk$var_m1, 1, signo = TRUE)
  )
  c(base, list(
    analizado = ficha_banco(r$foco, r$n_bancos),
    vecino_superior = if (is.null(r$superior)) "No tiene: es el líder"
                      else ficha_banco(r$superior, r$n_bancos),
    vecino_inferior = if (is.null(r$inferior)) "No tiene: es el último"
                      else ficha_banco(r$inferior, r$n_bancos),
    lider = ficha_banco(r$lider, r$n_bancos),
    escalera = escalera_para_chat(ctx, foco, cuenta, periodo, monedas),
    puesto_hace_12_meses = puesto_para_chat(ctx, foco, cuenta, periodo, monedas),
    composicion_del_analizado = composicion_para_chat(ctx, foco, cuenta, periodo, monedas),
    total_sistema = monto_corto(r$total_sistema),
    var_mensual_sistema = porcentaje(r$var_m1_sistema, 1, signo = TRUE),
    ranking = ranking
  ))
}

# Escalera como la ve el usuario: bancos y brechas entre puestos consecutivos con su tendencia en 12 meses.
escalera_para_chat <- function(ctx, foco, cuenta, periodo, monedas) {
  e <- escalera(ctx$balance, cuenta, periodo, monedas, foco)
  if (is.null(e)) return(NULL)
  list(
    bancos = paste0(e$filas$posicion, "° ", ctx$nombre_banco(e$filas$cod_ifi)),
    participacion_conjunta = porcentaje(sum(e$filas$participacion), 1),
    brechas = lapply(seq_len(nrow(e$brechas)), function(i) {
      b <- e$brechas[i, ]
      list(
        arriba = ctx$nombre_banco(b$arriba),
        abajo = ctx$nombre_banco(b$abajo),
        monto = monto_corto(b$monto),
        participacion = puntos_base(b$pp),
        participacion_hace_12_meses = if (is.na(b$pp_12m)) NA_character_ else puntos_base(b$pp_12m),
        tendencia = b$tendencia
      )
    }),
    nota = paste("Brecha = el de arriba menos el de abajo. 'cambio de orden' significa que hace 12 meses",
                 "el de abajo estaba por encima.")
  )
}

puesto_para_chat <- function(ctx, foco, cuenta, periodo, monedas) {
  cp <- cambio_puesto(ctx$balance, cuenta, periodo, monedas, foco)
  list(
    hoy = sprintf("%d° de %d", cp$puesto, cp$n),
    hace_12_meses = if (is.na(cp$puesto_12m)) "sin dato" else
      sprintf("%d° de %d en %s", cp$puesto_12m, cp$n_12m, etiqueta_periodo(cp$periodo_12m)),
    salieron = if (nrow(cp$salieron)) sprintf("%s (estaba %d°)", ctx$nombre_banco(cp$salieron$cod_ifi),
                                              cp$salieron$posicion) else NULL,
    entraron = if (length(cp$entraron)) ctx$nombre_banco(cp$entraron) else NULL
  )
}

composicion_para_chat <- function(ctx, foco, cuenta, periodo, monedas) {
  co <- composicion(ctx$balance, cuenta, periodo, monedas)
  f <- co[co$cod_ifi == foco, ]
  if (!nrow(f)) return(NULL)
  partes <- lapply(attr(co, "monedas"), function(k) list(
    moneda = etiquetas_moneda[[k]], monto = monto_corto(f[[k]]),
    porcentaje = if (f$mixtos) NULL else porcentaje(f[[paste0("p_", k)]], 1)
  ))
  list(partes = partes, signos_mixtos = f$mixtos,
       nota = "Composición del monto en las monedas elegidas; los porcentajes son sobre esa selección.")
}

# Evolución en la ventana de 24 meses y brechas con el banco analizado, según el modo.
resumen_comparacion <- function(ctx, foco, cuenta, periodo, monedas, comparacion) {
  s <- series_comparacion(ctx$balance, cuenta, periodo, monedas, foco, comparacion$modo,
                          comparacion$bancos)
  integrantes <- attr(s, "integrantes")
  integrantes <- integrantes[integrantes$rol != "resto", ]
  if (!nrow(s) || !foco %in% integrantes$cod_ifi) {
    return(list(modo = comparacion$modo, mensaje = "Sin datos del banco analizado para comparar."))
  }

  evolucion <- lapply(seq_len(nrow(integrantes)), function(i) {
    d <- s[s$cod_ifi == integrantes$cod_ifi[i], ]
    d <- d[order(d$periodo), ]
    ini <- d[1, ]
    fin <- d[nrow(d), ]
    out <- list(
      banco = ctx$nombre_banco(integrantes$cod_ifi[i]),
      rol = etiquetas_rol[[integrantes$rol[i]]],
      desde = etiqueta_periodo(ini$periodo),
      hasta = etiqueta_periodo(fin$periodo),
      monto_inicio = monto_corto(ini$monto),
      monto_final = monto_corto(fin$monto),
      var_acumulada = porcentaje(variacion(fin$monto, ini$monto), 1, signo = TRUE)
    )
    if (integrantes$rol[i] != "sistema") {
      out$participacion_inicio <- porcentaje(ini$participacion, 2)
      out$participacion_final <- porcentaje(fin$participacion, 2)
    }
    out
  })

  # Brechas en los períodos comunes: otro menos analizado (monto y puntos de participación).
  f <- s[s$cod_ifi == foco, ]
  brechas <- lapply(setdiff(integrantes$cod_ifi, foco), function(cod) {
    o <- s[s$cod_ifi == cod, ]
    comunes <- sort(intersect(o$periodo, f$periodo))
    p <- comunes[c(1, length(comunes))]
    vo <- o[match(p, o$periodo), ]
    vf <- f[match(p, f$periodo), ]
    nombre <- ctx$nombre_banco(cod)
    if (cod == "999") {
      return(list(
        con = nombre,
        crecimiento_banco = porcentaje(variacion(vf$monto[2], vf$monto[1]), 1, signo = TRUE),
        crecimiento_sistema = porcentaje(variacion(vo$monto[2], vo$monto[1]), 1, signo = TRUE),
        participacion_inicio = porcentaje(vf$participacion[1], 2),
        participacion_final = porcentaje(vf$participacion[2], 2)
      ))
    }
    list(
      con = nombre,
      desde = etiqueta_periodo(p[1]),
      hasta = etiqueta_periodo(p[2]),
      monto_otro_menos_analizado_inicio = monto_corto(vo$monto[1] - vf$monto[1]),
      monto_otro_menos_analizado_final = monto_corto(vo$monto[2] - vf$monto[2]),
      participacion_otro_menos_analizado_inicio =
        puntos_base(100 * (vo$participacion[1] - vf$participacion[1])),
      participacion_otro_menos_analizado_final =
        puntos_base(100 * (vo$participacion[2] - vf$participacion[2]))
    )
  })

  list(modo = etiqueta_comparacion(ctx, comparacion), evolucion = evolucion, brechas = brechas)
}

# estado: lista de reactiveVal (banco_foco, cuenta, periodo, monedas, comparacion).
# al_cambiar: función sin argumentos que sincroniza los filtros (la pone el server).
# abrir_ventana: función que muestra una ventana emergente (la pone el server; en pruebas, un registro).
# con: conexión DuckDB de crear_base_sql() para consultar_datos.
crear_tools <- function(estado, ctx, al_cambiar = function() invisible(),
                        abrir_ventana = function(titulo, contenido, csv = NULL, nota = NULL) invisible(),
                        con = NULL) {
  leer <- function() isolate(list(
    foco = estado$banco_foco(), cuenta = estado$cuenta(), periodo = estado$periodo(),
    monedas = estado$monedas(), comparacion = estado$comparacion()
  ))
  resumen_actual <- function() {
    e <- leer()
    resumen_para_chat(ctx, e$foco, e$cuenta, e$periodo, e$monedas, e$comparacion)
  }
  codigo_banco <- function(nombre) {
    cod <- unname(ctx$bancos[nombre])
    if (anyNA(cod)) stop("No encontré el banco: ", paste(nombre[is.na(cod)], collapse = ", "),
                         ". Usa listar_opciones().")
    cod
  }

  listar_opciones <- function() {
    a_json(list(
      bancos = names(ctx$bancos),
      cuentas = data.frame(nombre = ctx$cuentas$nombre, grupo = ctx$cuentas$grupo,
                           codigo = ctx$cuentas$cuenta),
      periodo_primero = list(codigo = min(ctx$periodos), etiqueta = etiqueta_periodo(min(ctx$periodos))),
      periodo_ultimo = list(codigo = max(ctx$periodos), etiqueta = etiqueta_periodo(max(ctx$periodos))),
      monedas = unname(etiquetas_moneda),
      nota_monedas = "Total = las cuatro monedas. Sin moneda extranjera = las otras tres.",
      modos_comparacion = unname(modos_comparacion)
    ))
  }

  ver_analisis <- function() a_json(resumen_actual())

  seleccionar_analisis <- function(banco = NULL, puesto = NULL, cuenta = NULL, periodo = NULL,
                                   monedas = NULL) {
    if (is.null(banco) && is.null(puesto) && is.null(cuenta) && is.null(periodo) && is.null(monedas)) {
      stop("Indica al menos uno: banco, puesto, cuenta, periodo o monedas.")
    }
    if (!is.null(banco) && !is.null(puesto)) stop("Indica banco o puesto, no ambos.")
    # Validar todo antes de escribir, para no dejar el estado a medias.
    cod_banco <- if (!is.null(banco)) codigo_banco(banco)
    cod_cuenta <- if (!is.null(cuenta)) ctx$cuentas$cuenta[match(cuenta, ctx$cuentas$nombre)]
    if (length(cod_cuenta) && is.na(cod_cuenta)) stop("No encontré la cuenta: ", cuenta, ".")
    if (!is.null(periodo) && !periodo %in% ctx$periodos) stop("Período no disponible: ", periodo, ".")
    cod_monedas <- if (!is.null(monedas)) names(etiquetas_moneda)[match(monedas, etiquetas_moneda)]
    if (!is.null(monedas) && !length(monedas)) stop("Elige al menos una moneda.")
    if (anyNA(cod_monedas)) {
      stop("Moneda no válida: ", paste(monedas[is.na(cod_monedas)], collapse = ", "), ".")
    }
    # Con puesto, el banco sale del ranking de la cuenta, período y monedas que quedarán elegidos.
    if (!is.null(puesto)) {
      puesto <- as.integer(puesto)
      e <- leer()
      rk <- calcular_ranking(ctx$balance, if (is.null(cod_cuenta)) e$cuenta else cod_cuenta,
                             if (is.null(periodo)) e$periodo else periodo,
                             if (is.null(cod_monedas)) e$monedas else cod_monedas)
      if (is.na(puesto) || puesto < 1) stop("El puesto debe ser 1 o más.")
      if (puesto > nrow(rk)) stop("Solo hay ", nrow(rk), " bancos en ese ranking.")
      cod_banco <- rk$cod_ifi[puesto]
    }

    if (!is.null(cod_banco)) {
      estado$banco_foco(cod_banco)
      cmp <- isolate(estado$comparacion())
      estado$comparacion(list(modo = cmp$modo, bancos = setdiff(cmp$bancos, cod_banco)))
    }
    if (!is.null(cod_cuenta)) estado$cuenta(cod_cuenta)
    if (!is.null(periodo)) estado$periodo(periodo)
    if (!is.null(cod_monedas)) estado$monedas(normalizar_monedas(cod_monedas))
    al_cambiar()
    a_json(resumen_actual())
  }

  comparar <- function(modo, bancos = NULL) {
    if (!modo %in% modos_comparacion) stop("Modo no válido: ", modo, ".")
    actual <- leer()
    elegidos <- if (is.null(bancos)) actual$comparacion$bancos else setdiff(codigo_banco(bancos), actual$foco)
    if (modo == "bancos" && (length(elegidos) < 1 || length(elegidos) > 4)) {
      stop("Elige entre 1 y 4 bancos distintos del analizado.")
    }
    estado$comparacion(list(modo = modo, bancos = elegidos))
    al_cambiar()
    e <- leer()
    resumen <- resumen_para_chat(ctx, e$foco, e$cuenta, e$periodo, e$monedas, e$comparacion)
    a_json(c(
      resumen[c("banco", "cuenta", "periodo", "monedas", "fuente")],
      list(analizado = resumen$analizado),
      resumen_comparacion(ctx, e$foco, e$cuenta, e$periodo, e$monedas, e$comparacion)
    ))
  }

  # ventanas emergentes ------------------------------------------------------
  nombre <- ctx$nombre_banco
  contexto_txt <- function(e) paste0(ctx$nombre_cuenta(e$cuenta), " · ", etiqueta_monedas(e$monedas))

  # Códigos de 2 a 6 cuentas a partir de sus nombres.
  codigos_cuentas <- function(cuentas) {
    if (length(cuentas) < 2 || length(cuentas) > 6) stop("Elige de 2 a 6 cuentas.")
    cod <- ctx$cuentas$cuenta[match(cuentas, ctx$cuentas$nombre)]
    if (anyNA(cod)) stop("No encontré la cuenta: ", paste(cuentas[is.na(cod)], collapse = ", "), ".")
    unique(cod)
  }
  validar_medida <- function(medida) {
    if (!medida %in% names(medidas_cuentas)) stop("medida debe ser monto, indice o participacion.")
    medida
  }

  # Gráfico y tabla de varias cuentas de un banco, con el resumen por cuenta para el modelo.
  ventana_cuentas <- function(e, cod, cuentas, medida, meses, titulo, como_tabla) {
    sc <- serie_cuentas(ctx$balance, cod, cuentas, e$periodo, e$monedas, meses)
    if (all(is.na(sc$monto))) stop("Sin datos de ", nombre(cod), " en esas cuentas.")
    nombre_medida <- tolower(medidas_cuentas[[medida]])
    if (is.null(titulo) || !nzchar(titulo)) titulo <- paste0(nombre(cod), ": cuentas en ", nombre_medida)
    rango <- paste(etiqueta_periodo(min(sc$periodo)), "a", etiqueta_periodo(e$periodo))
    nota <- paste0(nombre(cod), " · ", etiqueta_monedas(e$monedas), " · ", rango, ". Fuente: CMF.")
    if (como_tabla) {
      t <- tabla_cuentas(sc, medida, ctx$nombre_cuenta)
      abrir_ventana(titulo, t$tabla, csv = t$csv, nota = nota)
    } else {
      abrir_ventana(titulo, grafico_cuentas(sc, medida, ctx$nombre_cuenta), nota = nota)
    }
    resumen <- lapply(unique(sc$cuenta), function(cta) {
      d <- sc[sc$cuenta == cta & !is.na(sc$monto), ]
      valor <- function(i) switch(medida, monto = monto_corto(d$monto[i]),
                                  indice = numero_cl(d$indice[i], 1),
                                  participacion = porcentaje(d$participacion[i], 2))
      paste0(ctx$nombre_cuenta(cta), ": ", valor(1), " → ", valor(nrow(d)), " (monto ",
             porcentaje(variacion(d$monto[nrow(d)], d$monto[1]), 1, signo = TRUE), ")")
    })
    list(banco = nombre(cod), medida = nombre_medida, periodo = rango, resumen = resumen)
  }

  mostrar_grafico <- function(tipo, bancos = NULL, cuentas = NULL, medida = "monto", meses = 24,
                              titulo = NULL) {
    e <- leer()
    meses <- as.integer(meses)
    if (!tipo %in% c("puestos", "composicion", "crecimiento", "evolucion", "cuentas")) {
      stop("Tipo no válido: ", tipo, ".")
    }
    if (!meses %in% c(12L, 24L, 36L)) stop("meses debe ser 12, 24 o 36.")
    if (length(bancos) > 6) stop("Elige hasta 6 bancos.")
    if (tipo == "cuentas") {
      cods_cta <- codigos_cuentas(cuentas)
      cod <- if (length(bancos)) codigo_banco(bancos[1]) else e$foco
      res <- ventana_cuentas(e, cod, cods_cta, validar_medida(medida), meses, titulo, como_tabla = FALSE)
      return(a_json(c(list(ventana = "abierta (el usuario la ve; tú no)", tipo = tipo), res)))
    }
    cods <- if (length(bancos)) codigo_banco(bancos) else {
      esc <- escalera(ctx$balance, e$cuenta, e$periodo, e$monedas, e$foco)
      if (is.null(esc)) stop("El banco analizado no tiene datos en el período; elige otro período o banco.")
      esc$filas$cod_ifi
    }
    desde <- etiqueta_periodo(desplazar_periodo(e$periodo, -(meses - 1)))
    rango <- paste(desde, "a", etiqueta_periodo(e$periodo))

    if (tipo == "puestos") {
      pt <- puestos_en_el_tiempo(ctx$balance, e$cuenta, e$periodo, e$monedas, cods, meses)
      grafico <- grafico_puestos(pt, e$foco, nombre)
      resumen <- resumen_puestos(pt, e$foco, nombre)
      por_defecto <- "Puestos en el ranking"
    } else if (tipo == "composicion") {
      cod <- if (length(bancos)) cods[1] else e$foco
      ct <- composicion_en_el_tiempo(ctx$balance, e$cuenta, e$periodo, e$monedas, cod, meses)
      if (is.null(ct)) stop("Sin datos de ", nombre(cod), " en la ventana.")
      grafico <- grafico_composicion_tiempo(ct)
      extremo <- function(f) paste(vapply(attr(ct, "monedas"), function(k) {
        valor <- if (f$mixtos) monto_corto(f[[k]]) else porcentaje(f[[paste0("p_", k)]], 1)
        paste(etiquetas_moneda[[k]], valor)
      }, ""), collapse = "; ")
      resumen <- list(banco = nombre(cod), inicio = extremo(ct[1, ]), final = extremo(ct[nrow(ct), ]))
      por_defecto <- paste("Composición por moneda de", nombre(cod))
    } else if (tipo == "crecimiento") {
      cr <- crecimiento_periodo(ctx$balance, e$cuenta, e$periodo, e$monedas, meses)
      grafico <- grafico_crecimiento(cr, e$foco, nombre)
      fila <- function(i) paste0(nombre(cr$cod_ifi[i]), " ", porcentaje(cr$variacion[i], 1, signo = TRUE))
      pos_foco <- match(e$foco, cr$cod_ifi)
      resumen <- list(
        mayores = vapply(seq_len(min(3, nrow(cr))), fila, ""),
        analizado = if (is.na(pos_foco)) "sin dato al inicio" else
          paste0(fila(pos_foco), " (", pos_foco, "° de ", nrow(cr), ")"),
        sin_dato_al_inicio = nombre(attr(cr, "sin_dato_inicio")),
        desde = etiqueta_periodo(attr(cr, "periodo_inicio")),
        para_dashboard = sprintf(paste("Si la pregunta era qué banco creció más, llama ahora a",
                                       "seleccionar_analisis(banco = \"%s\") para dejarlo en el dashboard."),
                                 nombre(cr$cod_ifi[1]))
      )
      rango <- paste(resumen$desde, "a", etiqueta_periodo(e$periodo))
      por_defecto <- "Crecimiento de los bancos"
    } else {
      s <- serie_bancos(ctx$balance, e$cuenta, e$periodo, e$monedas, cods, meses)
      grafico <- grafico_evolucion_bancos(s, e$foco, nombre)
      resumen <- lapply(cods, function(cod) {
        d <- s[s$cod_ifi == cod, ]
        paste0(nombre(cod), ": ", monto_corto(d$monto[1]), " → ", monto_corto(d$monto[nrow(d)]), " (",
               porcentaje(variacion(d$monto[nrow(d)], d$monto[1]), 1, signo = TRUE), ")")
      })
      por_defecto <- "Evolución de bancos"
    }
    titulo <- if (is.null(titulo) || !nzchar(titulo)) por_defecto else titulo
    abrir_ventana(titulo, grafico, nota = paste0(contexto_txt(e), " · ", rango, ". Fuente: CMF."))
    a_json(list(ventana = "abierta (el usuario la ve; tú no)", tipo = tipo, periodo = rango,
                resumen = resumen))
  }

  mostrar_tabla <- function(tipo, banco = NULL, cuentas = NULL, medida = "monto", meses = 24, titulo = NULL) {
    e <- leer()
    meses <- as.integer(meses)
    if (!tipo %in% c("ranking", "historia", "composicion", "cuentas")) stop("Tipo no válido: ", tipo, ".")
    if (!meses %in% c(12L, 24L, 36L)) stop("meses debe ser 12, 24 o 36.")
    if (tipo == "cuentas") {
      cods_cta <- codigos_cuentas(cuentas)
      cod <- if (length(banco)) codigo_banco(banco[1]) else e$foco
      res <- ventana_cuentas(e, cod, cods_cta, validar_medida(medida), meses, titulo, como_tabla = TRUE)
      return(a_json(c(list(ventana = "abierta con botón Descargar CSV (el usuario la ve; tú no)",
                           tipo = tipo), res)))
    }
    rk <- calcular_ranking(ctx$balance, e$cuenta, e$periodo, e$monedas)
    resumen <- NULL
    if (tipo == "ranking") {
      rk12 <- calcular_ranking(ctx$balance, e$cuenta, desplazar_periodo(e$periodo, -12), e$monedas)
      t <- tabla_ranking_12m(rk, rk12, nombre)
      # Quién ganó más participación en 12 meses, para responder sin leer la tabla.
      cambio <- 100 * (rk$participacion - rk12$participacion[match(rk$cod_ifi, rk12$cod_ifi)])
      orden <- order(-cambio, na.last = NA)[seq_len(min(3, sum(!is.na(cambio))))]
      resumen <- list(
        mas_ganaron_participacion =
          paste(nombre(rk$cod_ifi[orden]), puntos_base(cambio[orden], signo = TRUE)),
        para_dashboard = sprintf(paste("Si la pregunta era qué banco ganó más participación, llama ahora a",
                                       "seleccionar_analisis(banco = \"%s\") para dejarlo en el dashboard."),
                                 nombre(rk$cod_ifi[orden[1]]))
      )
      por_defecto <- paste("Ranking ·", etiqueta_periodo(e$periodo))
    } else if (tipo == "historia") {
      esc <- escalera(ctx$balance, e$cuenta, e$periodo, e$monedas, e$foco)
      if (is.null(esc)) stop("El banco analizado no tiene datos en el período.")
      cods <- esc$filas$cod_ifi
      serie <- serie_bancos(ctx$balance, e$cuenta, e$periodo, e$monedas, cods, meses)
      pt <- puestos_en_el_tiempo(ctx$balance, e$cuenta, e$periodo, e$monedas, cods, meses)
      t <- tabla_historia(serie, pt, nombre)
      por_defecto <- paste("Historia de la escalera de", nombre(e$foco))
    } else {
      t <- tabla_composicion(composicion(ctx$balance, e$cuenta, e$periodo, e$monedas), rk, nombre)
      por_defecto <- paste("Composición por moneda ·", etiqueta_periodo(e$periodo))
    }
    titulo <- if (is.null(titulo) || !nzchar(titulo)) por_defecto else titulo
    abrir_ventana(titulo, t$tabla, csv = t$csv, nota = paste0(contexto_txt(e), ". Fuente: CMF."))
    a_json(list(ventana = "abierta con botón Descargar CSV (el usuario la ve; tú no)", tipo = tipo,
                filas = nrow(t$csv), columnas = names(t$csv), resumen = resumen))
  }

  consultar_datos <- function(consulta) {
    if (is.null(con)) stop("La base de consultas no está disponible.")
    resultado <- consultar_sql(con, consulta)
    a_json(list(filas = nrow(resultado), nota = "Montos en millones de pesos (escríbelos como MM$).",
                datos = resultado))
  }

  list(listar_opciones = listar_opciones, ver_analisis = ver_analisis,
       seleccionar_analisis = seleccionar_analisis, comparar = comparar,
       mostrar_grafico = mostrar_grafico, mostrar_tabla = mostrar_tabla, consultar_datos = consultar_datos)
}

# Cambios de puesto del banco analizado, adelantamientos frente a cada banco y entradas o salidas.
resumen_puestos <- function(pt, foco, nombre_banco) {
  p <- pt$puestos
  f <- p[p$cod_ifi == foco & !is.na(p$posicion), ]
  cruces <- character()
  for (cod in setdiff(unique(p$cod_ifi), foco)) {
    o <- p[p$cod_ifi == cod, ]
    dif <- f$posicion - o$posicion[match(f$periodo, o$periodo)] # negativo: el foco va arriba
    ok <- which(!is.na(dif))
    for (j in ok[-1]) {
      prev <- ok[ok < j][sum(ok < j)]
      if (sign(dif[prev]) != sign(dif[j])) {
        mes <- etiqueta_periodo(f$periodo[j])
        cruces <- c(cruces, if (dif[j] < 0) paste("pasa a", nombre_banco(cod), "en", mes)
                    else paste(nombre_banco(cod), "lo pasa en", mes))
      }
    }
  }
  mov <- pt$movimientos
  puesto <- function(i) paste0(f$posicion[i], "° en ", etiqueta_periodo(f$periodo[i]))
  list(
    banco = nombre_banco(foco),
    puesto_inicio = if (nrow(f)) puesto(1) else NULL,
    puesto_final = if (nrow(f)) puesto(nrow(f)) else NULL,
    adelantamientos = cruces,
    entradas_y_salidas = if (nrow(mov)) {
      paste0(ifelse(mov$tipo == "sale", "sale ", "entra "), nombre_banco(mov$cod_ifi), " en ",
             vapply(mov$periodo, etiqueta_periodo, ""))
    }
  )
}

# Definiciones para ellmer, con argumentos acotados a los valores disponibles.
definir_tools <- function(f, ctx) {
  bancos <- names(ctx$bancos)
  list(
    ellmer::tool(
      f$listar_opciones, name = "listar_opciones",
      "Lista bancos, cuentas, períodos, tipos de valor y modos de comparación disponibles. No cambia nada."
    ),
    ellmer::tool(
      f$ver_analisis, name = "ver_analisis",
      paste("Devuelve el análisis que el usuario ve ahora en el dashboard (posición, vecinos, líder,",
            "ranking), sin cambiarlo. Úsala si el usuario pudo cambiar los filtros a mano.")
    ),
    ellmer::tool(
      f$seleccionar_analisis, name = "seleccionar_analisis",
      paste("Cambia lo que muestra el dashboard y devuelve el resumen del nuevo análisis. Entrega solo",
            "los argumentos que cambian; el resto se mantiene. Para el líder o un puesto (el top, el",
            "segundo, el último) usa puesto en vez de banco: deja seleccionado al banco en ese puesto."),
      arguments = list(
        banco = ellmer::type_enum(bancos, "Banco a analizar.", required = FALSE),
        puesto = ellmer::type_integer(
          paste("Puesto del banco a seleccionar (1 = líder) en la cuenta, período y monedas de esta misma",
                "llamada. No se usa junto con banco."),
          required = FALSE
        ),
        cuenta = ellmer::type_enum(ctx$cuentas$nombre, "Cuenta del balance.", required = FALSE),
        periodo = ellmer::type_enum(ctx$periodos, "Período AAAAMM.", required = FALSE),
        monedas = ellmer::type_array(
          ellmer::type_enum(unname(etiquetas_moneda)),
          "Monedas a sumar (una a cuatro). Las cuatro = Total. Sin moneda extranjera = las otras tres.",
          required = FALSE
        )
      )
    ),
    ellmer::tool(
      f$comparar, name = "comparar",
      paste("Cambia la comparación del dashboard y devuelve la evolución de 24 meses y las brechas con el",
            "banco analizado. Modos: vecinos (puesto superior e inferior), sistema, lider, bancos."),
      arguments = list(
        modo = ellmer::type_enum(unname(modos_comparacion), "Modo de comparación."),
        bancos = ellmer::type_array(
          ellmer::type_enum(bancos), "Solo en modo bancos: de 1 a 4 bancos a comparar.", required = FALSE
        )
      )
    ),
    ellmer::tool(
      f$mostrar_grafico, name = "mostrar_grafico",
      paste("Abre una ventana con un gráfico del período y monedas actuales, sin cambiar el dashboard:",
            "puestos (ranking mes a mes, con entradas y salidas de bancos), composicion (mezcla de monedas",
            "de un banco en el tiempo), crecimiento (variación de todos los bancos en el período), evolucion",
            "(monto de una lista de bancos) y cuentas (un banco en 2 a 6 cuentas a la vez). Salvo cuentas,",
            "usan la cuenta actual. Devuelve un resumen; tú no ves el gráfico."),
      arguments = list(
        tipo = ellmer::type_enum(c("puestos", "composicion", "crecimiento", "evolucion", "cuentas"),
                                 "Tipo de gráfico."),
        bancos = ellmer::type_array(
          ellmer::type_enum(bancos),
          paste("Opcional, hasta 6. Por defecto, los bancos de la escalera. En composicion y cuentas, el",
                "primero es el banco a mostrar (por defecto, el analizado)."),
          required = FALSE
        ),
        cuentas = ellmer::type_array(ellmer::type_enum(ctx$cuentas$nombre),
                                     "Solo en tipo cuentas: de 2 a 6 cuentas.", required = FALSE),
        medida = ellmer::type_enum(names(medidas_cuentas),
                                   paste("Solo en tipo cuentas: monto (por defecto), indice (base 100, para",
                                         "cuentas de distinto tamaño) o participacion."), required = FALSE),
        meses = ellmer::type_enum(c("12", "24", "36"), "Meses de la ventana (por defecto 24).",
                                  required = FALSE),
        titulo = ellmer::type_string("Título breve de la ventana (opcional).", required = FALSE)
      )
    ),
    ellmer::tool(
      f$mostrar_tabla, name = "mostrar_tabla",
      paste("Abre una ventana con una tabla descargable en CSV del período y monedas actuales, sin cambiar",
            "el dashboard: ranking (con puesto y participación de hace 12 meses), historia (mes a mes de la",
            "escalera), composicion (bancos por moneda) o cuentas (un banco en 2 a 6 cuentas, mes a mes).",
            "Tú no ves la tabla."),
      arguments = list(
        tipo = ellmer::type_enum(c("ranking", "historia", "composicion", "cuentas"), "Tipo de tabla."),
        banco = ellmer::type_enum(bancos, "Solo en tipo cuentas: banco (por defecto, el analizado).",
                                  required = FALSE),
        cuentas = ellmer::type_array(ellmer::type_enum(ctx$cuentas$nombre),
                                     "Solo en tipo cuentas: de 2 a 6 cuentas.", required = FALSE),
        medida = ellmer::type_enum(names(medidas_cuentas),
                                   "Solo en tipo cuentas: monto, indice o participacion.", required = FALSE),
        meses = ellmer::type_enum(c("12", "24", "36"), "Meses de la historia (por defecto 24).",
                                  required = FALSE),
        titulo = ellmer::type_string("Título breve de la ventana (opcional).", required = FALSE)
      )
    ),
    ellmer::tool(
      f$consultar_datos, name = "consultar_datos",
      paste("Ejecuta una consulta SQL SELECT (DuckDB) sobre la tabla balance y devuelve hasta 200 filas.",
            "Columnas: periodo (texto AAAAMM), fecha (date), cod_ifi, banco ('Sistema' es el total),",
            "cuenta, cuenta_nombre, grupo, clp_mm, ipc_mm, tc_mm, mx_mm, total_mm (millones de pesos).",
            "Úsala solo para preguntas que las otras tools no responden. No cambia el dashboard."),
      arguments = list(consulta = ellmer::type_string("Una sola consulta SELECT, sin punto y coma."))
    )
  )
}
