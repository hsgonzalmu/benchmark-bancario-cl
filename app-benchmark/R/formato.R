# Formato chileno de montos, porcentajes y períodos.

meses_es <- c("ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic")

etiqueta_periodo <- function(periodo) {
  paste(meses_es[as.integer(substr(periodo, 5, 6))], substr(periodo, 1, 4))
}

numero_cl <- function(x, decimales = 0) {
  formatC(x, format = "f", digits = decimales, big.mark = ".", decimal.mark = ",")
}

# Millones de pesos con la notación de la CMF: "MM$ 4.945.269"; bajo MM$ 10, con un decimal ("MM$ 2,5").
monto_corto <- function(x) {
  if (is.na(x)) return("N/A")
  millones <- x / 1e6
  paste0("MM$ ", numero_cl(millones, if (abs(millones) < 10) 1 else 0))
}

# Millones de pesos con separador de miles, para tablas y ejes.
monto_mm <- function(x) ifelse(is.na(x), "N/A", numero_cl(x / 1e6, 0))

porcentaje <- function(x, decimales = 1, signo = FALSE) {
  x <- ifelse(!is.na(x) & round(100 * x, decimales) == 0, 0, x) # evita "-0,00 %"
  txt <- numero_cl(100 * x, decimales)
  if (signo) txt <- ifelse(x > 0, paste0("+", txt), txt)
  ifelse(is.na(x), "N/A", paste0(txt, " %"))
}

# Diferencia entre dos porcentajes en puntos base, como se cita en finanzas (1 pp = 100 pb). Recibe puntos
# porcentuales: puntos_base(3.42, signo = TRUE) es "+342 pb". Sin decimales; evita "-0 pb".
puntos_base <- function(pp, signo = FALSE) {
  pb <- round(100 * pp)
  pb[!is.na(pb) & pb == 0] <- 0
  txt <- paste(numero_cl(pb), "pb")
  if (signo) txt <- ifelse(!is.na(pb) & pb > 0, paste0("+", txt), txt)
  ifelse(is.na(pp), "N/A", txt)
}
