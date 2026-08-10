"""
IoT Processor Lambda - Processes sensor data from IoT Core,
broadcasts to WebSocket clients, and triggers alerts on threshold violations.
"""

import json
import os
import time
import boto3
from decimal import Decimal
from boto3.dynamodb.conditions import Key

# Environment variables
DYNAMODB_TABLE_NAME = os.environ.get('DYNAMODB_TABLE_NAME')
CONNECTIONS_TABLE_NAME = os.environ.get('CONNECTIONS_TABLE_NAME')
WEBSOCKET_API_ENDPOINT = os.environ.get('WEBSOCKET_API_ENDPOINT')
SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN')

# Alert thresholds
TEMP_THRESHOLD_HIGH = float(os.environ.get('TEMP_THRESHOLD_HIGH', '35.0'))
TEMP_THRESHOLD_LOW = float(os.environ.get('TEMP_THRESHOLD_LOW', '5.0'))
HUMIDITY_THRESHOLD_HIGH = float(os.environ.get('HUMIDITY_THRESHOLD_HIGH', '85.0'))
HUMIDITY_THRESHOLD_LOW = float(os.environ.get('HUMIDITY_THRESHOLD_LOW', '20.0'))

# AWS clients
dynamodb = boto3.resource('dynamodb')
sensor_table = dynamodb.Table(DYNAMODB_TABLE_NAME)
connections_table = dynamodb.Table(CONNECTIONS_TABLE_NAME)
sns_client = boto3.client('sns')


def lambda_handler(event, context):
    """
    Process incoming IoT sensor data:
    1. Validate and store in DynamoDB
    2. Check thresholds and trigger alerts
    3. Broadcast to all connected WebSocket clients
    """
    print(f"Received IoT event: {json.dumps(event)}")

    try:
        # Extract sensor data from IoT Rule payload
        device_id = event.get('device_id', 'unknown')
        temperature = event.get('temperature')
        humidity = event.get('humidity')
        timestamp = event.get('received_at', int(time.time() * 1000))

        # Validate data
        if temperature is None or humidity is None:
            print(f"Invalid sensor data - missing temperature or humidity")
            return {'statusCode': 400, 'body': 'Invalid sensor data'}

        temperature = float(temperature)
        humidity = float(humidity)

        # Prepare item for DynamoDB
        item = {
            'device_id': device_id,
            'timestamp': int(timestamp),
            'temperature': Decimal(str(round(temperature, 2))),
            'humidity': Decimal(str(round(humidity, 2))),
            'raw_payload': json.dumps(event),
            'expiry_time': int(time.time()) + (30 * 24 * 60 * 60)
        }

        # Store in DynamoDB
        sensor_table.put_item(Item=item)
        print(f"Stored sensor data: device={device_id}, temp={temperature}, hum={humidity}")

        # Check thresholds and generate alerts
        alerts = check_thresholds(device_id, temperature, humidity, timestamp)

        # Broadcast to WebSocket clients (include alerts if any)
        broadcast_data = {
            'type': 'sensor_data',
            'device_id': device_id,
            'temperature': temperature,
            'humidity': humidity,
            'timestamp': int(timestamp),
            'alerts': alerts
        }
        broadcast_to_websocket_clients(broadcast_data)

        # Send SNS notification if there are alerts
        if alerts:
            send_sns_alert(device_id, temperature, humidity, alerts, timestamp)

        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Data processed successfully', 'alerts': len(alerts)})
        }

    except Exception as e:
        print(f"Error processing IoT data: {str(e)}")
        raise e


