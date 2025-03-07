//
//  RecordPlayingController.swift
//  MobileProject
//
//  Created by Никита Косянков on 07.03.2025.
//

import UIKit
import CoreLocation
class RecordModel {
    
    var startTime: Date
    var distance: Double = 0
    var pace: Double = 0
    var elapsedSeconds: Double = 0
    var isPlaying = false
    
    init() {
        startTime = Date()
    }
    
    func dropValues() {
        startTime = Date()
        elapsedSeconds = 0
        distance = 0
        pace = 0
    }
    
    func getTotalPace() -> Double {
        return distance/elapsedSeconds
    }
    
    func getTime() -> String {
        if isPlaying {
            elapsedSeconds += Double(Date().timeIntervalSince(startTime))
        }
        let hours = Int(elapsedSeconds) / 3600
        let minutes = (Int(elapsedSeconds) % 3600) / 60
        let seconds = Int(elapsedSeconds) % 60
        startTime = Date()
        if hours > 0 {
            return String(format: "%dч %02dм %02dс", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%dм %02dс", minutes, seconds)
        } else {
            return String(format: "%dс", seconds)
        }
    }
}

protocol RecordPlayingControllerDelegate: AnyObject {
    func stopDidTap(distance: Double, time: String, pace: Double)
}

class RecordPlayingController: UIViewController {
    private var isRunning = false
    private let model = RecordModel()
    private let locationManager = CLLocationManager()
    private var previousLocation: CLLocation?
    
    weak var delegate: RecordPlayingControllerDelegate?

    private lazy var playButton: RecordPlayButton = {
        let b = RecordPlayButton()
        b.translatesAutoresizingMaskIntoConstraints = false
        b.delegate = self
        return b
    }()

    private lazy var stopButton: UIButton = {
        let b = UIButton()
        b.setImage(UIImage(systemName: "stop.fill"), for: .normal)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(stopHandle(_:)), for: .touchUpInside)
        b.backgroundColor = .systemRed
        b.layer.cornerRadius = 40
        return b
    }()


    private lazy var trackView: RecordPlayingView = {
        let v = RecordPlayingView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.dataSource = self
        return v
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        model.dropValues()
        self.view.backgroundColor = .white

        self.view.addSubview(self.playButton)
        self.view.addSubview(self.trackView)
        self.view.addSubview(self.stopButton)

        self.configure(onlyButton: true)

        NSLayoutConstraint.activate([
            self.trackView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.trackView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),

            self.stopButton.widthAnchor.constraint(equalToConstant: 80),
            self.stopButton.heightAnchor.constraint(equalToConstant: 80),
            self.stopButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor, constant: 50),
            self.stopButton.bottomAnchor.constraint(equalTo: self.view.layoutMarginsGuide.bottomAnchor)
        ])
    }

    private lazy var state1Constraints: [NSLayoutConstraint] = [
        self.playButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
        self.playButton.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
        self.playButton.widthAnchor.constraint(equalToConstant: 120)
    ]

    private lazy var state2Constraints: [NSLayoutConstraint] = [
        self.playButton.bottomAnchor.constraint(equalTo: self.view.layoutMarginsGuide.bottomAnchor),
        self.playButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor, constant: -50),
        self.playButton.widthAnchor.constraint(equalToConstant: 80)
    ]
    
    private func configure(onlyButton: Bool) {
        if onlyButton {
            if !isRunning {
                self.trackView.isHidden = true
                self.stopButton.alpha = 0
                NSLayoutConstraint.deactivate(state2Constraints)
                NSLayoutConstraint.activate(state1Constraints)
            }
        } else {
            self.trackView.isHidden = false
            self.stopButton.alpha = 1
            NSLayoutConstraint.deactivate(state1Constraints)
            NSLayoutConstraint.activate(state2Constraints)
        }
    }
    
    @objc private func stopHandle(_ sender:UIButton) {
        isRunning = false
        delegate?.stopDidTap(distance: model.distance, time: model.getTime(), pace: model.getTotalPace())
    }
}

extension RecordPlayingController: RecordPlayingViewDataSource {
    func getTime() -> String {
        return model.getTime()
    }
    
    func currentPace() -> Double {
        return model.pace
    }
    
    func currentDistance() -> Double {
        return model.distance
    }
}

extension RecordPlayingController: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }

        if let previousLocation = previousLocation {
            let distance = newLocation.distance(from: previousLocation)
            model.distance += distance
        }
        model.pace = newLocation.speed >= 0 ? newLocation.speed : model.pace
        previousLocation = newLocation
    }
       
   func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
       print("Ошибка получения местоположения: \(error.localizedDescription)")
   }
}

extension RecordPlayingController: RecordPlayButtonDelegate {
    func statesDidChanged(_ isPlaying: Bool) {
        model.isPlaying = isPlaying
        if isPlaying {
            locationManager.startUpdatingLocation()
        } else {
            locationManager.stopUpdatingLocation()
        }
        UIView.animate(withDuration: 1) {
            self.configure(onlyButton: !isPlaying)
            self.view.layoutIfNeeded()
        }
        
        isRunning = true
    }
}
