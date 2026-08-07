# IoT Serverless Architecture - AWS

## Architecture Overview

```
ESP32 (DHT22 Sensor)
    │
    │ MQTT (TLS)
    ▼
┌─────────────────┐
│  AWS IoT Core   │
│  (MQTT Broker)  │
└────────┬────────┘
         │ IoT Rule
         ▼
┌─────────────────┐      ┌─────────────────┐
│  Lambda         │─────▶│   DynamoDB      │
│  (Process Data) │      │  (Sensor Data)  │
└────────┬────────┘      └────────┬────────┘
         │                        │
         │ Notify                 │ Query
         ▼                        ▼
┌─────────────────┐      ┌─────────────────┐
│ API Gateway     │      │  API Gateway    │
│ (WebSocket)     │      │  (REST)         │
└────────┬────────┘      └────────┬────────┘
         │                        │
         └────────┬───────────────┘
                  │
                  ▼
         ┌─────────────────┐
         │   CloudFront    │
         │   (CDN)         │
         └────────┬────────┘
                  │
                  ▼
         ┌─────────────────┐
         │   S3 Bucket     │
         │  (Dashboard)    │
         └─────────────────┘
                  │
                  ▼
         ┌─────────────────┐
         │    Cognito       │
         │ (Authentication) │
         └─────────────────┘
```

## AWS Services Used

| Service | Purpose |
|---------|---------|
| AWS IoT Core | MQTT broker for ESP32 communication |
| AWS Lambda | Process sensor data, API handlers, WebSocket management |
| DynamoDB | Store sensor readings (time-series) |
| API Gateway (REST) | Historical data queries |
| API Gateway (WebSocket) | Real-time data streaming to dashboard |
| Cognito | User authentication for dashboard |
| S3 | Host static dashboard files |
| CloudFront | CDN for dashboard delivery |

## Data Flow

1. ESP32 reads temperature & humidity from DHT22 sensor
2. ESP32 publishes JSON payload via MQTT to AWS IoT Core
3. IoT Rule triggers Lambda function
4. Lambda stores data in DynamoDB and pushes to connected WebSocket clients
5. Dashboard receives real-time updates via WebSocket
6. Users authenticate via Cognito before accessing dashboard
7. Historical data available via REST API
