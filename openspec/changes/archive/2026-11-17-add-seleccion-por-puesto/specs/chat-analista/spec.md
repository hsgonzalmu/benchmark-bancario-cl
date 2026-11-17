# Spec Delta

## MODIFIED Requirements

### Requirement: Tool seleccionar_analisis
La tool `seleccionar_analisis(banco, puesto, cuenta, periodo, monedas)` SHALL aceptar cada argumento como
opcional y limitado a los valores disponibles (`monedas` es una lista de una a cuatro monedas;
`puesto` es un número desde 1), actualizar solo los que se entreguen y devolver el resumen del análisis
resultante. Con `puesto`, el banco analizado SHALL ser el que ocupa ese puesto en la cuenta, período y
monedas resultantes de la misma llamada. Sin argumentos, con `monedas` vacía, con `banco` y `puesto` a
la vez, o con un puesto mayor que la cantidad de bancos, SHALL fallar con un mensaje claro.

#### Scenario: Cambiar solo la cuenta
- **WHEN** el análisis es BCI en Colocaciones y el usuario pide "ahora en depósitos a plazo"
- **THEN** la tool recibe solo `cuenta = "Depósitos a plazo"`, el banco sigue siendo BCI y el dashboard
  muestra depósitos a plazo

#### Scenario: Banco sin datos en el período
- **WHEN** se selecciona Security en sep 2026
- **THEN** el dashboard muestra el aviso de sin datos y el resumen indica que no hay datos y su último
  período disponible (oct 2025), para que el chat lo ofrezca

#### Scenario: Sin moneda extranjera
- **WHEN** el usuario pide "analiza BCI sin considerar moneda extranjera"
- **THEN** la tool recibe `monedas` con CLP no reajustable, reajustable IPC y reajustable TC, el dashboard
  y los filtros muestran esa selección y la respuesta usa los montos recalculados

#### Scenario: Solo IPC
- **WHEN** el usuario pide "muéstrame solo lo reajustable por IPC de Itaú"
- **THEN** la tool recibe `banco = "Itaú"` y `monedas` con solo reajustable IPC

#### Scenario: El top de una cuenta
- **WHEN** el análisis es Internacional en Colocaciones y el usuario pregunta "¿quién es el top en
  depósitos a plazo en UF?"
- **THEN** la tool recibe `puesto = 1`, `cuenta = "Depósitos a plazo"` y `monedas` con solo reajustable
  IPC; el dashboard y los filtros quedan en BancoEstado (60,5 % de participación) y la respuesta lo nombra

#### Scenario: Un puesto que no existe
- **WHEN** la tool recibe `puesto = 30` en una cuenta con 17 bancos
- **THEN** falla con "Solo hay 17 bancos en ese ranking" y el estado no cambia
