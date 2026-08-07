/**
 * Dashboard Configuration
 * Update these values after Terraform deployment using the outputs.
 */
const CONFIG = {
  // Cognito
  COGNITO_USER_POOL_ID: 'us-east-1_YbX4sfxyk',  // From terraform output cognito_user_pool_id
  COGNITO_CLIENT_ID: '4484le2qp6qouibsd59cunj5gb', // From terraform output cognito_client_id
  COGNITO_REGION: 'us-east-1',

  // API Gateway
  REST_API_URL: 'https://utorjoudi3.execute-api.us-east-1.amazonaws.com/dev', // From terraform output rest_api_url
  WEBSOCKET_API_URL: 'wss://jwhq35cyf4.execute-api.us-east-1.amazonaws.com/dev', // From terraform output websocket_api_url

  // Dashboard settings
  MAX_DATA_POINTS: 50,
  RECONNECT_INTERVAL: 5000, // 5 seconds
  PING_INTERVAL: 30000,     // 30 seconds
};
