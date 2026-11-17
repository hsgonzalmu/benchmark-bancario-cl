# Spec Delta

## ADDED Requirements

### Requirement: Escalera de competencia
Bajo el encabezado SHALL mostrarse la escalera: una fila por banco de la ventana con puesto, nombre,
monto, participación, una línea de participación de 12 meses y variación en 12 meses; y entre cada par de
filas, la brecha de hoy, la brecha hace 12 meses y su tendencia. La fila del banco analizado SHALL
destacarse, y las brechas que lo tocan SHALL redactarse desde su punto de vista.

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

### Requirement: Indicadores de posición
Junto a la escalera SHALL mostrarse dos indicadores: participación conjunta de la escalera sobre el
sistema, con el total del sistema y su variación mensual; y puesto del banco analizado con su cambio en
12 meses y, si cambió el conjunto de bancos, cuáles salieron o entraron.

#### Scenario: Subida de puesto con salida de un banco
- **WHEN** Internacional está 9° de 17, hace 12 meses estaba 11° de 17 y en ese lapso salió Security
  (que estaba arriba) y entró Tanner
- **THEN** el indicador muestra "9° de 17", "▲ 2 puestos" y la nota "salió Security (estaba 8°), entró
  Tanner"

### Requirement: Composición en la tabla de ranking
La tabla de ranking SHALL incluir una columna Composición con una barra 100 % apilada de los cuatro
componentes del total y, al expandir la fila, sus montos en MM$ y porcentajes. Con signos mixtos, la barra
SHALL reemplazarse por el texto "signos mixtos" y el detalle mostrar los montos con su signo.

#### Scenario: Detalle de la composición
- **WHEN** el usuario expande la fila de BCI en Colocaciones a sep 2026
- **THEN** ve CLP no reajustable, reajustable IPC, reajustable TC y moneda extranjera con monto y
  porcentaje

#### Scenario: Patrimonio
- **WHEN** la cuenta es Patrimonio y un banco tiene componentes de signo distinto
- **THEN** su celda dice "signos mixtos" y el detalle muestra los cuatro montos con signo

## MODIFIED Requirements

### Requirement: Gráfico de ranking
SHALL mostrarse un gráfico de barras horizontales con todos los bancos del ranking. Las barras de los
bancos de la escalera SHALL usar el color propio de cada banco y el resto ir en gris; la barra del banco
analizado SHALL destacarse con su etiqueta en negrita. El tooltip SHALL mostrar monto, participación y
variación mensual.

#### Scenario: Banco destacado
- **WHEN** se analiza Banco Internacional
- **THEN** su barra usa el color de Internacional, su etiqueta va en negrita con su posición y las barras
  de los puestos 7 a 11 usan el color de cada banco

### Requirement: Tarjeta de comparación
SHALL mostrarse una tarjeta con pestañas Evolución, Base 100, Participación, Brecha y Posición 12m, con al
menos 24 meses hasta el período elegido (12 meses en Posición 12m), cuyas series dependen del modo de
comparación.

#### Scenario: Modo sistema
- **WHEN** el modo es `sistema`
- **THEN** Evolución muestra banco y sistema en ejes separados, Base 100 ambos índices, Participación la
  cuota del banco en el tiempo y Posición 12m la participación hace 12 meses y hoy de todos los bancos

#### Scenario: Modo vecinos
- **WHEN** el modo es `vecinos`
- **THEN** Evolución muestra banco, superior e inferior con su color propio y el resto de los bancos en
  gris tenue, y Posición 12m muestra los bancos de la escalera

#### Scenario: Modo líder
- **WHEN** el modo es `lider`
- **THEN** Brecha muestra en el tiempo la diferencia de monto y de participación entre líder y banco, y
  Posición 12m muestra a ambos

#### Scenario: Banco sin dato hace 12 meses
- **WHEN** un banco de Posición 12m no informaba hace 12 meses
- **THEN** se muestra solo su punto actual, con la nota "sin dato hace 12 meses"

### Requirement: Tabla de ranking
SHALL mostrarse una tabla con posición, banco (con su color propio), clasificación de riesgo, monto,
participación, composición, variación mensual y variación en 12 meses, con barras en la columna de
monto, color según signo en las variaciones y la fila del banco analizado resaltada.

#### Scenario: Orden de la tabla
- **WHEN** el usuario ordena por variación en 12 meses
- **THEN** la tabla se reordena sin perder el resaltado del banco analizado

### Requirement: Sistema visual consistente
Cada banco SHALL tener un color propio, el mismo en todos los componentes y en todas las consultas. El
banco analizado SHALL destacarse por grosor de línea, negrita y fondo, no por un color distinto. El
sistema SHALL ir en línea punteada oscura y los bancos de contexto en gris. Números y fechas SHALL usar
formato chileno.

#### Scenario: Mismo color en todos los gráficos
- **WHEN** Consorcio aparece como vecino de Internacional y luego se analiza Consorcio
- **THEN** Consorcio usa el mismo color en ambas consultas, en escalera, ranking, gráficos y tabla

#### Scenario: Bancos vecinos distinguibles
- **WHEN** se muestran juntos bancos cuyos colores se parecen (separación OKLab menor a 15 en visión normal
  o menor a 6 con daltonismo)
- **THEN** cada banco se identifica también por su nombre (fila, etiqueta o leyenda) y, en gráficos de
  líneas y pesas, uno de los dos se dibuja con trazo punteado

#### Scenario: Formato numérico
- **WHEN** se muestra un monto de 7019316661760 pesos
- **THEN** se lee como "MM$ 7.019.317" (millones de pesos, notación de la CMF) en la escalera, en el chat
  y en la tabla, cuyo encabezado dice "Monto (MM$)"

#### Scenario: Monto pequeño
- **WHEN** se muestra un monto de 2500000 pesos
- **THEN** se lee como "MM$ 2,5"

## REMOVED Requirements

### Requirement: Value boxes de posición
**Reason**: La escalera de competencia muestra los mismos datos de banco analizado, superior e inferior,
más la brecha entre ellos y su tendencia.
**Migration**: Los datos de las cajas de banco pasan a las filas de la escalera; la participación
conjunta pasa al indicador de posición.