def check_thresholds(device_id, temperature, humidity, timestamp):
    """Evaluate sensor values against configured thresholds."""
    alerts = []

    if temperature > TEMP_THRESHOLD_HIGH:
        alerts.append({
            'type': 'temperature_high',
            'severity': 'critical',
            'message': f'Temperatura alta: {temperature:.1f}°C (umbral: {TEMP_THRESHOLD_HIGH}°C)',
            'value': temperature,
            'threshold': TEMP_THRESHOLD_HIGH,
            'device_id': device_id,
            'timestamp': timestamp
        })

    if temperature < TEMP_THRESHOLD_LOW:
        alerts.append({
            'type': 'temperature_low',
            'severity': 'warning',
            'message': f'Temperatura baja: {temperature:.1f}°C (umbral: {TEMP_THRESHOLD_LOW}°C)',
            'value': temperature,
            'threshold': TEMP_THRESHOLD_LOW,
            'device_id': device_id,
            'timestamp': timestamp
        })

    if humidity > HUMIDITY_THRESHOLD_HIGH:
        alerts.append({
            'type': 'humidity_high',
            'severity': 'warning',
            'message': f'Humedad alta: {humidity:.1f}% (umbral: {HUMIDITY_THRESHOLD_HIGH}%)',
            'value': humidity,
            'threshold': HUMIDITY_THRESHOLD_HIGH,
            'device_id': device_id,
            'timestamp': timestamp
        })

    if humidity < HUMIDITY_THRESHOLD_LOW:
        alerts.append({
            'type': 'humidity_low',
            'severity': 'warning',
            'message': f'Humedad baja: {humidity:.1f}% (umbral: {HUMIDITY_THRESHOLD_LOW}%)',
            'value': humidity,
            'threshold': HUMIDITY_THRESHOLD_LOW,
            'device_id': device_id,
            'timestamp': timestamp
        })

    if alerts:
        print(f"ALERTS triggered: {len(alerts)} for device {device_id}")

    return alerts


def send_sns_alert(device_id, temperature, humidity, alerts, timestamp):
    """Send alert notification via SNS (email)."""
    if not SNS_TOPIC_ARN:
        print("SNS Topic ARN not configured, skipping notification")
        return

    time_str = time.strftime('%Y-%m-%d %H:%M:%S UTC', time.gmtime(timestamp / 1000))

    # Build email subject
    severity = 'CRITICA' if any(a['severity'] == 'critical' for a in alerts) else 'ADVERTENCIA'
    subject = f"[{severity}] Alerta IoT - {device_id}"

    # Build email body
    alert_lines = '\n'.join([f"  - {a['message']}" for a in alerts])
    message = f"""
=== ALERTA DE SENSOR IoT ===

Dispositivo: {device_id}
Fecha/Hora: {time_str}

Valores actuales:
  - Temperatura: {temperature:.1f}°C
  - Humedad: {humidity:.1f}%

Alertas detectadas:
{alert_lines}

Umbrales configurados:
  - Temperatura: {TEMP_THRESHOLD_LOW}°C - {TEMP_THRESHOLD_HIGH}°C
  - Humedad: {HUMIDITY_THRESHOLD_LOW}% - {HUMIDITY_THRESHOLD_HIGH}%

---
Este mensaje fue generado automaticamente por el sistema de monitoreo IoT.
"""

    try:
        sns_client.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=subject[:100],  # SNS subject limit
            Message=message
        )
        print(f"SNS alert sent for device {device_id}: {len(alerts)} alerts")
    except Exception as e:
        print(f"Error sending SNS alert: {str(e)}")


def broadcast_to_websocket_clients(data):
    """Send data to all connected WebSocket clients."""
    if not WEBSOCKET_API_ENDPOINT:
        print("WebSocket API endpoint not configured, skipping broadcast")
        return

    # Get all active connections
    try:
        response = connections_table.scan(
            ProjectionExpression='connection_id'
        )
        connections = response.get('Items', [])
    except Exception as e:
        print(f"Error scanning connections table: {str(e)}")
        return

    if not connections:
        print("No active WebSocket connections")
        return

    # Create API Gateway management client
    apigw_management = boto3.client(
        'apigatewaymanagementapi',
        endpoint_url=WEBSOCKET_API_ENDPOINT
    )

    message = json.dumps(data).encode('utf-8')
    stale_connections = []

    for connection in connections:
        connection_id = connection['connection_id']
        try:
            apigw_management.post_to_connection(
                ConnectionId=connection_id,
                Data=message
            )
        except apigw_management.exceptions.GoneException:
            stale_connections.append(connection_id)
        except Exception as e:
            print(f"Error sending to connection {connection_id}: {str(e)}")
            stale_connections.append(connection_id)

    # Clean up stale connections
    for connection_id in stale_connections:
        try:
            connections_table.delete_item(Key={'connection_id': connection_id})
            print(f"Removed stale connection: {connection_id}")
        except Exception as e:
            print(f"Error removing stale connection {connection_id}: {str(e)}")

    print(f"Broadcast to {len(connections) - len(stale_connections)} clients, removed {len(stale_connections)} stale")
