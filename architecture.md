# IoT Serverless Architecture - Diagrama Completo

## Diagrama General

```
                                    ┌─────────────────────────────────────────────────────────────┐
                                    │                        AWS CLOUD                             │
                                    │                                                             │
┌──────────────┐  MQTT/TLS (8883)   │  ┌──────────────────┐     IoT Rule      ┌───────────────┐  │
│              │───────────────────────▶│                  │───────────────────▶│   Lambda      │  │
│  ESP32 +     │                    │  │   AWS IoT Core   │                    │ iot-processor │  │
│  DHT22       │                    │  │   (MQTT Broker)  │                    │               │  │
│              │                    │  └──────────────────┘                    └───┬──┬──┬─────┘  │
└──────────────┘                    │                                              │  │  │        │
                                    │                         ┌───────────────────-┘  │  └──────┐ │
                                    │                         │                       │         │ │
                                    │                         ▼                       │         ▼ │
                                    │              ┌──────────────────┐               │  ┌──────────┐
                                    │              │    DynamoDB      │               │  │   SNS    │
                                    │              │  (sensor-data)   │               │  │ (alerts) │
                                    │              │                  │               │  └────┬─────┘
                                    │              │  PK: device_id   │               │       │     │
                                    │              │  SK: timestamp   │               │       │     │
                                    │              └────────┬─────────┘               │       ▼     │
                                    │                       │                         │   ┌──────┐  │
                                    │                       │ Query                   │   │Email │  │
                                    │                       ▼                         │   └──────┘  │
                                    │              ┌──────────────────┐               │             │
                                    │              │     Lambda       │               │             │
                                    │              │   api-handler    │               │             │
                                    │              └────────┬─────────┘               │             │
                                    │                       │                         │             │
                                    │                       ▼                         ▼             │
                                    │              ┌──────────────────┐    ┌───────────────────┐   │
                                    │              │  API Gateway     │    │   API Gateway     │   │
                                    │              │     (REST)       │    │   (WebSocket)     │   │
                                    │              │                  │    │                   │   │
                                    │              │ GET /sensors     │    │ $connect          │   │
                                    │              │ GET /sensors/:id │    │ $disconnect       │   │
                                    │              └────────┬─────────┘    │ $default          │   │
                                    │                       │             └─────┬──┬──┬───────┘   │
                                    │                       │                   │  │  │           │
                                    │              ┌────────┴────────┐          │  │  │           │
                                    │              │    Cognito      │          ▼  ▼  ▼           │
                                    │              │  (Authorizer)   │    ┌───────────────────┐   │
                                    │              │                 │    │     Lambda (x3)   │   │
                                    │              │ User Pool       │    │  ws-connect       │   │
                                    │              │ App Client      │    │  ws-disconnect    │   │
                                    │              └─────────────────┘    │  ws-default       │   │
                                    │                                     └─────────┬─────────┘   │
                                    │                                               │             │
                                    │                                               ▼             │
                                    │                                     ┌───────────────────┐   │
                                    │                                     │    DynamoDB       │   │
                                    │                                     │ (ws-connections)  │   │
                                    │                                     │                   │   │
                                    │                                     │ PK: connection_id │   │
                                    │                                     └───────────────────┘   │
                                    │                                                             │
                                    │  ┌──────────────────┐    ┌──────────────────┐              │
                                    │  │   CloudFront     │◀───│     S3 Bucket    │              │
                                    │  │   (CDN/HTTPS)    │    │   (Dashboard)    │              │
                                    │  └────────┬─────────┘    └──────────────────┘              │
                                    │           │                                                 │
                                    └───────────┼─────────────────────────────────────────────────┘
                                                │
                                                │ HTTPS
                                                ▼
                                    ┌──────────────────────┐
                                    │   Browser/Usuario    │
                                    │                      │
                                    │  - Login (Cognito)   │
                                    │  - Graficos tiempo   │
                                    │    real (WebSocket)  │
                                    │  - Historico (REST)  │
                                    │  - Descarga CSV      │
                                    │  - Alertas visuales  │
                                    └──────────────────────┘
```

## Flujo de Datos Detallado

