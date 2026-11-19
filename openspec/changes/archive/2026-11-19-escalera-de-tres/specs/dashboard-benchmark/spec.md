## MODIFIED Requirements

### Requirement: Gráfico de ranking
SHALL mostrarse un gráfico de barras horizontales con todos los bancos del ranking. Las barras de los
bancos de la escalera SHALL usar el color propio de cada banco y el resto ir en gris; la barra del banco
analizado SHALL destacarse con su etiqueta en negrita. El tooltip SHALL mostrar monto, participación y
variación mensual.

#### Scenario: Banco destacado
- **WHEN** se analiza Banco Internacional
- **THEN** su barra usa el color de Internacional, su etiqueta va en negrita con su posición y las barras
  de los puestos 8 a 10 usan el color de cada banco

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
- **THEN** Evolución, Base 100 y Participación muestran solo banco, superior e inferior con su color
  propio y su nombre al final de la línea, sin leyenda; para sumar otros bancos se usa el modo `bancos`; y
  Posición 12m muestra los bancos de la escalera (con el líder, los puestos 1 a 3)

#### Scenario: Modo líder
- **WHEN** el modo es `lider`
- **THEN** Brecha muestra en el tiempo la diferencia de monto y de participación entre líder y banco, y
  Posición 12m muestra a ambos

#### Scenario: Banco sin dato hace 12 meses
- **WHEN** un banco de Posición 12m no informaba hace 12 meses
- **THEN** se muestra solo su punto actual, con la nota "sin dato hace 12 meses"

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
- **THEN** la escalera destaca a BCI, Santander y Banco de Chile, sin brecha hacia arriba

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

### Requirement: Ficha del indicador Puesto
El indicador Puesto SHALL mostrarse como ficha: etiqueta con el color del banco y la cuenta, puesto y
cambio en 12 meses, y debajo una tira de puestos a lo ancho con los bancos de la escalera en su color y
su número.

#### Scenario: Ficha de Internacional
- **WHEN** se analiza Internacional en Colocaciones a sep 2026
- **THEN** la ficha dice "Puesto de Internacional · Colocaciones", "9° de 17" y "▲ 2 puestos en 12
  meses", y la tira muestra los puestos 8 a 10 con el color de cada banco y su número, el 9 más grande y
  el 11 con el anillo de hace 12 meses

#### Scenario: Pantalla angosta
- **WHEN** la pantalla mide ~400 px
- **THEN** la tira cabe sin desbordarse

#### Scenario: Seleccionar desde la tira
- **WHEN** el usuario hace clic en el punto de Santander en la tira (cualquier banco salvo el analizado)
- **THEN** Santander pasa a ser el banco analizado y el filtro Banco se actualiza

#### Scenario: Nombre al pasar el puntero
- **WHEN** el usuario pasa el puntero por el punto del 8° con Internacional analizado
- **THEN** aparece al instante la etiqueta "8° Consorcio"; en el punto del analizado dice
  "9° Internacional · analizado"

### Requirement: Escalera actualizada sin redibujar
Al cambiar solo el banco analizado, la escalera SHALL actualizar en el navegador sus competidores, el
banco destacado y las brechas, y desplazarse con suavidad hasta los nuevos competidores, sin volver a
dibujar sus filas. Al cambiar cuenta, período o monedas SHALL dibujarse de nuevo.

#### Scenario: Cambiar de banco
- **WHEN** se analiza BCI y el usuario elige Internacional
- **THEN** las 17 filas se conservan, los puestos 8 a 10 pasan a destacados con sus brechas desde el
  punto de vista de Internacional, los 1 a 3 pasan a pálidos y la lista se desliza hasta el 8°

#### Scenario: Banco sin dato
- **WHEN** el usuario elige un banco que no informa en el período
- **THEN** la escalera y los indicadores se ocultan y el encabezado avisa, como antes

#### Scenario: Movimiento reducido
- **WHEN** el sistema del usuario pide reducir el movimiento
- **THEN** la lista salta a los competidores sin animación

### Requirement: Indicadores actualizados sin redibujar
Al cambiar solo el banco analizado, los indicadores SHALL actualizarse en el navegador sin redibujarse: la
participación del banco y el puesto cuentan hasta el nuevo valor, etiquetas, textos y chips se reemplazan
con un fundido, la tira de Puesto desliza sus marcas y el mini gráfico cambia de serie y de color. El
resultado SHALL ser igual al de dibujarlos de nuevo.

#### Scenario: De BCI a Internacional
- **WHEN** se analiza BCI y el usuario elige Internacional
- **THEN** la participación cuenta de 21,73 % a 1,78 %, el puesto de 1° a 9°, la franja de la tira se
  desliza a los puestos 8 a 10 y el anillo de hace 12 meses queda en el 11

#### Scenario: Movimiento reducido
- **WHEN** el sistema pide reducir el movimiento
- **THEN** las cifras y la tira cambian sin animación

### Requirement: Ranking actualizado sin redibujar
Al cambiar solo el banco analizado, el gráfico de ranking SHALL actualizar en el navegador los colores de
la escalera, la negrita del banco analizado y la pista de clic, sin volver a dibujarse. Al cambiar cuenta,
período o monedas SHALL dibujarse de nuevo.

#### Scenario: Cambiar de banco
- **WHEN** se analiza BCI y el usuario elige Internacional
- **THEN** el gráfico de ranking no repite la animación de entrada; las barras de los puestos 8 a 10
  pasan a su color, las de 1 a 3 a gris, y "9. Internacional" va en negrita

#### Scenario: Cambiar de cuenta
- **WHEN** el usuario cambia de Colocaciones a Depósitos a plazo
- **THEN** el gráfico de ranking se dibuja de nuevo con el ranking de esa cuenta

