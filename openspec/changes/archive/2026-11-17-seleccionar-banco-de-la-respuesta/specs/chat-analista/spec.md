## ADDED Requirements

### Requirement: Banco de la respuesta en el dashboard
Cuando una pregunta sin banco nombrado se responde con un banco, el chat SHALL dejarlo seleccionado con
`seleccionar_analisis`, además de abrir la ventana. Las tools de crecimiento y ranking SHALL indicar en
`para_dashboard` qué banco seleccionar.

#### Scenario: El que más creció
- **WHEN** el usuario pregunta "¿Qué banco creció más en colocaciones en los últimos 12 meses?"
- **THEN** se abre el gráfico de crecimiento, el dashboard queda en BICE en Colocaciones, y la respuesta
  aclara que su crecimiento viene de la fusión con Security

#### Scenario: El que más participación ganó
- **WHEN** el usuario pregunta qué banco ganó más participación en depósitos a la vista en el último año
- **THEN** el chat abre la tabla de ranking, cita los pb de `mas_ganaron_participacion` y deja
  seleccionado al primero (la tabla devuelve los 3 que más ganaron en 12 meses)

#### Scenario: Colores del gráfico de crecimiento
- **WHEN** se abre el gráfico de crecimiento
- **THEN** cada barra usa el color propio de su banco y el banco analizado va con su nombre en negrita
