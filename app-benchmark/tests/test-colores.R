# Pruebas de la paleta por banco (data/instituciones.csv, columna color).
# Uso, desde app-benchmark/: Rscript tests/test-colores.R   (tarda alrededor de un minuto)

for (f in c("ranking.R", "tema.R")) source(file.path("R", f))
datos <- readRDS(file.path("data", "balance.rds"))
fichas <- read.csv(file.path("data", "instituciones.csv"), colClasses = "character", encoding = "UTF-8")
usar_colores_bancos(fichas)

# Un color único y válido por institución
bancos <- setdiff(fichas$cod_ifi, "999")
stopifnot(all(grepl("^#[0-9A-F]{6}$", fichas$color)), !anyDuplicated(fichas$color))

# El cálculo de separación coincide con el validador de la guía de visualización (19,4 normal; 9,3 protan)
s <- separacion_colores("#2bacf5", "#cd86bc")
stopifnot(abs(s[["normal"]] - 19.6) < 0.2, abs(s[["daltonismo"]] - 9.3) < 0.2)

# Todo banco se distingue del gris de contexto y del gris oscuro del sistema
for (cod in bancos) {
  stopifnot(!colores_parecidos(color_banco(cod), colores[["resto"]]),
            !colores_parecidos(color_banco(cod), colores[["sistema"]]))
}

# En toda escalera de Total, tras aplicar el refuerzo, no quedan dos bancos con trazo continuo y color
# parecido
ventanas <- list()
for (cta in unique(datos$cuenta)) for (p in unique(datos$periodo)) {
  rk <- calcular_ranking(datos, cta, p, "total")
  for (f in rk$cod_ifi) {
    w <- ventana_escalera(rk, f)$cod_ifi
    ventanas[[paste(f, paste(w, collapse = "-"))]] <- c(f, setdiff(w, f)) # foco primero
  }
}
reforzadas <- 0
for (w in ventanas) {
  trazo <- trazos_bancos(w)
  continuos <- w[trazo == "Solid"]
  if (any(trazo == "Dash")) reforzadas <- reforzadas + 1
  if (length(continuos) > 1) {
    pares <- utils::combn(continuos, 2)
    stopifnot(!any(apply(pares, 2, function(x) colores_parecidos(color_banco(x[1]), color_banco(x[2])))))
  }
}
cat(sprintf("Escaleras revisadas: %d · con refuerzo punteado: %d (%.0f %%)\n",
            length(ventanas), reforzadas, 100 * reforzadas / length(ventanas)))
cat("Todas las pruebas de colores pasaron.\n")
