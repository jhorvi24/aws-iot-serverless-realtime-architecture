"""
WebSocket Handler Lambda - Manages WebSocket connections for real-time data streaming.
"""

import json
import os
import time
import boto3

# Environment variables
CONNECTIONS_TABLE_NAME = os.environ.get('CONNECTIONS_TABLE_NAME')

# AWS clients
dynamodb = boto3.resource('dynamodb')
connections_table = dynamodb.Table(CONNECTIONS_TABLE_NAME)


def connect_handler(event, context):
    """Handle new WebSocket connection ($connect route)."""
    connection_id = event['requestContext']['connectionId']
    print(f"WebSocket connect: {connection_id}")

    try:
        # Store connection in DynamoDB
        connections_table.put_item(
            Item={
                'connection_id': connection_id,
                'connected_at': int(time.time()),
                'ttl': int(time.time()) + (24 * 60 * 60)  # 24 hour TTL
            }
        )

        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Connected'})
        }

    except Exception as e:
        print(f"Error storing connection: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Failed to connect'})
        }


def disconnect_handler(event, context):
    """Handle WebSocket disconnection ($disconnect route)."""
    connection_id = event['requestContext']['connectionId']
    print(f"WebSocket disconnect: {connection_id}")

    try:
        # Remove connection from DynamoDB
        connections_table.delete_item(
            Key={'connection_id': connection_id}
        )

        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Disconnected'})
        }

    except Exception as e:
        print(f"Error removing connection: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Failed to disconnect'})
        }


def default_handler(event, context):
    """Handle default WebSocket messages ($default route)."""
    connection_id = event['requestContext']['connectionId']
    domain_name = event['requestContext']['domainName']
    stage = event['requestContext']['stage']

    print(f"WebSocket message from {connection_id}: {event.get('body', '')}")

    try:
        body = json.loads(event.get('body', '{}'))
        action = body.get('action', 'ping')

        # Handle ping/pong for connection keep-alive
        if action == 'ping':
            endpoint_url = f"https://{domain_name}/{stage}"
            apigw_management = boto3.client(
                'apigatewaymanagementapi',
                endpoint_url=endpoint_url
            )

            apigw_management.post_to_connection(
                ConnectionId=connection_id,
                Data=json.dumps({
                    'type': 'pong',
                    'timestamp': int(time.time() * 1000)
                }).encode('utf-8')
            )

        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Message processed'})
        }

    except Exception as e:
        print(f"Error handling message: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Failed to process message'})
        }
