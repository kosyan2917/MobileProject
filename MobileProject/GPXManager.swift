import MapKit

final class ClosureGPXDelegate: NSObject, XMLParserDelegate {
    private let onPoint: (CLLocationCoordinate2D) -> Void

    init(onPoint: @escaping (CLLocationCoordinate2D) -> Void) {
        self.onPoint = onPoint
    }

    func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes attributeDict: [String:String] = [:]) {
        guard elementName == "trkpt",
              let latS = attributeDict["lat"],
              let lonS = attributeDict["lon"],
              let lat = Double(latS),
              let lon = Double(lonS) else { return }

        let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        onPoint(coord)
    }
}

class GPXManager {
    
    static let shared = GPXManager()
    
    // Возможно ненужная функиця. Я не помню, где она используется
    func loadFile(filename: String) throws -> Data {
        guard let filePath = Bundle.main.path(forResource: filename, ofType: "gpx") else {throw parsingError.noSuchFile(file: filename)}
        guard let data = FileManager.default.contents(atPath: filePath) else {
            throw parsingError.readingError(file: filename)
        }
        return data
    }
    
    func parseXML(data: Data) -> [CLLocationCoordinate2D] {
        let parser = XMLParser(data: data)
        var points: [CLLocationCoordinate2D] = []
        
        let delegate = ClosureGPXDelegate { coord in
            points.append(coord)
        }
        parser.delegate = delegate
        parser.parse()
        return points
    }
    
    
    func generateGPX(from locations: [CLLocation]) -> Data {
        var gpxString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="MyApp" xmlns="http://www.topografix.com/GPX/1/1">
            <trk>
                <trkseg>
        """

        for location in locations {
            let timeString = ISO8601DateFormatter().string(from: location.timestamp)
            gpxString += """
            
                    <trkpt lat="\(location.coordinate.latitude)" lon="\(location.coordinate.longitude)">
                        <ele>\(location.altitude)</ele>
                        <time>\(timeString)</time>
                    </trkpt>
            """
        }

        gpxString += """
        
                </trkseg>
            </trk>
        </gpx>
        """

        return Data(gpxString.utf8)
    }
}
