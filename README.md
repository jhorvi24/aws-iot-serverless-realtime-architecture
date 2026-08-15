# IoT Serverless Architecture - AWS

Arquitectura completamente serverless para IoT que recibe datos de temperatura y humedad de un ESP32, los almacena en DynamoDB y los muestra en tiempo real a través de un dashboard con autenticación.

## Arquitectura

```
                                         ┌─────────── AWS Cloud ───────────┐
                                         │                                 │
                                         │         ┌───────────┐           │
                                         │    ┌───▶│  DynamoDB  │◀──┐      │
                                         │    │    │(sensor-data)│   │      │
                                         │    │    └────────────┘   │      │
                                         │    │Store            Query│      │
┌───────────┐   MQTT/TLS    ┌──────────┐ │ ┌──┴───────────┐  ┌─────┴────┐ │
│  ESP32    │──────────────▶│ IoT Core │───▶│   Lambda     │  │  Lambda  │ │
│  DHT22    │               │  (MQTT)  │ │ │iot-processor │  │api-handler│ │
└───────────┘               └──────────┘ │ └──┬────┬──────┘  └─────┬────┘ │
                                         │    │    │                │      │
                                         │    │    │         ┌──────┴────┐ │
                                         │    │    │         │ API GW    │ │
                                         │    │    │         │  (REST)   │ │
                                         │    ▼    ▼         └──────┬────┘ │
                                         │ ┌─────┐ ┌──────────┐    │      │
                                         │ │ SNS │ │  API GW   │   │      │
                                         │ │email│ │(WebSocket)│   │      │
                                         │ └──┬──┘ └─────┬────┘    │      │
                                         │    │          │         │      │
                                         │    │          │    ┌────┴────┐ │
                                         │    │          │    │ Cognito │ │
                                         │    │          │    │ (Auth)  │ │
                                         │    │          │    └─────────┘ │
                                         │    │          │                │
                                         │    │    ┌─────┴──────┐        │
                                         │    │    │ CloudFront  │        │
                                         │    │    │  + S3       │        │
                                         │    │    └─────┬──────┘        │
                                         │    │          │               │
                                         └────┼──────────┼───────────────┘
                                              │          │
                                              ▼          ▼
                                         ┌─────────────────────┐
                                         │   Usuario/Browser   │
                                         │  - Dashboard        │
                                         │  - Alertas email    │
                                         │  - CSV export       │
                                         └─────────────────────┘
```

## Servicios AWS

| Servicio | Proposito |
|----------|-----------|
| AWS IoT Core | Broker MQTT para comunicacion con ESP32 |
| Lambda (x5) | Procesamiento de datos, API, WebSocket |
| DynamoDB (x2) | Almacenamiento de lecturas + conexiones WS |
| API Gateway REST | Consultas historicas (protegido con Cognito) |
| API Gateway WebSocket | Streaming de datos en tiempo real |
| Cognito | Autenticacion de usuarios del dashboard |
| S3 | Hosting de archivos estaticos del dashboard |
| CloudFront | CDN con HTTPS para el dashboard |
| SNS | Notificaciones por email de alertas de umbrales |

## Estructura del Proyecto

