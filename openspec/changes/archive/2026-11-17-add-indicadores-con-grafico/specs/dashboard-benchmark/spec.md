# Spec Delta

## MODIFIED Requirements

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
