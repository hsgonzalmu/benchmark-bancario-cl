## ADDED Requirements

### Requirement: Escalera con todo el ranking
La escalera SHALL listar todos los bancos del ranking en un área con scroll que no cambia la altura de la
tarjeta. Los 5 competidores SHALL verse destacados por igual y con sus brechas; los demás SHALL verse en filas
compactas y pálidas, sin brechas. Clic en cualquier banco que no sea el analizado SHALL seleccionarlo.

#### Scenario: Banco del medio
- **WHEN** se analiza Internacional (9° de 17)
- **THEN** la escalera abre desplazada para mostrar los puestos 7 a 11 con sus brechas, y con scroll se
  ven del 1° al 6° y del 12° al 17° en filas pálidas

#### Scenario: Seleccionar desde la escalera
- **WHEN** el usuario hace clic en la fila pálida de Santander
- **THEN** Santander pasa a ser el banco analizado y el filtro Banco se actualiza

#### Scenario: Mismos 5 que el indicador
- **WHEN** se analiza Consorcio (8°)
- **THEN** los puestos 6 a 10 se ven con la misma intensidad, sin atenuar a Itaú ni a Falabella, y son
  los 5 bancos que suma el indicador de participación conjunta

#### Scenario: Seleccionar un vecino
- **WHEN** el usuario hace clic en la fila de Internacional, vecino de Consorcio
- **THEN** Internacional pasa a ser el banco analizado

#### Scenario: Chat
- **WHEN** el chat pide el resumen del análisis
- **THEN** la escalera del resumen sigue teniendo solo los 5 competidores
