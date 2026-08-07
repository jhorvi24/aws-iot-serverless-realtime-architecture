/**
 * ESP32 IoT Sensor - Configuration
 * Update these values with your AWS IoT Core credentials
 * and WiFi settings before uploading to the ESP32.
 */

#ifndef CONFIG_H
#define CONFIG_H

// --- WiFi Configuration ---
#define WIFI_SSID " "
#define WIFI_PASSWORD " "

// --- AWS IoT Core Configuration ---
// Get these from Terraform output: iot_endpoint
#define AWS_IOT_ENDPOINT " "

// MQTT Topic (must match terraform variable mqtt_topic)
#define MQTT_TOPIC "sensors/esp32/data"
#define DEVICE_ID "esp32-sensor-01"

// MQTT Port (8883 for TLS)
#define MQTT_PORT 8883

// --- Sensor Configuration ---
#define DHT_PIN 4           // GPIO pin connected to DHT22 data pin
#define DHT_TYPE DHT22      // DHT22 (AM2302)
#define READ_INTERVAL 10000 // Read sensor every 10 seconds (ms)

// --- Certificates ---
// Replace with your device certificate from Terraform output
// Use: terraform output -raw iot_certificate_pem

static const char AWS_CERT_CA[] PROGMEM = R"EOF(
-----BEGIN CERTIFICATE-----
MIIDQTCCAimgAwIBAgITBmyfz5m/jAo54vB4ikPmljZbyjANBgkqhkiG9w0BAQsF
ADA5MQswCQYDVQQGEwJVUzEPMA0GA1UEChMGQW1hem9uMRkwFwYDVQQDExBBbWF6
b24gUm9vdCBDQSAxMB4XDTE1MDUyNjAwMDAwMFoXDTM4MDExNzAwMDAwMFowOTEL
MAkGA1UEBhMCVVMxDwYNBgQKEwZBbWF6b24xGTAXBgNVBAMTEEFtYXpvbiBSb290
IENBIDEwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCwTaCELOr0F5LD
PASTE_YOUR_ROOT_CA_HERE
-----END CERTIFICATE-----
)EOF";

// Device Certificate (from Terraform output)
static const char AWS_CERT_CRT[] PROGMEM = R"KEY(
-----BEGIN CERTIFICATE-----
PASTE_YOUR_DEVICE_CERTIFICATE_HERE
-----END CERTIFICATE-----
)KEY";

// Device Private Key (from Terraform output)
static const char AWS_CERT_PRIVATE[] PROGMEM = R"KEY(
-----BEGIN RSA PRIVATE KEY-----
PASTE_YOUR_PRIVATE_KEY_HERE
-----END RSA PRIVATE KEY-----
)KEY";

#endif // CONFIG_H
