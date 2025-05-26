//
//  ResultViewController.swift
//  MobileProject
//
//  Created by Никита Косянков on 07.03.2025.
//


// НЕ ИСПОЛЬЗУЕТСЯ! Оставил пока чтобы было. Потом отправится на свалку истории
import UIKit
import CoreLocation
import MapKit
protocol ResultViewControllerDelegate: AnyObject {
    func newTrackDidTap()
}

final class ResultViewController: UIViewController {
    private let gpxParser = GPXManager.shared
    private let gpxGenerator = GPXManager.shared
    weak var delegate: ResultViewControllerDelegate?
    private let distance: Double
    private let time: String
    private let pace: Double
    private let locations: [CLLocation]
    init(distance: Double, time: String, pace: Double, locations: [CLLocation]) {
        self.distance = distance
        self.time = time
        self.pace = pace
        self.locations = locations
        super.init(nibName: nil, bundle: nil)
    }
    
    private lazy var resultText: UILabel = {
        let label = UILabel()
        label.text = "Результат"
        label.font = .systemFont(ofSize: 36, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var resultValue: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = .systemFont(ofSize: 14, weight: .light)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 5
        return label
    }()
    
    private var mapResult: MKMapView = {
        let map = MKMapView()
        map.translatesAutoresizingMaskIntoConstraints = false
        map.overrideUserInterfaceStyle = .dark
        return map
    }()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        let button = UIButton()
        button.setTitle("New Track", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(handleNewTrack(_:)), for: .touchUpInside)
        self.view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.trailingAnchor.constraint(equalTo: self.view.layoutMarginsGuide.trailingAnchor),
            button.topAnchor.constraint(equalTo: self.view.layoutMarginsGuide.topAnchor)
        ])
        setupResultText()
        setupResultValue()
        setupMap()
    }
    
    private func setupResultText() {
        view.addSubview(resultText)
        NSLayoutConstraint.activate([
            resultText.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            resultText.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
            resultText.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
            resultText.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupResultValue() {
        view.addSubview(resultValue)
        NSLayoutConstraint.activate([
            resultValue.topAnchor.constraint(equalTo: resultText.bottomAnchor, constant: 16),
            resultValue.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
            resultValue.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
            resultValue.heightAnchor.constraint(equalToConstant: 50)
        ])
        resultValue.text = String(format: "Результат тренировки: дистанция - %.2f метров, время - %@, средняя скорость - %.2f м/c", self.distance, self.time, self.pace)

    }
    
    private func setupMap() {
        mapResult.delegate = self
        view.addSubview(mapResult)
        NSLayoutConstraint.activate([
            mapResult.topAnchor.constraint(equalTo: resultValue.bottomAnchor, constant: 16),
            mapResult.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
            mapResult.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
            mapResult.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
            var locations2d: [CLLocationCoordinate2D] = []
            for location in locations {
                locations2d.append(CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude))
            }
            print(locations2d)
            let polyline = MKPolyline(coordinates: locations2d, count: locations2d.count)
            mapResult.addOverlay(polyline)
            let polylineRegion = MKCoordinateRegion(
                center: locations2d.first ?? CLLocationCoordinate2D(),
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            )
            mapResult.setRegion(polylineRegion, animated: true)
    }

    @objc private func handleNewTrack(_ sender:UIButton) {
        self.delegate?.newTrackDidTap()
    }
}

extension ResultViewController: MKMapViewDelegate {
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


