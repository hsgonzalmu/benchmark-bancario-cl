## MODIFIED Requirements

### Requirement: Tarjeta de comparación
SHALL mostrarse una tarjeta con pestañas Evolución, Base 100, Participación, Brecha y Posición 12m, con al
menos 24 meses hasta el período elegido (12 meses en Posición 12m), cuyas series dependen del modo de
comparación.

#### Scenario: Modo sistema
- **WHEN** el modo es `sistema`
- **THEN** Evolución muestra banco y sistema en ejes separados, Base 100 ambos índices, Participación la
  cuota del banco en el tiempo y Posición 12m la participación hace 12 meses y hoy de todos los bancos

#### Scenario: Modo vecinos
- **WHEN** el modo es `vecinos`
- **THEN** Evolución, Base 100 y Participación muestran solo banco, superior e inferior con su color
  propio, sin líneas de otros bancos, y Posición 12m muestra los bancos de la escalera

#### Scenario: Modo líder
- **WHEN** el modo es `lider`
- **THEN** Brecha muestra en el tiempo la diferencia de monto y de participación entre líder y banco, y
  Posición 12m muestra a ambos

#### Scenario: Banco sin dato hace 12 meses
- **WHEN** un banco de Posición 12m no informaba hace 12 meses
- **THEN** se muestra solo su punto actual, con la nota "sin dato hace 12 meses"