### Flujo 1: Ingesta de Datos (ESP32 → DynamoDB)

```
ESP32                IoT Core            Lambda              DynamoDB
  │                     │              iot-processor            │
  │  MQTT Publish       │                   │                  │
  │  topic: sensors/    │                   │                  │
  │  esp32/data         │                   │                  │
  │────────────────────▶│                   │                  │
  │                     │   IoT Rule SQL    │                  │
  │                     │──────────────────▶│                  │
  │                     │                   │   PutItem        │
  │                     │                   │─────────────────▶│
  │                     │                   │                  │
  │                     │                   │   200 OK         │
  │                     │                   │◀─────────────────│
  │                     │                   │                  │
```

### Flujo 2: Broadcast Tiempo Real (Lambda → Dashboard)

```
Lambda              DynamoDB            API Gateway          Browser
iot-processor      ws-connections       (WebSocket)         (Dashboard)
  │                     │                   │                  │
  │   Scan connections  │                   │                  │
  │────────────────────▶│                   │                  │
  │                     │                   │                  │
  │   [conn1, conn2]    │                   │                  │
  │◀────────────────────│                   │                  │
  │                     │                   │                  │
  │   POST @connections/conn1              │                  │
  │───────────────────────────────────────▶│                  │
  │                     │                   │   WS Message     │
  │                     │                   │─────────────────▶│
  │                     │                   │                  │  Actualiza
  │                     │                   │                  │  graficos
  │                     │                   │                  │  y stats
```

### Flujo 3: Alertas (Lambda → SNS → Email)

```
Lambda               Thresholds            SNS                 Email
iot-processor                            (alerts)             (Usuario)
  │                     │                   │                    │
  │  temp > 35°C?       │                   │                    │
  │────────────────────▶│                   │                    │
  │                     │                   │                    │
  │  SI - Alert!        │                   │                    │
  │◀────────────────────│                   │                    │
  │                     │                   │                    │
  │   sns:Publish                           │                    │
  │────────────────────────────────────────▶│                    │
  │                     │                   │   Email            │
  │                     │                   │───────────────────▶│
  │                     │                   │                    │
  │   (Tambien envia alerta via WebSocket al dashboard)         │
  │                     │                   │                    │
```

### Flujo 4: Consulta Historica (Dashboard → REST API)

```
Browser             API Gateway          Cognito             Lambda            DynamoDB
(Dashboard)           (REST)                                api-handler       sensor-data
  │                     │                   │                  │                  │
  │  GET /sensors/id    │                   │                  │                  │
  │  + Bearer token     │                   │                  │                  │
  │────────────────────▶│                   │                  │                  │
  │                     │  Validate token   │                  │                  │
  │                     │──────────────────▶│                  │                  │
  │                     │  OK (valid)       │                  │                  │
  │                     │◀──────────────────│                  │                  │
  │                     │                   │                  │                  │
  │                     │  Invoke Lambda                       │                  │
  │                     │─────────────────────────────────────▶│                  │
  │                     │                   │                  │   Query          │
  │                     │                   │                  │─────────────────▶│
  │                     │                   │                  │   Items[]        │
  │                     │                   │                  │◀─────────────────│
  │                     │                   │                  │                  │
  │                     │  JSON response                       │                  │
  │                     │◀─────────────────────────────────────│                  │
  │  {readings, stats}  │                   │                  │                  │
  │◀────────────────────│                   │                  │                  │
  │                     │                   │                  │                  │
  │  Genera CSV local   │                   │                  │                  │
  │  y descarga         │                   │                  │                  │
```

### Flujo 5: Conexion WebSocket (Dashboard → API Gateway)

