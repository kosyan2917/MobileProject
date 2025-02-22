//
//  TracksController.swift
//  MobileProject
//
//  Created by Никита Косянков on 16.12.2024.
//

import UIKit

class TracksController: UIViewController {
    
    var unauthorizedScreen = UnauthorizedScreen()
    var tracksScreen = TracksScreen()
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Треки"
        view.backgroundColor = .white
        if KeychainHelper.shared.get(forKey: "accessToken") != nil {
            setTracksView()
        } else {
            setUnauthorizedView()
        }
    }
    
    @objc func handleLoginSuccess() {
        setTracksView()
    }
    
    public func setTracksView() {
        view.subviews.forEach { $0.removeFromSuperview() }
        let loggedInVC = LoggedTracksController()
        let navController = UINavigationController(rootViewController: loggedInVC)
        addChild(navController)
        navController.view.frame = view.bounds
        view.addSubview(navController.view)
        navController.didMove(toParent: self)
    }
    
    public func setUnauthorizedView() {
        view.subviews.forEach { $0.removeFromSuperview() }
        addChild(unauthorizedScreen)
        unauthorizedScreen.view.frame = view.bounds
        view.addSubview(unauthorizedScreen.view)
        unauthorizedScreen.didMove(toParent: self)
    }
    
}

class UnauthorizedScreen: UIViewController {
    var unauthorizedLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUnathorizedLabel(text: "Вы не авторизованы")
    }
    
    private func setupUnathorizedLabel(text: String) {
        view.addSubview(unauthorizedLabel)
        unauthorizedLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            unauthorizedLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            unauthorizedLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 200),
            unauthorizedLabel.heightAnchor.constraint(equalToConstant: 80),
            unauthorizedLabel.widthAnchor.constraint(equalToConstant: 300)
        ])
        unauthorizedLabel.text = text
        unauthorizedLabel.textAlignment = .center
    }
}

class TracksScreen: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
}


