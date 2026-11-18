## Why

El indicador Puesto se veía pobre al lado de Participación conjunta: un número, un chip y una tira de
puntos chica arrinconada a la derecha.

## What Changes

- Ficha de posición: mismo borde de acento que Participación conjunta, etiqueta con el color del banco y
  la cuenta ("Puesto de ● Internacional · Colocaciones"), el puesto con su cambio en 12 meses y, debajo,
  la tira de puestos a lo ancho; el bloque va centrado en el alto de la tarjeta.
- Tira: los bancos de la escalera con su color y su número de puesto, el analizado más grande y el
  puesto de hace 12 meses como anillo con flecha. Al pasar el puntero, cada punto muestra puesto y nombre;
  clic en cualquier punto (salvo el analizado) selecciona ese banco, como en la escalera.
- Se probó un pie con hace 12 meses y mejor y peor puesto en 24 meses, y una leyenda; el usuario los
  descartó por recargar la tarjeta sin aportar.

## Impact

- `R/componentes.R`, `app.R`, `www/styles.css`, spec `dashboard-benchmark`.
- Tools y estado reactivo: sin cambios.
