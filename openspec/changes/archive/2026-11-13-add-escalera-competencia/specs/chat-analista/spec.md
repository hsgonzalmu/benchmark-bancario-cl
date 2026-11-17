# Spec Delta

## MODIFIED Requirements

### Requirement: Resumen del análisis
El resumen que devuelven las tools SHALL incluir banco, cuenta, período, tipo de valor y modo; posición,
monto, participación, variación mensual y en 12 meses del banco; los mismos datos del vecino superior,
del inferior y del líder; la participación conjunta; el total del sistema; el ranking completo de la
cuenta; la escalera con sus brechas y tendencias; el puesto hace 12 meses con la cantidad de bancos de
ambos períodos; y la composición del banco analizado por moneda. Montos y porcentajes SHALL ir ya
formateados en formato chileno.

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
