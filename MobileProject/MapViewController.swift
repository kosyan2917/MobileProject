//
//  ViewController.swift
//  MobileProject
//
//  Created by Никита Косянков on 12.12.2024.
//

import UIKit
import MapKit
import CoreLocation
class MapViewController: UIViewController {

    var filename: String
    let mapView: MKMapView = {
        let map = MKMapView()
        map.translatesAutoresizingMaskIntoConstraints = false
        map.overrideUserInterfaceStyle = .dark
        return map
    }()
    
    init(filename: String) {
        self.filename = filename
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        return nil
    }
    

    
    let gpxParser: GPXParser = GPXParser()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        mapView.delegate = self
        setMapConstraints()
//        makeDotsFromFile(filename: "fells_loop")
        Task {
            await makeDotsFromQuery()
        }
    }

    func setMapConstraints() {
        view.addSubview(mapView)
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mapView.leftAnchor.constraint(equalTo: view.leftAnchor),
            mapView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
    }
    
    func draw(data: Data) {
        gpxParser.parseXML(data: data)
        let waypoints = gpxParser.wayPoints
        let routePoints = gpxParser.routePoints
        for coordinate in waypoints {
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = "Waypoint"
            mapView.addAnnotation(annotation)
        }
        if !routePoints.isEmpty {
            let polyline = MKPolyline(coordinates: routePoints, count: routePoints.count)
            mapView.addOverlay(polyline)
            let allCoordinates = waypoints + routePoints
            let polylineRegion = MKCoordinateRegion(
                center: allCoordinates.first ?? CLLocationCoordinate2D(),
                latitudinalMeters: 5000,
                longitudinalMeters: 5000
            )
            mapView.setRegion(polylineRegion, animated: true)
        }
    }
    
    func makeDotsFromQuery() async {
        do {
            print(filename)
            let data = try await apiService.getGPX(filename: filename)
            print(data)
            draw(data: data)
        } catch {
            print("\(error.localizedDescription)")
        }
    }
    
    
    func makeDotsFromFile(filename: String) {
        do {
            let data = try gpxParser.loadFile(filename: filename)
            draw(data: data)
        } catch {
            print("Error file reading a file")

        }
    }
}

class GPXParser: NSObject, XMLParserDelegate {
    
    var wayPoints: [CLLocationCoordinate2D] = []
    var routePoints: [CLLocationCoordinate2D] = []
    
    func loadFile(filename: String) throws -> Data {
        guard let filePath = Bundle.main.path(forResource: filename, ofType: "gpx") else {throw parsingError.noSuchFile(file: filename)}
        guard let data = FileManager.default.contents(atPath: filePath) else {
            throw parsingError.readingError(file: filename)
        }
        return data
    }
    
    func parseXML(data: Data) {
        let parser = XMLParser(data: data)
        parser.delegate = self
        wayPoints = []
        routePoints = []
        parser.parse()
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String:String] = [:]) {
        if elementName == "wpt",
           let latString = attributeDict["lat"],
           let lonString = attributeDict["lon"],
           let lat = Double(latString),
           let lon = Double(lonString) {
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            wayPoints.append(coordinate)
        } else if elementName == "trkpt",
                  let latString = attributeDict["lat"],
                  let lonString = attributeDict["lon"],
                  let lat = Double(latString),
                  let lon = Double(lonString) {
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            routePoints.append(coordinate)
        }
    }
    
}

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .red
            renderer.lineWidth = 5
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
}

enum GPXError: Error {
    case fileNameOrTokenEqualsNil
}
enum parsingError: Error {
    case noSuchFile(file: String)
    case readingError(file: String)
}
