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
        addChild(profileScreen)
        profileScreen.view.frame = view.bounds
        view.addSubview(profileScreen.view)
        profileScreen.didMove(toParent: self)
    }
}


class ProfileScreen: UIViewController {
    var greeting = UITextField()
    var logoutButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGreeting()
        setupLogoutButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // TODO: Запрос на профиль
        greeting.text = "Здрасьте"
    }
    
    private func setupGreeting() {
        view.addSubview(greeting)
        greeting.textAlignment = .center
        greeting.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            greeting.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            greeting.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            greeting.heightAnchor.constraint(equalToConstant: 80),
            greeting.widthAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    private func setupLogoutButton() {
        view.addSubview(logoutButton)
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        logoutButton.setTitle("Выйти", for: .normal)
        logoutButton.setTitleColor(.white, for: .normal)
        logoutButton.backgroundColor = .systemRed
        logoutButton.layer.cornerRadius = 5
        logoutButton.layer.borderWidth = 1
        logoutButton.layer.borderColor = UIColor.black.cgColor
        logoutButton.addTarget(self, action: #selector(handleLogoutTap), for: .touchUpInside)
        NSLayoutConstraint.activate([
            logoutButton.topAnchor.constraint(equalTo: greeting.bottomAnchor, constant: 10),
            logoutButton.heightAnchor.constraint(equalToConstant: 50),
            logoutButton.widthAnchor.constraint(equalToConstant: 100),
            logoutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    @objc private func handleLogoutTap() {
        KeychainHelper.shared.delete(forKey: "accsesToken")
        KeychainHelper.shared.delete(forKey: "refreshToken")
        NotificationCenter.default.post(name: .logout, object: nil)
    }
    
}

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
                let data = try await apiService.login(username: username, password: passwordText)
                onLoginSuccess(data: data)
            } catch {
                showAlert(message: "Возникла ошибка при попытке входа \(error.localizedDescription)")
            }
        }
        
    }
    
    private func onLoginSuccess(data: Data) {
        do {
            let tokenJSON = try JSONDecoder().decode(loginResponse.self, from: data)
            let access_token = tokenJSON.access_token
            let refresh_token = tokenJSON.refresh_token
            KeychainHelper.shared.save(access_token, forKey: "accessToken")
            KeychainHelper.shared.save(refresh_token, forKey: "refreshToken")
            NotificationCenter.default.post(name: .loginSuccess, object: nil)
            self.dismiss(animated: true)
        } catch {
            DispatchQueue.main.async {
                self.showAlert(message: "Данные с сервера не преобразовались в JSON")
            }
            return
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

