import MapKit

class GPXGenerator {
    
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
