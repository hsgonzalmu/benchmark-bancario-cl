# Spec Delta

## ADDED Requirements

### Requirement: Tool mostrar_grafico
La tool `mostrar_grafico(tipo, bancos, meses, titulo)` SHALL abrir una ventana emergente con un gráfico
de la selección vigente. `tipo` es `puestos`, `composicion`, `crecimiento` o `evolucion`; `bancos`
(opcional, hasta 6) reemplaza al conjunto por defecto, que es la escalera; `meses` es 12, 24 o 36. SHALL
devolver una confirmación con un resumen breve de lo dibujado, sin cambiar el dashboard ni el estado.

#### Scenario: ¿Quién me adelantó?
- **WHEN** el análisis es Internacional en Colocaciones y el usuario pregunta "¿cuándo pasé a Falabella?"
- **THEN** el chat llama a `mostrar_grafico(tipo = "puestos", meses = 24)`, se abre el gráfico de puestos
  con la escalera, y la respuesta dice ago 2026 según el resumen de la tool

#### Scenario: Mezcla de monedas
- **WHEN** el usuario pide "muéstrame cómo cambió la composición por moneda de BCI"
- **THEN** el chat selecciona BCI si no es el analizado y llama a `mostrar_grafico(tipo = "composicion")`

#### Scenario: Demasiados bancos
- **WHEN** la tool recibe 7 bancos
- **THEN** falla con "Elige hasta 6 bancos" y no se abre ninguna ventana

### Requirement: Tool mostrar_tabla
La tool `mostrar_tabla(tipo, meses, titulo)` SHALL abrir una ventana emergente con una tabla de la
selección vigente: `ranking` (con puesto y participación de hace 12 meses), `historia` (mes a mes de los
bancos de la escalera) o `composicion` (bancos por moneda elegida). La tabla SHALL tener un botón para
descargar sus datos en CSV. SHALL devolver una confirmación breve, sin cambiar el dashboard ni el estado.

#### Scenario: Tabla para llevar
- **WHEN** el usuario pide "dame la tabla de depósitos a plazo para descargarla"
- **THEN** el chat selecciona Depósitos a plazo y llama a `mostrar_tabla(tipo = "ranking")`, y la ventana
  ofrece "Descargar CSV" con las mismas cifras de la tabla

### Requirement: Tool consultar_datos
La tool `consultar_datos(consulta)` SHALL ejecutar una sola consulta `SELECT` sobre la vista `balance`
(período, fecha, banco, cuenta, nombre de cuenta, grupo y montos por moneda y total en millones de pesos,
incluido el sistema) y devolver hasta 200 filas. Consultas que no sean `SELECT`, que no usen la vista o
que tengan más de una sentencia SHALL fallar con un mensaje claro. La base MUST NOT permitir acceso a
archivos ni red.

#### Scenario: Pregunta fuera del dashboard
- **WHEN** el usuario pregunta "¿qué banco creció más en depósitos a la vista durante 2025?"
- **THEN** el chat llama a `consultar_datos` con una consulta sobre dic 2024 y dic 2025, y responde con el
  banco y su variación según el resultado

#### Scenario: Consulta que modifica datos
- **WHEN** la tool recibe "DELETE FROM balance"
- **THEN** falla con "Solo se permiten consultas SELECT" y los datos no cambian

### Requirement: Ventanas emergentes no bloqueantes
Las ventanas emergentes SHALL cerrarse con un botón, con la tecla Escape o con un clic fuera, y cada
nueva llamada SHALL reemplazar a la anterior. El modelo no ve las ventanas: el prompt SHALL indicarlo y
las tools SHALL devolverle solo resúmenes breves.

#### Scenario: Dos gráficos seguidos
- **WHEN** el chat abre un gráfico de puestos y luego uno de composición
- **THEN** queda abierta solo la ventana de composición
