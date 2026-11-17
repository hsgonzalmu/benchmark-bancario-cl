# datos-balance-cmf Specification

## Purpose
Disponer localmente del Balance Mensual de bancos de la CMF, limpio y validado, para que el dashboard y
el chat analicen cuentas clave sin depender de la API en tiempo de uso.

## Requirements

### Requirement: Descarga de cuentas clave desde la API CMF
El script de preparación SHALL descargar, para cada cuenta del catálogo de cuentas clave, los montos de
todas las instituciones informadas, incluido el total del sistema (código `999`), desde enero del año
actual menos 3 hasta el último mes publicado.

#### Scenario: Descarga completa
- **WHEN** se ejecuta el script con una API key válida
- **THEN** el archivo resultante contiene todas las cuentas del catálogo, todos los meses publicados del
  rango y una fila por institución, cuenta y período

#### Scenario: Mes aún no publicado
- **WHEN** la API responde "No hay datos disponibles" para un mes o año
- **THEN** el script omite ese período sin fallar e informa el último período descargado

#### Scenario: Falla transitoria de la API
- **WHEN** una llamada falla por timeout o error de red
- **THEN** el script reintenta al menos tres veces antes de detenerse con un mensaje que indica la cuenta
  y el año afectados

### Requirement: Credencial fuera del código
El script MUST leer la API key desde la variable de entorno `CMF_API_KEY` y MUST NOT escribirla en
archivos, mensajes ni registros.

#### Scenario: Key ausente
- **WHEN** `CMF_API_KEY` no está definida
- **THEN** el script se detiene antes de llamar a la API con un mensaje que explica cómo definirla

### Requirement: Normalización de montos y períodos
Los montos SHALL convertirse de texto con coma decimal a números en pesos chilenos, y cada fila SHALL
tener un período `AAAAMM` y una fecha del primer día del mes.

#### Scenario: Monto con coma decimal
- **WHEN** la API entrega `"7019316661760,00"`
- **THEN** el dato almacenado es el número 7019316661760

### Requirement: Identificación de instituciones por código
Las instituciones SHALL identificarse por `cod_ifi` de tres dígitos; nombre corto, abreviación y
clasificación de riesgo SHALL provenir de la tabla auxiliar de instituciones, no del nombre que entrega
la API.

#### Scenario: Nombre distinto en la API
- **WHEN** la API entrega "ITAÚ CHILE" para el código `039`
- **THEN** la app muestra el nombre corto definido en la tabla auxiliar para `039`

#### Scenario: Institución sin ficha
- **WHEN** aparece un código que no está en la tabla auxiliar
- **THEN** el script conserva sus datos, usa el nombre de la API como nombre corto y lo informa como
  pendiente

### Requirement: Control de calidad contra el total del sistema
El script SHALL comparar, por cuenta y período, la suma de las instituciones con el total del sistema e
informar las diferencias mayores a 0,5 %, sin detener la preparación.

#### Scenario: Diferencia fuera de tolerancia
- **WHEN** la suma de bancos difiere del código `999` en más de 0,5 % para una cuenta y período
- **THEN** el reporte de calidad lista la cuenta, el período y la diferencia porcentual

### Requirement: Almacenamiento local para la app
El resultado SHALL guardarse en la carpeta `data/` de la app junto con la fecha de descarga, y la app
SHALL leerlo una sola vez al iniciar, sin llamar a la API.

#### Scenario: App sin conexión
- **WHEN** se inicia la app sin acceso a internet y con los datos ya preparados
- **THEN** la app carga y muestra el último período disponible

#### Scenario: Datos no preparados
- **WHEN** se inicia la app y falta el archivo de datos
- **THEN** la app se detiene con un mensaje que indica ejecutar `prepare-data.R`
