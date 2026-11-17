## MODIFIED Requirements

### Requirement: Brechas entre puestos consecutivos
Para cada par de puestos consecutivos de la escalera SHALL calcularse la brecha de hoy (monto y puntos de
participación del de arriba menos el de abajo) y la brecha en puntos hace 12 meses entre los mismos dos
bancos. La tendencia SHALL ser "se acorta", "se amplía" o "estable" (cambio menor a 2 pb), o "cambio de
orden" si hace 12 meses el de abajo estaba por encima.

#### Scenario: Adelantamiento
- **WHEN** Internacional está sobre Falabella hoy y hace 12 meses Falabella tenía más participación
- **THEN** la tendencia de ese par es "cambio de orden"

#### Scenario: Banco sin dato hace 12 meses
- **WHEN** uno de los dos bancos no informaba hace 12 meses
- **THEN** la brecha de hoy se calcula y la tendencia queda como "sin dato hace 12 meses"
