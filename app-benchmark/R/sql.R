# Base DuckDB en memoria para la tool consultar_datos: una tabla `balance` legible, en millones de pesos,
# sin acceso a archivos ni red.

crear_base_sql <- function(balance, fichas, cuentas) {
  nombre <- fichas$nombre_corto[match(balance$cod_ifi, fichas$cod_ifi)]
  nombre[balance$cod_ifi == "999"] <- "Sistema"
  i <- match(balance$cuenta, cuentas$cuenta)
  tabla <- data.frame(
    periodo = balance$periodo, fecha = balance$fecha, cod_ifi = balance$cod_ifi, banco = nombre,
    cuenta = balance$cuenta, cuenta_nombre = cuentas$nombre[i], grupo = cuentas$grupo[i],
    clp_mm = balance$clp / 1e6, ipc_mm = balance$ipc / 1e6, tc_mm = balance$tc / 1e6,
    mx_mm = balance$mx / 1e6, total_mm = balance$total / 1e6
  )
  con <- DBI::dbConnect(duckdb::duckdb(shared_home = FALSE), dbdir = ":memory:")
  DBI::dbWriteTable(con, "balance", tabla)
  DBI::dbExecute(con, "SET enable_external_access = false")
  con
}

validar_select <- function(consulta) {
  consulta <- trimws(consulta)
  if (!grepl("^(SELECT|WITH)\\b", consulta, ignore.case = TRUE)) stop("Solo se permiten consultas SELECT.")
  if (!grepl("\\bbalance\\b", consulta, ignore.case = TRUE)) stop("La consulta debe usar la tabla balance.")
  if (grepl(";", consulta, fixed = TRUE)) stop("Envía una sola consulta y no incluyas punto y coma.")
  if (grepl("\\b(INSERT|UPDATE|DELETE|DROP|ALTER|CREATE|ATTACH|COPY|INSTALL|LOAD|PRAGMA|SET)\\b",
            consulta, ignore.case = TRUE)) {
    stop("Solo se permiten consultas SELECT.")
  }
  consulta
}

# Ejecuta la consulta con un tope de 200 filas.
consultar_sql <- function(con, consulta) {
  consulta <- validar_select(consulta)
  DBI::dbGetQuery(con, paste0("SELECT * FROM (", consulta, ") AS consulta LIMIT 200"))
}
