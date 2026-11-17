## ADDED Requirements

### Requirement: Diferencias de participación en puntos base
Toda diferencia o cambio entre participaciones SHALL mostrarse en puntos base (pb), sin decimales, con
signo cuando es un cambio (1 pp = 100 pb). Las participaciones y las variaciones de montos SHALL seguir en
porcentaje.

#### Scenario: Indicador de participación conjunta
- **WHEN** la participación conjunta pasa de 9,68 % a 13,1 % en 12 meses
- **THEN** el indicador muestra "13,1 %" y "▲ +342 pb 12m"

#### Scenario: Brecha en la escalera
- **WHEN** Consorcio tiene 0,39 puntos porcentuales más de participación que Internacional
- **THEN** la brecha se lee "te faltan MM$ 1.086.485 · 39 pb"

#### Scenario: Cambio pequeño
- **WHEN** la participación cambia −0,004 puntos porcentuales en el mes
- **THEN** se muestra "= 0 pb m/m", no "-0 pb"

#### Scenario: Tabla descargable
- **WHEN** se descarga el CSV de `mostrar_tabla(tipo = "ranking")`
- **THEN** la columna se llama "Cambio de participación (pb)" y trae enteros
