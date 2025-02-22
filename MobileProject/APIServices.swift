//
//  APIServices.swift
//  MobileProject
//
//  Created by Никита Косянков on 05.02.2025.
//

import Foundation

enum APIErrors: Error {
    case NoData
    case IncorrectLoginData
    case ServerError
    case BadURL
    case BadServerResponse
    case Unauthorized
}

protocol APIService {
    var base_url: String { get }
    
    func getFiles() async throws -> Data
    func login(username: String, password: String) async throws -> Data
    func getGPX(filename: String) async throws -> Data
}


class MockAPIService: APIService {

    private let access_token_alive_time: Double = 10
    private let refresh_token_alive_time: Double = 1200
    
    func getFiles() async throws -> Data {
        if !checkAuth() {
            throw APIErrors.Unauthorized
        }
        let gpxFiles = Bundle.main.paths(forResourcesOfType: "gpx", inDirectory: nil)
        let fileNames = gpxFiles.map { URL(fileURLWithPath: $0).deletingPathExtension().lastPathComponent }
        let filesStruct = Files(files: fileNames)
        if let jsonData = try? JSONEncoder().encode(filesStruct) {
            return jsonData
        } else {
            throw APIErrors.NoData
        }
    }
    
    func login(username: String, password: String) async throws -> Data {
        let tokenData: Data
        let access_token = JWTHelper.shared.encode(name: username, alive: access_token_alive_time)
        let refresh_token = JWTHelper.shared.encode(name: username, alive: refresh_token_alive_time)
        let tokenStruct: loginResponse = loginResponse(access_token: access_token, refresh_token: refresh_token)
        if let jsonData = try? JSONEncoder().encode(tokenStruct) {
            tokenData = jsonData
        } else {
            throw APIErrors.NoData
        }
        if username == "test" && password == "test" {
            return tokenData
        } else {
            throw APIErrors.IncorrectLoginData
        }
    }
    
    func getGPX(filename: String) async throws -> Data {
        if !checkAuth() {
            throw APIErrors.Unauthorized
        }
        guard let filePath = Bundle.main.path(forResource: filename, ofType: "gpx") else {throw APIErrors.NoData}
        guard let data = FileManager.default.contents(atPath: filePath) else {
            throw APIErrors.NoData
        }
        return data
    }
    
    private func checkAuth() -> Bool {
        guard let access_token = KeychainHelper.shared.get(forKey: "accessToken") else {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .unauthorized, object: nil)
            }
            return false
        }
        guard let refresh_token = KeychainHelper.shared.get(forKey: "refreshToken") else {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .unauthorized, object: nil)
            }
            return false
        }
        print(access_token)
        print(refresh_token)
        do {
            let body = try JWTHelper.shared.decode(jwtToken: access_token)
            if let iat = body["exp"] as? Double {
                if iat < Date().timeIntervalSince1970 {
                    let refresh_body = try JWTHelper.shared.decode(jwtToken: refresh_token)
                    print(refresh_body)
                    if let refresh_iat = refresh_body["exp"] as? Double, let username = refresh_body["name"] as? String {
                        if refresh_iat < Date().timeIntervalSince1970 {
                            KeychainHelper.shared.delete(forKey: "accessToken")
                            KeychainHelper.shared.delete(forKey: "refreshToken")
                            DispatchQueue.main.async {
                                NotificationCenter.default.post(name: .unauthorized, object: nil)
                            }
                            return false
                        } else {
                            KeychainHelper.shared.delete(forKey: "accessToken")
                            let new_token = JWTHelper.shared.encode(name: username, alive: access_token_alive_time)
                            KeychainHelper.shared.save(new_token, forKey: "accessToken")
                            return true
                        }
                    } else {
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: .unauthorized, object: nil)
                        }
                        return false
                    }
                } else {
                    return true
                }
            } else {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .unauthorized, object: nil)
                }
                return false
            }
        } catch {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .unauthorized, object: nil)
            }
            return false
        }
    }
    
    internal let base_url: String = ""
    
}


class RealAPIService: APIService {
    internal var base_url: String = "http://127.0.0.1:1337/api/"
    
    private func makeAPICall(request: URLRequest) async throws -> Data {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 400 || httpResponse.statusCode == 401 {
                    
                }
                else if httpResponse.statusCode != 200 {
                    throw APIErrors.BadServerResponse
                }
            }
            return data
        } catch {
            print("\(error)")
            throw APIErrors.ServerError
        }
    }
    
    private func refresh(request: URLRequest) async throws -> URLRequest {
        guard let refresh = KeychainHelper.shared.get(forKey: "refreshToken") else {
            throw APIErrors.Unauthorized
        }
        let url = base_url + "auth/refresh"
        guard let url = URL(string: url) else { throw APIErrors.BadURL }
        var refreshRequset = URLRequest(url: url)
        refreshRequset.httpMethod = "GET"
        refreshRequset.setValue(refresh, forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: refreshRequset)
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
        let new_token = try JSONDecoder().decode(refreshResponse.self, from: data)
        let access_token = new_token.access_token
        
        var new_request = request
        new_request.setValue(access_token, forHTTPHeaderField: "Authorization")
        return new_request
    }
    
    func getFiles() async throws -> Data {
        guard let token = KeychainHelper.shared.get(forKey: "accessToken") else { throw APIErrors.Unauthorized }
        let url = base_url + "files"
        guard let url = URL(string: url) else { throw APIErrors.BadURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(token, forHTTPHeaderField: "Authorization")
        return try await makeAPICall(request: request)
    }
    
    func login(username: String, password: String) async throws -> Data {
        let url = base_url + "auth/login"
        guard let url = URL(string: url) else { throw APIErrors.BadURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body = "username=\(username)&password=\(password)"
        request.httpBody = body.data(using: .utf8)
        return try await makeAPICall(request: request)
    }
    
    func getGPX(filename: String) async throws -> Data {
        guard let token = KeychainHelper.shared.get(forKey: "accessToken") else { throw APIErrors.Unauthorized }
        let url = base_url + "files/\(filename)"
        guard let url = URL(string: url) else { throw  APIErrors.BadURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(token, forHTTPHeaderField: "Authorization")
        return try await makeAPICall(request: request)
    }
    
    
}

struct refreshResponse: Codable {
    var access_token: String
}

struct loginResponse: Codable {
    var access_token: String
    var refresh_token: String
}

struct Files: Codable {
    var files: [String]
}

let apiService: APIService = MockAPIService()