```
.
├── terraform/                  # Infraestructura como codigo
│   ├── main.tf               # Configuracion principal (orquesta modulos)
│   ├── variables.tf          # Variables de entrada
│   ├── outputs.tf            # Outputs del despliegue
│   ├── providers.tf          # Providers de Terraform
│   ├── terraform.tfvars.example
│   └── modules/
│       ├── iot_core/         # IoT Thing, Certificate, Policy, Rule
│       ├── dynamodb/         # Tablas de datos y conexiones
│       ├── lambda/           # Funciones Lambda + IAM roles
│       ├── api_gateway/      # REST API + WebSocket API
│       ├── cognito/          # User Pool + App Client
│       ├── alerts/           # SNS Topic + Suscripcion email
│       └── frontend_hosting/ # S3 + CloudFront
├── lambda/                    # Codigo de las funciones Lambda
│   ├── iot_processor/        # Procesa datos del IoT Core
│   ├── api_handler/          # Maneja consultas REST
│   └── websocket_handler/    # Gestiona conexiones WebSocket
├── frontend/                  # Dashboard SPA
│   ├── index.html
│   └── src/
│       ├── config.js         # Configuracion (endpoints, IDs)
│       ├── auth.js           # Autenticacion Cognito
│       ├── websocket.js      # Conexion WebSocket
│       ├── charts.js         # Graficos Chart.js
│       ├── app.js            # Logica principal
│       └── styles/
│           └── main.css      # Estilos dark theme
├── firmware/                  # Codigo ESP32
│   ├── platformio.ini        # Configuracion PlatformIO
│   └── src/
│       ├── main.cpp          # Programa principal
│       └── config.h          # Configuracion WiFi/AWS/Certs
└── architecture.md           # Diagrama detallado
```

## Prerequisitos

