## MODIFIED Requirements

### Requirement: Ventana de la escalera
La escalera SHALL incluir al banco analizado y sus vecinos directos (el de arriba y el de abajo), en orden
de ranking: 3 bancos. En los extremos SHALL desplazarse para mantener 3: el líder con los dos que le
siguen y el último con los dos de arriba.

#### Scenario: Banco en posición intermedia
- **WHEN** el banco analizado está 9° de 17
- **THEN** la escalera muestra los puestos 8 a 10

#### Scenario: Banco líder
- **WHEN** el banco analizado está 1° de 17
- **THEN** la escalera muestra los puestos 1 a 3, con el banco analizado arriba

#### Scenario: Último del ranking
- **WHEN** el banco analizado está 17° de 17
- **THEN** la escalera muestra los puestos 15 a 17
