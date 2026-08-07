/**
 * Charts Module - Chart.js configuration for temperature and humidity
 */

const Charts = (() => {
  let tempChart = null;
  let humChart = null;
  const maxPoints = CONFIG.MAX_DATA_POINTS;

  const commonOptions = {
    responsive: true,
    maintainAspectRatio: false,
    animation: { duration: 300 },
    interaction: { intersect: false, mode: 'index' },
    plugins: {
      legend: { display: false },
      tooltip: {
        backgroundColor: '#1a1a2e',
        titleColor: '#e0e0e0',
        bodyColor: '#a0a0a0',
        borderColor: '#2a2a4a',
        borderWidth: 1,
        padding: 12,
        cornerRadius: 8
      }
    },
    scales: {
      x: {
        grid: { color: 'rgba(42,42,74,0.3)', drawBorder: false },
        ticks: { color: '#666', maxRotation: 0, maxTicksLimit: 8, font: { size: 10 } }
      },
      y: {
        grid: { color: 'rgba(42,42,74,0.3)', drawBorder: false },
        ticks: { color: '#666', font: { size: 10 } }
      }
    }
  };

  function init() {
    const tempCtx = document.getElementById('tempChart').getContext('2d');
    tempChart = new Chart(tempCtx, {
      type: 'line',
      data: {
        labels: [],
        datasets: [{
          label: 'Temperatura (°C)',
          data: [],
          borderColor: '#ff8a65',
          backgroundColor: 'rgba(255,138,101,0.1)',
          borderWidth: 2,
          fill: true,
          tension: 0.4,
          pointRadius: 0,
          pointHoverRadius: 5
        }]
      },
      options: { ...commonOptions }
    });

    const humCtx = document.getElementById('humChart').getContext('2d');
    humChart = new Chart(humCtx, {
      type: 'line',
      data: {
        labels: [],
        datasets: [{
          label: 'Humedad (%)',
          data: [],
          borderColor: '#4fc3f7',
          backgroundColor: 'rgba(79,195,247,0.1)',
          borderWidth: 2,
          fill: true,
          tension: 0.4,
          pointRadius: 0,
          pointHoverRadius: 5
        }]
      },
      options: { ...commonOptions }
    });
  }

  function addDataPoint(temperature, humidity, timestamp) {
    const time = new Date(timestamp).toLocaleTimeString('es-ES', {
      hour: '2-digit', minute: '2-digit', second: '2-digit'
    });

    // Temperature chart
    tempChart.data.labels.push(time);
    tempChart.data.datasets[0].data.push(temperature);
    if (tempChart.data.labels.length > maxPoints) {
      tempChart.data.labels.shift();
      tempChart.data.datasets[0].data.shift();
    }
    tempChart.update('none');

    // Humidity chart
    humChart.data.labels.push(time);
    humChart.data.datasets[0].data.push(humidity);
    if (humChart.data.labels.length > maxPoints) {
      humChart.data.labels.shift();
      humChart.data.datasets[0].data.shift();
    }
    humChart.update('none');
  }

  function destroy() {
    if (tempChart) tempChart.destroy();
    if (humChart) humChart.destroy();
  }

  return { init, addDataPoint, destroy };
})();
