## ADDED Requirements

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
