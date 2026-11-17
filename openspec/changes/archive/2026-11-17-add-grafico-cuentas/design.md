# Design

## Context

`mostrar_grafico()` y `mostrar_tabla()` (en `R/tools.R`) leen la cuenta del estado y no tienen forma de
recibir otras. Los constructores de ventanas están en `R/modales.R` y los cálculos en `R/ranking.R`.

## Goals / Non-Goals

**Goals:**
- Un gráfico y una tabla de varias cuentas para un banco, con medidas comparables entre cuentas de
  distinto tamaño.
- Saludo útil para cualquier usuario, sin bancos fijos.

**Non-Goals:**
- Varias cuentas de varios bancos a la vez (se resuelve con dos preguntas o con SQL).
- Ratios entre cuentas (por ejemplo, colocaciones sobre depósitos).
- Cambiar la paleta de bancos (en pausa).

## Decisions

**Cálculo `serie_cuentas(datos, cod, cuentas, periodo, monedas, meses)`** en `R/ranking.R`: devuelve
período, fecha, cuenta, monto, participación sobre el sistema en esa cuenta e índice base 100 (primer mes
con monto distinto de cero). Reutiliza `valor_monedas()` y `periodos_ventana()`.

**Medidas.** `monto` (miles de millones de $, o millones si son chicos), `indice` (base 100) y
`participacion` (%). Un solo eje: no se usa doble eje, porque la guía de visualización lo desaconseja.
El índice resuelve la diferencia de tamaño entre cuentas.

**Color por cuenta.** Las cuentas no son bancos: usan los seis primeros colores de la paleta categórica
de referencia de la guía de visualización (`#2a78d6`, `#eb6834`, `#1baf7a`, `#eda100`, `#e87ba4`,
`#008300`), validada para series adyacentes, con leyenda y nombre de cuenta en el tooltip. Se asignan en
el orden en que se piden las cuentas. Como en un gráfico de líneas todas las parejas se ven juntas y la
guía valida solo los tres primeros colores para todas las parejas, desde la cuarta cuenta la línea va
punteada como codificación secundaria. La tabla equivalente (`mostrar_tabla`) cubre el aviso de
contraste de los colores claros.

**Argumentos.** `cuentas` es `type_array(type_enum(nombres de cuentas))`; `medida` es `type_enum(c("monto",
"indice", "participacion"))`, por defecto `monto`. En `mostrar_grafico`, el banco sale de `bancos[1]` o
del analizado; en `mostrar_tabla` se agrega `banco` (opcional). Se valida 2 a 6 cuentas con `stop()`.

**Resumen al modelo.** Por cuenta: valor inicial y final en la medida elegida y variación del monto en
la ventana.

**Saludo.** Cuatro sugerencias genéricas:
- "¿Qué banco lidera en colocaciones y cuánto le saca al segundo?"
- "¿Qué banco creció más en colocaciones en los últimos 12 meses?"
- "¿Qué bancos ganaron más participación en depósitos a la vista en el último año?"
- "Muéstrame la evolución de colocaciones y depósitos a plazo del líder del sistema"

El prompt indica cómo resolver "el líder" o "el que más creció" sin un banco nombrado: con el ranking
de `ver_analisis` o con `mostrar_grafico(tipo = "crecimiento")`.

## Risks / Trade-offs

- [Monto de cuentas muy distintas en un eje] → La descripción de la tool y el prompt sugieren `indice`
  cuando las cuentas difieren mucho.
- [Seis colores de cuentas junto a colores de bancos en otras ventanas] → Las cuentas solo aparecen en su
  propio gráfico; no se mezclan con bancos.
