//
//  MainController.swift
//  MobileProject
//
//  Created by Никита Косянков on 13.02.2025.
//

import UIKit

class MainController: UITabBarController {
    
    let tracksController = TracksController()
    let profileController = ProfileController()
    let recordController = RecordController()

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if KeychainHelper.shared.get(forKey: "refreshToken") == nil {
            presentLoginPage()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(handleLogout), name: .logout, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleUnauthorized), name: .unauthorized, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleLoginSuccess), name: .loginSuccess, object: nil)
        delegate = self
        tracksController.tabBarItem = UITabBarItem(
            title: "Треки",
            image: .init(systemName: "arrow.circlepath"),
            tag: 0
        )
        profileController.tabBarItem = UITabBarItem(
            title: "Профиль",
            image: .init(systemName: "person.fill.viewfinder"),
            tag: 2
        )
        recordController.tabBarItem = UITabBarItem(
            title: "Запись тренировки",
            image: .init(systemName: "arrow.triangle.merge"),
            tag: 1
        )
        viewControllers = [
            tracksController,
            recordController,
            profileController
        ]    }
    
    func presentLoginPage() {
        let loginPage = LoginScreen()
        self.present(loginPage, animated: true)
    }
    
    @objc private func handleLoginSuccess() {
        tracksController.setTracksView()
        profileController.setProfileScreen()
    }
    
    @objc private func handleLogout() {
        tracksController.setUnauthorizedView()
        presentLoginPage()
    }
    
    @objc private func handleUnauthorized() {
        KeychainHelper.shared.delete(forKey: "accessToken")
        KeychainHelper.shared.delete(forKey: "refreshToken")
        tracksController.setUnauthorizedView()
        presentLoginPage()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .logout, object: nil)
        NotificationCenter.default.removeObserver(self, name: .unauthorized, object: nil)
    }
}

extension Notification.Name {
    static let loginSuccess = Notification.Name("login")
    static let unauthorized = Notification.Name("unauthorized")
    static let logout = Notification.Name("logout")
    static let reloadTracks = Notification.Name("reloadTracks")
}

extension MainController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if viewController is TracksController {
            NotificationCenter.default.post(name: .reloadTracks, object: nil)
        }
    }
}
