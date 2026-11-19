## ADDED Requirements

### Requirement: Indicadores actualizados sin redibujar
Al cambiar solo el banco analizado, los indicadores SHALL actualizarse en el navegador sin redibujarse: la
participación conjunta y el puesto cuentan hasta el nuevo valor, textos y chips se reemplazan con un
fundido, la tira de Puesto desliza sus marcas y el mini gráfico cambia de serie. El resultado SHALL ser
igual al de dibujarlos de nuevo.

#### Scenario: De BCI a Internacional
- **WHEN** se analiza BCI y el usuario elige Internacional
- **THEN** la participación conjunta cuenta de 75,5 % a 13,1 %, el puesto de 1° a 9°, la franja de la
  tira se desliza a los puestos 7 a 11 y el anillo de hace 12 meses queda en el 11

#### Scenario: Movimiento reducido
- **WHEN** el sistema pide reducir el movimiento
- **THEN** las cifras y la tira cambian sin animación
