# Spec Delta

## ADDED Requirements

### Requirement: Serie de varias cuentas de un banco
Para un banco, de 2 a 6 cuentas, una selección de monedas y una ventana de 12, 24 o 36 meses SHALL
calcularse, mes a mes y por cuenta, el monto, la participación del banco sobre el sistema en esa cuenta y
un índice base 100 en el primer mes con dato.

#### Scenario: Colocaciones y depósitos a plazo de BCI
- **WHEN** se calcula la serie de BCI en Colocaciones y Depósitos a plazo, 24 meses a sep 2026
- **THEN** hay 24 meses por cuenta, el monto de sep 2026 en Colocaciones es MM$ 60.552.456 y el índice
  del primer mes es 100 en ambas cuentas

#### Scenario: Banco sin dato en una cuenta y mes
- **WHEN** el banco no informa una cuenta en algún mes de la ventana
- **THEN** ese mes queda vacío en esa cuenta, sin valor inventado
