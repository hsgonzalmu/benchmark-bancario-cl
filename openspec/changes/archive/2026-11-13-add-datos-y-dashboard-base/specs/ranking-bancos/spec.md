# Spec Delta

## Purpose

Calcular la posición competitiva de un banco en una cuenta, período y tipo de valor, y los conjuntos con
los que se compara, como base común para el dashboard y para las tools del chat.

## ADDED Requirements

### Requirement: Ranking por cuenta, período y tipo de valor
El ranking SHALL ordenar de mayor a menor las instituciones con dato en la cuenta, período y tipo de
valor elegidos, excluyendo el total del sistema, y asignar posiciones consecutivas desde 1.

#### Scenario: Ranking de colocaciones
- **WHEN** se elige Colocaciones, período 202609 y tipo de valor Total
- **THEN** el ranking lista los bancos con dato en 202609, sin el total del sistema, con posición 1 para
  el de mayor monto

#### Scenario: Cuenta de signo negativo
- **WHEN** la cuenta es de provisiones y los montos son negativos
- **THEN** el ranking ordena por valor absoluto, de modo que la posición 1 es la de mayor magnitud

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
