//
//  MQTTManager.swift
//  MQTT
//
//  Created by Ben Roberts on 3/21/23.
//

import Combine
import MQTTNIO
import SwiftUI

final class MQTTManager: ObservableObject {
    var address: String = ""
    var port: Int = 0
    var topic: String = ""
    var mqtt: MQTTClient?
    var cancellablePublisher: AnyCancellable?
    var cancellableConnection: AnyCancellable?
    @Published var data: [ArduinoData] = []
    @Published var pollRate: Int = 0
    
    /// Sets up and connects to a MQTT broker
    /// - Parameters:
    ///   - broker: Broker URL to connect to
    ///   - port: Port of the broker
    ///   - topic: Topic to subscribe to
    public func setUpAndConnect(broker: String, port: Int, topic: String) {
        self.address = broker
        self.port = port
        self.topic = topic
        
        let fullURL: URL = URL(string: "\(broker):\(port)")!                                            // Debug URL
        print("Setting URL to \(fullURL) with the topic \(topic)")
        
        let mqtt = MQTTClient(                                                                          // MQTT Configuration
            configuration: .init(
                target: .host(broker, port: port),                                                          // Host and port
                protocolVersion: .version5,                                                                 // MQTT v5
                clientId: "clientId-iOS",                                                                   // Client ID
                clean: true,                                                                                // I dunno
                credentials: .none,                                                                         // No credentials
                willMessage: .none,                                                                         // No leaving message?
                keepAliveInterval: .seconds(60),                                                            // Timeout
                reschedulePings: true                                                                       // Do ping when other messages are sent
            ),
            eventLoopGroupProvider: .createNew
        )
        
        mqtt.connect()                                                                                  // Connect to configured MQTT broker
        mqtt.subscribe(to: topic, qos: .exactlyOnce)                                                    // Subscribe to topic
        self.cancellablePublisher = mqtt.messagePublisher                                               // Setup background updates for messages
            .sink { message in
                DispatchQueue.main.async {                                                                  // Run on main thread
                    guard let rawData:Data = message.payload.string?.data(using: .utf8) else { return }         // Convert message to data type
                    print(String(decoding: rawData, as: UTF8.self))                                             // Debug message
                    if let decodedData = try? JSONDecoder().decode(ArduinoData.self, from: rawData) {           // Decode JSON into ArduinoData struct
                        if self.pollRate != 0 {                                                                     // If a valid poll rate...
                            withAnimation {
                                self.data.append(decodedData)                                                           // Save data
                            }
                        }
                    }
                    else if (try? JSONDecoder().decode(ArduinoReset.self, from: rawData)) != nil {              // Decode JSON into ArduinoReset struct
                        self.data = []                                                                              // Clear out data
                    }
                    else if let pollRate = try? JSONDecoder().decode(ArduinoPoll.self, from: rawData) {         // Decode JSON into ArduinoPoll struct
                        self.pollRate = pollRate.pollRate / 1000                                                    // Convert from ms to secs
                        self.data = []                                                                              // Clear data for consistency
                    }
                    withAnimation {
                        self.objectWillChange.send()                                                            // Send update about change to rest of app
                    }
                }
            }
        self.cancellableConnection = mqtt.connectPublisher                                              // Setup background updates for successful connection
            .sink(receiveValue: { connection in
                DispatchQueue.main.async {                                                                  // Run on main thread
                    self.getPollRate()                                                                      // Request the poll rate
                    self.objectWillChange.send()                                                            // Send update about change to rest of app
                }
            })
        self.mqtt = mqtt                                                                                // Save MQTT client
    }
    
    /// Standard function for requesting poll rate
    public func getPollRate() {
        print("Asking for poll rate")
        sendMessage(message: "getPollRate:")
    }
    
    /// Standard function for setting Arduino poll rate
    /// - Parameter rate: Rate to set to in seconds
    public func setPollRate(rate: Int) {
        sendMessage(message: "setPollRate:\(rate * 1000)")
    }
    
    /// Standard function for sending messages to Arduino
    /// - Parameter message: Message to send
    private func sendMessage(message: String) {
        guard let mqtt = mqtt else { return }
        mqtt.publish(message, to: topic, qos: .atLeastOnce)
    }
    
    /// Disconnects from broker and unloads MQTT manager
    public func disconnectAndDestroy() {
        guard let mqtt = mqtt else { return }   // Checks if there's a current MQTT instance
        mqtt.unsubscribe(from: topic)           // Unsubscribe from broker
        mqtt.disconnect()                       // Disconnect from broker
        self.mqtt = nil                         // Unload MQTT instance
        self.cancellablePublisher = nil         // Unload any observers for published messages
        self.cancellableConnection = nil        // Unload any observers for connection changes
        self.pollRate = 0                       // Set poll rate to 0
    }
    
    /// Boilerplate function for checking mqtt connection
    /// - Returns: Bool if being connected or not
    public func IsConnected() -> Bool {
        guard let mqtt = mqtt else { return false } // Checks for an MQTT instance
        return mqtt.isConnected                     // Checks current connection status
    }
    
    /// Struct for holding data from Arduino
    struct ArduinoData: Decodable, Identifiable {
        let humidity: Float
        let temperature: Float
        let time: Int
        let id: UUID = UUID()
        
        enum CodingKeys: CodingKey {
            case humidity
            case temperature
            case time
        }
    }
    
    /// Struct for understanding a reset command
    struct ArduinoReset: Decodable {
        let reset: Bool
        
        enum CodingKeys: CodingKey {
            case reset
        }
    }
    
    /// Struct for holding the current poll rate of the arduino
    struct ArduinoPoll: Decodable {
        let pollRate: Int
        
        enum CodingKeys: CodingKey {
            case pollRate
        }
    }
}
