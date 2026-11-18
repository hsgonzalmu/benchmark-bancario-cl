# Benchmark bancario Chile

Dashboard Shiny para analizar la posición de un banco chileno en una cuenta del balance frente al
sistema, a sus vecinos de ranking, al líder de la cuenta o a otros bancos. Un chat con Claude maneja el
mismo análisis: el usuario pregunta en lenguaje natural y el dashboard se actualiza mientras responde.

## Ejecutar

Desde esta carpeta:

```r
shiny::runApp()
```

Dependencias: `shiny`, `bslib`, `bsicons`, `highcharter`, `reactable`, `ellmer`, `shinychat`, `jsonlite` y
`curl`, `DBI` y `duckdb`.

Claves en `app-benchmark/.Renviron` (excluido de git; deja un salto de línea al final):

```
ANTHROPIC_API_KEY=<key de Anthropic>   # para el chat
CMF_API_KEY=<key de la CMF>            # solo para prepare-data.R
MAX_MENSAJES_CHAT=15                   # opcional: tope de preguntas al chat por sesión
```

El tope de mensajes acota el gasto cuando la app es pública: al llegar a él, el chat responde un aviso sin
llamar a la API y el dashboard sigue funcionando.

`app.R` carga este archivo al iniciar, así que funciona también con `shiny::runApp("app-benchmark")` desde
la carpeta del proyecto. Si cambias una clave, reinicia la app. Sin `ANTHROPIC_API_KEY` el dashboard
funciona igual y el chat responde cómo configurarla.

## Chat

- Modelo `claude-opus-5-5` con effort `low` y fallback del servidor ante rechazos (constantes `modelo` y
  `esfuerzo` al inicio de `app.R`). Para bajar costo se puede usar `claude-sonnet-5-5`.
- Cada pregunta cuesta del orden de 1 a 3 centavos de dólar y tarda entre 5 y 20 segundos, según cuántas
  tools use.
- `prompt.md`: rol, datos, una regla por tool, límites y "no inventes cifras". `greeting.md`: saludo con
  tres sugerencias que se envían al pulsarlas.
- En pantallas angostas el panel lateral está cerrado y se abre con el botón ›.

Tools (`R/tools.R`); todas devuelven JSON con cifras ya formateadas, iguales a las del dashboard:

| Tool | Argumentos | Devuelve | Cambia la UI |
|---|---|---|---|
| `listar_opciones()` | — | Bancos, cuentas, períodos, monedas, modos | No |
| `ver_analisis()` | — | Resumen del análisis visible y ranking completo | No |
| `seleccionar_analisis()` | `banco` o `puesto`, `cuenta`, `periodo`, `monedas` (opc.) | Resumen nuevo | Sí |
| `comparar()` | `modo`, `bancos` (1 a 4, solo modo bancos) | Evolución 24 meses y brechas | Sí |
| `mostrar_grafico()` | `tipo`, `bancos`, `cuentas`, `medida`, `meses`, `titulo` | Resumen | Ventana |
| `mostrar_tabla()` | `tipo`, `banco`, `cuentas`, `medida`, `meses`, `titulo` | Filas | Ventana con CSV |
| `consultar_datos()` | `consulta` (un SELECT sobre `balance`) | Hasta 200 filas | No |

Pruebas sin modelo: `Rscript tests/test-tools.R`.

### Ventanas y consultas

- `mostrar_grafico`: `puestos` (ranking mes a mes con entradas y salidas de bancos marcadas, como la
  fusión BICE-Security), `composicion` (mezcla de monedas de un banco en el tiempo), `crecimiento`
  (variación de todos los bancos en 12, 24 o 36 meses), `evolucion` (monto de hasta 6 bancos) y
  `cuentas` (un banco en 2 a 6 cuentas a la vez, en monto, índice base 100 o participación; desde la
  cuarta cuenta la línea va punteada).
- `mostrar_tabla`: `ranking` (con puesto y participación de hace 12 meses), `historia` (mes a mes de la
  escalera), `composicion` (bancos por moneda) y `cuentas` (un banco en varias cuentas, mes a mes). El
  botón "Descargar CSV" entrega un archivo con `;`, decimal `,` y marca UTF-8, que Excel en Chile abre
  directo.
- `consultar_datos`: SQL de solo lectura en DuckDB, en memoria, sin acceso a archivos ni red. Tabla
  `balance`: `periodo`, `fecha`, `cod_ifi`, `banco` ("Sistema" es el total), `cuenta`, `cuenta_nombre`,
  `grupo`, `clp_mm`, `ipc_mm`, `tc_mm`, `mx_mm`, `total_mm` (millones de pesos). Solo `SELECT`, una
  sentencia y como máximo 200 filas.

Las ventanas usan el período y las monedas actuales (y la cuenta actual, salvo `cuentas`) y no cambian
el dashboard. El modelo no las ve: recibe un resumen breve para comentarlas.

Las preguntas de ejemplo del saludo son genéricas (líder, mayor crecimiento, participación); el chat
resuelve "el líder" o "el que más creció" con los datos, sin suponer un banco. Las preguntas por un puesto
("¿quién es el top en depósitos en UF?", "el segundo en colocaciones") usan `seleccionar_analisis` con
`puesto`, así el dashboard y los filtros quedan en ese banco.

