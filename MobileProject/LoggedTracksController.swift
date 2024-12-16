//
//  LoggedTracksController.swift
//  MobileProject
//
//  Created by Никита Косянков on 16.12.2024.
//

import UIKit

class LoggedTracksController: UIViewController {
    
    
    var token: String?
    var tableView = UITableView()
    var files: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        configureTableView()
        do {
            try getFiles()
            
        } catch {
            print("Ошибка в getFiles \(error.localizedDescription)")
        }
        
    }
    
    func getFiles() throws {
        if token != nil {
            let url_string = "http://127.0.0.1:1337/api/files"
            guard let url = URL(string: url_string) else {
                throw URLError(.badURL)
            }
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue(token, forHTTPHeaderField: "Authorization")
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.showAlert(message: "Ошибка: \(error.localizedDescription)")
                    }
                    return
                }
                if let response = response as? HTTPURLResponse {
                    if response.statusCode == 200 {
                        guard let downloadedData = data else {
                            DispatchQueue.main.async {
                                self.showAlert(message: "Сервер вернул 200, но данных нет")
                            }
                            return
                        }
                        self.makeNavigationView(data: downloadedData)
                    }
                    else {
                        DispatchQueue.main.async {
                            self.showAlert(message: "Сервер не вернул 200 при попытке подгрузить файлы с треками  \(response.statusCode)")
                        }
                    }
                }
            }
            task.resume()
        }
    }
    
    func configureTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FileCell")
    }
    
    func makeNavigationView(data: Data) {
        do {
            var filesResponse = try JSONDecoder().decode(Files.self, from: data)
            files = filesResponse.files
            DispatchQueue.main.async{
                self.tableView.reloadData()
            }
            print(files)
        } catch {
            print("Ошибка")
        }
    }

    
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Уведомление", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }
}

struct Files: Codable {
    var files: [String]
}

extension LoggedTracksController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FileCell", for: indexPath)
        cell.textLabel?.text = files[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Переход на новый экран при выборе строки
        let mapVC = MapViewController()
        mapVC.fileName = files[indexPath.row]
        mapVC.token = token
        navigationController?.pushViewController(mapVC, animated: true)
    }
}
