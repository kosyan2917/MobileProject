//
//  LoggedTracksController.swift
//  MobileProject
//
//  Created by Никита Косянков on 16.12.2024.
//

import UIKit
import SwiftUI

class LoggedTracksController: UIViewController {
    
    
    var tableView = UITableView()
    private var syncButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Синхронизировать", for: .normal)
        button.backgroundColor = .systemIndigo
        button.titleLabel?.textColor = .white
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        button.layer.cornerRadius = 25
        return button
    }()
    
    var files: [Tracks] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
//        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .reloadTracks, object: nil)
        setupSyncButton()
        setupTableView()
    }
    
    @objc private func reloadData() {
        Task {
            do {
                print(345)
                files = try await apiService.getFiles()
                DispatchQueue.main.async{
                    self.tableView.reloadData()
                }
            } catch APIErrors.Unauthorized {
                NotificationCenter.default.post(name: .unauthorized, object: nil)
            } catch {
                print("Ошибка в getFiles \(error.localizedDescription)")
            }
        }
    }
    
    private func setupSyncButton() {
        view.addSubview(syncButton)
        NSLayoutConstraint.activate([
            syncButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            syncButton.heightAnchor.constraint(equalToConstant: 50),
            syncButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            syncButton.widthAnchor.constraint(equalToConstant: 250)
        ])
        syncButton.addTarget(self, action: #selector(sync), for: .touchUpInside)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task {
            do {
                print(123)
                files = try await apiService.getFiles()
                DispatchQueue.main.async{
                    self.tableView.reloadData()
                }
            } catch APIErrors.Unauthorized {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .unauthorized, object: nil)
                }
            } catch {
                print(error)
                print("Ошибка в getFiles \(error.localizedDescription)")
            }
        }
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: syncButton.topAnchor)
        ])
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FileCell")
    }
    @objc private func sync() {
        Task {
            do {
                try await apiService.sync()
                DispatchQueue.main.async{
                    self.tableView.reloadData()
                }
            } catch APIErrors.Unauthorized {
                NotificationCenter.default.post(name: .unauthorized, object: nil)
            } catch {
                print("Ошибка в getFiles \(error.localizedDescription)")
            }
        }
    }
    
    private func showAlert(message: String) {
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
        cell.textLabel?.text = files[indexPath.row].name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let mapVC = UIHostingController(rootView: TrainingView(filename: files[indexPath.row].name!))
        navigationController?.pushViewController(mapVC, animated: true)
    }
}
