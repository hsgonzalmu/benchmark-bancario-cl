## ADDED Requirements

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
