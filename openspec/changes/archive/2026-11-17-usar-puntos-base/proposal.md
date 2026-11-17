## Why

Las diferencias de participación se mostraban en puntos porcentuales ("+3,42 pp"). En finanzas se citan
en puntos base ("+342 pb"): es la unidad que espera un analista y evita decimales en cambios pequeños
("−9 pb" en vez de "−0,09 pp").

## What Changes

- Toda diferencia o cambio de participación se muestra en pb, sin decimales (1 pp = 100 pb): indicadores,
  brechas de la escalera, Brecha y Posición 12m, ventanas de crecimiento y tabla de ranking 12m (pantalla
  y CSV).
- Las participaciones siguen en % (13,1 %) y las variaciones de montos también (+1,6 % m/m).
- Las tools entregan esas diferencias en pb y el prompt pide citarlas así.
- Nuevo formateador `puntos_base()` en `R/formato.R`; los cálculos internos no cambian.

## Impact

- `R/formato.R`, `R/componentes.R`, `R/graficos.R`, `R/modales.R`, `R/tools.R`, `prompt.md`, README,
  specs `dashboard-benchmark`, `ranking-bancos` y `chat-analista`.
- Tools: mismas tools y argumentos; cambia el texto de `escalera.brechas[].participacion`,
  `participacion_hace_12_meses` y las brechas de `comparar` ("39 pb" en vez de "0,39 pp").
- Estado reactivo: sin cambios.
