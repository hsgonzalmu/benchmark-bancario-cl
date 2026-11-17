# Spec Delta

## MODIFIED Requirements

### Requirement: Tool mostrar_grafico
La tool `mostrar_grafico(tipo, bancos, cuentas, medida, meses, titulo)` SHALL abrir una ventana emergente
con un gráfico de la selección vigente. `tipo` es `puestos`, `composicion`, `crecimiento`, `evolucion` o
`cuentas`; `bancos` (opcional, hasta 6) reemplaza al conjunto por defecto, que es la escalera; en
`cuentas`, el gráfico muestra un banco (el primero de `bancos` o el analizado) en 2 a 6 `cuentas`, con
`medida` monto, índice base 100 o participación; `meses` es 12, 24 o 36. SHALL devolver un resumen breve
de lo dibujado, sin cambiar el dashboard ni el estado.

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

#### Scenario: Dos cuentas de un banco
- **WHEN** el usuario pide "muéstrame la evolución de colocaciones y depósitos a plazo de BCI"
- **THEN** el chat llama a `mostrar_grafico(tipo = "cuentas", bancos = "BCI", cuentas = c("Colocaciones",
  "Depósitos a plazo"))`, se abre un gráfico con una línea por cuenta y la respuesta comenta la variación
  de cada una según el resumen

#### Scenario: Cuentas de distinto tamaño
- **WHEN** el usuario pide comparar el crecimiento de activos y patrimonio de un banco
- **THEN** el chat usa `medida = "indice"` para que ambas cuentas partan en 100

#### Scenario: Una sola cuenta
- **WHEN** la tool recibe `tipo = "cuentas"` con menos de 2 cuentas
- **THEN** falla con "Elige de 2 a 6 cuentas" y no se abre ninguna ventana

### Requirement: Tool mostrar_tabla
La tool `mostrar_tabla(tipo, banco, cuentas, medida, meses, titulo)` SHALL abrir una ventana emergente
con una tabla de la selección vigente: `ranking` (con puesto y participación de hace 12 meses),
`historia` (mes a mes de los bancos de la escalera), `composicion` (bancos por moneda elegida) o `cuentas`
(mes a mes de un banco en 2 a 6 cuentas, en la medida elegida). La tabla SHALL tener un botón para
descargar sus datos en CSV. SHALL devolver una confirmación breve, sin cambiar el dashboard ni el estado.

#### Scenario: Tabla para llevar
- **WHEN** el usuario pide "dame la tabla de depósitos a plazo para descargarla"
- **THEN** el chat selecciona Depósitos a plazo y llama a `mostrar_tabla(tipo = "ranking")`, y la ventana
  ofrece "Descargar CSV" con las mismas cifras de la tabla

#### Scenario: Tabla de varias cuentas
- **WHEN** el usuario pide "dame en una tabla las colocaciones y depósitos a plazo de BCI mes a mes"
- **THEN** el chat llama a `mostrar_tabla(tipo = "cuentas", banco = "BCI", cuentas = c("Colocaciones",
  "Depósitos a plazo"))` y la ventana muestra una columna por cuenta con su CSV

### Requirement: Chat en el sidebar
La app SHALL mostrar un chat con mensaje de bienvenida y preguntas de ejemplo en el sidebar, en un
acordeón con dos paneles: "Chat" (abierto al iniciar) y "Filtros". Las preguntas de ejemplo MUST NOT
nombrar a un banco en particular. Cada sesión SHALL tener su propio historial de conversación.

#### Scenario: Apertura de la app
- **WHEN** el usuario abre la app
- **THEN** ve el panel del chat abierto con el saludo y cuatro preguntas de ejemplo genéricas que se
  envían al pulsarlas

#### Scenario: Teléfono
- **WHEN** el usuario abre la app en una pantalla de ~400 px
- **THEN** el panel lateral está cerrado y se abre con un botón, mostrando el chat sobre el dashboard

#### Scenario: Dos usuarios a la vez
- **WHEN** dos personas usan la app en sesiones distintas
- **THEN** cada una ve solo su conversación y su propio estado del dashboard

#### Scenario: Pregunta genérica
- **WHEN** el usuario pulsa "¿Qué banco creció más en colocaciones en los últimos 12 meses?"
- **THEN** el chat responde con el banco de mayor crecimiento según `mostrar_grafico(tipo =
  "crecimiento")` y menciona fusiones si explican el resultado
