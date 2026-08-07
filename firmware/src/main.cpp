/**
 * ESP32 IoT Sensor - Temperature & Humidity Monitor
 * 
 * Reads DHT22 sensor data and publishes to AWS IoT Core via MQTT/TLS.
 * 
 * Hardware:
 *   - ESP32 DevKit
 *   - DHT22 sensor (data pin -> GPIO 4, VCC -> 3.3V, GND -> GND)
 *   - 10K pull-up resistor between data and VCC
 */

#include <Arduino.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <MQTTClient.h>
#include <ArduinoJson.h>
#include <DHT.h>
#include <time.h>
#include "config.h"

// --- Global objects ---
WiFiClientSecure wifiClient;
MQTTClient mqttClient(512);
DHT dht(DHT_PIN, DHT_TYPE);

// --- Timing ---
unsigned long lastPublish = 0;
unsigned long lastReconnect = 0;
int failCount = 0;

// --- Function declarations ---
void connectWiFi();
void connectAWS();
void publishSensorData();
void syncTime();
void handleMQTTMessage(String &topic, String &payload);

void setup() {
  Serial.begin(115200);
  delay(1000);
  
  Serial.println("\n========================================");
  Serial.println("  ESP32 IoT Sensor - Starting...");
  Serial.println("========================================\n");

  // Initialize DHT sensor
  dht.begin();
  Serial.println("[SENSOR] DHT22 initialized on GPIO " + String(DHT_PIN));

  // Connect to WiFi
  connectWiFi();

  // Sync time (required for TLS certificate validation)
  syncTime();

  // Configure TLS certificates
  wifiClient.setCACert(AWS_CERT_CA);
  wifiClient.setCertificate(AWS_CERT_CRT);
  wifiClient.setPrivateKey(AWS_CERT_PRIVATE);

  // Configure MQTT
  mqttClient.begin(AWS_IOT_ENDPOINT, MQTT_PORT, wifiClient);
  mqttClient.onMessage(handleMQTTMessage);

  // Connect to AWS IoT
  connectAWS();
}

void loop() {
  // Maintain MQTT connection
  mqttClient.loop();

  // Reconnect if disconnected
  if (!mqttClient.connected()) {
    unsigned long now = millis();
    if (now - lastReconnect > 5000) {
      lastReconnect = now;
      Serial.println("[MQTT] Disconnected, reconnecting...");
      connectAWS();
    }
    return;
  }

  // Publish sensor data at interval
  unsigned long now = millis();
  if (now - lastPublish >= READ_INTERVAL) {
    lastPublish = now;
    publishSensorData();
  }
}

void connectWiFi() {
  Serial.print("[WiFi] Connecting to ");
  Serial.println(WIFI_SSID);

  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

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

void syncTime() {
  Serial.print("[TIME] Syncing NTP...");
  configTime(-5 * 3600, 0, "pool.ntp.org", "time.nist.gov");
  
  time_t now = time(nullptr);
  int attempts = 0;
  while (now < 100000 && attempts < 20) {
    delay(500);
    Serial.print(".");
    now = time(nullptr);
    attempts++;
  }
  
  Serial.println(" Done!");
  struct tm timeinfo;
  gmtime_r(&now, &timeinfo);
  Serial.printf("[TIME] UTC: %04d-%02d-%02d %02d:%02d:%02d\n",
    timeinfo.tm_year + 1900, timeinfo.tm_mon + 1, timeinfo.tm_mday,
    timeinfo.tm_hour, timeinfo.tm_min, timeinfo.tm_sec);
}

void connectAWS() {
  Serial.print("[MQTT] Connecting to AWS IoT Core...");

  int attempts = 0;
  while (!mqttClient.connect(DEVICE_ID) && attempts < 10) {
    Serial.print(".");
    delay(1000);
    attempts++;
  }

  if (mqttClient.connected()) {
    Serial.println(" Connected!");
    failCount = 0;
    
    // Subscribe to command topic (optional, for receiving commands)
    mqttClient.subscribe("sensors/esp32/commands");
    Serial.println("[MQTT] Subscribed to command topic");
  } else {
    Serial.println(" FAILED!");
    failCount++;
    
    if (failCount > 5) {
      Serial.println("[MQTT] Too many failures, restarting...");
      ESP.restart();
    }
  }
}

void publishSensorData() {
  // Read sensor
  float humidity = dht.readHumidity();
  float temperature = dht.readTemperature();

  // Validate readings
  if (isnan(humidity) || isnan(temperature)) {
    Serial.println("[SENSOR] Failed to read DHT22!");
    return;
  }

  // Get timestamp
  time_t now = time(nullptr);
  unsigned long timestamp = (unsigned long)now * 1000; // milliseconds

  // Build JSON payload
  JsonDocument doc;
  doc["device_id"] = DEVICE_ID;
  doc["temperature"] = round(temperature * 100.0) / 100.0;
  doc["humidity"] = round(humidity * 100.0) / 100.0;
  doc["timestamp"] = timestamp;
  doc["firmware_version"] = "1.0.0";

  char payload[256];
  serializeJson(doc, payload);

  // Publish to MQTT
  bool success = mqttClient.publish(MQTT_TOPIC, payload);
  
  if (success) {
    Serial.printf("[MQTT] Published: T=%.1f°C H=%.1f%%\n", temperature, humidity);
  } else {
    Serial.println("[MQTT] Publish FAILED!");
  }
}

void handleMQTTMessage(String &topic, String &payload) {
  Serial.printf("[MQTT] Received on '%s': %s\n", topic.c_str(), payload.c_str());
  
  // Handle commands from cloud (extensible)
  JsonDocument doc;
  DeserializationError error = deserializeJson(doc, payload);
  
  if (!error) {
    const char* command = doc["command"];
    if (command) {
      if (strcmp(command, "restart") == 0) {
        Serial.println("[CMD] Restart requested!");
        delay(1000);
        ESP.restart();
      } else if (strcmp(command, "status") == 0) {
        Serial.println("[CMD] Status requested");
        // Could publish status back
      }
    }
  }
}
