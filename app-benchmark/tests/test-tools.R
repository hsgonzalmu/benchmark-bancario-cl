# Pruebas de R/tools.R sin llamar al modelo: las tools se ejecutan con reactiveVal reales.
# Uso, desde app-benchmark/: Rscript tests/test-tools.R

library(shiny)
for (f in c("ranking.R", "formato.R", "tema.R", "graficos.R", "modales.R", "sql.R", "tools.R")) {
  source(file.path("R", f))
}
balance <- readRDS(file.path("data", "balance.rds"))
fichas <- read.csv(file.path("data", "instituciones.csv"), colClasses = "character", encoding = "UTF-8")
cuentas <- read.csv(file.path("data", "cuentas.csv"), colClasses = "character", encoding = "UTF-8")
ctx <- crear_contexto(balance, fichas, cuentas)
periodo <- max(balance$periodo)

nuevo_estado <- function(banco = "009") list(
  banco_foco = reactiveVal(banco), cuenta = reactiveVal("144000000"), periodo = reactiveVal(periodo),
  monedas = reactiveVal(monedas_todas),
  comparacion = reactiveVal(list(modo = "vecinos", bancos = character()))
)
json <- function(x) jsonlite::fromJSON(x, simplifyVector = FALSE)
falla <- function(expr) inherits(tryCatch(expr, error = function(e) e), "error")
llamadas <- 0
estado <- nuevo_estado()
f <- crear_tools(estado, ctx, al_cambiar = function() llamadas <<- llamadas + 1)

# resumen_para_chat coincide con resumen_posicion
rk <- calcular_ranking(balance, "144000000", periodo, "total", "009")
r <- resumen_posicion(rk, "009")
v <- json(f$ver_analisis())
stopifnot(
  v$banco == "Internacional", v$cuenta == "Colocaciones",
  v$analizado$posicion == sprintf("%d de %d", r$foco$posicion, r$n_bancos),
  v$analizado$monto == monto_corto(r$foco$monto),
  v$vecino_superior$banco == ctx$nombre_banco(r$superior$cod_ifi),
  length(v$ranking) == r$n_bancos, llamadas == 0
)
cat("ver_analisis:", v$banco, v$analizado$posicion, v$analizado$monto, v$analizado$participacion, "\n")

# Escalera, puesto y composición en el resumen, iguales a los cálculos del dashboard
br <- v$escalera$brechas
sup <- br[[which(vapply(br, function(b) b$abajo == "Internacional", TRUE))]]
inf <- br[[which(vapply(br, function(b) b$arriba == "Internacional", TRUE))]]
stopifnot(
  length(v$escalera$bancos) == 3, sup$arriba == "Consorcio", sup$tendencia == "estable",
  sup$monto == "MM$ 1.086.485", inf$tendencia == "cambio de orden",
  v$puesto_hace_12_meses$hoy == "9° de 17", grepl("^11° de 17", v$puesto_hace_12_meses$hace_12_meses),
  grepl("Security", v$puesto_hace_12_meses$salieron), v$puesto_hace_12_meses$entraron == "Tanner"
)
vb <- json(crear_tools(nuevo_estado("016"), ctx)$ver_analisis())
mx <- vb$composicion_del_analizado$partes[[4]]
stopifnot(mx$moneda == "Moneda extranjera", mx$porcentaje == "47,4 %")
cat("Escalera en el chat:", sup$arriba, "->", sup$abajo, sup$monto, sup$tendencia,
    "| BCI en moneda extranjera:", mx$porcentaje, "\n")

# El líder no tiene vecino superior
lider <- rk$cod_ifi[1]
vl <- json(crear_tools(nuevo_estado(lider), ctx)$ver_analisis())
stopifnot(grepl("líder", vl$vecino_superior), vl$lider$banco == ctx$nombre_banco(lider))

# listar_opciones
o <- json(f$listar_opciones())
stopifnot(length(o$bancos) == length(ctx$bancos), !"Sistema" %in% unlist(o$bancos), length(o$cuentas) == 11,
          o$periodo_ultimo$codigo == periodo)

# seleccionar_analisis: solo la cuenta conserva el banco
s <- json(f$seleccionar_analisis(cuenta = "Depósitos a plazo"))
stopifnot(isolate(estado$cuenta()) == "242000000", isolate(estado$banco_foco()) == "009",
          s$cuenta == "Depósitos a plazo", llamadas == 1)

# Sin argumentos falla; argumentos inválidos fallan sin cambiar el estado
antes <- isolate(lapply(estado, function(x) x()))
stopifnot(
  falla(f$seleccionar_analisis()),
  falla(f$seleccionar_analisis(banco = "Banco Pichincha", cuenta = "Colocaciones")),
  falla(f$seleccionar_analisis(periodo = "209912")),
  identical(antes, isolate(lapply(estado, function(x) x())))
)

# Security sin datos en el último período
sec <- json(f$seleccionar_analisis(banco = "Security", cuenta = "Colocaciones"))
stopifnot(isTRUE(sec$sin_datos), sec$ultimo_periodo_codigo == "202510")
cat("Security:", sec$mensaje, "Último:", sec$ultimo_periodo_disponible, "\n")