## ADDED Requirements

### Requirement: Indicadores del banco analizado
Junto a la escalera SHALL mostrarse dos indicadores del banco analizado. Participación: su participación,
su cambio en pb (m/m y 12m), la distancia en pb a sus vecinos directos, el total del sistema y un gráfico
de 24 meses en su color, y como dato de apoyo la participación conjunta de los bancos de la escalera.
Puesto: su puesto, su cambio en 12 meses y una tira de posiciones. Las entradas
o salidas de bancos no se muestran; el chat las recibe.

#### Scenario: Subida de puesto con salida de un banco
- **WHEN** Internacional está 9° de 17, hace 12 meses estaba 11° de 17 y en ese lapso salió Security
  (que estaba arriba) y entró Tanner
- **THEN** el indicador muestra "9° de 17" y "▲ 2 puestos", sin nota de entradas o salidas, y si el
  usuario pregunta por el ascenso, el chat dice que salió Security, que estaba arriba

#### Scenario: Participación del banco
- **WHEN** se analiza Internacional en Colocaciones a sep 2026 con las cuatro monedas
- **THEN** el indicador dice "Participación de Internacional · Colocaciones", "1,78 %", "+3 pb m/m",
  "+23 pb 12m", "39 pb para alcanzar a Consorcio", "6 pb sobre Falabella", "Sistema MM$ 278.598.681"
  y, debajo, la participación conjunta de los 3 de la escalera

#### Scenario: Líder
- **WHEN** se analiza BCI, 1° en Colocaciones
- **THEN** el indicador muestra su ventaja sobre Santander, ninguna línea hacia arriba y la participación
  conjunta de BCI, Santander y Banco de Chile

#### Scenario: Salto brusco en la serie
- **WHEN** la participación del banco cambia más de 100 pb en un solo mes dentro de la ventana, como la
  de BICE en nov 2025 por la fusión con Security
- **THEN** el indicador agrega la nota "salto de <pb> en nov 2025" para que el cambio en 12 meses no se
  lea como crecimiento propio

#### Scenario: Tira de posiciones
- **WHEN** se analiza Internacional en Colocaciones a sep 2026
- **THEN** el indicador Puesto muestra 17 posiciones, con la 9 marcada con el color de Internacional, la
  11 marcada como posición de hace 12 meses y los puestos 8 a 10 de la escalera sombreados

#### Scenario: Selección de monedas
- **WHEN** se quita moneda extranjera
- **THEN** la participación del banco, el total del sistema, sus variaciones, el gráfico y la tira se
  recalculan sin moneda extranjera

### Requirement: Diferencias en puntos base
Toda diferencia o cambio entre participaciones SHALL mostrarse en puntos base (pb), sin decimales, con
signo cuando es un cambio (1 pp = 100 pb). Las participaciones y las variaciones de montos SHALL seguir en
porcentaje.

#### Scenario: Indicador de participación
- **WHEN** la participación de Internacional pasa de 1,55 % a 1,78 % en 12 meses
- **THEN** el indicador muestra "1,78 %" y "▲ +23 pb 12m"

#### Scenario: Brecha en la escalera
- **WHEN** Consorcio tiene 0,39 puntos porcentuales más de participación que Internacional
- **THEN** la brecha se lee "te faltan MM$ 1.086.485 · 39 pb"

#### Scenario: Cambio pequeño
- **WHEN** la participación cambia −0,004 puntos porcentuales en el mes
- **THEN** se muestra "= 0 pb m/m", no "-0 pb"

#### Scenario: Tabla descargable
- **WHEN** se descarga el CSV de `mostrar_tabla(tipo = "ranking")`
- **THEN** la columna se llama "Cambio de participación (pb)" y trae enteros

### Requirement: Escalera con el ranking completo
La escalera SHALL listar todos los bancos del ranking en un área con scroll que no cambia la altura de la
tarjeta. El banco y sus vecinos directos SHALL verse destacados y con sus brechas; los demás SHALL verse
en filas compactas y pálidas, sin brechas. Clic en cualquier banco que no sea el analizado SHALL
seleccionarlo.

#### Scenario: Banco del medio
- **WHEN** se analiza Internacional (9° de 17)
- **THEN** la escalera abre desplazada para mostrar los puestos 8 a 10 con sus brechas, y con scroll se
  ven del 1° al 7° y del 11° al 17° en filas pálidas

#### Scenario: Seleccionar desde la escalera
- **WHEN** el usuario hace clic en la fila pálida de Santander
- **THEN** Santander pasa a ser el banco analizado y el filtro Banco se actualiza

#### Scenario: Seleccionar un vecino
- **WHEN** el usuario hace clic en la fila de Internacional, vecino de Consorcio
- **THEN** Internacional pasa a ser el banco analizado

#### Scenario: Chat
- **WHEN** el chat pide el resumen del análisis
- **THEN** la escalera del resumen trae al banco y sus vecinos directos, con sus dos brechas


## REMOVED Requirements

### Requirement: Indicadores de posición
**Reason**: el indicador de participación conjunta de 5 bancos se reemplaza por la participación del banco.
**Migration**: ver "Indicadores del banco analizado".

### Requirement: Diferencias de participación en puntos base
**Reason**: su escenario de ejemplo usaba la participación conjunta.
**Migration**: ver "Diferencias en puntos base", con la misma regla.

### Requirement: Escalera con todo el ranking
**Reason**: los competidores destacados pasan de 5 a 3 y desaparece el escenario de los mismos 5.
**Migration**: ver "Escalera con el ranking completo".

