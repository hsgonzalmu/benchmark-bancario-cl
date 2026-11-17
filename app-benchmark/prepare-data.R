# Prepara data/balance.rds con el Balance Mensual de bancos de la API CMF (v3).
# Uso, desde app-benchmark/: Rscript prepare-data.R
# Requiere CMF_API_KEY en app-benchmark/.Renviron (o en ~/.Renviron).

key <- Sys.getenv("CMF_API_KEY")
if (!nzchar(key)) {
  stop(
    "Falta CMF_API_KEY. Crea app-benchmark/.Renviron con la línea CMF_API_KEY=<tu key> ",
    "(se obtiene en https://api.cmfchile.cl/uso-de-api-key.html).",
    call. = FALSE
  )
}

cuentas <- read.csv(file.path("data", "cuentas.csv"), colClasses = "character", encoding = "UTF-8")
instituciones <- read.csv(file.path("data", "instituciones.csv"), colClasses = "character",
                          encoding = "UTF-8")
anio_actual <- as.integer(format(Sys.Date(), "%Y"))
anios <- (anio_actual - 3):anio_actual

# descarga ----------------------------------------------------------------
# IPv4 forzado: la resolución IPv6 de api.cmfchile.cl no responde desde algunas redes.
descargar <- function(anio, cuenta) {
  url_api <- sprintf(
    "https://api.cmfchile.cl/api-sbifv3/recursos_api/balances/%d/cuentas/%s?apikey=%s&formato=json",
    anio, cuenta, key
  )
  for (intento in 1:4) {
    h <- curl::new_handle(timeout = 120, connecttimeout = 30, ipresolve = 1L)
    r <- tryCatch(curl::curl_fetch_memory(url_api, handle = h), error = function(e) NULL)
    if (!is.null(r) && r$status_code == 200) {
      return(jsonlite::fromJSON(rawToChar(r$content))$CodigosBalances)
    }
    if (!is.null(r) && r$status_code == 404) return(NULL) # código 80: sin datos para ese año
    if (intento < 4) Sys.sleep(2^intento)
  }
  estado <- if (is.null(r)) "error de red" else paste("HTTP", r$status_code)
  stop(sprintf("No se pudo descargar la cuenta %s del año %d (%s).", cuenta, anio, estado), call. = FALSE)
}

a_numero <- function(x) as.numeric(sub(",", ".", x, fixed = TRUE))

partes <- list()
for (cuenta in cuentas$cuenta) {
  for (anio in anios) {
    df <- descargar(anio, cuenta)
    cat(sprintf("cuenta %s · %d: %d filas\n", cuenta, anio, if (is.null(df)) 0L else nrow(df)))
    if (is.null(df) || !nrow(df)) next
    partes[[paste(cuenta, anio)]] <- data.frame(
      periodo = sprintf("%s%02d", df$Anho, as.integer(df$Mes)),
      cod_ifi = df$CodigoInstitucion,
      nombre_api = df$NombreInstitucion,
      cuenta = df$CodigoCuenta,
      clp = a_numero(df$MonedaChilenaNoReajustable),
      ipc = a_numero(df$MonedaReajustablePorIPC),
      tc = a_numero(df$MonedaReajustablePorTipoDeCambio),
      mx = a_numero(df$MonedaExtranjera),
      total = a_numero(df$MonedaTotal)
    )
  }
}
balance <- do.call(rbind, partes)
rownames(balance) <- NULL
balance$fecha <- as.Date(paste0(balance$periodo, "01"), "%Y%m%d")

# instituciones -----------------------------------------------------------
ultimo <- balance[order(balance$periodo, decreasing = TRUE), c("cod_ifi", "nombre_api")]
nombres_api <- ultimo[!duplicated(ultimo$cod_ifi), ]
nombres_api$nombre_api[nombres_api$cod_ifi == "999"] <- "TOTAL SISTEMA FINANCIERO"
balance$nombre_api <- NULL

# calidad -----------------------------------------------------------------
cat("\n== Reporte de calidad ==\n")
cat("Períodos:", min(balance$periodo), "a", max(balance$periodo), "·", nrow(balance), "filas\n")

sin_ficha <- setdiff(nombres_api$cod_ifi, instituciones$cod_ifi)
if (length(sin_ficha)) {
  pendientes <- nombres_api[nombres_api$cod_ifi %in% sin_ficha, ]
  cat("Códigos sin ficha en data/instituciones.csv (se usará el nombre de la API):\n")
  cat(paste0("  ", pendientes$cod_ifi, " ", pendientes$nombre_api), sep = "\n")
} else {
  cat("Todas las instituciones tienen ficha.\n")
}

bancos <- balance[balance$cod_ifi != "999", ]
suma <- aggregate(total ~ cuenta + periodo, data = bancos, FUN = sum)
sistema <- balance[balance$cod_ifi == "999", c("cuenta", "periodo", "total")]
control <- merge(suma, sistema, by = c("cuenta", "periodo"), suffixes = c("_bancos", "_sistema"))
control$dif_pct <- 100 * (control$total_bancos / control$total_sistema - 1)
fuera <- control[is.finite(control$dif_pct) & abs(control$dif_pct) > 0.5, ]
if (nrow(fuera)) {
  cat("Diferencias mayores a 0,5 % entre la suma de bancos y el total del sistema:\n")
  print(fuera[order(fuera$cuenta, fuera$periodo), ], row.names = FALSE)
} else {
  cat("La suma de bancos cuadra con el total del sistema (tolerancia 0,5 %).\n")
}

# guardado ----------------------------------------------------------------
attr(balance, "descargado") <- Sys.Date()
attr(balance, "nombres_api") <- nombres_api
temporal <- file.path("data", "balance.rds.tmp")
saveRDS(balance, temporal)
invisible(file.rename(temporal, file.path("data", "balance.rds")))
cat(paste0("\nGuardado data/balance.rds (descargado el ", format(Sys.Date()), ")\n"))