- [Terraform](https://terraform.io) >= 1.5.0
- [AWS CLI](https://aws.amazon.com/cli/) configurado
- [PlatformIO](https://platformio.org/) para firmware ESP32
- ESP32 DevKit + Sensor DHT22
- Cuenta AWS con permisos de administrador

## Despliegue

### 0. Configurar AWS Profile

Antes de desplegar, debes crear un perfil de AWS CLI con tus credenciales:

```bash
aws configure --profile iot-serverless
```

Esto te pedira:
- AWS Access Key ID
- AWS Secret Access Key
- Default region (us-east-1)
- Default output format (json)

Luego, edita el archivo `terraform/variables.tf` y coloca el nombre de tu profile en la variable `aws_profile`:

```hcl
variable "aws_profile" {
  description = "AWS Profile"
  type        = string
  default     = "iot-serverless"  # <-- nombre del profile que creaste
}
```

Este perfil es usado por el provider de Terraform para autenticarse contra AWS.

### 1. Infraestructura (Terraform)

```bash
cd terraform

# Copiar y editar variables
cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars con tus valores

# Inicializar y desplegar
terraform init
terraform plan
terraform apply
```

### 2. Actualizar WebSocket Endpoint en Lambda IoT Processor

Despues del despliegue, la Lambda `iot-processor` necesita el endpoint del WebSocket API para hacer broadcast a los clientes conectados. Este endpoint usa `https://` (no `wss://`) porque la Lambda no se conecta como cliente WebSocket, sino que llama a la **API Gateway Management API** via HTTP POST para enviar mensajes a los clientes ya conectados.

```bash
# Obtener el WebSocket API endpoint y convertir wss:// a https://
# (formato requerido por API Gateway Management API)
WS_ENDPOINT=$(terraform output -raw websocket_api_url | sed 's|wss://|https://|')

# Obtener el nombre de la funcion Lambda IoT Processor
FUNCTION_NAME=$(aws lambda list-functions \
  --query "Functions[?contains(FunctionName,'iot-processor')].FunctionName" \
  --output text)

# Obtener las variables de entorno actuales y actualizar WEBSOCKET_API_ENDPOINT
DYNAMODB_TABLE=$(terraform output -raw dynamodb_table_name 2>/dev/null || aws lambda get-function-configuration \
  --function-name $FUNCTION_NAME \
  --query "Environment.Variables.DYNAMODB_TABLE_NAME" --output text)

CONNECTIONS_TABLE=$(aws lambda get-function-configuration \
  --function-name $FUNCTION_NAME \
  --query "Environment.Variables.CONNECTIONS_TABLE_NAME" --output text)

# Actualizar la variable de entorno de la Lambda
aws lambda update-function-configuration \
  --function-name $FUNCTION_NAME \
  --environment "Variables={DYNAMODB_TABLE_NAME=${DYNAMODB_TABLE},CONNECTIONS_TABLE_NAME=${CONNECTIONS_TABLE},WEBSOCKET_API_ENDPOINT=${WS_ENDPOINT},SNS_TOPIC_ARN=$(terraform output -raw sns_alerts_topic_arn),TEMP_THRESHOLD_HIGH=35.0,TEMP_THRESHOLD_LOW=5.0,HUMIDITY_THRESHOLD_HIGH=85.0,HUMIDITY_THRESHOLD_LOW=20.0,ENVIRONMENT=dev}"
```

Verificar que se actualizo correctamente:
```bash
aws lambda get-function-configuration \
  --function-name $FUNCTION_NAME \
  --query "Environment.Variables.WEBSOCKET_API_ENDPOINT" \
  --output text
```

### 3. Obtener Outputs

```bash
# Ver todos los outputs
terraform output

# Outputs importantes:
terraform output iot_endpoint          # Endpoint MQTT para ESP32
terraform output cognito_user_pool_id  # Para configurar el dashboard
terraform output cognito_client_id     # Para configurar el dashboard
terraform output rest_api_url          # API REST endpoint
terraform output websocket_api_url     # WebSocket endpoint
terraform output dashboard_url         # URL del dashboard
terraform output s3_bucket_name        # Bucket para subir frontend
```

### 4. Configurar el Dashboard

Editar `frontend/src/config.js` con los outputs de Terraform:

```javascript
const CONFIG = {
  COGNITO_USER_POOL_ID: '<cognito_user_pool_id>',
  COGNITO_CLIENT_ID: '<cognito_client_id>',
  COGNITO_REGION: 'us-east-1',
  REST_API_URL: '<rest_api_url>',
  WEBSOCKET_API_URL: '<websocket_api_url>',
  ...
};
```

### 5. Subir Dashboard a S3

```bash
# Subir archivos del frontend al bucket S3
aws s3 sync frontend/ s3://<bucket-name>/ --delete

# Invalidar cache de CloudFront
aws cloudfront create-invalidation \
  --distribution-id <distribution_id> \
  --paths "/*"
```

### 6. Crear Usuario en Cognito

```bash
# Crear usuario para acceder al dashboard
aws cognito-idp admin-create-user \
  --user-pool-id <user_pool_id> \
  --username usuario@ejemplo.com \
  --user-attributes Name=email,Value=usuario@ejemplo.com Name=name,Value="Tu Nombre" \
  --temporary-password "TempPass123!"

# El usuario debera cambiar la contrasena en el primer login
```

### 7. Configurar ESP32

1. Obtener certificados del output de Terraform (desde la carpeta `terraform/`):
```bash
mkdir -p ../firmware/certs
terraform output -raw iot_certificate_pem > ../firmware/certs/device.pem.crt
terraform output -raw iot_private_key > ../firmware/certs/private.pem.key
curl -o ../firmware/certs/AmazonRootCA1.pem https://www.amazontrust.com/repository/AmazonRootCA1.pem
```

Verificar que los 3 archivos existen:
```bash
ls ../firmware/certs/
# device.pem.crt  private.pem.key  AmazonRootCA1.pem
```

2. Editar `firmware/src/config.h`:
   - Configurar SSID y password de WiFi
   - Pegar el endpoint IoT (`terraform output iot_endpoint`)
   - Pegar los certificados obtenidos

3. Compilar y subir con PlatformIO:
```bash
cd firmware
pio run --target upload
pio device monitor  # Ver logs del ESP32
```

## Conexiones de Hardware (ESP32 + DHT22)

```
ESP32          DHT22
─────          ─────
3.3V  ────────  VCC (Pin 1)
GPIO4 ────────  DATA (Pin 2)  ─── 10K resistor ─── 3.3V
              ×  NC (Pin 3)
GND   ────────  GND (Pin 4)
```

## API REST Endpoints

| Metodo | Endpoint | Descripcion |
|--------|----------|-------------|
| GET | /sensors | Ultima lectura de todos los dispositivos |
| GET | /sensors/{device_id}?from=&to=&limit= | Historico de un dispositivo |

Todas las peticiones requieren header `Authorization: Bearer <id_token>`.

## Sistema de Alertas

El sistema evalua cada lectura del sensor contra umbrales configurables. Si se supera un umbral:
1. Se envia una notificacion por email via SNS
2. El dashboard muestra un banner de alerta visual con animacion
3. Las tarjetas de las metricas afectadas se resaltan en rojo
4. Se envia una notificacion del navegador (si el usuario lo permite)

### Configuracion de Umbrales

Los umbrales se configuran en `terraform.tfvars`:

```hcl
# Email para recibir alertas (obligatorio)
alert_email = "tu-email@ejemplo.com"

# Umbrales de temperatura (Celsius)
temperature_threshold_high = 35.0   # Alerta si supera este valor
temperature_threshold_low  = 5.0    # Alerta si baja de este valor

# Umbrales de humedad (%)
humidity_threshold_high = 85.0      # Alerta si supera este valor
humidity_threshold_low  = 20.0      # Alerta si baja de este valor
```

### Confirmar Suscripcion SNS

Despues del primer `terraform apply` con la variable `alert_email` configurada:

1. Revisa tu bandeja de entrada (y spam) buscando un email de "AWS Notifications"
2. Haz clic en **"Confirm subscription"** en el email
3. Solo despues de confirmar recibiras las alertas

### Tipos de Alerta

| Tipo | Severidad | Condicion |
|------|-----------|-----------|
| temperature_high | Critica | Temperatura > umbral alto |
| temperature_low | Advertencia | Temperatura < umbral bajo |
| humidity_high | Advertencia | Humedad > umbral alto |
| humidity_low | Advertencia | Humedad < umbral bajo |

### Ejemplo de Notificacion Email

```
=== ALERTA DE SENSOR IoT ===

Dispositivo: esp32-sensor-01
Fecha/Hora: 2026-08-03 15:30:00 UTC

Valores actuales:
  - Temperatura: 37.5°C
  - Humedad: 62.3%

Alertas detectadas:
  - Temperatura alta: 37.5°C (umbral: 35.0°C)

Umbrales configurados:
  - Temperatura: 5.0°C - 35.0°C
  - Humedad: 20.0% - 85.0%
```

### Modificar Umbrales sin Redesplegar

Si quieres cambiar los umbrales sin hacer `terraform apply`, puedes actualizar directamente la Lambda:

```bash
FUNCTION_NAME=$(aws lambda list-functions \
  --query "Functions[?contains(FunctionName,'iot-processor')].FunctionName" \
  --output text)

# Obtener variables actuales y actualizar solo los umbrales
aws lambda update-function-configuration \
  --function-name $FUNCTION_NAME \
  --environment "Variables=$(aws lambda get-function-configuration \
    --function-name $FUNCTION_NAME \
    --query 'Environment.Variables' --output json | \
    jq '.TEMP_THRESHOLD_HIGH="40.0" | .TEMP_THRESHOLD_LOW="2.0"' | \
    jq -r 'to_entries | map("\(.key)=\(.value)") | join(",") | "{" + . + "}"')"
```

## Limpieza

```bash
cd terraform
terraform destroy
```

## Costos Estimados

Con uso moderado (1 ESP32, lecturas cada 10s):
- **AWS IoT Core**: ~$0.10/mes (mensajes MQTT)
- **Lambda**: ~$0.00 (capa gratuita)
- **DynamoDB**: ~$0.25/mes (on-demand)
- **API Gateway**: ~$0.01/mes
- **S3 + CloudFront**: ~$0.05/mes
- **Cognito**: $0.00 (primeros 50,000 usuarios gratis)
- **SNS**: ~$0.00 (primeras 1,000 notificaciones email gratis)

**Total estimado: < $1 USD/mes**
