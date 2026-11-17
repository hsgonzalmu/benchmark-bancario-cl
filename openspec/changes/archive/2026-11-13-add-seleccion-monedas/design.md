# Design

## Context

Hoy `tipo_valor` es un solo texto (`"total"`, `"clp"`, `"ipc"`, `"tc"` o `"mx"`) que las funciones de
`R/ranking.R` usan como nombre de columna (`datos[[tipo_valor]]`). La composición (`composicion()`) usa
siempre las cuatro monedas. En los datos, `clp + ipc + tc + mx` es exactamente `total` en las 8.921 filas,
así que cualquier selección se obtiene sumando columnas.

## Goals / Non-Goals

**Goals:**
- Que cualquier combinación de monedas recalcule todo de forma consecuente: ranking, escalera, brechas,
  puesto, series, pesas, tabla, composición y chat.
- Un solo punto donde se calcula el monto de una selección.

**Non-Goals:**
- Cambiar la paleta de bancos (se dejó para más adelante).
- Agregar monedas o cuentas nuevas.

## Decisions

**Selección como vector de códigos.** `monedas` es un vector con uno o más de `c("clp", "ipc", "tc",
"mx")`, siempre en ese orden. Las cuatro juntas equivalen a Total. Se descarta mantener `"total"` como
valor aparte: con el vector completo basta y evita casos especiales.

**Un solo cálculo del monto: `valor_monedas(datos, monedas)`.** Devuelve `rowSums(datos[, monedas, drop =
FALSE])`. Reemplaza todos los `datos[[tipo_valor]]` de `R/ranking.R` (`montos_periodo()`,
`series_comparacion()`, `escalera()`) y aplica igual al sistema (código `999`), así la participación se
calcula sobre la misma selección. Los parámetros `tipo_valor` de las funciones pasan a llamarse `monedas`.

**Nombres en un solo lugar.** `etiquetas_moneda` (código → nombre) pasa de `R/tema.R` a `R/ranking.R`,
porque es dominio y la usan las tools. `etiqueta_monedas(monedas)` arma el nombre de la selección:
"Total" (4), el nombre (1), "Total sin <moneda en minúscula>" (3) o "A y B" (2). Reemplaza al vector
`tipos_valor`.

**Composición sobre la selección.** `composicion(datos, cuenta, periodo, monedas)` calcula los
porcentajes sobre la suma de las monedas elegidas y marca signos mixtos solo entre ellas. La tabla, su
leyenda y el detalle muestran solo las monedas elegidas.

**Casillas en Filtros.** `checkboxGroupInput("monedas", ...)` con las cuatro opciones y un
`actionLink("monedas_total", "Total")` que marca todas. Si el usuario desmarca la última, un observador
vuelve a marcarla con `updateCheckboxGroupInput()` y muestra `showNotification("Elige al menos una
moneda")`; el `reactiveVal` no cambia. La sincronización con el chat sigue el patrón actual (escribir el
mismo valor no invalida).

**Tool.** `seleccionar_analisis()` cambia `tipo_valor` por `monedas = type_array(type_enum(nombres),
required = FALSE)`. Una lista vacía falla con mensaje claro. El resumen informa `monedas` con
`etiqueta_monedas()`, y `listar_opciones()` devuelve las cuatro monedas. El prompt explica que "sin
moneda extranjera" son las otras tres y que "Total" son las cuatro.

## Risks / Trade-offs

- [Renombrar `tipo_valor` toca muchos archivos] → Las tres suites de pruebas cubren ranking, tools y
  colores; se corren después del cambio y se agregan casos de selección parcial.
- [Selecciones con montos casi en cero, como solo TC] → La app ya maneja escalas chicas (MM$ con decimal
  y ejes en millones) y signos mixtos.
- [El chat podría seguir enviando `tipo_valor`] → El esquema de la tool ya no lo acepta; el prompt se
  actualiza en el mismo cambio.
