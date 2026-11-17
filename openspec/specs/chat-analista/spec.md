# chat-analista Specification

## Purpose
Permitir analizar bancos chilenos conversando: el chat consulta y cambia el análisis del dashboard con
tools y responde solo con cifras que esas tools devuelven.

## Requirements

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

### Requirement: Tool listar_opciones
La tool `listar_opciones()` no recibe argumentos y SHALL devolver los nombres de bancos, cuentas (con su
grupo), el primer y último período disponibles, los tipos de valor y los modos de comparación. No cambia
la UI.

#### Scenario: Banco que no existe
- **WHEN** el usuario pide analizar "Banco Pichincha"
- **THEN** el chat consulta `listar_opciones()` y responde que ese banco no está en los datos,
  mencionando los disponibles, sin cambiar el dashboard

### Requirement: Tool ver_analisis
La tool `ver_analisis()` no recibe argumentos y SHALL devolver el resumen del análisis visible (ver
"Resumen del análisis") sin modificar el estado.

#### Scenario: Cambio manual seguido de pregunta
- **WHEN** el usuario elige Itaú en los filtros y luego pregunta "¿y cómo le va a este banco?"
- **THEN** el chat llama a `ver_analisis()` y responde sobre Itaú con las cifras del resumen

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

### Requirement: Tool comparar
La tool `comparar(modo, bancos)` SHALL recibir un modo (`vecinos`, `sistema`, `lider`, `bancos`) y, en
modo `bancos`, de 1 a 4 bancos distintos del analizado; SHALL actualizar `comparacion` y devolver la
evolución de cada integrante en la ventana de 24 meses (monto y participación al inicio y al final,
variación acumulada) y la brecha con el banco analizado al inicio y al final.

#### Scenario: Comparar con el sistema
- **WHEN** el usuario pide "compáralo con el sistema"
- **THEN** la tool recibe `modo = "sistema"`, la tarjeta de comparación muestra el modo sistema y el chat
  responde si el banco creció más o menos que el sistema, con ambas variaciones

#### Scenario: Demasiados bancos
- **WHEN** la tool recibe 5 bancos en modo `bancos`
- **THEN** falla con "Elige entre 1 y 4 bancos" y el estado no cambia

### Requirement: Resumen del análisis
El resumen que devuelven las tools SHALL incluir banco, cuenta, período, monedas elegidas y modo; posición,
monto, participación, variación mensual y en 12 meses del banco; los mismos datos del vecino superior,
del inferior y del líder; la participación conjunta; el total del sistema; el ranking completo de la
cuenta; la escalera con sus brechas y tendencias; el puesto hace 12 meses con la cantidad de bancos de
ambos períodos; y la composición del banco analizado en las monedas elegidas. Montos y porcentajes SHALL ir
ya formateados en formato chileno.

#### Scenario: Pregunta por posición
- **WHEN** el usuario pregunta "¿cómo está Internacional en colocaciones?"
- **THEN** el chat llama a `seleccionar_analisis(banco = "Internacional", cuenta = "Colocaciones")`, el
  dashboard se actualiza y la respuesta da puesto, monto, participación y variación mensual tal como
  vienen en el resumen

#### Scenario: Pregunta por el líder
- **WHEN** el usuario pregunta "¿quién lidera depósitos a plazo y cuánto le falta a Consorcio?"
- **THEN** el chat selecciona Consorcio en Depósitos a plazo, compara con el líder y responde con el
  nombre del líder y la brecha de monto y participación

#### Scenario: Pregunta por la brecha con el vecino
- **WHEN** el usuario pregunta "¿Internacional se está acercando a Consorcio?"
- **THEN** el chat responde con la brecha de hoy, la de hace 12 meses y la tendencia tal como vienen en
  la escalera del resumen

#### Scenario: Pregunta por la composición
- **WHEN** el usuario pregunta "¿cuánto de las colocaciones de BCI está en moneda extranjera?"
- **THEN** el chat responde con el monto y el porcentaje en moneda extranjera de la composición del
  resumen

#### Scenario: Selección de monedas en el resumen
- **WHEN** las monedas elegidas son CLP no reajustable, reajustable IPC y reajustable TC
- **THEN** el resumen indica "Total sin moneda extranjera" y todas sus cifras corresponden a esa selección

### Requirement: Respuestas basadas en datos
El chat SHALL responder en español, de forma breve, citando monto o porcentaje con su unidad, período y
fuente (CMF), y MUST NOT entregar cifras que no provengan de una tool. Las diferencias y cambios de
participación SHALL citarse en puntos base (pb), como los entregan las tools. Cuando algo no está en los
datos (otras cuentas, resultados, indicadores), SHALL decirlo.

#### Scenario: Cifra no disponible
- **WHEN** el usuario pregunta por el ROE de un banco
- **THEN** el chat responde que la app no tiene datos de resultados ni indicadores y ofrece las cuentas
  disponibles

#### Scenario: Brecha en puntos base
- **WHEN** el usuario pregunta cuánto le falta a Internacional para alcanzar a Consorcio
- **THEN** el chat cita "MM$ 1.086.485" y "39 pb" de participación, sin pasarlo a puntos porcentuales

### Requirement: Chat sin API key
Cuando `ANTHROPIC_API_KEY` no está definida, el dashboard SHALL funcionar igual y el chat SHALL responder
a cualquier mensaje con instrucciones para configurar la key, sin errores.

#### Scenario: Pregunta sin key
- **WHEN** no hay key y el usuario escribe una pregunta
- **THEN** el chat responde que falta `ANTHROPIC_API_KEY` en `app-benchmark/.Renviron` y que el dashboard
  sigue disponible con los filtros

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

### Requirement: Tope de mensajes por sesión
Cada sesión SHALL poder enviar como máximo `MAX_MENSAJES_CHAT` mensajes al chat (15 si no está definido).
Pasado el tope, el chat SHALL responder un aviso fijo sin llamar a la API, y el dashboard SHALL seguir
funcionando.

#### Scenario: Llegar al tope
- **WHEN** el tope es 15 y el usuario envía su mensaje número 16
- **THEN** el chat responde que se alcanzó el límite de 15 preguntas de la sesión, que puede seguir usando
  los filtros y que recargar la página inicia una sesión nueva, sin llamar a la API

#### Scenario: Tope configurable
- **WHEN** `.Renviron` define `MAX_MENSAJES_CHAT=30`
- **THEN** el aviso aparece en el mensaje 31
