# Spec Delta

## Purpose

Permitir analizar bancos chilenos conversando: el chat consulta y cambia el análisis del dashboard con
tools y responde solo con cifras que esas tools devuelven.

## ADDED Requirements

### Requirement: Chat en el sidebar
La app SHALL mostrar un chat con mensaje de bienvenida y preguntas de ejemplo en el sidebar, en un
acordeón con dos paneles: "Chat" (abierto al iniciar) y "Filtros". Cada sesión SHALL tener su propio
historial de conversación.

#### Scenario: Apertura de la app
- **WHEN** el usuario abre la app
- **THEN** ve el panel del chat abierto con el saludo y tres preguntas de ejemplo que se envían al
  pulsarlas

#### Scenario: Teléfono
- **WHEN** el usuario abre la app en una pantalla de ~400 px
- **THEN** el panel lateral está cerrado y se abre con un botón, mostrando el chat sobre el dashboard

#### Scenario: Dos usuarios a la vez
- **WHEN** dos personas usan la app en sesiones distintas
- **THEN** cada una ve solo su conversación y su propio estado del dashboard

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
La tool `seleccionar_analisis(banco, cuenta, periodo, tipo_valor)` SHALL aceptar cada argumento como
opcional y limitado a los valores disponibles, actualizar solo los que se entreguen y devolver el
resumen del análisis resultante. Sin argumentos, SHALL fallar con un mensaje claro.

#### Scenario: Cambiar solo la cuenta
- **WHEN** el análisis es BCI en Colocaciones y el usuario pide "ahora en depósitos a plazo"
- **THEN** la tool recibe solo `cuenta = "Depósitos a plazo"`, el banco sigue siendo BCI y el dashboard
  muestra depósitos a plazo

#### Scenario: Banco sin datos en el período
- **WHEN** se selecciona Security en sep 2026
- **THEN** el dashboard muestra el aviso de sin datos y el resumen indica que no hay datos y su último
  período disponible (oct 2025), para que el chat lo ofrezca

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
El resumen que devuelven las tools SHALL incluir banco, cuenta, período, tipo de valor y modo; posición,
monto, participación, variación mensual y en 12 meses del banco; los mismos datos del vecino superior,
del inferior y del líder; la participación conjunta; el total del sistema; y el ranking completo de la
cuenta. Montos y porcentajes SHALL ir ya formateados en formato chileno.

#### Scenario: Pregunta por posición
- **WHEN** el usuario pregunta "¿cómo está Internacional en colocaciones?"
- **THEN** el chat llama a `seleccionar_analisis(banco = "Internacional", cuenta = "Colocaciones")`, el
  dashboard se actualiza y la respuesta da puesto, monto, participación y variación mensual tal como
  vienen en el resumen

#### Scenario: Pregunta por el líder
- **WHEN** el usuario pregunta "¿quién lidera depósitos a plazo y cuánto le falta a Consorcio?"
- **THEN** el chat selecciona Consorcio en Depósitos a plazo, compara con el líder y responde con el
  nombre del líder y la brecha de monto y participación

### Requirement: Respuestas basadas en datos
El chat SHALL responder en español, de forma breve, citando monto o porcentaje con su unidad, período y
fuente (CMF), y MUST NOT entregar cifras que no provengan de una tool. Cuando algo no está en los datos
(otras cuentas, resultados, indicadores), SHALL decirlo.

#### Scenario: Cifra no disponible
- **WHEN** el usuario pregunta por el ROE de un banco
- **THEN** el chat responde que la app no tiene datos de resultados ni indicadores y ofrece las cuentas
  disponibles

### Requirement: Chat sin API key
Cuando `ANTHROPIC_API_KEY` no está definida, el dashboard SHALL funcionar igual y el chat SHALL responder
a cualquier mensaje con instrucciones para configurar la key, sin errores.

#### Scenario: Pregunta sin key
- **WHEN** no hay key y el usuario escribe una pregunta
- **THEN** el chat responde que falta `ANTHROPIC_API_KEY` en `app-benchmark/.Renviron` y que el dashboard
  sigue disponible con los filtros
