# Spec Delta

## ADDED Requirements

### Requirement: Ventana de la escalera
La escalera SHALL incluir al banco analizado y hasta dos puestos hacia cada lado, en orden de ranking,
con 5 bancos cuando el ranking tiene 5 o más. En los extremos, la ventana SHALL desplazarse para
mantener 5 bancos.

#### Scenario: Banco en posición intermedia
- **WHEN** el banco analizado está 9° de 17
- **THEN** la escalera muestra los puestos 7 a 11

#### Scenario: Banco líder
- **WHEN** el banco analizado está 1° de 17
- **THEN** la escalera muestra los puestos 1 a 5, con el banco analizado arriba

#### Scenario: Último del ranking
- **WHEN** el banco analizado está 17° de 17
- **THEN** la escalera muestra los puestos 13 a 17

### Requirement: Brechas entre puestos consecutivos
Para cada par de puestos consecutivos de la escalera SHALL calcularse la brecha de hoy (monto y puntos de
participación del de arriba menos el de abajo) y la brecha en puntos hace 12 meses entre los mismos dos
bancos. La tendencia SHALL ser "se acorta", "se amplía" o "estable" (cambio menor a 0,02 pp), o "cambio de
orden" si hace 12 meses el de abajo estaba por encima.

#### Scenario: Adelantamiento
- **WHEN** Internacional está sobre Falabella hoy y hace 12 meses Falabella tenía más participación
- **THEN** la tendencia de ese par es "cambio de orden"

#### Scenario: Banco sin dato hace 12 meses
- **WHEN** uno de los dos bancos no informaba hace 12 meses
- **THEN** la brecha de hoy se calcula y la tendencia queda como "sin dato hace 12 meses"

### Requirement: Cambio de puesto en 12 meses
SHALL calcularse el puesto del banco analizado y la cantidad de bancos del ranking hoy y hace 12 meses,
y las instituciones que salieron (con su puesto de entonces) o entraron entre ambos períodos.

#### Scenario: Sale un banco que estaba arriba
- **WHEN** Internacional estaba 11° en sep 2025 y está 9° en sep 2026, y Security (8° en sep 2025) ya no
  informa
- **THEN** el resultado informa el cambio de 11° a 9° y que Security salió desde un puesto superior, para
  no atribuir al banco todo el ascenso

#### Scenario: Entra un banco
- **WHEN** Tanner informa en sep 2026 pero no en sep 2025
- **THEN** el resultado lo informa como institución que entró

### Requirement: Composición por moneda
Para cada banco SHALL calcularse la composición del monto total en CLP no reajustable, reajustable IPC,
reajustable TC y moneda extranjera, en monto y porcentaje del total. Si los componentes tienen signos
distintos, la composición SHALL marcarse como de signos mixtos y no informar porcentajes.

#### Scenario: Composición normal
- **WHEN** se calcula la composición de BCI en Colocaciones a sep 2026
- **THEN** los cuatro porcentajes suman 100 %

#### Scenario: Signos mixtos
- **WHEN** en Patrimonio el componente CLP es positivo y el IPC negativo
- **THEN** la composición queda marcada como de signos mixtos, con los cuatro montos y sin porcentajes
