//
//  ProfileController.swift
//  MobileProject
//
//  Created by Никита Косянков on 13.02.2025.
//
import UIKit
class ProfileController: UIViewController {
    
    var loginScreen = LoginScreen()
    var profileScreen = ProfileScreen()
    override func viewDidLoad() {
        super.viewDidLoad()
        if KeychainHelper.shared.get(forKey: "accessToken") != nil {
            setProfileScreen()
        } else {
            setLoginScreen()
        }
    }
    
    public func setLoginScreen() {
        view.subviews.forEach { $0.removeFromSuperview() }
        addChild(loginScreen)
        loginScreen.view.frame = view.bounds
        view.addSubview(loginScreen.view)
        loginScreen.didMove(toParent: self)
    }
    
    public func setProfileScreen() {
        view.subviews.forEach { $0.removeFromSuperview() }
        let profileView = UIHostingController(rootView: profileScreen)
        addChild(profileView)
        profileView.view.frame = view.bounds
        view.addSubview(profileView.view)
        profileView.didMove(toParent: self)
    }
}

import SwiftUI

struct ProfileScreen: View {
    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            VStack(spacing: 10) {
                Image("profileImage")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .shadow(radius: 5)
                Text("Ivan Petrov")
                    .font(.title)
                    .fontWeight(.bold)
            }
            .padding()
            
            VStack(alignment: .center, spacing: 8) {
                Text("Последняя активность")
                    .font(.headline)
                Text("Последняя тренировка: 5 апреля 2025")
                    .font(.subheadline)
                Text("Тип: Силовая • Длительность: 45 мин")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .frame(minWidth: 0, maxWidth: .infinity)
            
            
            VStack(alignment: .center, spacing: 8) {
                Text("За последние 30 дней")
                    .font(.headline)
                HStack {
                    VStack(alignment: .leading) {
                        Text("Дистанция")
                            .font(.subheadline)
                        Text("42 км")
                            .font(.title2)
                            .fontWeight(.medium)
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("Время тренировок")
                            .font(.subheadline)
                        Text("5 ч")
                            .font(.title2)
                            .fontWeight(.medium)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .frame(minWidth: 0, maxWidth: .infinity)

            
            Button(action: {
                NotificationCenter.default.post(name: .logout, object: nil)
            }) {
                Text("Выйти")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            Spacer()

        }
        .padding()
        
    }
}


//    @objc private func handleLogoutTap() {
//        KeychainHelper.shared.delete(forKey: "accsesToken")
//        KeychainHelper.shared.delete(forKey: "refreshToken")
//        NotificationCenter.default.post(name: .logout, object: nil)

class LoginScreen: UIViewController {
    var login = UITextField()
    var password = UITextField()
    var enterLabel = UILabel()
    var loginButton = UIButton()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.isModalInPresentation = true
        title = "Профиль"
        view.backgroundColor = .white
        configureLoginField()
        configureLabelField()
        configurePasswordField()
        configureLoginButton()
    }
    
    private func configureLabelField() {
        view.addSubview(enterLabel)
        enterLabel.text = "Вход"
        enterLabel.textAlignment = .center
        enterLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            enterLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            enterLabel.bottomAnchor.constraint(equalTo: login.topAnchor, constant: -50)
        ])
    }
    
    private func configureLoginField() {
        view.addSubview(login)
        login.delegate = self
        login.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            login.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            login.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            login.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            login.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        login.borderStyle = .roundedRect
        login.placeholder = "username"
        login.autocapitalizationType = .none
    }
    
    private func configurePasswordField() {
        view.addSubview(password)
        password.delegate = self
        password.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            password.topAnchor.constraint(equalTo: login.bottomAnchor, constant: 50),
            password.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            password.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        password.borderStyle = .roundedRect
        password.placeholder = "password"
        password.isSecureTextEntry = true
        password.autocapitalizationType = .none
    }
    
    private func configureLoginButton() {
        view.addSubview(loginButton)
        loginButton.setTitle("Войти", for: .normal)
        loginButton.backgroundColor = .systemBlue
        loginButton.layer.cornerRadius = 10
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.addTarget(self, action: #selector(handleLoginButtonTap), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            loginButton.topAnchor.constraint(equalTo: password.bottomAnchor, constant: 30),
            loginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loginButton.widthAnchor.constraint(equalToConstant: 100),
            loginButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
        
    @objc private func handleLoginButtonTap() {
        print("aboba")
        guard let username = login.text, !username.isEmpty,
              let passwordText = password.text, !passwordText.isEmpty else {
            showAlert(message: "Пожалуйста, заполните оба поля")
            return
        }
        Task {
            do {
                try await apiService.login(username: username, password: passwordText)
                NotificationCenter.default.post(name: .loginSuccess, object: nil)
                self.dismiss(animated: true)
            } catch {
                showAlert(message: "Возникла ошибка при попытке входа \(error.localizedDescription)")
            }
        }
        
    }
    
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Уведомление", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }
}

extension LoginScreen: UITextFieldDelegate {
    
}

