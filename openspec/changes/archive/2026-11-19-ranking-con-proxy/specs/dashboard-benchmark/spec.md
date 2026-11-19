## ADDED Requirements

### Requirement: Ranking actualizado sin redibujar
Al cambiar solo el banco analizado, el gráfico de ranking SHALL actualizar en el navegador los colores de
la escalera, la negrita del banco analizado y la pista de clic, sin volver a dibujarse. Al cambiar cuenta,
período o monedas SHALL dibujarse de nuevo.

#### Scenario: Cambiar de banco
- **WHEN** se analiza BCI y el usuario elige Internacional
- **THEN** el gráfico de ranking no repite la animación de entrada; las barras de los puestos 7 a 11
  pasan a su color, las de 1 a 5 a gris, y "9. Internacional" va en negrita

#### Scenario: Cambiar de cuenta
- **WHEN** el usuario cambia de Colocaciones a Depósitos a plazo
- **THEN** el gráfico de ranking se dibuja de nuevo con el ranking de esa cuenta
