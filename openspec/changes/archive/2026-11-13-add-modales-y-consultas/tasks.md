# Tasks

## 1. Cálculos (`ranking-bancos`)

- [x] 1.1 Implementar `puestos_en_el_tiempo()`; verificar en `tests/test-ranking.R` el adelantamiento de
  Internacional a Falabella en ago 2026, la salida de Security en nov 2025 y los meses vacíos de Tanner
- [x] 1.2 Implementar `composicion_en_el_tiempo()` y `crecimiento_periodo()`; verificar que la mezcla
  de BCI suma 100 % cada mes y que BICE crece +85,0 % en 12 meses en Colocaciones

## 2. Ventanas emergentes (`chat-analista`)

- [x] 2.1 Crear `R/modales.R` con los cuatro gráficos y las tres tablas; verificar que cada constructor
  produce su objeto sin errores con datos reales
- [x] 2.2 Implementar `mostrar_grafico()` y `mostrar_tabla()` en `crear_tools()` con `abrir_ventana`
  inyectada; verificar en `tests/test-tools.R` (con una función que registra las llamadas) los tipos,
  el límite de 6 bancos y que el estado no cambia
- [x] 2.3 Implementar `abrir_ventana` en el server con outputs efímeros, `modalDialog` y descarga CSV;
  verificar en el navegador que la ventana abre, se cierra con Escape y que el CSV abre bien

## 3. SQL (`chat-analista`)

- [x] 3.1 Crear la base DuckDB con la tabla `balance` legible, `validar_select()` y `consultar_datos()`;
  verificar en `tests/test-tools.R` una consulta válida, el rechazo de DELETE, de `;` y de otra tabla,
  y el límite de 200 filas

## 4. Chat

- [x] 4.1 Registrar las tres tools, ampliar `prompt.md` y `greeting.md`; verificar con
  `chat$register_tool()` sin modelo y que las líneas tienen 110 caracteres o menos
- [x] 4.2 Probar con el modelo los escenarios de la spec ("¿cuándo pasé a Falabella?", composición de
  BCI, tabla para descargar, crecimiento en depósitos a la vista en 2025, DELETE); verificar las tools
  usadas y que las cifras coinciden con las ventanas

## 5. Documentación y verificación final

- [x] 5.1 Actualizar `app-benchmark/README.md` (tools nuevas, vista SQL, descarga); verificar que los
  comandos documentados funcionan
- [x] 5.2 Ejecutar la app desde su carpeta y las tres pruebas; verificar que no hay errores en consola ni
  en outputs

## Workflow follow-up

- Archivar el cambio tras la revisión.
- Retomar la paleta de colores cuando el usuario lo pida.
