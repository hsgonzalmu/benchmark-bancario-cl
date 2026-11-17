# Benchmark CL – Dashboard MB1 (Banco Internacional)

*Documento de proyecto · actualizado el 12 de noviembre de 2026*

## 1. Objetivo

Dashboard en Shiny (bslib) para comparar la posición de un banco dentro del sistema financiero chileno, a
partir del modelo **MB1 – Estado de Situación Financiera Consolidado**. El usuario elige período, banco,
cuenta y tipo de valor, y ve:

- El monto del banco seleccionado y su variación mensual.
- El banco que está un puesto **arriba** y el que está un puesto **abajo** en el ranking.
- La participación conjunta de los tres con respecto al total del sistema.
- Un ranking completo de bancos y la evolución histórica.

Los datos se actualizan **una vez al mes**.

## 2. Datos de origen

Dataset principal: ~651.412 filas × 14 columnas.

| Columna | Tipo | Descripción |
|---|---|---|
| `modelo` | chr | Modelo de reporte (ej. `"b1"`) |
| `periodo` | chr | Período `AAAAMM` (ej. `"202511"`) |
| `cod_ifi` | chr | Código de la institución (ej. `"001"`) |
| `ifi` | chr | Razón social del banco |
| `cuenta` | dbl | Código de cuenta contable |
| `monto_clp_no_reajustable` | dbl | Monto CLP no reajustable |
| `monto_reajustable_icp` | dbl | Monto reajustable ICP |
| `monto_reajustable_tc` | dbl | Monto reajustable por tipo de cambio |
| `monto_mx` | dbl | Monto en moneda extranjera |
| `total` | dbl | Suma de los cuatro montos |
| `rubro` | dbl | Rubro contable |
| `linea` | chr | Línea |
| `item` | chr | Ítem |
| `glosa` | chr | Descripción de la cuenta (ej. `"TOTAL"`, `"EFECTIVO"`) |

## 3. Arquitectura de la app

Tres archivos:

- **`global.R`**: librerías, carga de datos (una sola vez al iniciar la app), transformaciones base y listas
  para los filtros. Es el lugar correcto porque los datos son mensuales y se comparten entre sesiones.
- **`ui.R`**: layout con sidebar y contenedores (`uiOutput`, tablas, gráfico). Solo elementos estáticos.
- **`server.R`**: lógica reactiva, filtros, cálculos de ranking y renderizado de componentes dinámicos.

## 4. Diseño del dashboard (estado actual)

**Sidebar (filtros)**
- Período (`selectizeInput`, con valor preseleccionado vía `selected =`)
- Bancos (preseleccionado: BANCO INTERNACIONAL)
- Cuentas (ej. Depósitos a plazo)
- Tipo de valor (radio): Total · CLP No Reajustable · Reajustable ICP · Reajustable TC · Moneda Extranjera

**Encabezado**: banner con modelo, período, banco, tipo de valor y cuenta(s) seleccionadas.

**Fila de value boxes (4)**
1. Banco seleccionado: monto, posición, variación m-1.
2. Banco un puesto arriba: monto, posición, variación m-1.
3. Banco un puesto abajo: monto, posición, variación m-1.
4. Participación conjunta de los tres sobre el total del sistema, más el total.

El ícono (flecha arriba/abajo) y el color dependen del signo de la variación mensual.

**Fila inferior**
- **Ranking de bancos**: posición, banco, valor, var m-1; se destacan el banco seleccionado y sus dos vecinos.
- **Evolución histórica**: líneas por banco en los últimos ~15 meses; los tres bancos de interés resaltados y
  el resto atenuado en la leyenda.

## 5. Decisiones técnicas

### 5.1 Filtrado reactivo
Una sola función `reactive()` en el server filtra los datos cargados en `global.R` según los inputs; todos los
componentes la consumen.

### 5.2 Ranking y bancos vecinos
1. Filtrar por período, cuenta/glosa y tipo de valor.
2. Agrupar por banco, sumar el monto y ordenar de mayor a menor.
3. Asignar `posicion = row_number()`.
4. Tomar la posición del banco seleccionado; el vecino superior es `pos - 1` y el inferior `pos + 1`.
5. Casos borde: el primer lugar no tiene superior y el último no tiene inferior (mostrar "N/A").
6. Excluir `TOTAL SISTEMA FINANCIERO` del ranking; usarlo solo como denominador de la participación.

### 5.3 Value boxes dinámicos (bslib)
- `bslib::value_box()` no tiene `subtitle`; las líneas extra (posición, variación) se agregan con `tagList()`
  / `p()` dentro de `value`.
- Un valor calculado en el server (ej. `"arrow-up"`) **no se puede pasar a un atributo** de un `value_box`
  definido estáticamente en el UI. La solución es construir el `value_box` completo en el server con
  `renderUI()` y usar `uiOutput()` en el UI.
