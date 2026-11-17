# Cálculos de posición competitiva. Funciones puras: reciben el balance y devuelven data.frames.
# Las usan el dashboard y las tools del chat.

# monedas ---------------------------------------------------------------
# Una selección de monedas es un vector con uno o más códigos, en este orden. Las cuatro juntas son el
# Total (en los datos, clp + ipc + tc + mx = total en todas las filas).
monedas_todas <- c("clp", "ipc", "tc", "mx")
etiquetas_moneda <- c(clp = "CLP no reajustable", ipc = "Reajustable IPC", tc = "Reajustable TC",
                      mx = "Moneda extranjera")

normalizar_monedas <- function(monedas) {
  if (identical(monedas, "total")) return(monedas_todas)
  monedas_todas[monedas_todas %in% monedas]
}

# Monto de una selección de monedas: suma de sus columnas.
valor_monedas <- function(datos, monedas) {
  rowSums(datos[, normalizar_monedas(monedas), drop = FALSE])
}

# Nombre de la selección: "Total", "Reajustable IPC", "Total sin moneda extranjera" o "A y B".
etiqueta_monedas <- function(monedas) {
  # Minúscula inicial dentro de una frase, salvo siglas ("CLP no reajustable").
  en_frase <- function(x) if (grepl("^[A-Z]{2}", x)) x else paste0(tolower(substr(x, 1, 1)), substring(x, 2))
  m <- normalizar_monedas(monedas)
  if (length(m) == 4) return("Total")
  if (length(m) == 1) return(etiquetas_moneda[[m]])
  if (length(m) == 3) return(paste("Total sin", en_frase(etiquetas_moneda[[setdiff(monedas_todas, m)]])))
  paste(etiquetas_moneda[[m[1]]], "y", en_frase(etiquetas_moneda[[m[2]]]))
}

modos_comparacion <- c(
  "Vecinos" = "vecinos",
  "Sistema" = "sistema",
  "Líder" = "lider",
  "Bancos" = "bancos"
)

desplazar_periodo <- function(periodo, meses) {
  fecha <- as.Date(paste0(periodo, "01"), "%Y%m%d")
  format(seq(fecha, by = paste(meses, "months"), length.out = 2)[2], "%Y%m")
}

variacion <- function(actual, base) {
  ifelse(is.na(base) | base == 0, NA_real_, actual / base - 1)
}

# Monto de cada institución (sin el sistema) en una cuenta, período y tipo de valor.
montos_periodo <- function(datos, cuenta, periodo, monedas) {
  fila <- datos$cuenta == cuenta & datos$periodo == periodo
  data.frame(cod_ifi = datos$cod_ifi[fila], monto = valor_monedas(datos[fila, ], monedas))
}

# Ranking completo con métricas y rol de cada institución respecto del banco foco.
# Roles por prioridad: foco > lider > superior > inferior > resto.
calcular_ranking <- function(datos, cuenta, periodo, monedas = monedas_todas, foco = NULL) {
  actual <- montos_periodo(datos, cuenta, periodo, monedas)
  total_sistema <- actual$monto[actual$cod_ifi == "999"]
  rk <- actual[actual$cod_ifi != "999", ]
  rk <- rk[order(-abs(rk$monto)), ]
  rk$posicion <- seq_len(nrow(rk))

  previo <- montos_periodo(datos, cuenta, desplazar_periodo(periodo, -1), monedas)
  anual <- montos_periodo(datos, cuenta, desplazar_periodo(periodo, -12), monedas)
  rk$participacion <- if (length(total_sistema)) rk$monto / total_sistema else NA_real_
  rk$var_m1 <- variacion(rk$monto, previo$monto[match(rk$cod_ifi, previo$cod_ifi)])
  rk$var_12m <- variacion(rk$monto, anual$monto[match(rk$cod_ifi, anual$cod_ifi)])

  pos_foco <- if (is.null(foco)) NA else match(foco, rk$cod_ifi)
  rk$rol <- "resto"
  if (!is.na(pos_foco)) {
    rk$rol[rk$posicion == pos_foco + 1] <- "inferior"
    rk$rol[rk$posicion == pos_foco - 1] <- "superior"
  }
  rk$rol[rk$posicion == 1] <- "lider"
  if (!is.na(pos_foco)) rk$rol[pos_foco] <- "foco"

  rownames(rk) <- NULL
  attr(rk, "total_sistema") <- if (length(total_sistema)) total_sistema else NA_real_
  attr(rk, "var_m1_sistema") <- variacion(
    if (length(total_sistema)) total_sistema else NA_real_,
    previo$monto[previo$cod_ifi == "999"][1]
  )
  rk
}

