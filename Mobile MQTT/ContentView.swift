//
//  ContentView.swift
//  MQTT
//
//  Created by Ben Roberts on 3/21/23.
//

import Charts
import SwiftUI

struct ContentView: View {
    @StateObject private var controller: ContentViewModel = ContentViewModel()
    @StateObject var mqttManager = MQTTManager()
    
    var body: some View {
        NavigationView {
            VStack {
                TabView {
                    VStack {
                        Text("Humidity")
                            .font(.callout)
                            .fontWeight(.heavy)
                            .foregroundColor(.secondary)
                        Chart {
                            ForEach(mqttManager.data) { item in
                                LineMark(
                                    x: .value("Time", item.time / 1000),
                                    y: .value("Humidity", item.humidity))
                            }
                        }
                        .chartXScale(domain: .automatic(includesZero: false, reversed: false), range: .plotDimension)
                        .chartYScale(domain: .automatic(includesZero: false, reversed: false), range: .plotDimension)
                        .padding(.vertical)
                    }
                    .padding(.bottom, 30)
                    
                    VStack {
                        Text("Temperature")
                            .font(.callout)
                            .fontWeight(.heavy)
                            .foregroundColor(.secondary)
                        Chart {
                            ForEach(mqttManager.data) { item in
                                LineMark(
                                    x: .value("Time", item.time / 1000),
                                    y: .value("Temperature", item.temperature))
                            }
                        }
                        .chartXScale(domain: .automatic(includesZero: false, reversed: false), range: .plotDimension)
                        .chartYScale(domain: .automatic(includesZero: false, reversed: false), range: .plotDimension)
                        .padding(.vertical)
                    }
                    .padding(.bottom, 30)
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .frame(height: 500)
                
                VStack {                                                                                                            // Slider for 1 to 10
                    Slider(
                        value: $controller.pollRate,
                        in: 1...10,
                        step: 1
                    )
                    .disabled(mqttManager.pollRate == 0)
                    
                    if Int(controller.pollRate) != mqttManager.pollRate && mqttManager.pollRate != 0 {                              // If the slider value differs from Arduino's...
                        Button(action: {                                                                                                // Show a button to set the Arduino's
                            mqttManager.setPollRate(rate: Int(controller.pollRate))
                        }, label: {
                            HStack {
                                if controller.pollRate == 1 {
                                    Text("Change to poll every \(String(format: "%g", controller.pollRate)) second?")                   // Single second text
                                        .foregroundColor(.blue)
                                }
                                else {
                                    Text("Change to poll every \(String(format: "%g", controller.pollRate)) seconds?")                  // Multiple seconds text
                                        .foregroundColor(.blue)
                                }
                                Image(systemName: "paperplane.fill")
                            }
                        })
                    }
                    else {                                                                                                          // Otherwise show normal text
                        if controller.pollRate == 1 {
                            Text("Poll every \(String(format: "%g", controller.pollRate)) second")                                      // Single second text
                        }
                        else {
                            Text("Poll every \(String(format: "%g", controller.pollRate)) seconds")                                     // Multiple seconds text
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .sheet(                                                                                                                 // Settings sheet
                isPresented: $controller.showSettings,
                content: {
                    SettingsV(isPresented: $controller.showSettings, mqttManager: _mqttManager)
                }
            )
            .navigationTitle("MQTT")                                                                                                // Show MQTT at top
            .toolbar {                                                                                                              // Add buttons to nav bar
                ShareLink("", item: controller.generateCSV(data: mqttManager.data))                                                     // Share button
                Button(action: {                                                                                                        // Settings button
                    controller.showSettings = true
                }, label: {
                    Image(systemName: "gear")
                })
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
