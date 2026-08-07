"""
IoT Processor Lambda - Processes sensor data from IoT Core and broadcasts to WebSocket clients.
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

# AWS clients
dynamodb = boto3.resource('dynamodb')
sensor_table = dynamodb.Table(DYNAMODB_TABLE_NAME)
connections_table = dynamodb.Table(CONNECTIONS_TABLE_NAME)


def lambda_handler(event, context):
    """
    Process incoming IoT sensor data:
    1. Validate and store in DynamoDB
    2. Broadcast to all connected WebSocket clients
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

        # Prepare item for DynamoDB
        item = {
            'device_id': device_id,
            'timestamp': int(timestamp),
            'temperature': Decimal(str(round(float(temperature), 2))),
            'humidity': Decimal(str(round(float(humidity), 2))),
            'raw_payload': json.dumps(event),
            'expiry_time': int(time.time()) + (30 * 24 * 60 * 60)  # 30 days TTL
        }

        # Store in DynamoDB
        sensor_table.put_item(Item=item)
        print(f"Stored sensor data: device={device_id}, temp={temperature}, hum={humidity}")

        # Broadcast to WebSocket clients
        broadcast_data = {
            'type': 'sensor_data',
            'device_id': device_id,
            'temperature': float(temperature),
            'humidity': float(humidity),
            'timestamp': int(timestamp)
        }
        broadcast_to_websocket_clients(broadcast_data)

        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Data processed successfully'})
        }

    except Exception as e:
        print(f"Error processing IoT data: {str(e)}")
        raise e


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
