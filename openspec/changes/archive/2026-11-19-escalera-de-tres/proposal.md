## Why

La escalera de 5 (el banco y dos puestos a cada lado) nació cuando era la única lista visible. Hoy la
escalera muestra todo el ranking, y el bloque de 5 diluye lo importante: los puestos a dos de distancia se
ven tan relevantes como los vecinos directos, aparecen brechas que no tocan al banco y el indicador
"participación conjunta" suma un grupo que cambia según el banco que se mire.

## What Changes

- La escalera es el banco y sus vecinos directos: 3 bancos. El líder muestra a los dos que le siguen y el
  último a los dos de arriba. Las brechas que tocan al banco son "te faltan" y "le llevas".
- El indicador "Participación conjunta" se reemplaza por "Participación de <banco>": su participación, su
  cambio en pb (m/m y 12m), lo que le falta para alcanzar al de arriba y su ventaja sobre el de abajo en
  pb, el sistema, la participación conjunta de los 3 de la escalera como dato de apoyo y un mini gráfico
  de 24 meses en el color del banco. Avisa saltos bruscos.
- El ranking colorea y la tira de Puesto sombrea esos 3 bancos.
- La comparación con vecinos muestra solo esos 3 bancos, sin la leyenda "Agregar:" (que restaba diseño);
  para sumar otros bancos está el modo `bancos` del panel de filtros.
- El chat recibe la escalera de 3; el prompt la describe así.

## Impact

- `R/ranking.R` (`ventana_escalera(radio)`), `R/componentes.R` (`participacion_partes`,
  `caja_participacion`), `R/graficos.R`, `app.R`, `www/escalera.js`, `www/styles.css`, `prompt.md`,
  tests y specs `ranking-bancos` y `dashboard-benchmark`.
- Estado reactivo sin cambios. Tools: `escalera` del resumen trae 3 bancos y 2 brechas.
