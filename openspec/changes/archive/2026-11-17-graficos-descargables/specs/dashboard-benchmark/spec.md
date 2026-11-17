## ADDED Requirements

### Requirement: Gráficos descargables y con animación suave
Todos los gráficos highcharter SHALL entrar con una animación de 1,6 s. Los gráficos del dashboard y de
las ventanas de `mostrar_grafico` SHALL tener un botón de opciones con pantalla completa, imprimir y
descarga en PNG, JPEG y SVG, generados en el navegador sin enviar datos a un servidor externo. Los mini
gráficos de los indicadores SHALL quedar sin botón.

#### Scenario: Descargar un gráfico del dashboard
- **WHEN** el usuario abre el botón de opciones del gráfico de ranking y elige "Descargar PNG"
- **THEN** descarga `grafico-cmf.png` con fondo blanco y la fuente "CMF"

#### Scenario: Descargar un gráfico de una ventana
- **WHEN** el chat abre una ventana con `mostrar_grafico(tipo = "crecimiento")`
- **THEN** el gráfico de la ventana tiene el mismo botón de opciones

#### Scenario: Mini gráficos
- **WHEN** se muestran los indicadores
- **THEN** sus mini gráficos se animan al aparecer y no muestran botón de opciones