# comparar: cuatro modos
invisible(f$seleccionar_analisis(banco = "Internacional"))
cs <- json(f$comparar("sistema"))
stopifnot(isolate(estado$comparacion())$modo == "sistema", cs$brechas[[1]]$con == "Sistema")
cat("Sistema: crecimiento banco", cs$brechas[[1]]$crecimiento_banco, "vs sistema",
    cs$brechas[[1]]$crecimiento_sistema, "\n")

cl <- json(f$comparar("lider"))
stopifnot(length(cl$brechas) == 1, cl$brechas[[1]]$con == ctx$nombre_banco(lider))
cat("Líder:", cl$brechas[[1]]$con, "le saca", cl$brechas[[1]]$monto_otro_menos_analizado_final, "y",
    cl$brechas[[1]]$participacion_otro_menos_analizado_final, "\n")

cv <- json(f$comparar("vecinos"))
stopifnot(length(cv$evolucion) == 3, length(cv$brechas) == 2)

cb <- json(f$comparar("bancos", c("BCI", "Itaú", "Internacional")))
stopifnot(identical(isolate(estado$comparacion())$bancos, c("016", "039")), length(cb$brechas) == 2)

# Selección por puesto: el top de depósitos a plazo en UF y el segundo en colocaciones
sp <- json(f$seleccionar_analisis(puesto = 1, cuenta = "Depósitos a plazo", monedas = "Reajustable IPC"))
stopifnot(isolate(estado$banco_foco()) == "012", sp$banco == "BancoEstado",
          grepl("^1 de", sp$analizado$posicion), isolate(estado$cuenta()) == "242000000",
          identical(isolate(estado$monedas()), "ipc"))
antes <- isolate(lapply(estado, function(x) x()))
stopifnot(falla(f$seleccionar_analisis(banco = "BCI", puesto = 1)),
          falla(f$seleccionar_analisis(puesto = 30)),
          identical(antes, isolate(lapply(estado, function(x) x()))))