```
Browser             API Gateway           Lambda             DynamoDB
(Dashboard)         (WebSocket)          ws-connect         ws-connections
  │                     │                   │                  │
  │  wss://connect      │                   │                  │
  │────────────────────▶│                   │                  │
  │                     │  $connect route   │                  │
  │                     │──────────────────▶│                  │
  │                     │                   │  PutItem         │
  │                     │                   │  {connection_id} │
  │                     │                   │─────────────────▶│
  │                     │                   │                  │
  │                     │  200 OK           │                  │
  │                     │◀──────────────────│                  │
  │  Connection open    │                   │                  │
  │◀────────────────────│                   │                  │
  │                     │                   │                  │
  │  (30s) ping         │                   │                  │
  │────────────────────▶│  $default route   │                  │
  │                     │──────────────────▶│ ws-default       │
  │  pong               │                   │                  │
  │◀────────────────────│◀──────────────────│                  │
  │                     │                   │                  │
  │  Close tab          │                   │                  │
  │────────────────────▶│  $disconnect      │                  │
  │                     │──────────────────▶│ ws-disconnect    │
  │                     │                   │  DeleteItem      │
  │                     │                   │─────────────────▶│
```

## Servicios AWS Utilizados

| Servicio | Recurso | Proposito |
|----------|---------|-----------|
| IoT Core | Thing, Certificate, Policy, Rule | Conectividad MQTT segura con ESP32 |
| Lambda | iot-processor | Procesa datos, guarda, broadcast, alertas |
| Lambda | api-handler | Consultas REST de datos historicos |
| Lambda | ws-connect | Registra conexion WebSocket |
| Lambda | ws-disconnect | Elimina conexion WebSocket |
| Lambda | ws-default | Keepalive ping/pong |
| DynamoDB | sensor-data | Almacena lecturas (PK: device_id, SK: timestamp) |
| DynamoDB | ws-connections | Registro de clientes WebSocket activos |
| API Gateway | REST API | Endpoints HTTP con autorizacion Cognito |
| API Gateway | WebSocket API | Canal bidireccional para datos en tiempo real |
| Cognito | User Pool + Client | Autenticacion de usuarios del dashboard |
| SNS | Topic + Email Sub | Notificaciones de alertas por email |
| S3 | Bucket | Hosting de archivos estaticos (HTML/JS/CSS) |
| CloudFront | Distribution | CDN con HTTPS, cache, SPA routing |
| IAM | Roles + Policies | Permisos minimos para cada Lambda |
| CloudWatch | Log Groups | Logs de todas las funciones Lambda |

## Seguridad

```
┌─────────────────────────────────────────────────────────────────┐
│                         SEGURIDAD                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ESP32 → IoT Core:                                              │
│    - TLS 1.2 (puerto 8883)                                      │
│    - Certificado X.509 por dispositivo                          │
│    - Politica IoT (solo publish a su topic)                     │
│                                                                  │
│  Dashboard → REST API:                                          │
│    - HTTPS (CloudFront)                                         │
│    - JWT Token (Cognito ID Token)                               │
│    - Authorizer valida token en cada request                    │
│                                                                  │
│  Dashboard → WebSocket:                                         │
│    - WSS (TLS)                                                  │
│    - Conexiones con TTL (auto-expiran en 24h)                   │
│                                                                  │
│  S3:                                                            │
│    - Acceso publico bloqueado                                   │
│    - Solo accesible via CloudFront (OAC)                        │
│    - Server-side encryption (AES-256)                           │
│                                                                  │
│  Lambda:                                                        │
│    - IAM roles con permisos minimos                             │
│    - Variables de entorno (no secrets en codigo)                 │
│                                                                  │
│  DynamoDB:                                                      │
│    - Encryption at rest                                         │
│    - TTL para limpieza automatica                               │
│    - Point-in-time recovery (sensor-data)                       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Payload MQTT (ESP32 → IoT Core)

```json
{
  "device_id": "esp32-sensor-01",
  "temperature": 25.30,
  "humidity": 62.10,
  "timestamp": 1691078400000,
  "firmware_version": "1.0.0"
}
```

## Payload WebSocket (Lambda → Dashboard)

```json
{
  "type": "sensor_data",
  "device_id": "esp32-sensor-01",
  "temperature": 25.30,
  "humidity": 62.10,
  "timestamp": 1691078400000,
  "alerts": [
    {
      "type": "temperature_high",
      "severity": "critical",
      "message": "Temperatura alta: 37.5°C (umbral: 35.0°C)",
      "value": 37.5,
      "threshold": 35.0
    }
  ]
}
```
