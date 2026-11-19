# dashboard-benchmark Specification

## Purpose
Mostrar de forma clara y visualmente consistente la posición de un banco frente al sistema, sus vecinos,
el líder u otros bancos, con un estado de selección que luego podrá manejar el chat de IA.

## Requirements

### Requirement: Estado de selección
La app SHALL mantener la selección en cinco `reactiveVal`: `banco_foco`, `cuenta`, `periodo`, `monedas`
(una o más de CLP no reajustable, reajustable IPC, reajustable TC y moneda extranjera) y `comparacion`
(modo y lista de bancos). Todos los outputs SHALL derivarse de ese estado. Lo modifican los filtros
manuales y las tools `seleccionar_analisis` (banco, cuenta, período, monedas) y `comparar` (comparación)
del chat.

#### Scenario: Estado inicial
- **WHEN** se abre la app
- **THEN** el estado es el banco líder de Colocaciones en el último período disponible, Colocaciones,
  ese período, las cuatro monedas (Total) y modo `vecinos`

#### Scenario: Cambio de filtro
- **WHEN** el usuario elige otra cuenta en el sidebar
- **THEN** se actualiza `cuenta` y todos los componentes reflejan la nueva cuenta

#### Scenario: Cambio desde el chat
- **WHEN** la tool `seleccionar_analisis` cambia el banco a Itaú
- **THEN** se actualiza `banco_foco` y todos los componentes reflejan Itaú

#### Scenario: Quitar una moneda
- **WHEN** el usuario desmarca moneda extranjera
- **THEN** se actualiza `monedas` y escalera, indicadores, gráficos, pesas y tabla se recalculan sin
  moneda extranjera

### Requirement: Filtros manuales
El sidebar SHALL ofrecer, en el panel "Filtros", período, banco, cuenta (por nombre amigable y agrupada),
casillas de monedas (CLP no reajustable, reajustable IPC, reajustable TC, moneda extranjera) con un acceso
rápido para volver al Total, y modo de comparación, con selector de bancos visible solo en modo `bancos`.
La selección de monedas MUST NOT quedar vacía. Cuando el chat cambia el estado, los filtros SHALL mostrar
los nuevos valores.

#### Scenario: Modo bancos
- **WHEN** el usuario elige el modo `bancos`
- **THEN** aparece un selector que admite de 1 a 4 bancos además del analizado

#### Scenario: Filtros sincronizados con el chat
- **WHEN** el chat ejecuta `comparar(modo = "bancos", bancos = c("BCI", "Itaú"))`
- **THEN** el panel "Filtros" muestra el modo Bancos con BCI e Itaú elegidos y el estado no vuelve al
  valor anterior

#### Scenario: Desmarcar la última moneda
- **WHEN** queda una sola moneda marcada y el usuario la desmarca
- **THEN** la casilla vuelve a marcarse, el estado no cambia y se avisa "Elige al menos una moneda"

#### Scenario: Volver al Total
- **WHEN** el usuario pulsa el acceso rápido "Total"
- **THEN** se marcan las cuatro monedas

### Requirement: Encabezado de contexto
El área principal SHALL mostrar un encabezado con banco, cuenta, período en formato "sep 2026", nombre de
la selección de monedas y fecha de descarga de los datos. La selección SHALL nombrarse "Total" con las
cuatro monedas, por su nombre con una, "Total sin <moneda>" con tres, y unida por "y" con dos.

#### Scenario: Encabezado actualizado
- **WHEN** cambia cualquier elemento del estado
- **THEN** el encabezado muestra los nuevos valores

#### Scenario: Nombre de la selección
- **WHEN** están elegidas CLP no reajustable, reajustable IPC y reajustable TC
- **THEN** el encabezado dice "Total sin moneda extranjera"

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

### Requirement: Mensajes de estado vacío
Cuando la selección no tiene datos, los componentes SHALL mostrar un mensaje legible en vez de un error.

#### Scenario: Banco sin datos en el período
- **WHEN** el banco analizado no informa en el período elegido
- **THEN** los componentes muestran "Sin datos para <banco> en <período>" y su último período disponible

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

### Requirement: Composición en la tabla de ranking
La tabla de ranking SHALL incluir una columna Composición con una barra 100 % apilada de las monedas
elegidas y, al expandir la fila, sus montos en MM$ y porcentajes sobre la selección. La leyenda SHALL
mostrar solo las monedas elegidas. Con signos mixtos, la barra SHALL reemplazarse por el texto "signos
mixtos" y el detalle mostrar los montos con su signo.

