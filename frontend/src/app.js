/**
 * Main App - Orchestrates authentication, WebSocket, and UI updates
 */

const App = (() => {
  let readingsCount = 0;
  let activeDevices = new Set();
  let lastTemp = null;
  let lastHum = null;

  function init() {
    // Check existing session
    const user = Auth.checkSession();
    if (user) {
      showDashboard(user);
    } else {
      showLogin();
    }

    // Bind events
    document.getElementById('loginForm').addEventListener('submit', handleLogin);
    document.getElementById('logoutBtn').addEventListener('click', handleLogout);
  }

  async function handleLogin(e) {
    e.preventDefault();
    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;
    const btn = document.getElementById('loginBtn');
    const errorDiv = document.getElementById('loginError');
    const errorText = document.getElementById('loginErrorText');

    btn.disabled = true;
    btn.textContent = 'Conectando...';
    errorDiv.classList.remove('visible');

    try {
      const user = await Auth.signIn(email, password);
      showDashboard(user);
    } catch (error) {
      errorText.textContent = error.message || 'Error de autenticacion';
      errorDiv.classList.add('visible');
    } finally {
      btn.disabled = false;
      btn.textContent = 'Iniciar Sesion';
    }
  }

  function handleLogout() {
    Auth.signOut();
    WS.disconnect();
    Charts.destroy();
    showLogin();
  }

  function showLogin() {
    document.getElementById('loginScreen').style.display = 'flex';
    document.getElementById('dashboard').classList.remove('active');
  }

  function showDashboard(user) {
    document.getElementById('loginScreen').style.display = 'none';
    document.getElementById('dashboard').classList.add('active');

    const displayName = user.email || user.name || 'Usuario';
    document.getElementById('userInfo').textContent = displayName;

    // Initialize charts and WebSocket
    Charts.init();
    setupWebSocket();
  }

  function setupWebSocket() {
    WS.onStatusChange((connected) => {
      const dot = document.getElementById('statusDot');
      const text = document.getElementById('statusText');
      if (connected) {
        dot.classList.add('connected');
        text.textContent = 'Conectado';
      } else {
        dot.classList.remove('connected');
        text.textContent = 'Desconectado';
      }
    });

    WS.onMessage((data) => {
      if (data.type === 'sensor_data') {
        handleSensorData(data);
      }
    });

    WS.connect();
  }

  function handleSensorData(data) {
    const { device_id, temperature, humidity, timestamp } = data;

    // Update stat cards
    document.getElementById('currentTemp').textContent = temperature.toFixed(1);
    document.getElementById('currentHumidity').textContent = humidity.toFixed(1);

    // Show change indicator
    if (lastTemp !== null) {
      const tempDiff = temperature - lastTemp;
      const arrow = tempDiff >= 0 ? '↑' : '↓';
      document.getElementById('tempChange').textContent = 
        `${arrow} ${Math.abs(tempDiff).toFixed(1)}°C vs anterior`;
    }
    if (lastHum !== null) {
      const humDiff = humidity - lastHum;
      const arrow = humDiff >= 0 ? '↑' : '↓';
      document.getElementById('humChange').textContent = 
        `${arrow} ${Math.abs(humDiff).toFixed(1)}% vs anterior`;
    }

    lastTemp = temperature;
    lastHum = humidity;

    // Update device count
    activeDevices.add(device_id);
    document.getElementById('deviceCount').textContent = activeDevices.size;

    // Update readings count
    readingsCount++;
    document.getElementById('readingsCount').textContent = readingsCount;

    // Update last time
    const now = new Date();
    document.getElementById('lastUpdate').textContent = 
      `Ultima: ${now.toLocaleTimeString('es-ES')}`;

    // Update charts
    Charts.addDataPoint(temperature, humidity, timestamp);

    // Add activity log entry
    addActivityEntry(device_id, temperature, humidity, timestamp);
  }

  function addActivityEntry(deviceId, temp, hum, timestamp) {
    const list = document.getElementById('activityList');
    const time = new Date(timestamp).toLocaleTimeString('es-ES', {
      hour: '2-digit', minute: '2-digit', second: '2-digit'
    });

    const entry = document.createElement('li');
    entry.className = 'activity-item';
    entry.innerHTML = `
      <div class="activity-icon temp">🌡</div>
      <div class="activity-details">
        <div class="activity-text">
          <strong>${deviceId}</strong> — ${temp.toFixed(1)}°C / ${hum.toFixed(1)}%
        </div>
        <div class="activity-time">${time}</div>
      </div>
    `;

    list.insertBefore(entry, list.firstChild);

    // Keep max 20 entries
    while (list.children.length > 20) {
      list.removeChild(list.lastChild);
    }

    // Update count
    const count = Math.min(readingsCount, 20);
    document.getElementById('activityCount').textContent = `${count} eventos`;
  }

  // Start app when DOM is ready
  document.addEventListener('DOMContentLoaded', init);

  return { init };
})();
