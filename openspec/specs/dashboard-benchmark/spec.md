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
- **THEN** Evolución, Base 100 y Participación muestran solo banco, superior e inferior con su color
  propio, sin líneas de otros bancos, y Posición 12m muestra los bancos de la escalera

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

### Requirement: Indicadores de posición
Junto a la escalera SHALL mostrarse dos indicadores: Participación conjunta, con la participación de los
bancos de la escalera como cifra principal, su cambio en puntos base en el mes y en 12 meses, el total del
sistema en negrita con su variación mensual y la participación del banco analizado, y un gráfico pequeño
de 24 meses a la derecha; y Puesto, con el puesto del banco analizado, su cambio en 12 meses y una tira
de posiciones del 1° al último. Las entradas o salidas de bancos no se muestran en el indicador; el chat
las sigue recibiendo para explicar cambios de puesto.

#### Scenario: Subida de puesto con salida de un banco
- **WHEN** Internacional está 9° de 17, hace 12 meses estaba 11° de 17 y en ese lapso salió Security
  (que estaba arriba) y entró Tanner
- **THEN** el indicador muestra "9° de 17" y "▲ 2 puestos", sin nota de entradas o salidas, y si el
  usuario pregunta por el ascenso, el chat dice que salió Security, que estaba arriba

#### Scenario: Participación conjunta destacada
- **WHEN** se analiza Internacional en Colocaciones a sep 2026 con las cuatro monedas
- **THEN** el indicador muestra "13,1 %" como cifra principal, "+342 pb 12m", la línea "Sistema
  MM$ 278.598.681" con el monto en negrita y "+1,6 % m/m", y "Internacional 1,78 %"

#### Scenario: Gráfico de la participación conjunta
- **WHEN** el usuario pasa el mouse sobre el gráfico del indicador
- **THEN** ve el mes y la participación conjunta de los bancos de la escalera actual en ese mes

#### Scenario: Salto brusco en la serie
- **WHEN** la participación conjunta cambia más de 100 pb en un solo mes dentro de la ventana, como en
  nov 2025 por la fusión BICE-Security
- **THEN** el indicador agrega la nota "salto de +269 pb en nov 2025" para que el cambio en 12 meses no
  se lea como crecimiento propio

#### Scenario: Tira de posiciones
- **WHEN** se analiza Internacional en Colocaciones a sep 2026
- **THEN** el indicador Puesto muestra 17 posiciones, con la 9 marcada con el color de Internacional, la
  11 marcada como posición de hace 12 meses y los puestos 7 a 11 de la escalera sombreados

#### Scenario: Selección de monedas
- **WHEN** se quita moneda extranjera
- **THEN** la participación conjunta, el total del sistema, sus variaciones, el gráfico y la tira se
  recalculan sin moneda extranjera

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

### Requirement: Diferencias de participación en puntos base
Toda diferencia o cambio entre participaciones SHALL mostrarse en puntos base (pb), sin decimales, con
signo cuando es un cambio (1 pp = 100 pb). Las participaciones y las variaciones de montos SHALL seguir en
porcentaje.

#### Scenario: Indicador de participación conjunta
- **WHEN** la participación conjunta pasa de 9,68 % a 13,1 % en 12 meses
- **THEN** el indicador muestra "13,1 %" y "▲ +342 pb 12m"

#### Scenario: Brecha en la escalera
- **WHEN** Consorcio tiene 0,39 puntos porcentuales más de participación que Internacional
- **THEN** la brecha se lee "te faltan MM$ 1.086.485 · 39 pb"

#### Scenario: Cambio pequeño
- **WHEN** la participación cambia −0,004 puntos porcentuales en el mes
- **THEN** se muestra "= 0 pb m/m", no "-0 pb"

#### Scenario: Tabla descargable
- **WHEN** se descarga el CSV de `mostrar_tabla(tipo = "ranking")`
- **THEN** la columna se llama "Cambio de participación (pb)" y trae enteros
