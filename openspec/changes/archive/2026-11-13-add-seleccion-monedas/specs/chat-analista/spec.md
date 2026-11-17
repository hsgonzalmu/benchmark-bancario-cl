# Spec Delta

## MODIFIED Requirements

### Requirement: Tool seleccionar_analisis
La tool `seleccionar_analisis(banco, cuenta, periodo, monedas)` SHALL aceptar cada argumento como
opcional y limitado a los valores disponibles (`monedas` es una lista de una a cuatro monedas), actualizar
solo los que se entreguen y devolver el resumen del análisis resultante. Sin argumentos, o con `monedas`
vacía, SHALL fallar con un mensaje claro.

#### Scenario: Cambiar solo la cuenta
- **WHEN** el análisis es BCI en Colocaciones y el usuario pide "ahora en depósitos a plazo"
- **THEN** la tool recibe solo `cuenta = "Depósitos a plazo"`, el banco sigue siendo BCI y el dashboard
  muestra depósitos a plazo

#### Scenario: Banco sin datos en el período
- **WHEN** se selecciona Security en sep 2026
- **THEN** el dashboard muestra el aviso de sin datos y el resumen indica que no hay datos y su último
  período disponible (oct 2025), para que el chat lo ofrezca

#### Scenario: Sin moneda extranjera
- **WHEN** el usuario pide "analiza BCI sin considerar moneda extranjera"
- **THEN** la tool recibe `monedas` con CLP no reajustable, reajustable IPC y reajustable TC, el dashboard
  y los filtros muestran esa selección y la respuesta usa los montos recalculados

#### Scenario: Solo IPC
- **WHEN** el usuario pide "muéstrame solo lo reajustable por IPC de Itaú"
- **THEN** la tool recibe `banco = "Itaú"` y `monedas` con solo reajustable IPC

### Requirement: Resumen del análisis
El resumen que devuelven las tools SHALL incluir banco, cuenta, período, monedas elegidas y modo; posición,
monto, participación, variación mensual y en 12 meses del banco; los mismos datos del vecino superior,
del inferior y del líder; la participación conjunta; el total del sistema; el ranking completo de la
cuenta; la escalera con sus brechas y tendencias; el puesto hace 12 meses con la cantidad de bancos de
ambos períodos; y la composición del banco analizado en las monedas elegidas. Montos y porcentajes SHALL ir
ya formateados en formato chileno.

#### Scenario: Pregunta por posición
- **WHEN** el usuario pregunta "¿cómo está Internacional en colocaciones?"
- **THEN** el chat llama a `seleccionar_analisis(banco = "Internacional", cuenta = "Colocaciones")`, el
  dashboard se actualiza y la respuesta da puesto, monto, participación y variación mensual tal como
  vienen en el resumen

#### Scenario: Pregunta por el líder
- **WHEN** el usuario pregunta "¿quién lidera depósitos a plazo y cuánto le falta a Consorcio?"
- **THEN** el chat selecciona Consorcio en Depósitos a plazo, compara con el líder y responde con el
  nombre del líder y la brecha de monto y participación

#### Scenario: Pregunta por la brecha con el vecino
- **WHEN** el usuario pregunta "¿Internacional se está acercando a Consorcio?"
- **THEN** el chat responde con la brecha de hoy, la de hace 12 meses y la tendencia tal como vienen en
  la escalera del resumen

#### Scenario: Pregunta por la composición
- **WHEN** el usuario pregunta "¿cuánto de las colocaciones de BCI está en moneda extranjera?"
- **THEN** el chat responde con el monto y el porcentaje en moneda extranjera de la composición del
  resumen

#### Scenario: Selección de monedas en el resumen
- **WHEN** las monedas elegidas son CLP no reajustable, reajustable IPC y reajustable TC
- **THEN** el resumen indica "Total sin moneda extranjera" y todas sus cifras corresponden a esa selección
