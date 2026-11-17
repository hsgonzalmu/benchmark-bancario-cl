# Tasks

## 1. Estado inicial

- [x] 1.1 Calcular el banco inicial como líder de Colocaciones en el último período y usarlo en
  `inicial$banco`; verificar en el navegador que la app abre con BCI y la caja superior en "N/A"

## 2. Tools (`chat-analista`)

- [x] 2.1 Crear `R/tools.R` con `resumen_para_chat()` (textos formateados, vecinos, líder, ranking) y
  verificar con `tests/test-tools.R` que coincide con `resumen_posicion()` para Internacional y BCI
- [x] 2.2 Implementar `listar_opciones()`, `ver_analisis()` y `seleccionar_analisis()` en la fábrica
  `crear_tools()`; verificar en `tests/test-tools.R` que cambiar solo la cuenta conserva el banco, que
  sin argumentos falla y que Security en 202609 devuelve "sin datos" con su último período
- [x] 2.3 Implementar `comparar()` con evolución y brechas por modo; verificar en `tests/test-tools.R` los
  cuatro modos, la brecha con el líder y el error con 5 bancos sin cambio de estado
- [x] 2.4 Definir las tools con `ellmer::tool()` y `type_enum()`; verificar que `chat$register_tool()`
  acepta las cuatro sin errores (sin llamar al modelo)

## 3. Chat en la app

- [x] 3.1 Escribir `prompt.md` y `greeting.md` (líneas de 110 caracteres o menos); verificar que el
  saludo se ve en el chat
- [x] 3.2 Pasar el sidebar a acordeón "Chat" / "Filtros", crear el cliente en `server`, registrar tools y
  conectar el streaming; verificar con capturas que el chat ocupa el alto del sidebar a 1440 y 400 px
- [x] 3.3 Sincronizar los filtros cuando las tools cambian el estado; verificar en el navegador, llamando
  a las tools desde la consola del servidor de prueba, que los filtros muestran banco, cuenta, modo y
  bancos nuevos y que el estado no vuelve atrás
- [x] 3.4 Responder sin key con instrucciones; verificar sin `ANTHROPIC_API_KEY` que el chat contesta el
  texto de configuración y el dashboard sigue funcionando

## 4. Conversaciones reales (requiere `ANTHROPIC_API_KEY`)

- [x] 4.1 Agregar la key del usuario a `app-benchmark/.Renviron`; verificar que `nzchar()` es TRUE sin
  imprimirla
- [x] 4.2 Recorrer los escenarios conversacionales de la spec (posición, solo cuenta, sistema, líder,
  Security, cambio manual, banco inexistente, ROE); verificar que cada respuesta usa las tools esperadas
  y que sus cifras coinciden con el dashboard

## 5. Documentación y verificación final

- [x] 5.1 Actualizar `app-benchmark/README.md` (chat, key, modelo y costo, tools, estado); verificar que
  los comandos documentados funcionan
- [x] 5.2 Ejecutar la app desde su carpeta y las pruebas `tests/test-ranking.R` y `tests/test-tools.R`;
  verificar que no hay errores y que todas las líneas tienen 110 caracteres o menos

## Workflow follow-up

- Archivar el cambio tras la revisión.
- Proponer la fase 3 (modales `mostrar_grafico` y `mostrar_tabla`, `consultar_datos` con SQL).
