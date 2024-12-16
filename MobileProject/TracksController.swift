//
//  TracksController.swift
//  MobileProject
//
//  Created by Никита Косянков on 16.12.2024.
//

import UIKit

class TracksController: UIViewController {
    
    var unauthorizedLabel = UILabel()
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Треки"
        view.backgroundColor = .white
        NotificationCenter.default.addObserver(self, selector: #selector(handleLoginSuccess), name: .loginSuccess, object: nil)
        if let token = KeychainHelper.shared.get(forKey: "userToken") {
            print("Aboba")
            navigateToLoggedInView(token: token)
        } else {
            showUnauthorizedView()
        }
    }
    
    func configureUnathorizedLabel(text: String) {
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
    
    @objc func handleLoginSuccess() {
        if let token = KeychainHelper.shared.get(forKey: "userToken") {
            DispatchQueue.main.async {
                self.navigateToLoggedInView(token: token)
            }
        }
    }
    
    func navigateToLoggedInView(token: String) {
        let loggedInVC = LoggedTracksController()
        loggedInVC.token = token
        let navController = UINavigationController(rootViewController: loggedInVC)
        view.subviews.forEach { $0.removeFromSuperview() }
        self.addChild(navController)
        navController.view.frame = view.bounds
        view.addSubview(navController.view)
        navController.didMove(toParent: self)
    }
    
    func showUnauthorizedView() {
        unauthorizedLabel.removeFromSuperview()
        view.addSubview(unauthorizedLabel)
        unauthorizedLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            unauthorizedLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            unauthorizedLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 200),
            unauthorizedLabel.heightAnchor.constraint(equalToConstant: 80),
            unauthorizedLabel.widthAnchor.constraint(equalToConstant: 300)
        ])
        unauthorizedLabel.text = "Вы не авторизованы"
        unauthorizedLabel.textAlignment = .center
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .loginSuccess, object: nil)
    }
    
    
}
