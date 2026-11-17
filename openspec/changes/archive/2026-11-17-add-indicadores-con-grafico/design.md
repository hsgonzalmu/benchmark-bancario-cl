# Design

## Context

Los indicadores se construyen en `R/componentes.R` (`caja_participacion()` y `caja_puesto()`) con
`bslib::value_box()`, junto a la escalera en `layout_columns(col_widths = c(8, 4))`. Las series ya
existen: `serie_bancos()` y `puestos_en_el_tiempo()` (en `R/modales.R` y `R/ranking.R`), y el total del
sistema sale de `valor_monedas()` sobre el código `999`.

## Goals / Non-Goals

**Goals:**
- Total del sistema como cifra principal y tendencia visible en ambos indicadores.
- Gráficos pequeños con tooltip, legibles al lado de la cifra.

**Non-Goals:**
- Cambiar paleta o tipografía (pendientes).
- Nuevos indicadores.

## Decisions

**Gráficos pequeños con highcharter** (`grafico_mini_sistema()` y `grafico_mini_puesto()` en
`R/graficos.R`): sin ejes visibles, sin leyenda ni créditos, márgenes mínimos, tooltip con mes y valor, y
el último punto marcado. Los diseños de `showcase` de bslib ponen el gráfico a la izquierda o arriba, así
que cada indicador se arma como una tarjeta propia con una grilla de dos columnas: texto a la izquierda
y gráfico a la derecha. Así controlamos el ancho y la alineación.

- Sistema: área de 24 meses del total del sistema en el gris oscuro del sistema (`colores[["sistema"]]`),
  en miles de millones de $ en el tooltip.
- Puesto: línea en escalones (`step`) con el eje Y invertido, color del banco analizado; el tooltip
  muestra "9°".

**Etiquetas de variación.** Las variaciones mensual y en 12 meses van como etiquetas redondeadas de
fondo suave, verde o rojo según el signo, con flecha; el color nunca va solo (signo y flecha).

**Proporción.** La fila pasa a `col_widths = c(7, 5)` en pantallas grandes; en pantallas angostas todo se
apila y el gráfico queda a la derecha de la cifra mientras haya ancho, o debajo si no cabe.

**Datos.** `serie_sistema(datos, cuenta, periodo, monedas, meses)` en `R/ranking.R` devuelve la serie
del total del sistema; el puesto reutiliza `puestos_en_el_tiempo()` con el banco analizado. Todo sigue la
cuenta y la selección de monedas.

## Risks / Trade-offs

- [Varios widgets pequeños más en la página] → Son dos, con pocos puntos; el costo es menor.
- [Escalera más angosta] → Se revisa con capturas que los montos y brechas no se corten a 1440 px.