# Banco foco, vecinos y líder del ranking, con la participación conjunta del foco y sus vecinos.
resumen_posicion <- function(rk, foco) {
  pos <- match(foco, rk$cod_ifi)
  if (is.na(pos)) return(list(con_dato = FALSE))
  fila <- function(p) if (p >= 1 && p <= nrow(rk)) rk[p, ] else NULL
  superior <- fila(pos - 1)
  inferior <- fila(pos + 1)
  conjunto <- rbind(rk[pos, ], superior, inferior)
  list(
    con_dato = TRUE,
    foco = rk[pos, ],
    superior = superior,
    inferior = inferior,
    lider = rk[1, ],
    es_lider = pos == 1,
    n_bancos = nrow(rk),
    participacion_conjunta = sum(conjunto$participacion),
    total_sistema = attr(rk, "total_sistema"),
    var_m1_sistema = attr(rk, "var_m1_sistema")
  )
}

ultimo_periodo_banco <- function(datos, cuenta, cod_ifi) {
  p <- datos$periodo[datos$cuenta == cuenta & datos$cod_ifi == cod_ifi]
  if (length(p)) max(p) else NA_character_
}

# Instituciones que participan en la comparación, con su rol fijado en el período elegido.
integrantes_comparacion <- function(rk, foco, modo, bancos = character()) {
  if (!foco %in% rk$cod_ifi) return(data.frame(cod_ifi = character(), rol = character()))
  roles <- rk[, c("cod_ifi", "rol")]
  elegidos <- switch(
    modo,
    sistema = foco,
    vecinos = rk$cod_ifi[max(1, match(foco, rk$cod_ifi) - 1):min(nrow(rk), match(foco, rk$cod_ifi) + 1)],
    lider = unique(c(foco, rk$cod_ifi[1])),
    bancos = unique(c(foco, intersect(bancos, rk$cod_ifi)))
  )
  out <- roles[roles$cod_ifi %in% elegidos, ]
  if (modo == "lider") out$rol[out$cod_ifi == rk$cod_ifi[1] & out$cod_ifi != foco] <- "lider"
  if (modo == "bancos") out$rol[out$cod_ifi != foco] <- "comparado"
  out <- out[match(elegidos, out$cod_ifi, nomatch = 0), ]
  if (modo == "sistema") out <- rbind(out, data.frame(cod_ifi = "999", rol = "sistema"))
  out[!duplicated(out$cod_ifi), ]
}

# Serie histórica de los integrantes hasta el período elegido, con participación e índice base 100.
series_comparacion <- function(datos, cuenta, periodo, monedas, foco, modo,
                               bancos = character(), meses = 24) {
  rk <- calcular_ranking(datos, cuenta, periodo, monedas, foco)
  integrantes <- integrantes_comparacion(rk, foco, modo, bancos)
  desde <- desplazar_periodo(periodo, -(meses - 1))
  fila <- datos$cuenta == cuenta & datos$periodo >= desde & datos$periodo <= periodo
  historia <- datos[fila, c("periodo", "fecha", "cod_ifi")]
  historia$monto <- valor_monedas(datos[fila, ], monedas)

  sistema <- historia[historia$cod_ifi == "999", c("periodo", "monto")]
  names(sistema)[2] <- "monto_sistema"
  s <- merge(historia[historia$cod_ifi %in% integrantes$cod_ifi, ], sistema, by = "periodo")
  s$rol <- integrantes$rol[match(s$cod_ifi, integrantes$cod_ifi)]
  s$participacion <- s$monto / s$monto_sistema
  s <- s[order(s$cod_ifi, s$periodo), ]
  s$indice <- unlist(lapply(split(s$monto, s$cod_ifi), function(m) {
    base <- m[which(abs(m) > 0)[1]]
    if (is.na(base)) rep(NA_real_, length(m)) else 100 * m / base
  }))
  s$monto_sistema <- NULL
  rownames(s) <- NULL
  attr(s, "integrantes") <- integrantes
  s
}

