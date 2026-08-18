#include <DHT.h>
#include <DHT_U.h>
#include <WiFiClientSecure.h>
#include <WiFi.h>
#include "config.h"
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include <time.h>

// --- Sensor readings ---
float h;
float t;

// --- Timing (non-blocking) ---
unsigned long lastPublish = 0;
unsigned long lastReconnectAttempt = 0;

// --- Clients ---
WiFiClientSecure client;
PubSubClient esp32(client);
DHT dht(DHT_PIN, DHT_TYPE);

// --- Function declarations ---
void connectWiFi();
void connectMQTT();
void publishMessage();

void setup() {
  Serial.begin(115200);
  delay(1000);

  Serial.println("\n========================================");
  Serial.println("  ESP32 IoT Sensor - Starting...");
  Serial.println("========================================\n");

  // Initialize DHT sensor
  dht.begin();
  Serial.println("[SENSOR] DHT initialized on GPIO " + String(DHT_PIN));

  // Connect to WiFi
  connectWiFi();

  // Sync time (required for TLS certificate validation)
  configTime(-5 * 3600, 0, "pool.ntp.org", "time.nist.gov");  // GMT-5 Colombia
  Serial.print("[TIME] Syncing NTP...");
  time_t now = time(nullptr);
  while (now < 100000) {
    delay(500);
    Serial.print(".");
    now = time(nullptr);
  }
  Serial.println(" Done!");

  // Configure TLS certificates
  client.setCACert(AWS_CERT_CA);
  client.setCertificate(AWS_CERT_CRT);
  client.setPrivateKey(AWS_CERT_PRIVATE);

  // Configure MQTT
  esp32.setServer(AWS_IOT_ENDPOINT, MQTT_PORT);

  // Connect to AWS IoT
  connectMQTT();
}

void loop() {
  // Maintain MQTT connection (must be called frequently)
  esp32.loop();

  // Reconnect WiFi if lost
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("[WiFi] Connection lost. Reconnecting...");
    connectWiFi();
  }

  // Reconnect MQTT if lost (non-blocking, with 5s interval)
  if (!esp32.connected()) {
    unsigned long now = millis();
    if (now - lastReconnectAttempt > 5000) {
      lastReconnectAttempt = now;
      Serial.println("[MQTT] Disconnected, reconnecting...");
      connectMQTT();
    }
    return;  // Skip publish until connected
  }

  // Publish sensor data at interval (non-blocking)
  unsigned long now = millis();
  if (now - lastPublish >= READ_INTERVAL) {
    lastPublish = now;

    // Read sensor
    h = dht.readHumidity();
    t = dht.readTemperature();

    // Validate readings
    if (isnan(h) || isnan(t)) {
      Serial.println("[SENSOR] Failed to read DHT!");
      return;
    }

    Serial.printf("[SENSOR] Temp: %.1f°C  Humidity: %.1f%%\n", t, h);
    publishMessage();
  }
}

void connectWiFi() {
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  Serial.print("[WiFi] Connecting to ");
  Serial.print(WIFI_SSID);

  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 30) {
    delay(500);
    Serial.print(".");
    attempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n[WiFi] Connected!");
    Serial.print("[WiFi] IP: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\n[WiFi] Connection FAILED! Restarting...");
    ESP.restart();
  }
}

void connectMQTT() {
  Serial.print("[MQTT] Connecting to AWS IoT Core...");

  int attempts = 0;
  while (!esp32.connect(DEVICE_ID) && attempts < 10) {
    Serial.print(".");
    delay(1000);
    attempts++;
  }

  if (esp32.connected()) {
    Serial.println(" Connected!");
  } else {
    Serial.println(" FAILED!");
  }
}

void publishMessage() {
  // Get timestamp
  time_t now = time(nullptr);
  unsigned long timestamp = (unsigned long)now * 1000;  // milliseconds

  // Build JSON payload
  JsonDocument doc;
  doc["device_id"] = DEVICE_ID;
  doc["temperature"] = round(t * 100.0) / 100.0;
  doc["humidity"] = round(h * 100.0) / 100.0;
  doc["timestamp"] = timestamp;
  doc["firmware_version"] = "1.0.0";

  char payload[256];
  serializeJson(doc, payload);

  // Publish to MQTT
  bool success = esp32.publish(MQTT_TOPIC, payload);
  if (success) {
    Serial.printf("[MQTT] Published: T=%.1f°C H=%.1f%%\n", t, h);
  } else {
    Serial.println("[MQTT] Publish FAILED!");
  }
}


