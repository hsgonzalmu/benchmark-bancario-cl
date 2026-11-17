## MODIFIED Requirements

### Requirement: Respuestas basadas en datos
El chat SHALL responder en español, de forma breve, citando monto o porcentaje con su unidad, período y
fuente (CMF), y MUST NOT entregar cifras que no provengan de una tool. Las diferencias y cambios de
participación SHALL citarse en puntos base (pb), como los entregan las tools. Cuando algo no está en los
datos (otras cuentas, resultados, indicadores), SHALL decirlo.

#### Scenario: Cifra no disponible
- **WHEN** el usuario pregunta por el ROE de un banco
- **THEN** el chat responde que la app no tiene datos de resultados ni indicadores y ofrece las cuentas
  disponibles

#### Scenario: Brecha en puntos base
- **WHEN** el usuario pregunta cuánto le falta a Internacional para alcanzar a Consorcio
- **THEN** el chat cita "MM$ 1.086.485" y "39 pb" de participación, sin pasarlo a puntos porcentuales
