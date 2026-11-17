# Pruebas de R/ranking.R con los datos preparados.
# Uso, desde app-benchmark/: Rscript tests/test-ranking.R

source(file.path("R", "ranking.R"))
datos <- readRDS(file.path("data", "balance.rds"))
periodo <- max(datos$periodo)

# Ranking de colocaciones: posiciones consecutivas, sin sistema, participaciones ~100 %
rk <- calcular_ranking(datos, "144000000", periodo, "total", foco = "009")
stopifnot(
  !"999" %in% rk$cod_ifi,
  identical(rk$posicion, seq_len(nrow(rk))),
  all(diff(abs(rk$monto)) <= 0),
  abs(sum(rk$participacion) - 1) < 0.005,
  sum(rk$rol == "foco") == 1
)
r <- resumen_posicion(rk, "009")
cat(sprintf("Internacional en Colocaciones %s: puesto %d de %d, participación %.2f %%\n",
            periodo, r$foco$posicion, r$n_bancos, 100 * r$foco$participacion))
stopifnot(r$superior$posicion == r$foco$posicion - 1, r$inferior$posicion == r$foco$posicion + 1)

# Líder: sin vecino superior; participación conjunta = foco + inferior
lider <- rk$cod_ifi[1]
r <- resumen_posicion(calcular_ranking(datos, "144000000", periodo, "total", lider), lider)
stopifnot(r$es_lider, is.null(r$superior), !is.null(r$inferior),
          abs(r$participacion_conjunta - r$foco$participacion - r$inferior$participacion) < 1e-12)

# Último: sin vecino inferior
ultimo <- rk$cod_ifi[nrow(rk)]
r <- resumen_posicion(calcular_ranking(datos, "144000000", periodo, "total", ultimo), ultimo)
stopifnot(is.null(r$inferior), !is.null(r$superior))

# Cuenta negativa (provisiones): ordenada por magnitud
rk_prov <- calcular_ranking(datos, "149000000", periodo, "total", "009")
stopifnot(all(rk_prov$monto <= 0), all(diff(abs(rk_prov$monto)) <= 0), all(rk_prov$participacion >= 0))

# Banco sin dato en el período (Security dejó de informar)
rk_sec <- calcular_ranking(datos, "144000000", periodo, "total", "049")
stopifnot(!resumen_posicion(rk_sec, "049")$con_dato, !"foco" %in% rk_sec$rol)
cat("Último período de Security:", ultimo_periodo_banco(datos, "144000000", "049"), "\n")

# Primer período: variación mensual no disponible
rk_ini <- calcular_ranking(datos, "144000000", min(datos$periodo), "total", "009")
stopifnot(all(is.na(rk_ini$var_m1)), all(is.na(rk_ini$var_12m)))

# Series: identidad fija de los vecinos y base 100 en el primer mes
s <- series_comparacion(datos, "144000000", periodo, "total", "009", "vecinos")
sup <- rk$cod_ifi[rk$rol == "superior"]
stopifnot(
  all(s$rol[s$cod_ifi == sup] == "superior"),
  !"resto" %in% s$rol, length(unique(s$cod_ifi)) == 3,
  length(unique(s$periodo)) == 24,
  all(abs(s$indice[s$periodo == min(s$periodo)] - 100) < 1e-9)
)

# Modos de comparación
stopifnot(
  setequal(unique(series_comparacion(datos, "144000000", periodo, "total", "009", "sistema")$rol),
           c("foco", "sistema")),
  setequal(unique(series_comparacion(datos, "144000000", periodo, "total", "009", "lider")$rol),
           c("foco", "lider")),
  setequal(unique(series_comparacion(datos, "144000000", periodo, "total", "009", "bancos",
                                     c("016", "039"))$cod_ifi), c("009", "016", "039")),
  identical(unique(series_comparacion(datos, "144000000", periodo, "total", "009", "bancos")$cod_ifi),
            "009")
)

# Ventana de la escalera: intermedio, líder y último
rk_ultimo <- calcular_ranking(datos, "144000000", periodo, "total")
stopifnot(
  identical(ventana_escalera(rk, "009")$posicion, 7:11),
  identical(ventana_escalera(rk, rk$cod_ifi[1])$posicion, 1:5),
  identical(ventana_escalera(rk, rk$cod_ifi[nrow(rk)])$posicion, (nrow(rk) - 4):nrow(rk)),
  nrow(ventana_escalera(rk, "049")) == 0
)

