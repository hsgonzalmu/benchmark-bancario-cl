## ADDED Requirements

### Requirement: Tope de mensajes por sesión
Cada sesión SHALL poder enviar como máximo `MAX_MENSAJES_CHAT` mensajes al chat (15 si no está definido).
Pasado el tope, el chat SHALL responder un aviso fijo sin llamar a la API, y el dashboard SHALL seguir
funcionando.

#### Scenario: Llegar al tope
- **WHEN** el tope es 15 y el usuario envía su mensaje número 16
- **THEN** el chat responde que se alcanzó el límite de 15 preguntas de la sesión, que puede seguir usando
  los filtros y que recargar la página inicia una sesión nueva, sin llamar a la API

#### Scenario: Tope configurable
- **WHEN** `.Renviron` define `MAX_MENSAJES_CHAT=30`
- **THEN** el aviso aparece en el mensaje 31
