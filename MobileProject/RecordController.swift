//
//  RecordController.swift
//  MobileProject
//
//  Created by Никита Косянков on 15.02.2025.
//

import UIKit
import CoreLocation
import SwiftUI

class RecordController: UIViewController {
    
    var currentVC: UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        newTrack()
    }

    func newTrack() {
        if let currentVC {
            currentVC.willMove(toParent: nil)
            currentVC.view.removeFromSuperview()
            currentVC.removeFromParent()
        }

        let trackVC = RecordPlayingController()
        trackVC.delegate = self

        addChild(trackVC)
        trackVC.view.frame = view.bounds
        view.addSubview(trackVC.view)
        trackVC.didMove(toParent: self)

        currentVC = trackVC
    }
}

extension RecordController: RecordPlayingControllerDelegate {
    func stopDidTap(distance: Double, time: String, pace: Double, locations: [CLLocation], elapsed: Int) {
//        let resultVC = ResultViewController(distance: distance, time: time, pace: pace, locations: locations)
//        resultVC.delegate = self
        let resultVC = UIHostingController(rootView: ResultView(time: time, elapsed: elapsed, distance: distance, pace: pace, locations: locations, onTapped: newTrackDidTap))
        let transition = CATransition()
        transition.type = .push
        transition.subtype = .fromRight
        transition.duration = 0.5
        view.layer.add(transition, forKey: kCATransition)
        
        currentVC?.willMove(toParent: nil)
        currentVC?.view.removeFromSuperview()
        currentVC?.removeFromParent()
        
        self.addChild(resultVC)
        resultVC.view.frame = view.bounds
        view.addSubview(resultVC.view)
        resultVC.didMove(toParent: self)
        
        currentVC = resultVC
    }
}
    
extension RecordController {
    func newTrackDidTap(locations: [CLLocation], distance: Double, time: Int) {
        let context = CoreDataManager.shared.context
        let track = Tracks(context: context)
        let name = "Жесткий тренинг \(Int(Date().timeIntervalSince1970))"
        track.name = name
        track.createdAt = Date.now
        track.isPublished = false
        track.distance = distance
        track.time = Int64(time)
        track.user = JWTHelper.shared.getUser()
        CoreDataManager.shared.saveContext()
        let gpx = GPXManager.shared.generateGPX(from: locations)
        GPXFileManager.shared.saveTrackFile(fileName: name, data: gpx)
        Task {
            do {
                try await apiService.sendFile(file: gpx, name: name)
            } catch {
                print("Ошибка при отправке результата на сервер")
            }
        }
        let transition = CATransition()
        transition.type = .push
        transition.subtype = .fromLeft
        transition.duration = 0.5
        view.layer.add(transition, forKey: kCATransition)
        newTrack()
    }
}


