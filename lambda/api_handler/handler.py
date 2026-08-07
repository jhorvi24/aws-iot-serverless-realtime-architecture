"""
API Handler Lambda - REST API for querying historical sensor data.
"""

import json
import os
import time
from decimal import Decimal
import boto3
from boto3.dynamodb.conditions import Key

# Environment variables
DYNAMODB_TABLE_NAME = os.environ.get('DYNAMODB_TABLE_NAME')

# AWS clients
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(DYNAMODB_TABLE_NAME)


class DecimalEncoder(json.JSONEncoder):
    """Custom JSON encoder for Decimal types from DynamoDB."""
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)


def lambda_handler(event, context):
    """
    Route requests based on HTTP method and path.
    - GET /sensors -> list latest data from all devices
    - GET /sensors/{device_id} -> get historical data for a device
    """
    print(f"API event: {json.dumps(event)}")

    http_method = event.get('httpMethod', 'GET')
    path = event.get('path', '/')
    path_params = event.get('pathParameters') or {}
    query_params = event.get('queryStringParameters') or {}

    try:
        if path == '/sensors' and http_method == 'GET':
            return get_all_devices_latest(query_params)
        elif '/sensors/' in path and http_method == 'GET':
            device_id = path_params.get('device_id', '')
            return get_device_data(device_id, query_params)
        else:
            return response(404, {'error': 'Not found'})

    except Exception as e:
        print(f"Error handling request: {str(e)}")
        return response(500, {'error': 'Internal server error'})


def get_all_devices_latest(query_params):
    """Get the latest reading from all devices."""
    try:
        # Scan for unique devices and their latest readings
        scan_response = table.scan(
            Limit=100
        )
        items = scan_response.get('Items', [])

        # Group by device and get latest
        devices = {}
        for item in items:
            device_id = item['device_id']
            if device_id not in devices or item['timestamp'] > devices[device_id]['timestamp']:
                devices[device_id] = item

        result = list(devices.values())
        result.sort(key=lambda x: x['timestamp'], reverse=True)

        return response(200, {
            'devices': result,
            'count': len(result)
        })

    except Exception as e:
        print(f"Error fetching all devices: {str(e)}")
        return response(500, {'error': 'Failed to fetch devices'})


def get_device_data(device_id, query_params):
    """Get historical data for a specific device."""
    if not device_id:
        return response(400, {'error': 'device_id is required'})

    try:
        # Time range parameters
        limit = int(query_params.get('limit', '50'))
        limit = min(limit, 200)  # Cap at 200

        # Default: last 24 hours
        now = int(time.time() * 1000)
        from_ts = int(query_params.get('from', str(now - 86400000)))  # 24h ago
        to_ts = int(query_params.get('to', str(now)))

        # Query DynamoDB
        query_response = table.query(
            KeyConditionExpression=Key('device_id').eq(device_id) & Key('timestamp').between(from_ts, to_ts),
            ScanIndexForward=False,  # Latest first
            Limit=limit
        )

        items = query_response.get('Items', [])

        # Calculate statistics
        stats = calculate_stats(items)

        return response(200, {
            'device_id': device_id,
            'readings': items,
            'count': len(items),
            'statistics': stats,
            'time_range': {
                'from': from_ts,
                'to': to_ts
            }
        })

    except Exception as e:
        print(f"Error fetching device data: {str(e)}")
        return response(500, {'error': f'Failed to fetch data for device {device_id}'})


def calculate_stats(items):
    """Calculate basic statistics from sensor readings."""
    if not items:
        return {}

    temperatures = [float(item['temperature']) for item in items if 'temperature' in item]
    humidities = [float(item['humidity']) for item in items if 'humidity' in item]

    stats = {}
    if temperatures:
        stats['temperature'] = {
            'min': round(min(temperatures), 2),
            'max': round(max(temperatures), 2),
            'avg': round(sum(temperatures) / len(temperatures), 2),
            'count': len(temperatures)
        }
    if humidities:
        stats['humidity'] = {
            'min': round(min(humidities), 2),
            'max': round(max(humidities), 2),
            'avg': round(sum(humidities) / len(humidities), 2),
            'count': len(humidities)
        }

    return stats


def response(status_code, body):
    """Build API Gateway response with CORS headers."""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,Authorization,X-Amz-Date,X-Api-Key',
            'Access-Control-Allow-Methods': 'GET,OPTIONS'
        },
        'body': json.dumps(body, cls=DecimalEncoder)
    }
