# Design

## Context

El dashboard (fases 1 y 2, archivadas) colorea por rol (`colores[rol]` en `R/tema.R`), muestra tres
cajas de banco más la participación conjunta (`caja_banco()`, `caja_participacion()` en
`R/componentes.R`) y arma la tabla con `tabla_ranking()` en `R/graficos.R`. La maqueta visual aprobada
es la página "Competidores directos" (13-11-2026), hecha con datos reales.
Datos verificados el 13-11-2026:
- `clp + ipc + tc + mx` es igual a `total` en las 8.921 filas.
- 366 filas tienen signos mezclados, casi todas en Patrimonio (300000000).
- BICE se fusionó con Security en oct 2025 (el ranking pasa de 18 a 17 bancos en nov 2025).

## Goals / Non-Goals

**Goals:**
- Responder "cuánto me falta y cuánto me sacan" sin que el usuario haga cálculos.
- Que cada banco se pueda seguir por su color entre consultas y gráficos.
- Mostrar la composición por moneda sin ensanchar la tabla.

**Non-Goals:**
- Modales del chat y gráfico de puestos en el tiempo (fase 3).
- Tema oscuro de la app.
- Recalcular datos o tocar `prepare-data.R`.

## Decisions

**Cálculos puros en `R/ranking.R`.** `ventana_escalera(rk, foco)` devuelve las 5 filas (desplazadas en los
extremos). `escalera(datos, cuenta, periodo, tipo_valor, foco)` agrega a cada fila su serie de
participación de los últimos 12 meses y a cada par su brecha actual, la de hace 12 meses y la
tendencia. `cambio_puesto()` y `composicion()` completan el conjunto. Todas se prueban en
`tests/test-ranking.R` y las reutiliza el resumen del chat, así que el chat y la pantalla dicen lo mismo.

**Color por banco en `data/instituciones.csv`.** Nueva columna `color` (hex). `R/tema.R` expone
`color_banco(cod)`, con gris para bancos sin color y gris oscuro para el sistema. Se dejan de usar los
colores por rol como identidad: el foco se destaca por grosor de línea (4 frente a 2,5), negrita y un
fondo azul marino neutro en la escalera y la tabla. Los 18 colores se eligen cargando la skill `dataviz`
(paleta categórica, contraste sobre blanco, distinguibles del gris de contexto), tomando como referencia
el color de marca de un banco solo cuando no choca con un vecino habitual (Santander rojo, Falabella
verde, Ripley morado, BancoEstado naranjo). `tests/test-colores.R` comprueba que, en toda ventana de 5
filas de toda cuenta y mes, los colores son distintos y tienen una distancia perceptual mínima (ΔE ≥ 15
en CIELAB). Alternativa: paleta de 5 posiciones según el lugar en la ventana (siempre distinguible, pero
un banco cambiaría de color entre consultas, que es justo lo que este cambio evita).

**Escalera como HTML, no como gráfico.** Filas y brechas construidas con `htmltools` en
`R/componentes.R`. La línea de 12 meses es un SVG pequeño generado en R (`sparkline_svg()`), sin
dependencias, igual que en la maqueta. En pantallas angostas la grilla se apila con CSS
(`@media (max-width: 640px)`). Va en un `layout_columns(col_widths = c(8, 4))` junto a los dos
indicadores.

**Pestaña "Posición 12m" con `dumbbell` de highcharter.** El módulo `modules/dumbbell.js` viene con
highcharter (`hc_add_dependency("modules/dumbbell.js")`). El conjunto de bancos sigue el modo: escalera
(vecinos), foco + líder (lider), foco + bancos elegidos (bancos), todos los bancos (sistema). Los bancos
sin dato hace 12 meses van como punto `scatter`, con una nota en el tooltip.

**Composición en reactable.** Columna `Composición` con una barra apilada al 100 % hecha de `div`s (4
segmentos), más `details` con una tabla chica de los 4 montos y %. Las 4 monedas usan una paleta propia
y apagada (azul marino, azul acero, arena, gris), separada de la de bancos para que no parezca un banco.
Con signos mixtos, la celda dice "signos mixtos" en gris y el detalle muestra los montos con su signo. La
composición es siempre la del total, aunque el tipo de valor sea otro, porque describe cómo se forma la
cuenta.

**Indicador de puesto.** "9° de 17", "▲ 2 puestos" (verde), "▼" (rojo) o "=" (gris). Cuando cambió el
conjunto de bancos, agrega quién salió (con su puesto de entonces) o entró: "salió Security (estaba 8°),
entró Tanner". La cantidad sola no basta: en sep 2025 y sep 2026 hay 17 bancos, pero Internacional sube
un puesto porque sale Security, que estaba arriba, y otro porque supera a Falabella.

**Resumen del chat.** `resumen_para_chat()` agrega `escalera` (filas y brechas con tendencia),
`puesto_hace_12_meses` y `composicion`. El prompt explica cómo leer la tendencia y que un cambio en la
cantidad de bancos puede explicar un cambio de puesto.

## Risks / Trade-offs

- [18 colores distinguibles es difícil] → Solo se muestran juntos los 5 de la ventana (más el gris y el
  sistema); la prueba de colores exige distancia donde de verdad coinciden, no entre los 18.
- [La escalera ocupa más alto que las cajas] → Va en una fila 8/4 junto a los indicadores, y las filas
  ±2 van atenuadas para dejar el peso visual en el foco.
- [Composición con signos mixtos] → Texto explícito "signos mixtos" en vez de una barra engañosa.
- [Resumen del chat más largo] → La escalera son 5 filas y 4 brechas; suma unos 600 tokens por llamada.

## Open Questions

- La paleta final se presenta al usuario en una captura de la escalera y el ranking antes de cerrarla;
  se puede ajustar sin cambiar las specs.