# escalera de competencia -------------------------------------------------

# Filas de la escalera: el foco y hasta dos puestos a cada lado; en los extremos se desplaza para
# mantener 5 bancos (o todos, si el ranking tiene menos).
ventana_escalera <- function(rk, foco, tamano = 5) {
  pos <- match(foco, rk$cod_ifi)
  if (is.na(pos)) return(rk[0, ])
  k <- min(tamano, nrow(rk))
  desde <- min(max(1, pos - (k - 1) %/% 2), nrow(rk) - k + 1)
  rk[desde:(desde + k - 1), ]
}

# pp: brecha en puntos de participación (arriba menos abajo), hoy y hace 12 meses.
tendencia_brecha <- function(pp, pp_12m) {
  if (is.na(pp_12m)) return("sin dato hace 12 meses")
  if (pp_12m < 0) return("cambio de orden")
  d <- pp - pp_12m
  if (abs(d) < 0.02) "estable" else if (d < 0) "se acorta" else "se amplía"
}

# Filas de la escalera con participación hace 12 meses y su serie mensual, y brechas entre puestos
# consecutivos. Las brechas de monto usan magnitudes, así sirven también para cuentas negativas.
escalera <- function(datos, cuenta, periodo, monedas, foco) {
  rk <- calcular_ranking(datos, cuenta, periodo, monedas, foco)
  v <- ventana_escalera(rk, foco)
  if (!nrow(v)) return(NULL)
  hace <- desplazar_periodo(periodo, -12)
  rk12 <- calcular_ranking(datos, cuenta, hace, monedas)
  v$participacion_12m <- rk12$participacion[match(v$cod_ifi, rk12$cod_ifi)]

  periodos <- vapply(11:0, function(m) if (m == 0) periodo else desplazar_periodo(periodo, -m), "")
  cuenta_datos <- datos[datos$cuenta == cuenta, ]
  sistema <- cuenta_datos[cuenta_datos$cod_ifi == "999", ]
  base <- valor_monedas(sistema, monedas)[match(periodos, sistema$periodo)]
  v$serie <- lapply(v$cod_ifi, function(cod) {
    d <- cuenta_datos[cuenta_datos$cod_ifi == cod, ]
    valor_monedas(d, monedas)[match(periodos, d$periodo)] / base
  })

  arriba <- seq_len(nrow(v) - 1)
  brechas <- data.frame(
    arriba = v$cod_ifi[arriba],
    abajo = v$cod_ifi[arriba + 1],
    monto = abs(v$monto[arriba]) - abs(v$monto[arriba + 1]),
    pp = 100 * (v$participacion[arriba] - v$participacion[arriba + 1]),
    pp_12m = 100 * (v$participacion_12m[arriba] - v$participacion_12m[arriba + 1])
  )
  brechas$tendencia <- vapply(seq_len(nrow(brechas)), function(i) {
    tendencia_brecha(brechas$pp[i], brechas$pp_12m[i])
  }, "")
  rownames(v) <- NULL
  list(filas = v, brechas = brechas, periodo_12m = hace, n_bancos = nrow(rk), periodos = periodos)
}

# Puesto del foco y cantidad de bancos, hoy y hace 12 meses, con las instituciones que salieron (y su
# puesto de entonces) o entraron: explican cambios de puesto que no vienen del crecimiento del banco.
cambio_puesto <- function(datos, cuenta, periodo, monedas, foco) {
  hace <- desplazar_periodo(periodo, -12)
  rk <- calcular_ranking(datos, cuenta, periodo, monedas)
  rk12 <- calcular_ranking(datos, cuenta, hace, monedas)
  salieron <- rk12[!rk12$cod_ifi %in% rk$cod_ifi, c("cod_ifi", "posicion")]
  rownames(salieron) <- NULL
  list(
    puesto = match(foco, rk$cod_ifi), n = nrow(rk),
    puesto_12m = match(foco, rk12$cod_ifi), n_12m = nrow(rk12), periodo_12m = hace,
    salieron = salieron,
    entraron = if (nrow(rk12)) setdiff(rk$cod_ifi, rk12$cod_ifi) else character()
  )
}

