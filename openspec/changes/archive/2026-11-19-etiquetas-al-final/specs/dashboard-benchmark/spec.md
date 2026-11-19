## ADDED Requirements

### Requirement: Etiquetas al final de las líneas
En Evolución, Base 100 y Participación, cada línea visible SHALL rotularse donde termina con su nombre y
un punto de su color, sin que dos etiquetas se monten. La leyenda SHALL mostrar solo los bancos ocultos
de la escalera ("Agregar:"). En modo `sistema` SHALL mantenerse la leyenda.

#### Scenario: Líneas que terminan juntas
- **WHEN** se analiza Internacional en Colocaciones y Falabella termina casi en el mismo valor
- **THEN** "Internacional" y "Falabella" se leen al final de sus líneas, una sobre otra, sin montarse

#### Scenario: Activar un banco oculto
- **WHEN** el usuario hace clic en "BICE" bajo "Agregar:"
- **THEN** aparece la línea de BICE con su etiqueta al final
