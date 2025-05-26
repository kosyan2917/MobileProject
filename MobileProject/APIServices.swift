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
    let baseUrl = "http://localhost:1337/api/"
    let staticUrl = "http://localhost:1337/static/"
    
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
    
    func getStatic(file: String) async throws -> Data {
        guard let url = URL(string: staticUrl+file) else { throw APIErrors.BadURL }
        print(url)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
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
    
    func getProfile(user: String) async throws -> Profile {
        let response = try await get(path: "profile/\(user)", auth: true)
        let profile = try JSONDecoder().decode(Profile.self, from: response)
        return profile
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
            let userInfo: [String: String] = ["accessToken": tokens.accessToken, "refreshToken": tokens.refreshToken, "username": username]
            NotificationCenter.default.post(name: .loginSuccess, object: nil, userInfo: userInfo)
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
    
    func getPieces(added: Bool) async throws -> [PiecesData] {
        let response: Data
        if added {
            response = try await get(path: "pieces/added", auth: true)
        } else {
            response = try await get(path: "pieces/all", auth: true)
        }
        let result = try JSONDecoder().decode([PiecesData].self, from: response)
        return result
    }
    
    func calculatePieces(filename: String) async throws -> [PiecesStatsData] {
        let track = TracksNames(name: filename + ".gpx")
        let body = try JSONEncoder().encode(track)
        let response = try await post(path: "pieces/calculate", body: body, auth: true)
        let result = try JSONDecoder().decode([PiecesStatsData].self, from: response)
        return result
    }
    
    func sendFile(file: Data, name: String) async throws {
        guard let url = URL(string: baseUrl+"tracks/upload") else { throw APIErrors.BadURL }
        if !checkAuth() {
            do {
                try await refresh()
            } catch {
                print("Ошибка в рефреше")
            }
        }
        guard let token = KeychainHelper.shared.get(forKey: "accessToken") else { throw APIErrors.Unauthorized }
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()

        let mimeType = "application/gpx+xml"
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append(
          "Content-Disposition: form-data; name=\"file\"; filename=\"\(name)\"\r\n"
          .data(using: .utf8)!
        )
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(file)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)",
                         forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        let (_, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            print(http.statusCode)
            throw APIErrors.BadServerResponse
        }
    }
    
    func sync() async throws {
        let files = await CoreDataManager.shared.getNotPublishedTracks()
        for file in files {
            guard let fileData = GPXFileManager.shared.readTrackFile(fileName: file) else {
                continue
            }
            try await sendFile(file: fileData, name: file)
        }
    }
}

struct Profile: Codable {
    var name: String
    var image: String
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

struct PiecesData: Codable {
    var name: String
    var filename: String
    var length: Double
}

struct PiecesStatsData: Codable {
    var name: String
    var path: String
    var time: Int
}


let apiService = NewAPIService()
