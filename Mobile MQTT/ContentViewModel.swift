import SwiftUI

final class ContentViewModel: ObservableObject {
    /// Controller to show/hide settings sheet
    @Published var showSettings: Bool
    /// Rate to display on slider
    @Published var pollRate: Float
    
    init() {
        self.showSettings = false
        self.pollRate = 1
    }
    
    /// Generates a CSV file based on MQTT Manager data
    /// - Parameter data: Data to put into CSV file
    /// - Returns: URL to saved file
    func generateCSV(data: [MQTTManager.ArduinoData]) -> URL {
        let fileName = "data.csv"
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
        
        var csvText = "Time,Temperature,Humidity\n"
        for datum in data {
            let newLine = "\(datum.time / 1000),\(datum.humidity),\(datum.temperature)\n"
            csvText.append(newLine)
        }
        
        do {
            try csvText.write(to: path, atomically: true, encoding: .utf8)
        }
        catch {
            return URL(string: "")!
        }
        return path;
    }
}
