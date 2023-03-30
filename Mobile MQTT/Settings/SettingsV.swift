//
//  SettingsV.swift
//  MQTT
//
//  Created by Ben Roberts on 3/21/23.
//

import SwiftUI

struct SettingsV: View {
    @StateObject var controller: SettingsVM
    
    init(isPresented: Binding<Bool>, mqttManager: StateObject<MQTTManager>) {
        self._controller = StateObject(wrappedValue: SettingsVM(isPresented: isPresented, mqttManager: mqttManager))
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    TextField("Enter broker URL", text: $controller.address)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disableAutocorrection(true)
                        .disabled(controller.isConnected)
                        .opacity(controller.isConnected ? 0.5 : 1.0)
                    TextField("Port", text: $controller.port)                   // BenRID
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disableAutocorrection(true)
                        .disabled(controller.isConnected)
                        .opacity(controller.isConnected ? 0.5 : 1.0)
                        .keyboardType(.numberPad)
                        .frame(width: 70)
                }
                TextField("Enter a topic", text: $controller.topic)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disableAutocorrection(true)
                    .disabled(controller.isConnected)
                    .opacity(controller.isConnected ? 0.5 : 1.0)

                Button(action: {
                    withAnimation{
                        controller.ToggleConnection()
                    }
                }, label: {
                    Text(controller.isConnected ? "Disconnect" : "Connect")
                        .frame(width: 150, height: 45)
                        .background(controller.isConnected ? .green : .red)
                        .foregroundColor(.black)
                        .cornerRadius(40)
                })
                
                Spacer()
            }
            .padding()
            .navigationTitle("Settings")
            .interactiveDismissDisabled(!controller.isConnected)
            .toolbar {
                Button(action: {
                    controller.isPresented = false
                }, label: {
                    Text("Close")
                })
                .disabled(!controller.isConnected)
            }
            .alert(isPresented: $controller.showAlert) {
                Alert(
                    title: Text("Missing information"),
                    message: Text("Make sure that there's both an address, port, and topic."),
                    dismissButton: .default(Text("Ok"))
                )
            }
        }
    }
}

struct SettingsV_Previews: PreviewProvider {
    static var previews: some View {
        SettingsV(isPresented: .constant(true), mqttManager: StateObject(wrappedValue: MQTTManager()))
    }
}
