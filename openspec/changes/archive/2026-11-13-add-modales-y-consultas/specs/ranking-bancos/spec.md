# Spec Delta

## ADDED Requirements

### Requirement: Puestos en el tiempo
Para un conjunto de bancos, una cuenta, una selección de monedas y una ventana de 12, 24 o 36 meses
hasta el período elegido, SHALL calcularse el puesto de cada banco en cada mes y los meses en que una
institución entró o salió del ranking.

#### Scenario: Adelantamiento
- **WHEN** se calculan los puestos de Internacional y Falabella en Colocaciones, 24 meses a sep 2026
- **THEN** Internacional figura bajo Falabella hasta jul 2026 y sobre Falabella desde ago 2026

#### Scenario: Salida por fusión
- **WHEN** la ventana incluye nov 2025
- **THEN** el resultado marca que Security salió del ranking en nov 2025

#### Scenario: Banco sin dato en algunos meses
- **WHEN** Tanner está en el conjunto y la ventana empieza antes de oct 2025
- **THEN** sus meses sin dato quedan vacíos, sin puesto inventado

### Requirement: Composición en el tiempo
Para un banco, una cuenta y una ventana de meses SHALL calcularse, mes a mes, el monto y el porcentaje de
cada moneda elegida sobre la suma de la selección, con la misma regla de signos mixtos de la composición.

#### Scenario: Mezcla de monedas de BCI
- **WHEN** se calcula la composición de BCI en Colocaciones, 24 meses a sep 2026, con las cuatro monedas
- **THEN** cada mes tiene los cuatro porcentajes y suman 100 %

### Requirement: Crecimiento del período
Para una cuenta, una selección de monedas y una ventana de meses SHALL calcularse, para cada banco con
dato al inicio y al final, la variación del monto y el cambio de participación en puntos, ordenados de
mayor a menor variación.

#### Scenario: Crecimiento en 12 meses
- **WHEN** se calcula el crecimiento de Colocaciones en 12 meses a sep 2026
- **THEN** BICE aparece con +85,0 % y los bancos sin dato al inicio (Tanner) quedan fuera con una nota