# Participación hoy y hace 12 meses de un conjunto de bancos (pestaña Posición 12m), en orden de ranking.
participacion_12m <- function(datos, cuenta, periodo, monedas, cods) {
  rk <- calcular_ranking(datos, cuenta, periodo, monedas)
  rk12 <- calcular_ranking(datos, cuenta, desplazar_periodo(periodo, -12), monedas)
  d <- rk[rk$cod_ifi %in% cods, c("cod_ifi", "posicion", "participacion")]
  d$participacion_12m <- rk12$participacion[match(d$cod_ifi, rk12$cod_ifi)]
  rownames(d) <- NULL
  d
}

# Composición por moneda de cada institución (sin el sistema), solo con las monedas elegidas y en % de su
# suma. Con signos mixtos no hay porcentajes: una barra al 100 % no representa bien montos positivos y
# negativos a la vez. Las columnas de monedas no elegidas quedan en NA.
composicion <- function(datos, cuenta, periodo, monedas = monedas_todas) {
  m <- normalizar_monedas(monedas)
  d <- datos[datos$cuenta == cuenta & datos$periodo == periodo & datos$cod_ifi != "999",
             c("cod_ifi", monedas_todas)]
  d[setdiff(monedas_todas, m)] <- NA_real_
  partes <- as.matrix(d[, m, drop = FALSE])
  d$total <- rowSums(partes)
  d$mixtos <- apply(partes, 1, function(x) any(x < 0) && any(x > 0))
  pct <- matrix(NA_real_, nrow(d), 4, dimnames = list(NULL, paste0("p_", monedas_todas)))
  pct[, paste0("p_", m)] <- partes / d$total
  pct[d$mixtos | d$total == 0, ] <- NA
  out <- cbind(d, pct)
  rownames(out) <- NULL
  attr(out, "monedas") <- m
  out
}

# series para ventanas emergentes -------------------------------------------

# Períodos de una ventana de `meses` meses que termina en `periodo` (solo los que existen en los datos).
periodos_ventana <- function(datos, periodo, meses) {
  per <- vapply((meses - 1):0, function(m) if (m == 0) periodo else desplazar_periodo(periodo, -m), "")
  per[per %in% datos$periodo]
}

# Puesto mes a mes de un conjunto de bancos, y entradas o salidas del ranking (fusiones, bancos nuevos).
puestos_en_el_tiempo <- function(datos, cuenta, periodo, monedas, cods, meses = 24) {
  per <- periodos_ventana(datos, periodo, meses)
  presentes <- list()
  filas <- lapply(per, function(p) {
    rk <- calcular_ranking(datos, cuenta, p, monedas)
    presentes[[p]] <<- rk$cod_ifi
    data.frame(periodo = p, cod_ifi = cods, posicion = rk$posicion[match(cods, rk$cod_ifi)])
  })
  puestos <- do.call(rbind, filas)
  puestos$fecha <- as.Date(paste0(puestos$periodo, "01"), "%Y%m%d")
  movimientos <- data.frame(periodo = character(), cod_ifi = character(), tipo = character(),
                            posicion_previa = integer())
  for (i in seq_along(per)[-1]) {
    antes <- presentes[[per[i - 1]]]
    ahora <- presentes[[per[i]]]
    for (cod in setdiff(antes, ahora)) {
      movimientos <- rbind(movimientos, data.frame(periodo = per[i], cod_ifi = cod, tipo = "sale",
                                                   posicion_previa = match(cod, antes)))
    }
    for (cod in setdiff(ahora, antes)) {
      movimientos <- rbind(movimientos, data.frame(periodo = per[i], cod_ifi = cod, tipo = "entra",
                                                   posicion_previa = NA_integer_))
    }
  }
  rownames(puestos) <- NULL
  list(puestos = puestos, movimientos = movimientos)
}

