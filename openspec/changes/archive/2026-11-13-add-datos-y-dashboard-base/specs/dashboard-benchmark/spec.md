# Spec Delta

## Purpose

Mostrar de forma clara y visualmente consistente la posición de un banco frente al sistema, sus vecinos,
el líder u otros bancos, con un estado de selección que luego podrá manejar el chat de IA.

## ADDED Requirements

### Requirement: Estado de selección
La app SHALL mantener la selección en cinco `reactiveVal`: `banco_foco`, `cuenta`, `periodo`,
`tipo_valor` y `comparacion` (modo y lista de bancos). Todos los outputs SHALL derivarse de ese estado.
En este cambio solo los filtros manuales lo modifican; no hay tools ni chat.

#### Scenario: Estado inicial
- **WHEN** se abre la app
- **THEN** el estado es Banco Internacional, Colocaciones, último período disponible, tipo de valor Total
  y modo `vecinos`

#### Scenario: Cambio de filtro
- **WHEN** el usuario elige otra cuenta en el sidebar
- **THEN** se actualiza `cuenta` y todos los componentes reflejan la nueva cuenta

### Requirement: Filtros manuales
El sidebar SHALL ofrecer período, banco, cuenta (por nombre amigable y agrupada), tipo de valor (Total,
CLP no reajustable, reajustable IPC, reajustable TC, moneda extranjera) y modo de comparación, con
selector de bancos visible solo en modo `bancos`.

#### Scenario: Modo bancos
- **WHEN** el usuario elige el modo `bancos`
- **THEN** aparece un selector que admite de 1 a 4 bancos además del analizado

### Requirement: Encabezado de contexto
El área principal SHALL mostrar un encabezado con banco, cuenta, período en formato "sep 2026", tipo de
valor y fecha de descarga de los datos.

#### Scenario: Encabezado actualizado
- **WHEN** cambia cualquier elemento del estado
- **THEN** el encabezado muestra los nuevos valores

### Requirement: Value boxes de posición
SHALL mostrarse cuatro value boxes: banco analizado, vecino superior y vecino inferior (monto, posición
y variación mensual con flecha y color según signo), y participación conjunta con el total del sistema.

#### Scenario: Variación negativa
- **WHEN** la variación mensual de un banco es negativa
- **THEN** su value box muestra flecha hacia abajo y el color de alerta

#### Scenario: Vecino no disponible
- **WHEN** el banco analizado es el líder
- **THEN** la caja del vecino superior muestra "N/A" con estilo atenuado, sin error

### Requirement: Gráfico de ranking
SHALL mostrarse un gráfico de barras horizontales con todos los bancos del ranking, con el banco
analizado, sus vecinos y el líder destacados con sus colores y el resto en gris, y un tooltip con
monto, participación y variación mensual.

#### Scenario: Banco destacado
- **WHEN** se analiza Banco Internacional
- **THEN** su barra usa el color del banco analizado y lleva etiqueta con su posición

### Requirement: Tarjeta de comparación
SHALL mostrarse una tarjeta con pestañas Evolución, Base 100, Participación y Brecha, con al menos 24
meses hasta el período elegido, cuyas series dependen del modo de comparación.

#### Scenario: Modo sistema
- **WHEN** el modo es `sistema`
- **THEN** Evolución muestra banco y sistema en ejes separados, Base 100 ambos índices y Participación la
  cuota del banco en el tiempo

#### Scenario: Modo vecinos
- **WHEN** el modo es `vecinos`
- **THEN** Evolución muestra banco, superior e inferior destacados y el resto de los bancos en gris tenue

#### Scenario: Modo líder
- **WHEN** el modo es `lider`
- **THEN** Brecha muestra en el tiempo la diferencia de monto y de participación entre líder y banco

### Requirement: Tabla de ranking
SHALL mostrarse una tabla con posición, banco, clasificación de riesgo, monto, participación, variación
mensual y variación en 12 meses, con barras en la columna de monto, color según signo en las
variaciones y las filas del banco y sus vecinos resaltadas.

#### Scenario: Orden de la tabla
- **WHEN** el usuario ordena por variación en 12 meses
- **THEN** la tabla se reordena sin perder el resaltado del banco y sus vecinos

### Requirement: Sistema visual consistente
Cada rol SHALL tener un color fijo en todos los componentes: banco analizado, vecino superior, vecino
inferior, líder, sistema (línea punteada) y resto (gris). Números y fechas SHALL usar formato chileno.

#### Scenario: Mismo color en todos los gráficos
- **WHEN** un banco es vecino superior
- **THEN** aparece con el mismo color en value box, ranking, evolución y tabla

#### Scenario: Formato numérico
- **WHEN** se muestra un monto de 7019316661760 pesos
- **THEN** se lee como "$7,02 billones" en value boxes y en millones con separador de miles en la tabla

### Requirement: Mensajes de estado vacío
Cuando la selección no tiene datos, los componentes SHALL mostrar un mensaje legible en vez de un error.

#### Scenario: Banco sin datos en el período
- **WHEN** el banco analizado no informa en el período elegido
- **THEN** los componentes muestran "Sin datos para <banco> en <período>" y su último período disponible