## Datos

Fuente: API CMF v3, Balance mensual de bancos (`balances/<AAAA>/cuentas/<cuenta>`). La app no llama a la
API: lee `data/balance.rds`, generado por `prepare-data.R`.

Actualización mensual, desde esta carpeta:

```sh
Rscript prepare-data.R
```

El script necesita la API key en `app-benchmark/.Renviron` (excluido de git):

```
CMF_API_KEY=<tu key>
```

Descarga desde enero de hace tres años hasta el último mes publicado (unas 44 llamadas, menos de un
minuto), convierte los montos a pesos, guarda el archivo de forma atómica e imprime un reporte de
calidad:

- Códigos de institución sin ficha en `data/instituciones.csv` (la app usa el nombre de la API).
- Cuentas y períodos donde la suma de bancos difiere del total del sistema (`999`) en más de 0,5 %.

La conexión fuerza IPv4: desde algunas redes `api.cmfchile.cl` no responde por IPv6.

| Archivo | Contenido |
|---|---|
| `data/cuentas.csv` | Catálogo de cuentas clave: código de 9 dígitos, nombre amigable y grupo |
| `data/instituciones.csv` | `cod_ifi`, nombre corto, abreviación, clasificación de riesgo, razón social |
| `data/balance.rds` | Montos por período, institución y cuenta (`clp`, `ipc`, `tc`, `mx`, `total`) |

Para agregar una cuenta, añade una fila a `data/cuentas.csv` (el código debe existir en
`balances/<AAAA>/<MM>/cuentas`) y vuelve a ejecutar `prepare-data.R`.

Particularidades de los datos:

- BICE (`028`) se fusionó con Banco Security (`049`): Security informa hasta oct 2025 y desde nov 2025
  BICE incluye su balance, por eso BICE casi duplica su participación ese mes. Al salir Security, los
  bancos que estaban debajo suben un puesto en nov 2025 sin haber crecido.
- Tanner (`062`) informa desde oct 2025. Los rankings usan solo las instituciones con dato en el período
  elegido.
- Las provisiones son negativas: el ranking ordena por valor absoluto.

## Estructura

| Archivo | Rol |
|---|---|
| `app.R` | Datos, interfaz, estado reactivo, outputs y chat |
| `prompt.md`, `greeting.md` | System prompt y saludo del chat |
| `R/tools.R` | Contexto de datos, resúmenes para el chat y las siete tools |
| `R/modales.R` | Gráficos y tablas de las ventanas emergentes, y escritura del CSV |
| `R/sql.R` | Base DuckDB de solo lectura y validación de consultas |
| `R/ranking.R` | Ranking, vecinos, líder, participación, variaciones y series de comparación (puras) |
| `R/graficos.R` | Gráficos highcharter y tabla reactable |
| `R/componentes.R` | Value boxes y encabezado |
| `R/formato.R` | Formato chileno de montos, porcentajes y períodos |
| `R/tema.R` | Paleta por rol, tema bslib y opciones de idioma de highcharter |
| `www/styles.css` | Estilos complementarios |
| `tests/test-ranking.R` | Pruebas de los cálculos: `Rscript tests/test-ranking.R` |
| `tests/test-tools.R` | Pruebas de las tools sin modelo: `Rscript tests/test-tools.R` |
| `tests/test-colores.R` | Pruebas de la paleta por banco: `Rscript tests/test-colores.R` |

Estado reactivo (`reactiveVal`): `banco_foco`, `cuenta`, `periodo`, `monedas` y `comparacion`
(`modo` + `bancos`). Los cambian los filtros y las tools `seleccionar_analisis` y `comparar`; todos los
outputs derivan de ellos. Cuando cambia el chat, los filtros se actualizan solos. Al abrir, el banco
analizado es el líder de Colocaciones en el último período.

## Selección de monedas