# Composición por moneda de un banco mes a mes (misma regla de signos mixtos que composicion()).
composicion_en_el_tiempo <- function(datos, cuenta, periodo, monedas, cod, meses = 24) {
  filas <- lapply(periodos_ventana(datos, periodo, meses), function(p) {
    co <- composicion(datos, cuenta, p, monedas)
    f <- co[co$cod_ifi == cod, ]
    if (nrow(f)) cbind(periodo = p, f) else NULL
  })
  out <- do.call(rbind, filas)
  if (is.null(out)) return(NULL)
  out$fecha <- as.Date(paste0(out$periodo, "01"), "%Y%m%d")
  rownames(out) <- NULL
  attr(out, "monedas") <- normalizar_monedas(monedas)
  out
}

# Variación del monto y cambio de participación de cada banco entre el inicio y el fin de la ventana.
crecimiento_periodo <- function(datos, cuenta, periodo, monedas, meses = 12) {
  inicio <- desplazar_periodo(periodo, -meses)
  a <- calcular_ranking(datos, cuenta, inicio, monedas)
  b <- calcular_ranking(datos, cuenta, periodo, monedas)
  i <- match(b$cod_ifi, a$cod_ifi)
  d <- data.frame(cod_ifi = b$cod_ifi, monto = b$monto, monto_inicio = a$monto[i],
                  participacion = b$participacion, participacion_inicio = a$participacion[i])
  d$variacion <- variacion(d$monto, d$monto_inicio)
  d$cambio_pp <- 100 * (d$participacion - d$participacion_inicio)
  sin_dato <- d$cod_ifi[is.na(d$monto_inicio)]
  d <- d[!is.na(d$monto_inicio), ]
  d <- d[order(-d$variacion), ]
  rownames(d) <- NULL
  attr(d, "sin_dato_inicio") <- sin_dato
  attr(d, "periodo_inicio") <- inicio
  d
}

# Serie de varias cuentas de un banco: monto, participación sobre el sistema en cada cuenta e índice base
# 100 (primer mes con monto distinto de cero).
serie_cuentas <- function(datos, cod, cuentas, periodo, monedas, meses = 24) {
  per <- periodos_ventana(datos, periodo, meses)
  filas <- lapply(cuentas, function(cta) {
    d <- datos[datos$cuenta == cta & datos$periodo %in% per & datos$cod_ifi %in% c(cod, "999"), ]
    monto <- valor_monedas(d, monedas)
    banco <- d$cod_ifi == cod
    sistema <- monto[!banco][match(d$periodo[banco], d$periodo[!banco])]
    out <- data.frame(periodo = per, cuenta = cta)
    i <- match(per, d$periodo[banco])
    out$monto <- monto[banco][i]
    out$participacion <- (monto[banco] / sistema)[i]
    base <- out$monto[which(!is.na(out$monto) & out$monto != 0)[1]]
    out$indice <- if (is.na(base)) NA_real_ else 100 * out$monto / base
    out
  })
  out <- do.call(rbind, filas)
  out$fecha <- as.Date(paste0(out$periodo, "01"), "%Y%m%d")
  out
}

# Total del sistema (código 999) mes a mes en la cuenta y monedas elegidas.
serie_sistema <- function(datos, cuenta, periodo, monedas, meses = 24) {
  per <- periodos_ventana(datos, periodo, meses)
  d <- datos[datos$cuenta == cuenta & datos$cod_ifi == "999" & datos$periodo %in% per, ]
  d <- d[order(d$periodo), ]
  data.frame(periodo = d$periodo, fecha = d$fecha, monto = valor_monedas(d, monedas))
}

# Participación conjunta mes a mes de un conjunto fijo de bancos (por ejemplo, la escalera actual).
serie_conjunta <- function(datos, cuenta, periodo, monedas, cods, meses = 24) {
  per <- periodos_ventana(datos, periodo, meses)
  d <- datos[datos$cuenta == cuenta & datos$periodo %in% per & datos$cod_ifi %in% c(cods, "999"), ]
  monto <- valor_monedas(d, monedas)
  sistema <- tapply(monto[d$cod_ifi == "999"], d$periodo[d$cod_ifi == "999"], sum)
  bancos <- tapply(monto[d$cod_ifi != "999"], d$periodo[d$cod_ifi != "999"], sum)
  data.frame(periodo = per, fecha = as.Date(paste0(per, "01"), "%Y%m%d"),
             participacion = as.numeric(bancos[per] / sistema[per]))
}