s2 <- json(f$seleccionar_analisis(puesto = 2, cuenta = "Colocaciones", monedas = unname(etiquetas_moneda)))
stopifnot(s2$banco == "Santander")
invisible(f$seleccionar_analisis(banco = "Internacional"))
cat("Top en depósitos a plazo en UF:", sp$banco, sp$analizado$participacion, "| segundo en colocaciones:",
    s2$banco, "
")

# Selección de monedas: sin moneda extranjera, solo IPC, lista vacía y moneda inválida
llamadas_antes <- llamadas
sm <- json(f$seleccionar_analisis(banco = "BCI",
                                  monedas = c("CLP no reajustable", "Reajustable IPC", "Reajustable TC")))
stopifnot(identical(isolate(estado$monedas()), c("clp", "ipc", "tc")),
          sm$monedas == "Total sin moneda extranjera", length(sm$composicion_del_analizado$partes) == 3,
          llamadas == llamadas_antes + 1, sm$analizado$posicion == "4 de 17")
si <- json(f$seleccionar_analisis(monedas = "Reajustable IPC"))
stopifnot(identical(isolate(estado$monedas()), "ipc"), si$monedas == "Reajustable IPC",
          si$composicion_del_analizado$partes[[1]]$porcentaje == "100,0 %")
antes <- isolate(estado$monedas())
stopifnot(falla(f$seleccionar_analisis(monedas = character())),
          falla(f$seleccionar_analisis(monedas = "Bitcoin")), identical(antes, isolate(estado$monedas())))
invisible(f$seleccionar_analisis(banco = "Internacional", monedas = unname(etiquetas_moneda)))
stopifnot(identical(isolate(estado$monedas()), monedas_todas))
cat("BCI sin moneda extranjera:", sm$analizado$posicion, sm$analizado$monto, "\n")

# Demasiados bancos: falla y el estado no cambia
antes <- isolate(estado$comparacion())
stopifnot(
  falla(f$comparar("bancos", c("BCI", "Itaú", "Santander", "Scotiabank", "BICE"))),
  identical(antes, isolate(estado$comparacion()))
)

# Cambiar el banco lo quita de los comparados
invisible(f$seleccionar_analisis(banco = "BCI"))
stopifnot(identical(isolate(estado$comparacion())$bancos, "039"))

# Ventanas emergentes: se registran en vez de mostrarse
ventanas <- list()
registrar <- function(titulo, contenido, csv = NULL, nota = NULL) {
  ventanas[[length(ventanas) + 1]] <<- list(titulo = titulo, clase = class(contenido)[1], csv = csv)
}
usar_colores_bancos(fichas)
con <- crear_base_sql(balance, fichas, cuentas)
ev <- nuevo_estado("009")
g <- crear_tools(ev, ctx, abrir_ventana = registrar, con = con)
antes <- isolate(lapply(ev, function(x) x()))

gp <- json(g$mostrar_grafico("puestos"))
stopifnot(length(ventanas) == 1, ventanas[[1]]$clase == "highchart",
          "pasa a Falabella en ago 2026" %in% unlist(gp$resumen$adelantamientos),
          any(grepl("sale Security en nov 2025", unlist(gp$resumen$entradas_y_salidas))))
gc <- json(g$mostrar_grafico("composicion", bancos = "BCI"))
gk <- json(g$mostrar_grafico("crecimiento", meses = "12"))
stopifnot(gk$resumen$mayores[[1]] == "BICE +85,0 %", gc$resumen$banco == "BCI")
# El resumen indica qué banco dejar en el dashboard: el que más creció
stopifnot(grepl("seleccionar_analisis(banco = \"BICE\")", gk$resumen$para_dashboard, fixed = TRUE))
ge <- json(g$mostrar_grafico("evolucion", bancos = c("Internacional", "Consorcio", "BCI")))
stopifnot(length(ventanas) == 4, length(ge$resumen) == 3,
          falla(g$mostrar_grafico("evolucion", bancos = names(ctx$bancos)[1:7])), length(ventanas) == 4)
cat("Puestos:", unlist(gp$resumen$adelantamientos), "| crecimiento:", unlist(gk$resumen$mayores), "
")

tr <- json(g$mostrar_tabla("ranking"))
stopifnot(tr$filas == 17, nrow(ventanas[[5]]$csv) == 17, ventanas[[5]]$clase == "reactable")
# Quién ganó más participación, en pb, y qué banco dejar en el dashboard
stopifnot(length(tr$resumen$mas_ganaron_participacion) == 3,
          all(grepl(" [+-]?[0-9.]+ pb$", unlist(tr$resumen$mas_ganaron_participacion))),
          grepl("seleccionar_analisis(banco = ", tr$resumen$para_dashboard, fixed = TRUE))
cat("Ganaron participación:", unlist(tr$resumen$mas_ganaron_participacion), "\n")
th <- json(g$mostrar_tabla("historia", meses = "12"))
tc <- json(g$mostrar_tabla("composicion"))
stopifnot(th$filas == 12, tc$filas == 17, identical(antes, isolate(lapply(ev, function(x) x()))))

# Varias cuentas de un banco: gráfico y tabla
n_antes <- length(ventanas)
gcu <- json(g$mostrar_grafico("cuentas", bancos = "BCI", cuentas = c("Colocaciones", "Depósitos a plazo")))
stopifnot(length(ventanas) == n_antes + 1, ventanas[[n_antes + 1]]$clase == "highchart",
          gcu$banco == "BCI", length(gcu$resumen) == 2, grepl("^Colocaciones: MM\\$", gcu$resumen[[1]]))
gci <- json(g$mostrar_grafico("cuentas", bancos = "BCI", cuentas = c("Activos totales", "Patrimonio"),
                              medida = "indice", meses = "12"))
stopifnot(grepl("^Activos totales: 100,0 →", gci$resumen[[1]]))
tcu <- json(g$mostrar_tabla("cuentas", banco = "BCI", cuentas = c("Colocaciones", "Depósitos a plazo"),
                            medida = "participacion"))
stopifnot(ventanas[[length(ventanas)]]$clase == "reactable", nrow(ventanas[[length(ventanas)]]$csv) == 24,
          ncol(ventanas[[length(ventanas)]]$csv) == 3)
n_antes <- length(ventanas)
stopifnot(falla(g$mostrar_grafico("cuentas", cuentas = "Colocaciones")), length(ventanas) == n_antes,
          identical(antes, isolate(lapply(ev, function(x) x()))))
cat("Cuentas de BCI:", unlist(gcu$resumen), "\n")

# SQL de solo lectura
q <- json(g$consultar_datos(paste("SELECT banco, total_mm FROM balance WHERE cuenta = '144000000'",
                                  "AND periodo = '202609' AND banco <> 'Sistema' ORDER BY total_mm DESC")))
stopifnot(q$filas == 17, q$datos[[1]]$banco == "BCI")
stopifnot(falla(g$consultar_datos("DELETE FROM balance")), falla(g$consultar_datos("SELECT 1; SELECT 2")),
          falla(g$consultar_datos("SELECT * FROM otra_tabla")),
          json(g$consultar_datos("SELECT * FROM balance"))$filas == 200,
          DBI::dbGetQuery(con, "SELECT COUNT(*) AS n FROM balance")$n == nrow(balance))
DBI::dbDisconnect(con, shutdown = TRUE)

# Las definiciones se registran en un chat sin llamar al modelo
chat <- ellmer::chat_anthropic(model = "claude-opus-5-5", credentials = function() "sin-uso", echo = "none")
for (t in definir_tools(g, ctx)) chat$register_tool(t)
stopifnot(setequal(names(chat$get_tools()), c("listar_opciones", "ver_analisis", "seleccionar_analisis",
                                               "comparar", "mostrar_grafico", "mostrar_tabla",
                                               "consultar_datos")))

cat("Todas las pruebas de tools pasaron.
")
