# Proposal

## Why

Queremos analizar la posición de cada banco chileno frente al sistema, a sus competidores inmediatos y al
líder de cada cuenta, con un resultado visual de alta calidad. Antes de sumar el chat de IA (fases 2–4)
necesitamos datos confiables del Balance Mensual de la CMF y un dashboard sólido que el chat pueda
manejar después.

## What Changes

- Nueva app `app-benchmark/`, ejecutable desde su carpeta, sin chat en esta etapa.
- Script `prepare-data.R` que descarga desde la API CMF (v3) un catálogo acotado de cuentas clave para
  todos los bancos y al menos los últimos 36 meses, normaliza montos y nombres, revisa la calidad
  (suma de bancos frente al total del sistema) y guarda un archivo local que la app lee al iniciar.
- Tablas auxiliares de instituciones (código, nombre corto, abreviación, clasificación de riesgo) y de
  cuentas clave (código, nombre amigable, grupo).
- Cálculo de ranking por cuenta, período y tipo de valor: posición, vecino superior e inferior, líder,
  participación, variación mensual y variación en 12 meses.
- Dashboard con sidebar de filtros manuales (período, banco, cuenta, tipo de valor, modo de
  comparación), encabezado de contexto, cuatro value boxes, gráfico de ranking, tarjeta de comparación
  con pestañas (evolución, base 100, participación, brecha) y tabla de ranking.
- Sistema visual coherente: un color con significado fijo para banco analizado, vecinos, líder, sistema
  y resto; formato numérico chileno y textos de gráficos en español.
- Estado de selección en `reactiveVal` que hoy cambian los filtros y que en la fase 2 cambiarán las
  tools del chat. Este cambio no registra tools ni escenarios conversacionales.

## Capabilities

### New Capabilities
- `datos-balance-cmf`: obtención, normalización, control de calidad y almacenamiento local del Balance
  Mensual de bancos desde la API CMF, con sus tablas auxiliares.
- `ranking-bancos`: métricas comparativas de un banco en una cuenta y período: posición, vecinos, líder,
  participación y variaciones, y los conjuntos de comparación (sistema, vecinos, líder, bancos).
- `dashboard-benchmark`: interfaz del dashboard, estado de selección, visualizaciones y sistema visual.

### Modified Capabilities
<!-- Ninguna: no existen specs previas. -->

## Impact

- Código nuevo en `app-benchmark/` (`app.R`, `prepare-data.R`, `data/`, `www/`, `README.md`).
- Dependencias nuevas de R: `highcharter`, `reactable`, `bsicons` (más `shiny`, `bslib`, `jsonlite`, ya
  instaladas).
- Requiere `CMF_API_KEY` en `.Renviron` para preparar datos; la app no llama a la API en tiempo de uso.
- Highcharts exige licencia para uso comercial o institucional; uso personal o académico es libre.
- La credencial que hoy está en `apikey_cmf.md` pasa a `.Renviron`; ambos quedan en `.gitignore`.
