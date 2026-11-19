## ADDED Requirements

### Requirement: Escalera actualizada sin redibujar
Al cambiar solo el banco analizado, la escalera SHALL actualizar en el navegador sus competidores, el
banco destacado y las brechas, y desplazarse con suavidad hasta los nuevos competidores, sin volver a
dibujar sus filas. Al cambiar cuenta, período o monedas SHALL dibujarse de nuevo.

#### Scenario: Cambiar de banco
- **WHEN** se analiza BCI y el usuario elige Internacional
- **THEN** las 17 filas se conservan, los puestos 7 a 11 pasan a competidores con sus brechas desde el
  punto de vista de Internacional, del 1 al 5 pasan a pálidos y la lista se desliza hasta el 7°

#### Scenario: Banco sin dato
- **WHEN** el usuario elige un banco que no informa en el período
- **THEN** la escalera y los indicadores se ocultan y el encabezado avisa, como antes

#### Scenario: Movimiento reducido
- **WHEN** el sistema del usuario pide reducir el movimiento
- **THEN** la lista salta a los competidores sin animación