# Escalera de Internacional: Consorcio arriba (estable), Falabella abajo (cambio de orden)
e <- escalera(datos, "144000000", periodo, "total", "009")
b_sup <- e$brechas[e$brechas$abajo == "009", ]
b_inf <- e$brechas[e$brechas$arriba == "009", ]
stopifnot(
  nrow(e$filas) == 5, nrow(e$brechas) == 4,
  b_sup$arriba == "055", b_sup$tendencia == "estable", round(b_sup$monto / 1e6) == 1086485,
  b_inf$abajo == "051", b_inf$tendencia == "cambio de orden", round(b_inf$monto / 1e6) == 164125,
  all(lengths(e$filas$serie) == 12),
  abs(utils::tail(e$filas$serie[[3]], 1) - e$filas$participacion[3]) < 1e-12
)
cat("Escalera Internacional:", paste(e$brechas$tendencia, collapse = " | "), "\n")

# Cambio de puesto: 9° hoy, 11° hace 12 meses; salió Security (8°) y entró Tanner
cp <- cambio_puesto(datos, "144000000", periodo, "total", "009")
stopifnot(cp$puesto == 9, cp$n == 17, cp$puesto_12m == 11, cp$n_12m == 17,
          identical(cp$salieron$cod_ifi, "049"), cp$salieron$posicion == 8, identical(cp$entraron, "062"))

# Composición: suma 100 % en colocaciones; signos mixtos en patrimonio
co <- composicion(datos, "144000000", periodo)
bci <- co[co$cod_ifi == "016", ]
stopifnot(abs(bci$p_clp + bci$p_ipc + bci$p_tc + bci$p_mx - 1) < 1e-9, !bci$mixtos)
cat(sprintf("BCI colocaciones en moneda extranjera: %.1f %%\n", 100 * bci$p_mx))
cp_pat <- composicion(datos, "300000000", periodo)
stopifnot(any(cp_pat$mixtos), all(is.na(cp_pat$p_clp[cp_pat$mixtos])))

# Selección de monedas: las cuatro equivalen a Total; sin moneda extranjera se recalcula todo
stopifnot(identical(calcular_ranking(datos, "144000000", periodo, monedas_todas, "009"), rk))
sin_mx <- c("clp", "ipc", "tc")
rk_sin_mx <- calcular_ranking(datos, "144000000", periodo, sin_mx, "016")
fila_bci <- datos[datos$cuenta == "144000000" & datos$periodo == periodo & datos$cod_ifi == "016", ]
fila_sis <- datos[datos$cuenta == "144000000" & datos$periodo == periodo & datos$cod_ifi == "999", ]
stopifnot(
  rk_sin_mx$monto[rk_sin_mx$cod_ifi == "016"] == fila_bci$clp + fila_bci$ipc + fila_bci$tc,
  abs(rk_sin_mx$participacion[rk_sin_mx$cod_ifi == "016"] -
        (fila_bci$clp + fila_bci$ipc + fila_bci$tc) / (fila_sis$clp + fila_sis$ipc + fila_sis$tc)) < 1e-12,
  etiqueta_monedas(sin_mx) == "Total sin moneda extranjera",
  etiqueta_monedas("ipc") == "Reajustable IPC",
  etiqueta_monedas(c("clp", "ipc")) == "CLP no reajustable y reajustable IPC",
  etiqueta_monedas(monedas_todas) == "Total"
)
cat("BCI sin moneda extranjera: puesto", rk_sin_mx$posicion[rk_sin_mx$cod_ifi == "016"], "\n")

# Composición sobre la selección
co3 <- composicion(datos, "144000000", periodo, sin_mx)
b3 <- co3[co3$cod_ifi == "016", ]
stopifnot(abs(b3$p_clp + b3$p_ipc + b3$p_tc - 1) < 1e-9, is.na(b3$p_mx), is.na(b3$mx))
co1 <- composicion(datos, "144000000", periodo, "ipc")
stopifnot(all(abs(co1$p_ipc[!is.na(co1$p_ipc)] - 1) < 1e-9), all(is.na(co1$p_clp)))

