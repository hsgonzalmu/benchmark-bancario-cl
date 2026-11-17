# Spec Delta

## MODIFIED Requirements

### Requirement: Ranking por cuenta, período y tipo de valor
El ranking SHALL ordenar de mayor a menor las instituciones con dato en la cuenta, período y selección de
monedas elegidos, excluyendo el total del sistema, y asignar posiciones consecutivas desde 1. El monto de
cada institución y del sistema SHALL ser la suma de las monedas elegidas; las cuatro juntas equivalen al
Total.

#### Scenario: Ranking de colocaciones
- **WHEN** se elige Colocaciones, período 202609 y tipo de valor Total
- **THEN** el ranking lista los bancos con dato en 202609, sin el total del sistema, con posición 1 para
  el de mayor monto

#### Scenario: Cuenta de signo negativo
- **WHEN** la cuenta es de provisiones y los montos son negativos
- **THEN** el ranking ordena por valor absoluto, de modo que la posición 1 es la de mayor magnitud

#### Scenario: Total sin moneda extranjera
- **WHEN** se eligen CLP no reajustable, reajustable IPC y reajustable TC en Colocaciones a sep 2026
- **THEN** el monto de BCI es la suma de esos tres componentes, su participación se calcula sobre la misma
  suma del sistema y el ranking se ordena por ese monto

#### Scenario: Una sola moneda
- **WHEN** se elige solo reajustable IPC
- **THEN** ranking, participación y variaciones son los de la columna IPC

### Requirement: Composición por moneda
Para cada banco SHALL calcularse la composición de su monto en las monedas elegidas, en monto y porcentaje
sobre la suma de esa selección. Si los componentes elegidos tienen signos distintos, la composición SHALL
marcarse como de signos mixtos y no informar porcentajes.

#### Scenario: Composición normal
- **WHEN** se calcula la composición de BCI en Colocaciones a sep 2026 con las cuatro monedas
- **THEN** los cuatro porcentajes suman 100 %

#### Scenario: Signos mixtos
- **WHEN** en Patrimonio el componente CLP es positivo y el IPC negativo, y ambos están elegidos
- **THEN** la composición queda marcada como de signos mixtos, con los montos elegidos y sin porcentajes

#### Scenario: Selección parcial
- **WHEN** se eligen CLP no reajustable y reajustable IPC
- **THEN** la composición tiene solo esos dos componentes y sus porcentajes suman 100 %
