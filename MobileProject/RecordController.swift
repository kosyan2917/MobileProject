//
//  RecordController.swift
//  MobileProject
//
//  Created by Никита Косянков on 15.02.2025.
//

import UIKit
import CoreLocation

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
    func stopDidTap(distance: Double, time: String, pace: Double) {
        let resultVC = ResultViewController(distance: distance, time: time, pace: pace)
        resultVC.delegate = self
        
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
    
extension RecordController: ResultViewControllerDelegate {
    func newTrackDidTap() {
        let transition = CATransition()
        transition.type = .push
        transition.subtype = .fromLeft
        transition.duration = 0.5
        view.layer.add(transition, forKey: kCATransition)

        newTrack()
    }
}


