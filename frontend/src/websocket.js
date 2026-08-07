/**
 * WebSocket Module - Real-time connection to API Gateway WebSocket
 */

const WS = (() => {
  let socket = null;
  let reconnectTimer = null;
  let pingTimer = null;
  let onMessageCallback = null;
  let onStatusChangeCallback = null;

  function connect() {
    if (socket && socket.readyState === WebSocket.OPEN) return;

    const url = CONFIG.WEBSOCKET_API_URL;
    console.log('Connecting to WebSocket:', url);

    try {
      socket = new WebSocket(url);
    } catch (e) {
      console.error('WebSocket creation failed:', e);
      scheduleReconnect();
      return;
    }

    socket.onopen = () => {
      console.log('WebSocket connected');
      updateStatus(true);
      startPing();
      clearReconnectTimer();
    };

    socket.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        if (data.type === 'pong') return;
        if (onMessageCallback) onMessageCallback(data);
      } catch (e) {
        console.error('Error parsing message:', e);
      }
    };

    socket.onclose = (event) => {
      console.log('WebSocket closed:', event.code);
      updateStatus(false);
      stopPing();
      scheduleReconnect();
    };

    socket.onerror = (error) => {
      console.error('WebSocket error:', error);
      updateStatus(false);
    };
  }

  function disconnect() {
    clearReconnectTimer();
    stopPing();
    if (socket) {
      socket.close();
      socket = null;
    }
    updateStatus(false);
  }

  function send(data) {
    if (socket && socket.readyState === WebSocket.OPEN) {
      socket.send(JSON.stringify(data));
    }
  }

  function startPing() {
    stopPing();
    pingTimer = setInterval(() => {
      send({ action: 'ping' });
    }, CONFIG.PING_INTERVAL);
  }

  function stopPing() {
    if (pingTimer) {
      clearInterval(pingTimer);
      pingTimer = null;
    }
  }

  function scheduleReconnect() {
    clearReconnectTimer();
    reconnectTimer = setTimeout(() => {
      console.log('Attempting reconnect...');
      connect();
    }, CONFIG.RECONNECT_INTERVAL);
  }

  function clearReconnectTimer() {
    if (reconnectTimer) {
      clearTimeout(reconnectTimer);
      reconnectTimer = null;
    }
  }

  function updateStatus(connected) {
    if (onStatusChangeCallback) {
      onStatusChangeCallback(connected);
    }
  }

  function onMessage(callback) {
    onMessageCallback = callback;
  }

  function onStatusChange(callback) {
    onStatusChangeCallback = callback;
  }

  return { connect, disconnect, send, onMessage, onStatusChange };
})();
