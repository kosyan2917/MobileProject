//
//  LoggedTracksController.swift
//  MobileProject
//
//  Created by Никита Косянков on 16.12.2024.
//

import UIKit

class LoggedTracksController: UIViewController {
    
    
    var tableView = UITableView()
    var files: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .reloadTracks, object: nil)
        configureTableView()
    }
    
    @objc private func reloadData() {
        Task {
            do {
                print(345)
                let data = try await apiService.getFiles()
                makeNavigationView(data: data)
            } catch {
                print("Ошибка в getFiles \(error.localizedDescription)")
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task {
            do {
                print(123)
                let data = try await apiService.getFiles()
                makeNavigationView(data: data)
            } catch {
                print("Ошибка в getFiles \(error.localizedDescription)")
            }
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
            let filesResponse = try JSONDecoder().decode(Files.self, from: data)
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
        let mapVC = MapViewController(filename: files[indexPath.row])
        navigationController?.pushViewController(mapVC, animated: true)
    }
}