#### Scenario: Detalle de la composición
- **WHEN** el usuario expande la fila de BCI en Colocaciones a sep 2026 con las cuatro monedas
- **THEN** ve CLP no reajustable, reajustable IPC, reajustable TC y moneda extranjera con monto y
  porcentaje

#### Scenario: Patrimonio
- **WHEN** la cuenta es Patrimonio y un banco tiene componentes elegidos de signo distinto
- **THEN** su celda dice "signos mixtos" y el detalle muestra los montos elegidos con signo

#### Scenario: Solo IPC
- **WHEN** la selección es solo reajustable IPC
- **THEN** la barra de cada banco es 100 % IPC y el detalle muestra solo esa moneda

### Requirement: Gráficos descargables y con animación suave
Todos los gráficos highcharter SHALL entrar con una animación de 1,6 s. Los gráficos del dashboard y de
las ventanas de `mostrar_grafico` SHALL tener un botón de opciones con pantalla completa, imprimir y
descarga en PNG, JPEG y SVG, generados en el navegador sin enviar datos a un servidor externo. Los mini
gráficos de los indicadores SHALL quedar sin botón.

#### Scenario: Descargar un gráfico del dashboard
- **WHEN** el usuario abre el botón de opciones del gráfico de ranking y elige "Descargar PNG"
- **THEN** descarga `grafico-cmf.png` con fondo blanco y la fuente "CMF"

#### Scenario: Descargar un gráfico de una ventana
- **WHEN** el chat abre una ventana con `mostrar_grafico(tipo = "crecimiento")`
- **THEN** el gráfico de la ventana tiene el mismo botón de opciones

#### Scenario: Mini gráficos
- **WHEN** se muestran los indicadores
- **THEN** sus mini gráficos se animan al aparecer y no muestran botón de opciones

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

### Requirement: Etiquetas al final de las líneas
En Evolución, Base 100 y Participación, cada línea visible SHALL rotularse donde termina con su nombre y
un punto de su color, sin que dos etiquetas se monten. La leyenda SHALL mostrar solo los bancos ocultos
de la escalera ("Agregar:"). En modo `sistema` SHALL mantenerse la leyenda.

#### Scenario: Líneas que terminan juntas
- **WHEN** se analiza Internacional en Colocaciones y Falabella termina casi en el mismo valor
- **THEN** "Internacional" y "Falabella" se leen al final de sus líneas, una sobre otra, sin montarse

#### Scenario: Activar un banco oculto
- **WHEN** el usuario hace clic en "BICE" bajo "Agregar:"
- **THEN** aparece la línea de BICE con su etiqueta al final

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

### Requirement: Seleccionar desde el ranking
Clic en una barra del gráfico de ranking o en una fila de la tabla de ranking SHALL dejar ese banco como
analizado, por el mismo camino que el filtro Banco. La flecha de detalle de la tabla SHALL seguir abriendo
la composición sin cambiar el banco.

#### Scenario: Clic en una barra
- **WHEN** el usuario hace clic en la barra de Santander del gráfico de ranking
- **THEN** Santander pasa a ser el banco analizado y el filtro Banco se actualiza

#### Scenario: Clic en una fila de la tabla
- **WHEN** el usuario hace clic en la fila de Falabella de la tabla de ranking
- **THEN** Falabella pasa a ser el banco analizado

#### Scenario: Abrir el detalle
- **WHEN** el usuario hace clic en la flecha de la fila de Falabella
- **THEN** se abre el detalle de composición y el banco analizado no cambia

### Requirement: Tooltip en tabla ordenada
Los gráficos de tiempo SHALL mostrar el tooltip como tabla con el mes, un punto del color de cada banco,
su nombre y su valor. En Evolución, Base 100, Participación y las ventanas de evolución y de varias
cuentas, las filas SHALL ir de mayor a menor valor.

#### Scenario: Tooltip de Evolución
- **WHEN** se analiza Internacional y el usuario pasa el puntero por ene 2026 en Evolución
- **THEN** el tooltip dice "enero 2026" y lista Consorcio, Falabella e Internacional en ese orden, con sus
  montos en mil millones

### Requirement: Transiciones suaves al cambiar de banco
Al cambiar de banco, los cambios del ranking SHALL animarse en 0,9 s y la escalera SHALL deslizarse en
0,7 s con aceleración y frenado suaves, con transición en las filas y fundido en las brechas, salvo que
el sistema pida reducir el movimiento.

#### Scenario: Cambio de banco
- **WHEN** se analiza BCI y el usuario elige Internacional
- **THEN** los colores del ranking cambian en 0,9 s y la escalera se desliza hasta el 7° en 0,7 s

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
