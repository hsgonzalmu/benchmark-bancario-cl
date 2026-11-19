# ranking-bancos Specification

## Purpose
Calcular la posición competitiva de un banco en una cuenta, período y tipo de valor, y los conjuntos con
los que se compara, como base común para el dashboard y para las tools del chat.

## Requirements

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

### Requirement: Vecinos superior e inferior
Para el banco analizado, el vecino superior SHALL ser el de la posición inmediatamente anterior y el
inferior el de la inmediatamente siguiente; si no existe, el resultado SHALL indicarlo como no
disponible.

#### Scenario: Banco en posición intermedia
- **WHEN** el banco analizado está en la posición 9
- **THEN** el vecino superior es el de la posición 8 y el inferior el de la 10

#### Scenario: Banco líder
- **WHEN** el banco analizado está en la posición 1
- **THEN** el vecino superior figura como "N/A" y el inferior es el de la posición 2

### Requirement: Líder de la cuenta
El líder SHALL ser el banco en posición 1 del ranking para la cuenta, período y tipo de valor elegidos.

#### Scenario: Banco analizado es el líder
- **WHEN** el banco analizado ocupa la posición 1
- **THEN** la comparación con el líder indica que el banco es el líder y la brecha es cero

### Requirement: Métricas por institución
Para cada institución del ranking SHALL calcularse monto, participación sobre el total del sistema,
variación mensual y variación en 12 meses; una variación sin período base SHALL quedar como no
disponible.

#### Scenario: Participación
- **WHEN** un banco tiene 7,0 billones y el sistema 452,7 billones
- **THEN** su participación es 1,55 %

#### Scenario: Sin dato del mes anterior
- **WHEN** el período elegido es el primero disponible
- **THEN** la variación mensual figura como no disponible en vez de 0 %

### Requirement: Participación conjunta
SHALL calcularse la participación conjunta del banco analizado y sus vecinos disponibles sobre el total
del sistema.

#### Scenario: Sin vecino superior
- **WHEN** el banco analizado es el líder
- **THEN** la participación conjunta suma solo al banco y su vecino inferior

### Requirement: Conjuntos de comparación
SHALL existir cuatro modos de comparación: `sistema` (banco frente al total), `vecinos` (banco, superior e
inferior), `lider` (banco y líder) y `bancos` (banco y una lista de 1 a 4 bancos elegidos).

#### Scenario: Modo bancos con lista vacía
- **WHEN** el modo es `bancos` y no se eligió ningún otro banco
- **THEN** la comparación muestra solo el banco analizado y un aviso para elegir bancos

### Requirement: Identidad fija en la serie histórica
En las series históricas, vecinos y líder SHALL ser los determinados en el período elegido y mantenerse
como las mismas instituciones en todos los meses de la serie.

#### Scenario: Cambio de posiciones en el pasado
- **WHEN** el vecino superior en 202609 estaba por debajo del banco analizado en 202501
- **THEN** la serie sigue mostrando a esa misma institución como vecino superior en 202501

### Requirement: Institución sin dato en el período
Cuando el banco analizado no tiene dato en el período elegido, el cálculo SHALL indicarlo en vez de
devolver posición o vecinos.

#### Scenario: Banco fusionado
- **WHEN** se analiza Banco Security en 202609 y no informa ese mes
- **THEN** el resultado indica que el banco no tiene datos en 202609 e informa su último período
  disponible

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
