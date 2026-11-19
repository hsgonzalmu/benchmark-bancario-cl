## Why

En Brecha, "distancia al superior" y "ventaja sobre el inferior" se dibujaban ambas en positivo y costaba
leer qué era falta y qué ventaja. En Base 100 el índice partía siempre en el primer mes de la ventana
(hace 2 años), aunque a menudo interesa el último año o el último trimestre.

## What Changes

- Brecha (vecinos y bancos): otro banco menos el analizado. El cero es el analizado (línea marcada con
  su nombre); arriba, en positivo, lo que le falta para alcanzar al de arriba; abajo, en negativo, su
  ventaja sobre el de abajo. Áreas transparentes hacia el cero, en el color del otro banco, con su nombre
  al final de la línea y una nota que explica la lectura. Si una curva cruza el cero, hubo adelantamiento.
- Base 100: botones "Desde hace 3 meses · 12 meses · 24 meses" (12 por defecto). El índice vale 100 en
  ese mes (`rebasar_indice()`) y el gráfico muestra solo desde ahí.

## Impact

- `R/graficos.R` (`grafico_brecha`), `R/ranking.R` (`rebasar_indice`), `app.R`, `www/styles.css`,
  `tests/test-ranking.R`, spec `dashboard-benchmark`.
- Estado reactivo: nuevo input `base_desde` (solo lo cambia el usuario). Tools sin cambios.
