//
//  RecordPlayButton.swift
//  MobileProject
//
//  Created by Никита Косянков on 07.03.2025.
//

import UIKit

protocol RecordPlayButtonDelegate: AnyObject {
    func statesDidChanged(_ isPlaying: Bool)
}

final class RecordPlayButton: UIButton {

    private var isPlaying: Bool = false
    weak var delegate: RecordPlayButtonDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addTarget(self, action: #selector(handleTouch(_:)), for: .touchUpInside)
        self.widthAnchor.constraint(equalTo: self.heightAnchor).isActive = true

        self.configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.bounds.width / 2
    }

    @objc private func handleTouch(_ sender:UIButton) {
        self.isPlaying = !self.isPlaying
        self.delegate?.statesDidChanged(self.isPlaying)
        UIView.animate(withDuration: 1) {
            self.configure()
        }
    }

    private func configure() {
        if isPlaying {
            self.setImage(UIImage(systemName: "pause"), for: .normal)
            self.backgroundColor = .systemYellow
        } else {
            self.setImage(UIImage(systemName: "play"), for: .normal)
            self.backgroundColor = .systemGreen
        }
    }
}

