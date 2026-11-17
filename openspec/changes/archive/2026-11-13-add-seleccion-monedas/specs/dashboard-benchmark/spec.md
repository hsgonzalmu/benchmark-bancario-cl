# Spec Delta

## MODIFIED Requirements

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
