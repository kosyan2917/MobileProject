//
//  LoginController.swift
//  MobileProject
//
//  Created by Никита Косянков on 16.12.2024.
//

import UIKit

class LoginController: UIViewController {
    var login = UITextField()
    var password = UITextField()
    var enterLabel = UILabel()
    var loginButton = UIButton()
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Профиль"
        view.backgroundColor = .white
        configureLabelField()
        configureLoginField()
        configurePasswordField()
        configureLoginButton()
    }
    
    func configureLabelField() {
        view.addSubview(enterLabel)
        enterLabel.text = "Вход"
        enterLabel.textAlignment = .center
        enterLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            enterLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            enterLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 200),
            enterLabel.widthAnchor.constraint(equalToConstant: 200),
            enterLabel.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    func configureLoginField() {
        view.addSubview(login)
        login.delegate = self
        login.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            login.topAnchor.constraint(equalTo: enterLabel.bottomAnchor, constant: 50),
            login.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            login.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        login.borderStyle = .roundedRect
        login.placeholder = "username"
        login.autocapitalizationType = .none
    }
    
    func configurePasswordField() {
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
    
    func configureLoginButton() {
            loginButton.setTitle("Войти", for: .normal)
            loginButton.backgroundColor = .systemBlue
            loginButton.layer.cornerRadius = 10
            loginButton.translatesAutoresizingMaskIntoConstraints = false
            loginButton.addTarget(self, action: #selector(handleLoginButtonTap), for: .touchUpInside)
            view.addSubview(loginButton)
            
            NSLayoutConstraint.activate([
                loginButton.topAnchor.constraint(equalTo: password.bottomAnchor, constant: 30),
                loginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                loginButton.widthAnchor.constraint(equalToConstant: 100),
                loginButton.heightAnchor.constraint(equalToConstant: 50)
            ])
        }
        
    @objc func handleLoginButtonTap() {
        guard let username = login.text, !username.isEmpty,
              let passwordText = password.text, !passwordText.isEmpty else {
            showAlert(message: "Пожалуйста, заполните оба поля")
            return
        }
        do {
            try sendLoginRequest(username: username, password: passwordText)
        } catch {
            showAlert(message: "Возникла ошибка при попытке входа \(error.localizedDescription)")
        }
        
    }
    
    func sendLoginRequest(username: String, password: String) throws {
        // Подготовка данных для запроса
        guard let url = URL(string: "http://127.0.0.1:1337/api/auth") else {throw URLError(.badURL)}
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body = "username=\(username)&password=\(password)"
        request.httpBody = body.data(using: .utf8)
        // Отправка запроса
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.showAlert(message: "Ошибка: \(error.localizedDescription)")
                }
                return
            }
            
            if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                guard let downloadedData = data else {
                    DispatchQueue.main.async {
                        self.showAlert(message: "Данные для входа верны, но ответ от сервера неверный")
                    }
                    return
                }
                self.onLoginSuccess(data: downloadedData)
                
            } else {
                DispatchQueue.main.async {
                    self.showAlert(message: "Не удалось войти. Проверьте данные.")
                }
            }
        }
        task.resume()
    }
    
    func onLoginSuccess(data: Data) {
        do {
            let tokenJSON = try JSONDecoder().decode(loginResponse.self, from: data)
            let token = tokenJSON.token
            KeychainHelper.shared.save(token, forKey: "userToken")
            NotificationCenter.default.post(name: .loginSuccess, object: nil)
            DispatchQueue.main.async {
                self.showAlert(message: "Успешный вход, \(token)")
            }
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

extension LoginController: UITextFieldDelegate {
    
}

struct loginResponse: Codable {
    var token: String
}

extension Notification.Name {
    static let loginSuccess = Notification.Name("loginSuccess")
}
