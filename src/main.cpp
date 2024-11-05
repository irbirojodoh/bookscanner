#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <Arduino.h>

#define SERVICE_UUID           "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define STATE_CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

enum State {
  IDLE = 0,
  SCANNING = 1,
  DONE = 2
};

State currentState = IDLE;
BLECharacteristic *pStateCharacteristic;
bool deviceConnected = false;
BLEAdvertising *pAdvertising; // Declare advertising pointer globally

// Update characteristic value, notify clients, and print state only if changed
void updateState(State newState) {
  if (currentState != newState) {
    currentState = newState;

    // Set the state name as the characteristic value
    String stateName;
    switch (currentState) {
      case IDLE: 
        stateName = "IDLE"; 
        break;
      case SCANNING: 
        stateName = "SCANNING"; 
        break;
      case DONE: 
        stateName = "DONE"; 
        break;
    }

    pStateCharacteristic->setValue(stateName.c_str()); // Set state name as characteristic value
    pStateCharacteristic->notify();

    Serial.print("State changed to: ");
    Serial.println(stateName);
  }
}

// Callback to handle device connection status
class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) {
    deviceConnected = true;
    Serial.println("Device connected");
  }

  void onDisconnect(BLEServer* pServer) {
    deviceConnected = false;
    Serial.println("Device disconnected");

    // Restart advertising
    pAdvertising->start();
    Serial.println("Restarting advertising...");
  }
};

// Callback for handling writes to the STATE characteristic
class StateControlCallback : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pCharacteristic) {
    std::string value = pCharacteristic->getValue();
    
    if (value.length() > 0) {
      if (value[0] == '0') updateState(IDLE);
      else if (value[0] == '1') updateState(SCANNING);
      else if (value[0] == '2') updateState(DONE);
      else Serial.println("Invalid state command received.");
    }
  }
};

void setup() {
  Serial.begin(115200);

  // Initialize BLE
  BLEDevice::init("ESP32_BLE_Device");
  BLEServer *pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Create a BLE characteristic for state control
  pStateCharacteristic = pService->createCharacteristic(
                           STATE_CHARACTERISTIC_UUID,
                           BLECharacteristic::PROPERTY_READ |
                           BLECharacteristic::PROPERTY_WRITE |
                           BLECharacteristic::PROPERTY_NOTIFY
                         );

  // Set initial state as a string
  pStateCharacteristic->setValue("IDLE"); // Initial state
  pStateCharacteristic->setCallbacks(new StateControlCallback());

  // Start the service and advertising
  pService->start();
  pAdvertising = BLEDevice::getAdvertising(); // Initialize advertising
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->start();

  Serial.println("ESP32 BLE device is ready and advertising.");
}

void loop() {
  // Check Serial input to control state manually (optional)
  if (Serial.available()) {
    char input = Serial.read();
    if (input == '0') updateState(IDLE);
    else if (input == '1') updateState(SCANNING);
    else if (input == '2') updateState(DONE);
    else Serial.println("Invalid Serial input.");
  }

  // Display connection status
  if (deviceConnected) {
    Serial.println("A device is connected.");
  } else {
    Serial.println("No device is connected.");
  }

  delay(1000);  // Print the connection status every second
}