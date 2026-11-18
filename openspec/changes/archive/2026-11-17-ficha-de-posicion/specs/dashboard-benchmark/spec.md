## ADDED Requirements

### Requirement: Ficha del indicador Puesto
El indicador Puesto SHALL mostrarse como ficha: etiqueta con el color del banco y la cuenta, puesto y
cambio en 12 meses, y debajo una tira de puestos a lo ancho con los bancos de la escalera en su color y
su número.

#### Scenario: Ficha de Internacional
- **WHEN** se analiza Internacional en Colocaciones a sep 2026
- **THEN** la ficha dice "Puesto de Internacional · Colocaciones", "9° de 17" y "▲ 2 puestos en 12
  meses", y la tira muestra los puestos 7 a 11 con el color de cada banco y su número, el 9 más grande y
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
