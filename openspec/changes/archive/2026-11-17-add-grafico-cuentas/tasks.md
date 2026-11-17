# Tasks

## 1. Cálculo (`ranking-bancos`)

- [x] 1.1 Implementar `serie_cuentas()`; verificar en `tests/test-ranking.R` 24 meses por cuenta, el monto
  de BCI en Colocaciones a sep 2026 y el índice 100 en el primer mes

## 2. Gráfico y tabla (`chat-analista`)

- [x] 2.1 Agregar `grafico_cuentas()` y `tabla_cuentas()` en `R/modales.R` con las tres medidas;
  verificar que construyen sin errores con datos reales
- [x] 2.2 Agregar el tipo `cuentas` y los argumentos `cuentas`, `banco` y `medida` a las tools;
  verificar en `tests/test-tools.R` el gráfico y la tabla de BCI con dos cuentas, el error con una sola
  cuenta y que el estado no cambia

## 3. Saludo y prompt

- [x] 3.1 Reemplazar las sugerencias del saludo por cuatro genéricas y ampliar `prompt.md`; verificar que
  ninguna sugerencia nombra un banco y que las líneas tienen 110 caracteres o menos
- [x] 3.2 Probar con el modelo "muéstrame la evolución de colocaciones y depósitos a plazo de BCI" y las
  cuatro sugerencias; verificar las tools usadas y que las cifras coinciden con las ventanas

## 4. Documentación y verificación final

- [x] 4.1 Actualizar `app-benchmark/README.md`; verificar que los comandos documentados funcionan
- [x] 4.2 Ejecutar la app desde su carpeta y las tres pruebas; verificar que no hay errores

## Workflow follow-up

- Archivar el cambio tras la revisión.
- Retomar la paleta de colores cuando el usuario lo pida.
