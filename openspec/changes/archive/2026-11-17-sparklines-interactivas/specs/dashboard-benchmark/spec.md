## MODIFIED Requirements

### Requirement: Escalera de competencia
Bajo el encabezado SHALL mostrarse la escalera: una fila por banco de la ventana con puesto, nombre,
monto, participación, una línea de participación de 12 meses y variación en 12 meses; y entre cada par de
filas, la brecha de hoy, la brecha hace 12 meses y su tendencia. La fila del banco analizado SHALL
destacarse, y las brechas que lo tocan SHALL redactarse desde su punto de vista. La línea de 12 meses
SHALL ser interactiva: al pasar el puntero muestra el mes más cercano con su participación, y marca ese
mismo mes en las líneas de todos los bancos de la escalera.

#### Scenario: Brechas del banco analizado
- **WHEN** se analiza Internacional en Colocaciones a sep 2026
- **THEN** sobre su fila se lee "te faltan MM$ 1.086.485" para Consorcio y bajo ella "le llevas
  MM$ 164.125" a Falabella, con la tendencia de cada brecha

#### Scenario: Banco líder
- **WHEN** se analiza BCI, 1° en Colocaciones
- **THEN** la escalera empieza con BCI y muestra debajo los puestos 2 a 5, sin brecha hacia arriba

#### Scenario: Pantalla angosta
- **WHEN** la pantalla mide ~400 px
- **THEN** cada fila muestra puesto, banco, monto, línea y variación, sin desbordarse

#### Scenario: Leer un mes en la línea
- **WHEN** el usuario pasa el puntero sobre la línea de BCI cerca de oct 2025
- **THEN** ve "oct 2025 · <participación de BCI>" junto al cursor, y las líneas de los otros bancos de la
  escalera muestran un punto en oct 2025

#### Scenario: Mes sin dato
- **WHEN** un banco no informaba en el mes señalado (Tanner antes de oct 2025)
- **THEN** su línea no muestra punto en ese mes y su etiqueta dice "<mes> · sin dato"

#### Scenario: Salir de la línea
- **WHEN** el puntero sale de la línea
- **THEN** desaparecen el cursor y las etiquetas, y cada línea vuelve a marcar solo su último mes
