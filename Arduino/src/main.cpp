#include <Arduino.h>
#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include "config.h"
#include "stdlib.h"
#include <Arduino_MKRIoTCarrier.h>

WiFiClient wifiClient;
PubSubClient client(wifiClient);

WiFiClient iftttClient;

MKRIoTCarrier carrier;
int loops = 1;
int pollRate = 1000;
int notificationRate = 10000;
int lastNotificationTime = 0;

/// @brief Tell devices to reset their currently collected data
void sendReset() {
  StaticJsonDocument<200> doc;                    // JSON holder
  doc["reset"] = true;                            // Add "reset" field
  String jsonString;
  serializeJson(doc, jsonString);                 // Convert JSON to string
  client.publish(ID.c_str(), jsonString.c_str()); // Send JSON to MQTT
}

/// @brief Tell devices the current pollrate of this Arduino
void getDuration() {
  StaticJsonDocument<200> doc;                    // JSON holder
  doc["pollRate"] = pollRate;                     // Add "pollRate" field
  String jsonString;
  serializeJson(doc, jsonString);                 // Convert JSON to string
  Serial.print("Sending ");
  Serial.println(jsonString.c_str());
  client.publish(ID.c_str(), jsonString.c_str()); // Send JSON to MQTT
}

/// @brief Set the pollrate for the Arduino
/// @param duration Pollrate in ms
void setDuration(String duration) {
  pollRate = duration.toInt();      // Convert string to int pollrate
  loops = millis() / pollRate + 1;  // Adjust the number of loops to prevent long pause after change
  getDuration();                    // Broadcast new pollrate
}

/// @brief Reads commands being sent to Arduino
/// @param message Command type and param. Ex: setPollRate:5000
void commandDealer(String message) {
  int index = message.indexOf(':');                               // Find colon                            
  if (index != -1) {                                              // If colon was found...
    String command = message.substring(0, index);                   // Determine the command sent
    String query = message.substring(index+1, message.length());    // Determine the param with it
    if (command == "setPollRate") {                                 // If command is "setPollRate"
      setDuration(query);                                             // Set the pollRate
    }
    else if (command == "getPollRate") {                            // If command is getPollRate
      getDuration();                                                  // send the current pollRate
    }
  }
}

/// @brief Connecting to wifi network
void connectWiFi() {
  while (WiFi.status() != WL_CONNECTED)
  {
    Serial.println("Connecting to WiFi...");
    WiFi.begin(SSID, PASSWORD);
    delay(500);
  }

  Serial.println("Connected!");
}

/// @brief Connect to MQTT client if not already connected (ex. startup or random disconnect)
void reconnectMQTTClient() {
  while (!client.connected())
  {
    Serial.print("Attempting MQTT connection...");
    if (client.connect(CLIENT_NAME.c_str()))
    {
      Serial.println("connected");
      client.subscribe(ID.c_str()); // TO SUBCRIBE A TOPIC
    }
    else
    {
      Serial.print("Retying in 5 seconds - failed, rc=");
      Serial.println(client.state());

      delay(5000);
    }
  }
}

void clientCallback(char *topic, uint8_t *payload, unsigned int length) {
    char buff[length + 1];
    for (int i = 0; i < length; i++)
    {
        buff[i] = (char)payload[i];
    }
    buff[length] = '\0';

    Serial.print("Message received - ");
    Serial.println(buff);
    String message = buff;
   commandDealer(message);
}

/// @brief Connect to MQTT network
void createMQTTClient() {
  client.setServer(BROKER.c_str(), PORT_CONNECTION);
  client.setCallback(clientCallback);
  reconnectMQTTClient();
}

void sendTelemetry() {
  StaticJsonDocument<200> doc;
  doc["humidity"] = carrier.Env.readHumidity();
  doc["temperature"] = carrier.Env.readTemperature();
  doc["time"] = pollRate * loops;

  String jsonString;
  serializeJson(doc, jsonString);

  Serial.print("Sending: ");
  Serial.println(jsonString);
  client.publish(ID.c_str(), jsonString.c_str());
}

void callWebhook() {
  StaticJsonDocument<200> doc;
  doc["value1"] = "Hello from Arduino land!";
  doc["value2"] = iftttEvent;
  doc["value3"] = CLIENT_NAME;
  iftttClient.connect(iftttURL.c_str(), iftttPort);
  string json;
  serializeJson(doc, json);
  String requestInfo = "";
  requestInfo.concat("POST /trigger/");
  requestInfo.concat(iftttEvent.c_str());
  requestInfo.concat("/with/key/");
  requestInfo.concat(iftttKey.c_str());
  requestInfo.concat(" HTTP/1.1\r\n");
  requestInfo.concat("Host: ");
  requestInfo.concat(iftttURL.c_str());
  requestInfo.concat("\r\n");
  requestInfo.concat("Content-Type: application/json\r\n");
  requestInfo.concat("Content-Length: ");
  requestInfo.concat(json.length());
  requestInfo.concat("\r\n");
  requestInfo.concat("\r\n");
  requestInfo.concat(json.c_str());
  Serial.println(requestInfo.c_str());
  iftttClient.print(requestInfo.c_str());
  iftttClient.stop();
}

void setup() {
  Serial.begin(9600);

  while (!Serial)
    ; // Wait for Serial to be ready

  connectWiFi();      // Connect to wifi
  createMQTTClient(); // Connect to MQTT broker

  carrier.noCase();   // Configure Arduino for no case
  carrier.begin();    // Start Arduino data collection
  sendReset();        // Tell other devices to reset the data
  getDuration();      // Tell other devices this Arduino's pollrate
}

void loop() {
  reconnectMQTTClient();                                                    // Reconnect to client if needed
  client.loop();                                                            // Get client messages
  if (millis() / (pollRate * loops) >= 1.0) {                               // If it's time for an eval
    loops = millis() / pollRate + 1;                                          // Update the number of times this has happened
    sendTelemetry();                                                          // Send telemetry
    if (millis() - lastNotificationTime > notificationRate &&                 // If it'd be time to send a notification via IFTTT...
    (carrier.Env.readHumidity() > 40 || carrier.Env.readTemperature() > 17)   // ... and we've exceeded these params
    ) {
      lastNotificationTime = millis();                                            // Update when the last notification was sent
      callWebhook();                                                              // Send notification
    }
  }
}