## Why

La escalera muestra solo 5 bancos y, como su tarjeta se estira a la altura de los indicadores, deja mucho
espacio vacío abajo. El usuario quiere ver todo el ranking ahí mismo sin perder el foco en sus
competidores directos.

## What Changes

- La escalera lista todos los bancos del ranking dentro de un área con scroll de la altura de la tarjeta.
- Los 5 competidores (la ventana actual, los mismos que suma el indicador de participación conjunta) se
  ven destacados por igual, con sus brechas; se quita la atenuación de los puestos a dos de distancia. Los demás van en filas
  compactas, sin brecha y pálidas; al pasar el puntero recuperan el color.
- Al cargar, la lista se desplaza para mostrar a los 5 competidores. Los títulos de columna quedan fijos.
- Clic en cualquier banco que no sea el analizado (competidor o pálido) lo selecciona como analizado
  (cambia el filtro Banco, como si se eligiera a mano).
- `escalera()` devuelve además `todos`: el ranking completo con su serie de 12 meses.

## Impact

- `R/ranking.R`, `R/componentes.R`, `app.R`, `www/escalera.js`, `www/styles.css`, spec
  `dashboard-benchmark`.
- Estado reactivo: el clic cambia `banco_foco` por el mismo camino que el filtro Banco. Tools sin cambios:
  `escalera_para_chat` sigue entregando solo los 5 competidores.
- Reversible: respaldo de los archivos previos en el scratchpad de la sesión.