En Filtros se eligen las monedas a sumar: CLP no reajustable, reajustable IPC, reajustable TC y moneda
extranjera, en cualquier combinación (las cuatro = Total; "Marcar todas" vuelve al Total). Todo se
calcula sobre esa suma: ranking, participación (sobre la misma suma del sistema), escalera, puesto,
gráficos, pesas, tabla, composición y resumen del chat. El encabezado nombra la selección ("Total sin
moneda extranjera", "Reajustable IPC"). La selección no puede quedar vacía. Ejemplo: sin moneda
extranjera, BCI pasa del 1° al 4° puesto en Colocaciones a sep 2026.

## Escalera de competencia

Bajo el encabezado, el banco analizado y hasta dos puestos hacia cada lado (5 bancos; en los extremos la
ventana se desplaza: el 1° muestra del 1° al 5°). Entre cada par va la brecha de hoy en MM$ y puntos
base (pb), la de hace 12 meses y su tendencia: se acorta, se amplía, estable (cambio menor a 2 pb) o
cambio de orden.
Las brechas que tocan al banco analizado se leen desde su punto de vista ("te faltan", "le llevas").
La lista incluye todo el ranking con scroll: los demás bancos van en filas compactas y pálidas, sin
brecha. Clic en cualquier banco que no sea el analizado (también los vecinos) lo deja como
analizado. Al cargar, la lista se desplaza a los competidores.
La línea de 12 meses es interactiva (`www/escalera.js`, sin dependencias): al pasar el puntero muestra
mes y participación ("abr 2026 · 20,89 %") y marca ese mismo mes en las líneas de los demás bancos.

A su lado (fila 7/5), dos indicadores con un gráfico a la derecha:

- **Participación conjunta**: el peso de los bancos de la escalera sobre el sistema como cifra
  principal, su cambio en puntos base (pb; 1 pp = 100 pb) en el mes y en 12 meses, el total del
  sistema en negrita con su variación mensual, y la participación del banco analizado. Gráfico de
  área de 24 meses con tooltip. Si la serie salta más de 100 pb en un mes (por ejemplo, +269 pb en nov
  2025 por la fusión BICE-Security), lo avisa para que el cambio en 12 meses no se lea como
  crecimiento propio.
- **Puesto**: el puesto del banco y su cambio en 12 meses. Si salió o entró un banco, no lo muestra en el
  indicador, pero el chat lo sabe y lo explica cuando preguntan por el cambio de puesto. Tira de
  posiciones a lo ancho, del 1° al último: los bancos de la escalera con su color y su número, el
  analizado más grande y el puesto de hace 12 meses como anillo con una flecha. Cada punto muestra
  puesto y nombre al pasar el puntero, y un clic deja ese banco como analizado. Lleva el mismo borde
  de acento que Participación conjunta.

## Comparación

| Modo | Integrantes | Brecha | Posición 12m |
|---|---|---|---|
| Vecinos | Los 5 de la escalera; 2 ocultos en la leyenda | Distancia al superior y al inferior | Escalera |
| Sistema | Banco y sistema (eje propio, punteado) | Crecimiento del banco menos el del sistema | Todos |
| Líder | Banco y líder | Monto y puntos de participación del líder sobre el banco | Banco y líder |
| Bancos | Banco y hasta 4 bancos elegidos | Monto de cada banco elegido menos el del analizado | Elegidos |

Vecinos y líder se fijan en el período elegido y se siguen como las mismas instituciones en toda la
serie (24 meses). La pestaña Posición 12m muestra la participación hace 12 meses (punto claro) y hoy
(punto lleno).

## Tabla de ranking

Incluye la composición por moneda de las monedas elegidas: barra apilada y, al expandir la fila (▸), los
montos y su porcentaje sobre la selección. Si los
componentes tienen signos distintos (casi siempre en Patrimonio), la celda dice "signos mixtos" y no hay
porcentajes.

## Sistema visual

Cada banco tiene un color fijo en todos los gráficos y consultas (columna `color` de
`data/instituciones.csv`). El banco analizado se destaca con línea gruesa, negrita y fondo; el sistema va
en gris oscuro punteado y los bancos de contexto en gris claro.

Con 18 bancos, algunos colores se parecen. Por eso cada banco va siempre con su nombre, y en gráficos de
líneas y pesas, si dos bancos visibles tienen colores parecidos (separación OKLab menor a 15, o menor a 6
con daltonismo), uno se dibuja punteado. `Rscript tests/test-colores.R` comprueba que en toda escalera
no quedan dos bancos con trazo continuo y color parecido.

Montos en millones de pesos con la notación de la CMF (MM$ = millones de pesos) en escalera, chat y
tabla: "MM$ 4.945.269" (bajo MM$ 10, con un decimal). Los gráficos usan miles de millones de pesos en los
ejes. Separador de miles "." y decimal ",".

## Notas

- **Licencia de Highcharts**: gratuita para uso personal, académico y sin fines de lucro; el uso
  comercial o institucional requiere licencia (https://shop.highcharts.com).
- La fuente Inter se carga desde Google Fonts; sin conexión se usa la fuente del sistema.
- R debe correr con una configuración regional UTF-8 (lo normal en RStudio). Con `LANG` vacío, R usa
  `C` y los acentos de los textos se ven mal; en ese caso: `LC_ALL=en_US.UTF-8 Rscript ...`.

## Pendientes

- **Paleta de colores por banco** (ajustada 13-11-2026): marca como ancla. Santander, BancoEstado y
  Ripley usan su color de marca; Falabella un verde más profundo, Scotiabank un rojo vino e Itaú su azul
  secundario, para separarse de sus vecinos frecuentes. El resto se optimizó dentro de su familia de tono.
  Parejas frecuentes: separación mínima 15,2 (visión normal) y 7,2 (daltonismo); la vista de vecinos ya
  no necesita trazo punteado. Se valida con `tests/test-colores.R`.
- **Tipografía** (propuesta, 13-11-2026): sans neogrotesca con cifras tabulares y dígitos abiertos para
  datos (tablas, escalera, indicadores, ejes) y serif editorial para el texto del chat y los títulos.
  Opciones: IBM Plex Sans + IBM Plex Serif, o Inter (actual) + Source Serif 4. Siguiente paso: página de
  comparación con piezas reales de la app antes de decidir.
