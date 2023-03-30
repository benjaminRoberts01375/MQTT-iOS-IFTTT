//
//  SettingsVM.swift
//  MQTT
//
//  Created by Ben Roberts on 3/21/23.
//

import SwiftUI

final class SettingsVM: ObservableObject {
    @Published var address: String
    @Published var port: String
    @Published var topic: String
    @Published var pollRate: Float
    @Published var isConnected: Bool
    @Published var showAlert: Bool
    @Binding var isPresented: Bool
    @StateObject var mqttManager: MQTTManager
    
    init(isPresented: Binding<Bool>, mqttManager: StateObject<MQTTManager>) {
        self.address = mqttManager.projectedValue.address.wrappedValue == "" ? "broker.emqx.io" : mqttManager.projectedValue.address.wrappedValue
        self.port = mqttManager.projectedValue.port.wrappedValue == 0 ? "1883" : String(mqttManager.projectedValue.port.wrappedValue)
        self.topic = mqttManager.projectedValue.topic.wrappedValue == "" ? "BenRID" : mqttManager.projectedValue.topic.wrappedValue
        self.isConnected = mqttManager.wrappedValue.IsConnected()
        self.pollRate = 10
        self.showAlert = false
        self._isPresented = isPresented
        self._mqttManager = mqttManager
    }
    
    public func ToggleConnection() {
        if mqttManager.IsConnected() {
            mqttManager.disconnectAndDestroy()
            isConnected = false
            return
        }
        
        if address == "" || topic == "" || port == "" {
            showAlert = true
            return
        }
        
        mqttManager.setUpAndConnect(broker: address, port: Int(port) ?? 0, topic: topic)
        isConnected = true
    }
}
