//
//  ResultViewController.swift
//  MobileProject
//
//  Created by Никита Косянков on 07.03.2025.
//
import UIKit
protocol ResultViewControllerDelegate: AnyObject {
    func newTrackDidTap()
}

final class ResultViewController: UIViewController {
    weak var delegate: ResultViewControllerDelegate?
    private let distance: Double
    private let time: String
    private let pace: Double
    init(distance: Double, time: String, pace: Double) {
        self.distance = distance
        self.time = time
        self.pace = pace
        super.init(nibName: nil, bundle: nil)
    }
    
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

        let label = UILabel()
        label.numberOfLines = 5
        self.view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: self.view.layoutMarginsGuide.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: self.view.layoutMarginsGuide.trailingAnchor),
            label.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),

            button.trailingAnchor.constraint(equalTo: self.view.layoutMarginsGuide.trailingAnchor),
            button.topAnchor.constraint(equalTo: self.view.layoutMarginsGuide.topAnchor)
        ])
        label.text = "\(self.distance) \(self.time) \(self.pace)"
    }

    @objc private func handleNewTrack(_ sender:UIButton) {
        self.delegate?.newTrackDidTap()
    }
}