# Puestos en el tiempo: Internacional pasa a Falabella en ago 2026; Security sale en nov 2025; Tanner entra
pt <- puestos_en_el_tiempo(datos, "144000000", periodo, "total", c("009", "051", "062"), meses = 24)
pos <- function(cod, p) pt$puestos$posicion[pt$puestos$cod_ifi == cod & pt$puestos$periodo == p]
stopifnot(
  pos("009", "202607") > pos("051", "202607"), pos("009", "202608") < pos("051", "202608"),
  any(pt$movimientos$cod_ifi == "049" & pt$movimientos$periodo == "202511" & pt$movimientos$tipo == "sale"),
  any(pt$movimientos$cod_ifi == "062" & pt$movimientos$tipo == "entra"),
  is.na(pos("062", "202501")), length(unique(pt$puestos$periodo)) == 24
)

# Composición en el tiempo y crecimiento del período
ct <- composicion_en_el_tiempo(datos, "144000000", periodo, "total", "016", meses = 24)
stopifnot(nrow(ct) == 24, all(abs(ct$p_clp + ct$p_ipc + ct$p_tc + ct$p_mx - 1) < 1e-9))
cr <- crecimiento_periodo(datos, "144000000", periodo, "total", meses = 12)
stopifnot(cr$cod_ifi[1] == "028", round(100 * cr$variacion[1], 1) == 85,
          "062" %in% attr(cr, "sin_dato_inicio"))
cat("Crecimiento 12m: BICE", round(100 * cr$variacion[1], 1), "% · sin dato al inicio:",
    attr(cr, "sin_dato_inicio"), "\n")

# Serie de varias cuentas de un banco
rk_bci_total <- function(datos, p) {
  r <- calcular_ranking(datos, "144000000", p)
  r$participacion[r$cod_ifi == "016"]
}
sc <- serie_cuentas(datos, "016", c("144000000", "242000000"), periodo, "total", meses = 24)
ultimo_col <- sc[sc$cuenta == "144000000" & sc$periodo == periodo, ]
stopifnot(nrow(sc) == 48, round(ultimo_col$monto / 1e6) == 60552456,
          all(sc$indice[sc$periodo == min(sc$periodo)] == 100),
          abs(ultimo_col$participacion - rk_bci_total(datos, periodo)) < 1e-12)

# Serie del sistema: total de sep 2026 y variación en 12 meses
ss <- serie_sistema(datos, "144000000", periodo, "total", meses = 24)
fin <- ss$monto[nrow(ss)]
stopifnot(nrow(ss) == 24, round(fin / 1e6) == 278598681,
          round(100 * variacion(fin, ss$monto[ss$periodo == desplazar_periodo(periodo, -12)]), 1) == 5.1)

# Participación conjunta de la escalera: el último mes es la suma de la escalera; salto en oct 2025
esc <- escalera(datos, "144000000", periodo, "total", "009")
scj <- serie_conjunta(datos, "144000000", periodo, "total", esc$filas$cod_ifi, meses = 24)
saltos <- diff(100 * scj$participacion)
stopifnot(abs(scj$participacion[24] - sum(esc$filas$participacion)) < 1e-12,
          scj$periodo[which.max(saltos) + 1] == "202511", round(max(saltos), 2) == 2.69)

cat("Todas las pruebas de ranking pasaron.\n")

# Línea interactiva de la escalera: 12 meses con posición y texto; los meses sin dato quedan vacíos
for (f in c("formato.R", "tema.R", "componentes.R")) source(file.path("R", f))
e <- escalera(datos, "144000000", periodo, monedas_todas, "009")
stopifnot(length(e$periodos) == 12, e$periodos[12] == periodo)
sp <- sparkline_svg(c(NA, 0.01, 0.02, 0.015), "#000000", c("ene", "feb", "mar", "abr"))
stopifnot(
  identical(strsplit(sp$attribs[["data-x"]], ",")[[1]][1], "1.88"),
  startsWith(sp$attribs[["data-y"]], ","),
  grepl("^ene · sin dato\\|feb · 1,00 %", sp$attribs[["data-t"]]),
  sp$attribs[["data-ultimo"]] == 3
)
cat("Pruebas de la línea interactiva pasaron.\n")

# Puntos base: diferencias de participación (entran en puntos porcentuales)
stopifnot(
  identical(puntos_base(c(3.42, -0.09, -0.004, 7.12, NA), signo = TRUE),
            c("+342 pb", "-9 pb", "0 pb", "+712 pb", "N/A")),
  identical(puntos_base(12.3456), "1.235 pb")
)
cat("Pruebas de puntos base pasaron.\n")
