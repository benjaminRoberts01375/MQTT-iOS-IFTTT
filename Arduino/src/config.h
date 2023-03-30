#pragma once
#include <string>
using namespace std;

// Wifi Credentials
const char * SSID = "ChamplainPSK";
const char * PASSWORD = "letusdare";

// MQTT Settings
const string ID = "BenRID";
const string BROKER = "broker.emqx.io";
const int PORT_CONNECTION = 1883;
const string CLIENT_NAME = ID + "Benduino";

// IFTTT
const string iftttKey = "jJStd1LVkI3cJELkAZ1WFED3MYiH9AaLsV8eYcCvCTh";
const string iftttEvent = "Arduino_Weather";
string iftttURL = "maker.ifttt.com";
const int iftttPort = 80;