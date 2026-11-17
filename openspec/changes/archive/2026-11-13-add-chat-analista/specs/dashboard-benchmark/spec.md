# Spec Delta

## MODIFIED Requirements

### Requirement: Estado de selección
La app SHALL mantener la selección en cinco `reactiveVal`: `banco_foco`, `cuenta`, `periodo`,
`tipo_valor` y `comparacion` (modo y lista de bancos). Todos los outputs SHALL derivarse de ese estado.
Lo modifican los filtros manuales y las tools `seleccionar_analisis` (banco, cuenta, período, tipo de
valor) y `comparar` (comparación) del chat.

#### Scenario: Estado inicial
- **WHEN** se abre la app
- **THEN** el estado es el banco líder de Colocaciones en el último período disponible, Colocaciones,
  ese período, tipo de valor Total y modo `vecinos`

#### Scenario: Cambio de filtro
- **WHEN** el usuario elige otra cuenta en el sidebar
- **THEN** se actualiza `cuenta` y todos los componentes reflejan la nueva cuenta

#### Scenario: Cambio desde el chat
- **WHEN** la tool `seleccionar_analisis` cambia el banco a Itaú
- **THEN** se actualiza `banco_foco` y todos los componentes reflejan Itaú

### Requirement: Filtros manuales
El sidebar SHALL ofrecer, en el panel "Filtros", período, banco, cuenta (por nombre amigable y agrupada),
tipo de valor (Total, CLP no reajustable, reajustable IPC, reajustable TC, moneda extranjera) y modo de
comparación, con selector de bancos visible solo en modo `bancos`. Cuando el chat cambia el estado, los
filtros SHALL mostrar los nuevos valores.

#### Scenario: Modo bancos
- **WHEN** el usuario elige el modo `bancos`
- **THEN** aparece un selector que admite de 1 a 4 bancos además del analizado

#### Scenario: Filtros sincronizados con el chat
- **WHEN** el chat ejecuta `comparar(modo = "bancos", bancos = c("BCI", "Itaú"))`
- **THEN** el panel "Filtros" muestra el modo Bancos con BCI e Itaú elegidos y el estado no vuelve al
  valor anterior

### Requirement: Sistema visual consistente
Cada rol SHALL tener un color fijo en todos los componentes: banco analizado, vecino superior, vecino
inferior, líder, sistema (línea punteada) y resto (gris). Números y fechas SHALL usar formato chileno.

#### Scenario: Mismo color en todos los gráficos
- **WHEN** un banco es vecino superior
- **THEN** aparece con el mismo color en value box, ranking, evolución y tabla

#### Scenario: Formato numérico
- **WHEN** se muestra un monto de 7019316661760 pesos
- **THEN** se lee como "MM$ 7.019.317" (millones de pesos, notación de la CMF) en value boxes, en el
  chat y en la tabla, cuyo encabezado dice "Monto (MM$)"

#### Scenario: Monto pequeño
- **WHEN** se muestra un monto de 2500000 pesos
- **THEN** se lee como "MM$ 2,5"