- Ícono: `bsicons::bs_icon(nombre_icono)`, donde `nombre_icono` sale de la variación (`arrow-up`,
  `arrow-down`, `dash`).

### 5.4 Uso de inputs en el UI
`input$...` no existe en el UI. Para textos dinámicos (banner, títulos) se usa `renderText()` / `renderUI()`
en el server y `textOutput()` / `uiOutput()` en el UI.

## 6. Tablas auxiliares

### 6.1 Listado de instituciones (`listado_instituciones.txt`)

| INS_COD | RAZON SOCIAL |
|---|---|
| 1 | BANCO DE CHILE |
| 9 | BANCO INTERNACIONAL |
| 12 | BANCO DEL ESTADO DE CHILE |
| 14 | SCOTIABANK CHILE |
| 16 | BANCO DE CREDITO E INVERSIONES |
| 28 | BANCO BICE |
| 31 | HSBC BANK (CHILE) |
| 37 | BANCO SANTANDER-CHILE |
| 39 | BANCO ITAU CHILE |
| 41 | JP MORGAN CHASE BANK N.A. |
| 49 | BANCO SECURITY |
| 51 | BANCO FALABELLA |
| 53 | BANCO RIPLEY |
| 55 | BANCO CONSORCIO |
| 59 | BANCO BTG PACTUAL CHILE |
| 60 | CHINA CONSTRUCTION BANK |
| 61 | BANK OF CHINA, AGENCIA EN CHILE |
| 999 | TOTAL SISTEMA FINANCIERO |

### 6.2 Clasificación de riesgo (`clasificacion_final.txt`)

Fuente: `Clasificación enero 2026.xlsx`, cruzado con el listado por razón social, más agregados manuales
(HSBC, JP Morgan, China Construction Bank, Bank of China).

| RAZON SOCIAL | Clasificación |
|---|---|
| BANCO DEL ESTADO DE CHILE | AAA |
| BANCO SANTANDER-CHILE | AAA |
| BANCO ITAU CHILE | AAA |
| BANCO DE CHILE | AAA |
| SCOTIABANK CHILE | AAA |
| BANCO DE CREDITO E INVERSIONES | AAA |
| HSBC BANK (CHILE) | AAA |
| JP MORGAN CHASE BANK N.A. | AAA |
| CHINA CONSTRUCTION BANK | AAA |
| BANK OF CHINA, AGENCIA EN CHILE | AAA |
| BANCO SECURITY | AA+ |
| BANCO BICE | AA+ |
| BANCO INTERNACIONAL | AA |
| BANCO CONSORCIO | AA |
| BANCO FALABELLA | AA |
| BANCO BTG PACTUAL CHILE | AA |
| BANCO RIPLEY | AA- |

Uso en R:

```r
clasificaciones <- read.delim("clasificacion_final.txt", check.names = FALSE)
datos <- datos |> left_join(clasificaciones, by = c("ifi" = "RAZON SOCIAL"))
```

### 6.3 Abreviaciones de bancos (propuesta)

Las marcadas con * reemplazan un `NA` o un código numérico de la tabla original.

| ifi | Abreviación |
|---|---|
| BANCO DE CHILE | CHI |
| BANCO INTERNACIONAL | INT |
| BANCO DEL ESTADO DE CHILE | EST |
| SCOTIABANK CHILE | SCO |
| BANCO DE CREDITO E INVERSIONES | BCI * |
| BANCO BICE | BICE |
| HSBC BANK (CHILE) | HSBC * (antes 031) |
| BANCO SANTANDER-CHILE | SAN |
| BANCO ITAU CHILE | ITAU * |
| JP MORGAN CHASE BANK N.A. | JPM * (antes 041) |
| BANCO FALABELLA | FBLA |
| BANCO RIPLEY | RIP |
| BANCO CONSORCIO | CNSCIO |
| BANCO BTG PACTUAL CHILE | BTG * (antes 059) |
| CHINA CONSTRUCTION BANK | CCB * |
| BANK OF CHINA, AGENCIA EN CHILE | BOC * |
| TANNER BANCO DIGITAL | TANNER * |
| TOTAL SISTEMA FINANCIERO | TOTAL * |
| BANCO SECURITY | SCTY |

## 7. Pendientes y observaciones

- **TANNER BANCO DIGITAL** aparece en los datos pero no está en `listado_instituciones.txt` ni tiene
  clasificación de riesgo.
- Confirmar las abreviaciones propuestas antes de fijarlas en `global.R`.
- Cruzar por `cod_ifi` en vez de por nombre sería más robusto ante cambios de razón social.
- Ideas para una segunda versión:
  - Mostrar la clasificación de riesgo en la tabla de ranking o como filtro.
  - Variación interanual (12 meses) además de m-1.
  - Gráfico de participación de mercado.
  - Alertas por variaciones mensuales fuera de rango (ej. BICE +76,8 %, China Construction −51,6 % en
    Depósitos a plazo nov-2025).
