//
//  RecordPlayingView.swift
//  MobileProject
//
//  Created by Никита Косянков on 07.03.2025.
//
import UIKit

protocol RecordPlayingViewDataSource: AnyObject {
    func currentPace() -> Double
    func currentDistance() -> Double
    func getTime() -> String
}

final class RecordPlayingView: UIView {
    private var timer: Timer?
    weak var dataSource: RecordPlayingViewDataSource?

    private let timeTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "TIME"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        return label
    }()

    private let timeValueLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00:00"
        label.font = .systemFont(ofSize: 36, weight: .bold)
        label.textAlignment = .center
        return label
    }()

    private let paceTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "AVG PACE (/KM)"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        return label
    }()

    private let paceValueLabel: UILabel = {
        let label = UILabel()
        label.text = "0:00"
        label.font = .systemFont(ofSize: 36, weight: .bold)
        label.textAlignment = .center
        return label
    }()

    private let distanceTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "DISTANCE (KM)"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        return label
    }()

    private let distanceValueLabel: UILabel = {
        let label = UILabel()
        label.text = "0.00"
        label.font = .systemFont(ofSize: 36, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupTimer()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    private func setupUI() {
        // Добавляем сабвью
        [timeTitleLabel, timeValueLabel,
         paceTitleLabel, paceValueLabel,
         distanceTitleLabel, distanceValueLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        // Настраиваем Auto Layout
        NSLayoutConstraint.activate([
            // TIME
            timeTitleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            timeTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            timeTitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            timeValueLabel.topAnchor.constraint(equalTo: timeTitleLabel.bottomAnchor, constant: 8),
            timeValueLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            timeValueLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            // AVG PACE
            paceTitleLabel.topAnchor.constraint(equalTo: timeValueLabel.bottomAnchor, constant: 32),
            paceTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            paceTitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            paceValueLabel.topAnchor.constraint(equalTo: paceTitleLabel.bottomAnchor, constant: 8),
            paceValueLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            paceValueLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            // DISTANCE (растягиваем на всю ширину, без графика)
            distanceTitleLabel.topAnchor.constraint(equalTo: paceValueLabel.bottomAnchor, constant: 32),
            distanceTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            distanceTitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            distanceValueLabel.topAnchor.constraint(equalTo: distanceTitleLabel.bottomAnchor, constant: 8),
            distanceValueLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            distanceValueLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            // Опционально можно зафиксировать нижний отступ,
            // чтобы всё красиво тянулось:
            distanceValueLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }

    private func setupTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateLabel), userInfo: nil, repeats: true)
    }

    @objc private func updateLabel() {
        timeValueLabel.text = dataSource?.getTime()
        if let pace: Double = dataSource?.currentPace() {
            paceValueLabel.text = String(format: "%.2f", pace)
        } else {
            paceValueLabel.text = "0.00"
        }
        if let distance: Double = dataSource?.currentDistance() {
            distanceValueLabel.text = String(format: "%.2f", distance)
        } else {
            distanceValueLabel.text = "0.00"
        }
    }
    
    
    
    // MARK: - Deinit (если нужно убрать link)

    deinit {
        timer?.invalidate()
    }
}
