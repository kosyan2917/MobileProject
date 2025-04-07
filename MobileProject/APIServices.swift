//
//  APIServices.swift
//  MobileProject
//
//  Created by Никита Косянков on 05.02.2025.
//

import Foundation
import CoreData

enum APIErrors: Error {
    case NoData
    case IncorrectLoginData
    case ServerError
    case BadURL
    case BadServerResponse
    case Unauthorized
}

class NewAPIService {
    private let baseUrl = "http://localhost:1337/api/"
    
    private func refresh() async throws {
        guard let url = URL(string: baseUrl+"auth/refresh") else { throw APIErrors.BadURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        guard let refresh = KeychainHelper.shared.get(forKey: "refreshToken") else {
            throw APIErrors.Unauthorized
        }
        request.setValue(refresh, forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 400 || httpResponse.statusCode == 401 {
                KeychainHelper.shared.delete(forKey: "accessToken")
                KeychainHelper.shared.delete(forKey: "refreshToken")
                throw APIErrors.Unauthorized
            }
            else if httpResponse.statusCode != 200 {
                KeychainHelper.shared.delete(forKey: "accessToken")
                KeychainHelper.shared.delete(forKey: "refreshToken")
                throw APIErrors.BadServerResponse
            }
        }
        let newTokens = try JSONDecoder().decode(tokens.self, from: data)
        KeychainHelper.shared.save(newTokens.refreshToken, forKey: "refreshToken")
        KeychainHelper.shared.save(newTokens.accessToken, forKey: "accessToken")
    }
    
    private func checkAuth() -> Bool {
        guard let token = KeychainHelper.shared.get(forKey: "accessToken") else { return false }
        do {
            let body = try JWTHelper.shared.decode(jwtToken: token)
            if let iat = body["exp"] as? Double {
                if iat < Date().timeIntervalSince1970-5 {
                    return false
                }
            }
            return true
        } catch {
            return false
        }
    }
    
    private func get(path: String, auth: Bool = false) async throws -> Data {
        guard let url = URL(string: baseUrl+path) else { throw APIErrors.BadURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if auth {
            if !checkAuth() {
                do {
                    try await refresh()
                } catch {
                    print("Ошибка в рефреше")
                }
            }
            guard let token = KeychainHelper.shared.get(forKey: "accessToken") else { throw APIErrors.Unauthorized }
            request.setValue(token, forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 400 || httpResponse.statusCode == 401 {
                throw APIErrors.Unauthorized
            }
            else if httpResponse.statusCode != 200 {
                throw APIErrors.BadServerResponse
            }
        }
        return data
    }
    
    private func post(path: String, body: Data, auth: Bool = false) async throws -> Data {
        guard let url = URL(string: baseUrl+path) else { throw APIErrors.BadURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        if auth {
            if !checkAuth() {
                do {
                    try await refresh()
                } catch {
                    print("Ошибка в рефреше")
                }
            }
            guard let token = KeychainHelper.shared.get(forKey: "accessToken") else { throw APIErrors.Unauthorized }
            request.setValue(token, forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 400 || httpResponse.statusCode == 401 {
                throw APIErrors.Unauthorized
            }
            else if httpResponse.statusCode != 200 {
                print(httpResponse.statusCode)
                throw APIErrors.BadServerResponse
            }
        }
        return data
    }
    
    func getFiles() async throws -> [Tracks] {
        var fetchRequest: NSFetchRequest<Tracks> = Tracks.fetchRequest()
        var tracksArray = try CoreDataManager.shared.context.fetch(fetchRequest)
        var body = TracksBody(files: [])
        tracksArray.forEach({
            body.files.append(TracksNames(name: $0.name!))
        })
        let jsonData = try JSONEncoder().encode(body)
        var filesResponse: Files
        do {
            let data = try await post(path: "tracks/diff", body: jsonData, auth: true)
            filesResponse = try JSONDecoder().decode(Files.self, from: data)
        } catch APIErrors.Unauthorized {
            throw APIErrors.Unauthorized
            } catch {
            print(error)
            filesResponse = Files(files: [])
        }
        let context = CoreDataManager.shared.context
        print(context)
        filesResponse.files.forEach({file in
            let track = Tracks(context: context)
            track.name = file.name
            track.createdAt = Date(timeIntervalSince1970: file.createdAt)
            track.distance = file.distance
            track.time = Int64(file.time)
            track.isPublished = true
            track.user = JWTHelper.shared.getUser()
        })
        CoreDataManager.shared.saveContext()
        fetchRequest = Tracks.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "user == %@", JWTHelper.shared.getUser())
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        tracksArray = try CoreDataManager.shared.context.fetch(fetchRequest)
        return tracksArray
    }
    
    func login(username: String, password: String) async throws {
        let loginData = LoginData(username: username, password: password)
        let body = try JSONEncoder().encode(loginData)
        do {
            let reponse = try await post(path: "auth/login", body: body)
            let tokens = try JSONDecoder().decode(tokens.self, from: reponse)
            KeychainHelper.shared.save(tokens.accessToken, forKey: "accessToken")
            KeychainHelper.shared.save(tokens.refreshToken, forKey: "refreshToken")
        } catch APIErrors.Unauthorized {
            throw APIErrors.IncorrectLoginData
        }
    }
    
    func getGPX(file: String) async throws -> Data {
        let fetchRequest: NSFetchRequest<Tracks> = Tracks.fetchRequest()
        let tracksArray = try CoreDataManager.shared.context.fetch(fetchRequest)
        for track in tracksArray {
            if track.name == file {
                if track.isPublished {
                    return try await get(path: "tracks/\(file).gpx", auth: true)
                } else {
                    guard let data = GPXFileManager.shared.readTrackFile(fileName: file) else {throw APIErrors.NoData}
                    return data
                }
            }
        }
        throw APIErrors.NoData
    }
    
}

struct LoginData : Codable {
    var username: String
    var password: String
}

struct tokens: Codable {
    var accessToken: String
    var refreshToken: String
}

struct Track: Codable {
    var name: String
    var createdAt: Double
    var distance: Double
    var time: Int
}

struct TracksNames: Codable {
    var name: String
}

struct TracksBody: Codable {
    var files: [TracksNames]
}

struct Files: Codable {
    var files: [Track]
}


let apiService = NewAPIService()
