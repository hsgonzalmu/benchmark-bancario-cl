## ADDED Requirements

### Requirement: Brecha con signo
En los modos `vecinos` y `bancos`, la pestaña Brecha SHALL mostrar el monto de cada otro banco menos el
del analizado, como área transparente hacia el cero en el color del otro banco y con su nombre al final.
El cero SHALL marcarse con el nombre del analizado.

#### Scenario: Vecinos de Internacional
- **WHEN** se analiza Internacional en Colocaciones a sep 2026
- **THEN** Consorcio termina sobre el cero en 1.086 mil millones (lo que le falta) y Falabella bajo el
  cero en −164 mil millones (su ventaja), y la curva de Falabella cruza el cero cuando Internacional la
  adelantó

### Requirement: Punto de partida de Base 100
La pestaña Base 100 SHALL ofrecer los puntos de partida "3 meses", "12 meses" y "24 meses" (12 por
defecto). El índice de cada banco SHALL valer 100 en ese mes y el gráfico SHALL mostrar solo desde ahí.

#### Scenario: Último trimestre
- **WHEN** el período es sep 2026 y el usuario elige "3 meses"
- **THEN** el eje dice "Índice (jun 2026 = 100)", todas las líneas parten en 100 y hay 4 meses
